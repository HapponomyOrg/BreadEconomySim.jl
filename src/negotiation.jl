# ---- reservation prices (spec v1 §5 with enterprises as employers/sellers) ----

hired_share(model, e::Enterprise) = e.production_target <= 0 ? 0.0 : 1.0   # enterprises have no own capacity

"""The factor a firm's cost floor is divided by when it prices per unit it expects to sell (22 October): 1 − its expected
unsold share (the average of its last months, capped). 1 when the switch is off, for anyone who is not a firm, or with no
history yet."""
function expected_sales_factor(model, seller)
    p = parameters(model)
    (p.floor_per_unit_sold && seller isa Enterprise && !isempty(seller.unsold_history)) || return 1.0
    u = min(sum(seller.unsold_history) / length(seller.unsold_history), p.expected_unsold_cap)
    return max(1 - u, 1 - p.expected_unsold_cap)
end

"""Each firm's unsold share of what it offered this month, kept for `plan_window` months (22 October)."""
function record_unsold!(model)
    p = parameters(model)
    for e in model.enterprise_list
        (e.alive && is_producer(e)) || continue
        good = e.kind == :bakery ? :bread : e.kind == :farm ? :grain : :ticket
        r = e.market[good]
        if r.offered > 1e-9                                                  # 22 Oct (second version): the LOST share — what spoiled — not the unsold share:
            push!(e.unsold_history, min(e.spoiled_this_round / r.offered, 1.0))   # a buffer carried into next month is not a loss, and counting it
        end                                                                  # as one made the floor 1/(1 − buffer) higher every month, which indexed wages turned into inflation
        e.spoiled_this_round = 0.0
        r.offered > 1e-9 || continue
        while length(e.unsold_history) > max(p.plan_window, 1); popfirst!(e.unsold_history); end
    end
    return nothing
end

"""A firm's debt service next month per unit of the good it plans (21 October): instalments and interest ÷ (planned units ×
goods per unit); 0 for anyone who is not a firm, has no loans, or when the switch is off."""
function debt_service_per_unit(model, seller, goods_per_unit::Float64)
    seller isa Enterprise || return 0.0
    due = debt_service_due(model, seller; interest_only = true); due > 0 || return 0.0   # the cost of capital is the interest; the instalments are a cash need, counted in the reserve
    return due / max(seller.production_target * goods_per_unit, 1.0)
end

"""The factor a sector's floor is raised by when it prices on a target margin (21 October): 1 + the net margin grossed up for
the profit tax, so that the margin left after tax is the target."""
function margin_factor(model, kind::Symbol, firm_pricing::Symbol = :sector)
    p = parameters(model)
    mode = firm_pricing != :sector ? firm_pricing : kind == :farm ? p.pricing_target_farm : kind == :bakery ? p.pricing_target_bakery : kind == :theatre ? p.pricing_target_theatre : :reserve
    mode == :margin || return 1.0
    m = kind == :farm ? p.target_net_margin_farm : kind == :bakery ? p.target_net_margin_bakery : p.target_net_margin_theatre
    tax = p.profit_tax_rate > 0 ? min(p.profit_tax_rate * model.profit_tax_scale, 0.95) : 0.0
    return 1 + m / (1 - tax)
end

function seller_reservation(model, seller::Agent, good::Symbol; age::Int = 0)
    p = parameters(model)
    if good == :wage          # person: one meal per round at full capacity, net of tax
        need = meal_price(model)
        p.wage_reservation_includes_savings && (need += max(savings_buffer(model) - cash(seller), 0.0) / p.savings_build_rounds)
        p.wage_reservation_net_of_gi && p.monetary_system == :sumsy && (need = max(need - p.guaranteed_income * income_cut_factor(model), 0.0))
        p.wage_reservation_net_of_gi && p.monetary_system != :sumsy && p.basic_income > 0 && (need = max(need - p.basic_income * income_cut_factor(model) * model.spending_scale, 0.0))   # 14 Oct
        base = need / p.maximum_capacity                        # gross; the tax wedge is left to redistribution (see handoff)
        p.wage_reservation_net_of_tax && (base /= (1 - effective_wage_tax_rate(model)))
        return base * max(1 - p.hunger_wage_discount * seller.hunger, 0.0)
    elseif good == :ticket    # theatre: wages per customer served
        return (expected_price(model, :wage) / p.customers_per_labour_unit + debt_service_per_unit(model, seller, p.customers_per_labour_unit)) / expected_sales_factor(model, seller) * margin_factor(model, :theatre, seller isa Enterprise ? seller.pricing : :sector)
    elseif good == :grain     # farm: rent + wages per unit
        return (expected_price(model, :rent) + expected_price(model, :wage) + debt_service_per_unit(model, seller, 1.0)) / expected_sales_factor(model, seller) * margin_factor(model, :farm, seller isa Enterprise ? seller.pricing : :sector)
    elseif good == :bread     # bakery: (grain + wages) per grain unit, per bread, at this round's actual input prices; ageing discount
        grain_paid = average_price(model, :grain); wage_paid = average_price(model, :wage)
        g = (isnan(grain_paid) || p.indexed_pricing) ? expected_price(model, :grain) : max(grain_paid, expected_price(model, :grain))
        w = (isnan(wage_paid) || p.indexed_pricing) ? expected_price(model, :wage) : max(wage_paid, expected_price(model, :wage))
        base = ((g + w) / p.breads_per_grain + debt_service_per_unit(model, seller, Float64(p.breads_per_grain))) / expected_sales_factor(model, seller) * margin_factor(model, :bakery, seller isa Enterprise ? seller.pricing : :sector)
        return base * max(1 - p.bread_price_ageing_discount * age, 0.0)
    elseif good == :rent      # landowner: a meal from full letting; bank: the going rent
        seller isa Person || return expected_price(model, :rent) * 0.5
        return min(meal_price(model) / max(seller.land, 1), expected_price(model, :rent))
    end
end

function buyer_reservation(model, buyer::Agent, good::Symbol)
    p = parameters(model)
    if good == :rent
        return p.farm_maximum_rent_fraction_of_grain_price * expected_price(model, :grain)
    elseif good == :wage
        limit = employer_wage_limit(model, buyer) * (1 + p.employer_loss_tolerance)   # 30 Sept: a firm hires at a small loss rather than close
        isfinite(p.employer_wage_margin) && (limit = min(limit, going_wage(model) * (1 + p.employer_wage_margin)))   # 28 Sept: at most so far above the going wage
        return p.wage_ceiling_in_breads > 0 ? min(wage_ceiling(model), limit) : limit
    elseif good == :grain
        return p.breads_per_grain * expected_price(model, :bread) - p.bakery_grain_wage_fraction * expected_price(model, :wage)
    elseif good == :bread
        # willingness to pay is for the price including the consumption tax; the seller sees it net
        return expected_price(model, :bread) * (p.bread_bid_base_multiplier + p.bread_bid_hunger_multiplier * buyer.hunger) / (1 + (buyer isa Person ? consumption_tax_rate(model) : 0.0))
    elseif good == :ticket
        worth = expected_price(model, :ticket) * p.bread_bid_base_multiplier
        isfinite(p.ticket_max_in_breads) && (worth = min(worth, p.ticket_max_in_breads * expected_price(model, :bread)))   # 28 Sept: a seat is worth so many loaves
        return worth / (1 + (buyer isa Person ? consumption_tax_rate(model) : 0.0))
    end
end

"""Statutory maximum wage per labour unit: `wage_ceiling_in_breads` loaves per full-time round, at the expected bread price."""
wage_ceiling(model) = parameters(model).wage_ceiling_in_breads * expected_price(model, :bread) / parameters(model).maximum_capacity

"""Was last month's bread short of what the village needs? (`food_emergency_share` of a meal for everyone alive.)"""
function food_emergency(model)
    p = parameters(model)
    p.food_emergency_share > 0 || return false
    d = model.data
    isempty(d) && return false
    row = d[end]
    return row.bread_baked < p.food_emergency_share * p.breads_per_meal * row.persons_alive
end

"""The going wage an employer measures itself against: the wage actually paid last month (not the asks — the idle cut theirs in
desperation and would drag the reference, and with it every employer's ceiling, below what workers in work will accept)."""
function going_wage(model)
    d = model.data
    if !isempty(d)
        w = d[end].price_wage
        isfinite(w) && w > 0 && return w
    end
    return expected_price(model, :wage)
end

"""The employer's own limit on the wage: what it recovers per unit of labour from the price it asks for its output (or the market average)."""
function employer_wage_limit(model, buyer::Agent)
    p = parameters(model)
    if p.wage_ceiling_from_own_ask
        is_farm(buyer) && return max(buyer.ask[:grain], seller_reservation(model, buyer, :grain)) - expected_price(model, :rent)
        is_bakery(buyer) && return p.breads_per_grain * max(buyer.ask[:bread], seller_reservation(model, buyer, :bread)) - expected_price(model, :grain)
        is_theatre(buyer) && return p.customers_per_labour_unit * max(buyer.ask[:ticket], seller_reservation(model, buyer, :ticket))
    end
    is_theatre(buyer) && return p.customers_per_labour_unit * expected_price(model, :ticket)
    is_farm(buyer) && return expected_price(model, :grain) - expected_price(model, :rent)
    is_bakery(buyer) && return p.breads_per_grain * expected_price(model, :bread) - expected_price(model, :grain)
    return max(is_sumsy(model) ? cash(buyer) : buyer.retained_interest, expected_price(model, :wage))            # bank
end

# ---- conceding (spec v1 §5) -----------------------------------------------------

function negotiate(model, seller::Agent, buyer::Agent, good::Symbol; age::Int = 0)
    key = (good, buyer.id)
    haskey(seller.negotiated, key) && return seller.negotiated[key]
    p = parameters(model); rng = stream(model, :negotiation)
    p.fixed_prices && return p.initial_prices[good] * p.initial_price_multiplier     # 26 Sept: the starting price, always
    seller_floor = seller_reservation(model, seller, good; age = age)
    if good == :wage && seller isa Person && p.wage_cut_maximum < 1 && seller.last_wage_rate > 0 && current_round(model) - seller.last_wage_round <= p.wage_floor_months && !food_emergency(model)
        seller_floor = max(seller_floor, seller.last_wage_rate * (1 - p.wage_cut_maximum))   # 27 Sept: what a worker in work will accept; out of work, the floor is gone
    end
    buyer_ceiling = buyer_reservation(model, buyer, good)
    ask = max(seller.ask[good], seller_floor)
    bid = min(buyer.bid[good], buyer_ceiling)
    price = nothing
    for step in 0:p.negotiation_steps
        if bid >= ask
            price = (ask + bid) / 2; break
        end
        step == p.negotiation_steps && break
        f_s = p.minimum_concession_fraction + rand(rng) * (p.maximum_concession_fraction - p.minimum_concession_fraction)
        f_b = p.minimum_concession_fraction + rand(rng) * (p.maximum_concession_fraction - p.minimum_concession_fraction)
        ask -= f_s * (ask - seller_floor)
        bid += f_b * (buyer_ceiling - bid)
    end
    price === nothing && buyer_ceiling >= seller_floor && (price = clamp((ask + bid) / 2, seller_floor, buyer_ceiling))   # never outside the zone (review 1, §5.1)
    price === nothing && return nothing
    price = round(price, digits = 4)
    seller.negotiated[key] = price
    return price
end

# ---- end-of-round adaptation (spec v1 §5, v2 §6) -----------------------------------

sells(a::Agent) = a isa Person ? (a.land > 0 ? (:wage, :rent) : (:wage,)) : a.kind == :farm ? (:grain,) : a.kind == :bakery ? (:bread,) : a.kind == :bank ? (:rent,) : a.kind == :theatre ? (:ticket,) : ()
buys(a::Agent) = a isa Person ? (:bread, :ticket) : a.kind == :farm ? (:rent, :wage) : a.kind == :bakery ? (:grain, :wage) : a.kind in (:bank, :theatre) ? (:wage,) : ()

"""
    demand_unmet(model, a, good)

Did demand for this good go unmet enough to react to? With `unmet_demand_share = 0` any miss counts (the original
rule). Otherwise the units the market failed to serve must be at least that share of what it sold plus what it
missed. Wages follow the same rule when `wage_threshold` is on (25 September); off, any miss raises the wage.
"""
function demand_unmet(model, a::Agent, good::Symbol)
    r = a.market[good]
    r.unmet_demand || return false
    share = parameters(model).unmet_demand_share
    (share <= 0 || (good == :wage && !parameters(model).wage_threshold)) && return true
    sold = sum(e.market[good].sold for e in alive_agents(model) if good in sells(e); init = 0.0)
    return r.unmet_units >= share * (sold + r.unmet_units) - 1e-9
end

"""The lowest a seller will post: unit cost, plus a markup while its reserves are not full."""
function ask_floor(model, a::Agent, good::Symbol)
    p = parameters(model)
    cost = seller_reservation(model, a, good)
    short = a isa Enterprise ? cash(a) < reserve_target(model, a) : cash(a) < savings_buffer(model)
    return cost * (1 + (short ? p.ask_floor_markup_when_short : 0.0))
end

"""Is this firm greedy (13 October)? Owned by greedy villagers, share-weighted; with no owners, a village whose greedy are the majority."""
function greedy_firm(model, e::Enterprise)
    p = parameters(model)
    p.greed || return false
    isempty(e.shares) && return p.greed_share >= 0.5
    g = 0.0; t = 0.0
    for (hid, units) in e.shares
        h = model[hid]
        t += units; h isa Person && h.greed == :greedy && (g += units)
    end
    return t > 0 && g / t >= 0.5
end

"""Is failure near (13 October)? Overdue obligations at `distress_share` of what would wind the firm up."""
function in_distress(model, e::Enterprise)
    p = parameters(model)
    e.kind in (:farm, :bakery, :theatre) || return false
    overdue = p.liquidation_test == :book ? invoices_overdue(model, e, p.liquidation_overdue_rounds) : obligations_overdue(model, e, p.liquidation_overdue_rounds)
    overdue > 1e-6 || return false
    turnover = isempty(e.turnover_history) ? 0.0 : sum(e.turnover_history) / length(e.turnover_history)
    turnover > 0 || return true
    return overdue >= p.distress_share * p.liquidation_arrears_share * turnover
end

"""Did the firm leave stock on the shelf last month (14 October)? Unsold at least `unsold_share` of what it offered."""
function shelf_left(model, e::Enterprise, g::Symbol)
    r = e.market[g]
    return r.offered > 1e-9 && r.sold < r.offered - 1e-9 && r.offered - r.sold >= parameters(model).unsold_share * r.offered - 1e-9   # 15 Oct: a sell-out leaves nothing on the shelf, whatever the threshold
end

"""The firm's own good: what it makes and sells."""
own_good(e::Enterprise) = is_farm(e) ? :grain : e.kind == :bakery ? :bread : is_theatre(e) ? :ticket : :none

"""
    distress_cost_cutting!(model)

After the month's plan (14 October): a firm near failure that did not sell out cuts next month's target to what it sold — the grain
a bakery buys, the hands a theatre hires — so that it spends only on what it can sell. A firm that sold out does not cut: its
answer is the price.
"""
function distress_cost_cutting!(model)
    p = parameters(model)
    p.distress_cost_cutting || return nothing
    for e in alive_agents(model)
        e isa Enterprise || continue
        g = own_good(e); g == :none && continue
        in_distress(model, e) || continue
        r = e.market[g]
        r.offered > 1e-9 || continue
        r.sold >= r.offered - 1e-9 && continue                                     # sold out: the price is the answer
        sold_target = e.kind == :bakery ? ceil(Int, r.sold / p.breads_per_grain) :
                      is_theatre(e) ? ceil(Int, r.sold / p.customers_per_labour_unit) : ceil(Int, r.sold)
        if sold_target < e.production_target
            log_event!(model, :distress_cut; actor = e.id, agent_kind = e.kind, from = e.production_target, to = sold_target)
            e.production_target = sold_target
        end
    end
    return nothing
end

"""The price that would clear a firm's arrears within `distress_months` (13 October): cost plus the arrears per unit it expects to sell."""
function distress_price(model, e::Enterprise, g::Symbol)
    p = parameters(model)
    overdue = p.liquidation_test == :book ? invoices_overdue(model, e, p.liquidation_overdue_rounds) : obligations_overdue(model, e, p.liquidation_overdue_rounds)
    units = max(e.market[g].sold, 1.0)
    return seller_reservation(model, e, g) + overdue / (units * max(p.distress_months, 1))
end

function adapt_prices!(model)
    parameters(model).fixed_prices && return nothing                                  # 26 Sept: nobody changes a price
    p = parameters(model)
    for a in alive_agents(model)
        for g in sells(a)
            r = a.market[g]
            if p.levy_pass_through && a isa Person && g == :rent && a.land > 0  # 16 Oct: Gesell's objection — the owner asks the levy on top of the rent; the market decides whether it sticks
                a.ask[g] = max(a.ask[g], expected_price(model, :rent) + land_levy_rate(model) * land_valuation_price(model))
            end
            if a isa Enterprise && a.community && g == :ticket                # 15 Oct: a community theatre's seat costs a fixed share of a loaf
                a.ask[g] = round(p.community_ticket_in_breads * expected_price(model, :bread), digits = 4); continue
            end
            r.offered <= 1e-9 && continue
            if p.price_on_expected_sales && a isa Enterprise && g != :wage && a.expected_sales > 0   # 22 Oct: against what it expected to sell
                r.idle_rounds = r.sold > 1e-9 ? 0 : r.idle_rounds + 1
                if r.sold >= r.offered - 1e-9 && demand_unmet(model, a, g)           # 22 Oct (Stef): up only when the whole buffer is gone AND customers were turned away — selling into the buffer raises the buffer, not the price
                    a.ask[g] *= 1 + p.ask_increase_after_sellout
                elseif r.sold < a.expected_sales * (1 - p.expected_sales_tolerance) - 1e-9
                    a.ask[g] *= 1 - (r.sold > 1e-9 ? p.ask_decrease_after_partial_sale : p.ask_decrease_when_idle[min(r.idle_rounds, length(p.ask_decrease_when_idle))])
                end
                if p.affordability_pricing && r.failed_for_cash > 0 && r.max_failed_cash > 0
                    a.ask[g] = max(seller_reservation(model, a, g), min(a.ask[g], 0.95 * r.max_failed_cash))
                end
                a.ask[g] = max(a.ask[g], seller_reservation(model, a, g))
                continue
            end
            if r.sold >= r.offered - 1e-9
                r.idle_rounds = 0
                (!p.ask_increase_only_on_unmet_demand || demand_unmet(model, a, g)) && (a.ask[g] *= 1 + p.ask_increase_after_sellout)
                if p.greedy_pricing && a isa Enterprise && g != :wage && greedy_firm(model, a)       # 13 Oct: a greedy firm takes what the market allows
                    a.ask[g] = max(a.ask[g], expected_price(model, g) * p.bread_bid_base_multiplier)
                end
            elseif r.sold > 1e-9
                r.idle_rounds = 0
                tol = (g == :wage && p.no_labour_tolerance) ? 0.0 : p.unsold_tolerance_units
                unsold = r.offered - r.sold
                partly_unsold = p.unsold_share > 0 && g != :wage ? unsold >= p.unsold_share * r.offered - 1e-9 : unsold > tol
                partly_unsold && (a.ask[g] *= 1 - p.ask_decrease_after_partial_sale)
            else
                r.idle_rounds += 1
                a.ask[g] *= 1 - p.ask_decrease_when_idle[min(r.idle_rounds, length(p.ask_decrease_when_idle))]
            end
            if p.affordability_pricing && r.failed_for_cash > 0 && r.max_failed_cash > 0
                a.ask[g] = max(seller_reservation(model, a, g), min(a.ask[g], 0.95 * r.max_failed_cash))
            end
            if p.tiered_bread_price && is_bakery(a) && g == :bread
                if a.tier_unmet
                    a.tier_multiplier *= 1 + p.tier_step
                elseif a.tier_sold == 0 && bread_units(a) > p.unsold_tolerance_units
                    a.tier_multiplier = max(a.tier_multiplier * (1 - p.tier_step), 1.0)
                end
            end
            if p.reserve_pricing && is_producer(a)
                target = reserve_target(model, a)
                if cash(a) > target
                    a.ask[g] = max(a.ask[g] * (1 - p.reserve_pricing_step), seller_reservation(model, a, g))
                elseif cash(a) < 0.5 * target
                    a.ask[g] *= 1 + p.reserve_pricing_step
                end
            end
            p.ask_floor == :cost && (a.ask[g] = max(a.ask[g], ask_floor(model, a, g)))
            if p.distress_pricing && a isa Enterprise && g != :wage && in_distress(model, a) && !(p.distress_cost_cutting && shelf_left(model, a, g))   # 13 Oct: failure near — the step limit goes (14 Oct: unless stock is left — then it cuts)
                a.ask[g] = max(a.ask[g], distress_price(model, a, g))
                log_event!(model, :distress_price; actor = a.id, agent_kind = a.kind, good = g, price = a.ask[g])
            end
        end
        for g in buys(a)
            r = a.market[g]
            r.wanted <= 1e-9 && continue
            if r.got >= r.wanted - 1e-9
                r.starved_rounds = 0; a.bid[g] *= 1 - p.bid_decrease_after_success
            else
                r.starved_rounds += 1
                a.bid[g] *= 1 + p.bid_increase_when_starved[min(r.starved_rounds, length(p.bid_increase_when_starved))]
            end
        end
    end
    return nothing
end

"""The loaves one bakery can bake in a month (14 October): what the village's labour would let it, at its share of the hands —
the planner must not target more than the ovens can turn out."""
function bakery_capacity_loaves(model)
    p = parameters(model)
    hands = p.maximum_capacity * length(persons(model))                   # the village at full strength — not today's hungry capacity (that fed a spiral)
    nb = max(length(enterprises(model, :bakery)), 1)
    return p.breads_per_grain * hands / nb * p.bakery_capacity_share      # a unit of labour bakes one grain
end

"""
    update_intervention!(model)

The emergency rule (19 October, Stef): an intervention begins when bread was short for want of production — the bakeries baked
less than the village's meals and people went hungry; hunger with bread left on the shelves is want of money, an outcome, not an
emergency. It ends after `intervention_exit_months` months running in which the village baked enough.
"""
function update_intervention!(model)
    p = parameters(model); p.own_market_planning || return nothing
    isempty(model.data) && return nothing
    x = model.data[end]
    need = p.breads_per_meal * x.persons_alive
    short = x.bread_baked < need - 1e-9 && x.hungry > 0
    if model.intervention
        model.intervention_months += 1
        model.fed_months = x.bread_baked >= need - 1e-9 ? model.fed_months + 1 : 0
        if model.fed_months >= p.intervention_exit_months
            model.intervention = false; model.fed_months = 0
            log_event!(model, :intervention_ended; months = model.intervention_months)
        end
    elseif short
        model.intervention = true; model.fed_months = 0
        log_event!(model, :intervention_started; baked = x.bread_baked, need = need, hungry = x.hungry)
    end
    return nothing
end

"""A firm's own plan (19 October; 21 October: on the average of its last `plan_window` months, net of usable stock): what it sold
plus its share of the customers turned away, averaged over the window (the months before its first taken as its first plan);
a firm that sold out plans `plan_step` more; the stock it carries into next month that will not spoil first is deducted."""
function own_plan!(model, e::Enterprise, good::Symbol, per_unit::Float64, cap::Int, n_kind::Int = 1)
    p = parameters(model); r = e.market[good]
    r.offered > 1e-9 || return nothing                                      # nothing offered last month: keep the plan
    turned_away = p.own_plan_counts_unmet ? r.unmet_units / max(n_kind, 1) : 0.0   # unmet demand is booked on every seller of the kind; this firm's share
    observed = r.sold + turned_away
    if p.plan_window > 1
        h = e.sales_history
        isempty(h) && append!(h, fill(e.production_target * per_unit, p.plan_window - 1))   # the missing months: its first plan
        push!(h, observed); while length(h) > p.plan_window; popfirst!(h); end
        # 21 Oct: the average guards against a dip; a rise is followed at once (the average alone kept firms sold out longer, and
        # every sold-out month raised the price: SuMSy step 8 +7 %/yr against +3.5 % on last month alone)
        expected = (p.plan_window_follows_rises ? max(sum(h) / length(h), observed) : sum(h) / length(h)) * (1 + p.planning_margin)
    else
        expected = observed * (1 + p.planning_margin)
    end
    r.sold >= r.offered * (1 - p.unsold_share) - 1e-9 && (expected = max(expected, e.production_target * per_unit * (1 + p.plan_step)))   # sold out: more
    if p.price_on_expected_sales                                            # 22 Oct: the plan is expected sales plus the firm's own buffer
        e.buffer_share < 0 && (e.buffer_share = max(p.planning_margin, p.buffer_min))
        base_expected = expected / (1 + p.planning_margin)                  # the margin was applied above; the firm's buffer replaces it
        if r.sold > e.expected_sales + 1e-9 && e.expected_sales > 0          # sold into the buffer: keep more
            e.buffer_share = min(e.buffer_share * (1 + p.buffer_step), p.buffer_max)
        elseif e.expected_sales > 0 && r.offered - r.sold >= e.expected_sales * e.buffer_share - 1e-9   # the extra never sold: keep less, never nothing
            e.buffer_share = max(e.buffer_share * (1 - p.buffer_step), p.buffer_min)
        end
        e.expected_sales = base_expected
        expected = base_expected * (1 + e.buffer_share)
    end
    if p.plan_nets_stock                                                    # the stock that will still be good next month
        items = good == :bread ? e.bread : good == :grain ? e.grain : StockItem[]
        usable = sum(i.units for i in items if i.age < p.spoilage_age_in_rounds - 1; init = 0.0)
        expected = max(expected - usable, 0.0)
    end
    desired = expected / per_unit
    if p.plan_window > 1
        target = desired                                                    # the window already smooths: no gradual pace on top
    else
        current = Float64(e.production_target); gap = desired - current
        if abs(gap) <= max(p.plan_small_change * current, 1.0)
            e.share_trend = 0; target = desired
        else
            dir = gap > 0 ? 1 : -1
            e.share_trend = sign(e.share_trend) == dir ? e.share_trend + dir : dir
            target = current + min(abs(e.share_trend), p.plan_adjustment_months) / p.plan_adjustment_months * gap
        end
    end
    e.production_target = clamp(ceil(Int, target - 1e-9), 1, cap)
    return nothing
end

function plan_targets!(model)
    p = parameters(model)
    ps = persons(model)
    own = p.own_market_planning && !model.intervention && current_round(model) > 2   # 19 Oct: the firms' own plans, unless the emergency rule is in force
    bakeries = sort(enterprises(model, :bakery); by = b -> b.id)
    farms = sort(enterprises(model, :farm); by = f -> f.id)
    demand_bread = sum(max(p.breads_per_meal - bread_units(w), 0.0) for w in ps; init = 0.0) * (1 + p.planning_margin)
    # expected gluttony: persons who can pay for a meal plus the extra bread from cash
    if p.plan_for_gluttony
        extra = p.maximum_breads_per_round - p.breads_per_meal
        can_pay = count(w -> w.greed == :none && cash(w) >= p.maximum_breads_per_round * expected_price(model, :bread), ps)
        demand_bread += p.gluttony_probability * extra * can_pay
        # 14 Oct: greedy demand is planned on what the greedy bought last month, not on what they could afford — the cash
        # estimate planned three times the village's baking capacity in the greedy village, and the bakeries bought the grain
        # for it and died of it (the trace of 14 October)
        if p.greed && p.plan_greedy_on_purchases
            demand_bread += isempty(model.data) ? 0.0 : Float64(model.data[end].greedy_loaves)
        else
            bp = expected_price(model, :bread)
            for w in ps
                w.greed == :greedy || continue
                share = (1 - p.greed_hoarding) * (p.entertainment ? 0.5 : 1.0)
                demand_bread += clamp(floor(share * (cash(w) - buffer_target(model, w)) / bp), 0, p.greedy_max_breads_per_round - p.breads_per_meal)
            end
        end
    end
    stock_bread = sum(bread_units(b) for b in bakeries; init = 0.0)
    grain_for_bread = max(ceil(Int, (demand_bread - stock_bread) / p.breads_per_grain), 0)
    if p.plan_within_capacity && !isempty(bakeries)                                  # 14 Oct: no bakery targets grain its hands cannot bake
        cap_each = ceil(Int, bakery_capacity_loaves(model) / p.breads_per_grain)
        grain_for_bread = min(grain_for_bread, cap_each * length(bakeries))
    end
    allot!(units, group) = for (k, e) in enumerate(group)
        e.production_target = units ÷ length(group) + (k <= units % length(group) ? 1 : 0)
    end
    # 15 Oct: in proportion to last month's sales of the firm's own good, at least one unit each
    function by_sales!(units, group, good)
        p.firms_plan_on_sales || return allot!(units, group)
        n = length(group)
        for e in group; e.plan_share >= 0 || (e.plan_share = 1 / n); end         # new or restarted firms start at an equal share
        sum(e.plan_share for e in group) > 1e-12 || for e in group; e.plan_share = 1 / n; end   # 16 Oct: the firms that held the shares are gone
        sold = [e.market[good].sold for e in group]
        offered = sum(e.market[good].offered for e in group; init = 0.0)
        # sales below half of what was offered are no signal (month 1: everyone's cupboard holds a meal): the shares stay as they are
        if sum(sold) > 0 && sum(sold) >= 0.5 * offered
            current = [e.plan_share for e in group] ./ sum(e.plan_share for e in group)
            target = sold ./ sum(sold)
            for (k, e) in enumerate(group)
                gap = target[k] - current[k]
                if abs(gap) <= p.plan_small_change * max(current[k], 1 / n)    # a small change is followed at once
                    e.share_trend = 0; e.plan_share = target[k]
                else                                                          # a large one a third, two thirds, then all the way
                    dir = gap > 0 ? 1 : -1
                    e.share_trend = sign(e.share_trend) == dir ? e.share_trend + dir : dir
                    e.plan_share = current[k] + min(abs(e.share_trend), p.plan_adjustment_months) / p.plan_adjustment_months * gap
                end
            end
        end
        if p.plan_share_floor > 0                                              # 19 Oct: the floor under every firm's share
            floor_share = p.plan_share_floor / n
            for e in group; e.plan_share = max(e.plan_share, floor_share); end
        end
        shares = [e.plan_share for e in group] ./ sum(e.plan_share for e in group)
        raw = units .* shares; t = floor.(Int, raw)
        for k in sortperm(raw .- t; rev = true)[1:(units - sum(t))]; t[k] += 1; end
        if units >= length(group)
            for k in eachindex(t)
                t[k] == 0 || continue
                j = argmax(t); t[j] > 1 && (t[j] -= 1; t[k] = 1)
            end
        end
        for (e, x) in zip(group, t); e.production_target = x; end
        return nothing
    end
    if own
        cap_each = p.plan_within_capacity ? ceil(Int, bakery_capacity_loaves(model) / p.breads_per_grain) : typemax(Int) ÷ 2
        for b in bakeries; own_plan!(model, b, :bread, Float64(p.breads_per_grain), cap_each, length(bakeries)); end
    else
        isempty(bakeries) || by_sales!(grain_for_bread, bakeries, :bread)
    end
    if p.plan_within_capacity && !isempty(bakeries)                                # each bakery within its ovens (16 Oct: what is clipped is lost — no planner hands it on)
        cap_each = ceil(Int, bakery_capacity_loaves(model) / p.breads_per_grain)
        for b in bakeries; b.production_target = min(b.production_target, cap_each); end
    end
    grain_demand = sum(max(b.production_target - floor(Int, grain_units(b) + 1e-9), 0) for b in bakeries; init = 0)
    if own
        for f in farms; own_plan!(model, f, :grain, 1.0, typemax(Int) ÷ 2, length(farms)); end
    else
        isempty(farms) || by_sales!(grain_demand, farms, :grain)
    end
    for e in vcat(bakeries, farms)
        e.production_target = max(e.production_target, 1)
    end
    theatres = sort(enterprises(model, :theatre); by = t -> t.id)
    if !isempty(theatres)
        tp = expected_price(model, :ticket)
        expected = 0.0
        for w in ps
            w.greed == :cash_hoarder && continue                          # 15 Oct: cash hoarders buy no tickets
            afford = floor(Int, max(cash(w) - buffer_target(model, w), 0.0) / tp)
            afford >= 1 || continue
            if w.greed == :greedy
                expected += p.plan_for_tickets ? min(floor((1 - p.greed_hoarding) * afford / 2), p.greedy_max_tickets_per_round) : 1.0; continue
            end
            expected += p.entertainment_propensity * (p.plan_for_tickets ? sum(min(afford, k) for k in 1:p.max_tickets_per_person) / p.max_tickets_per_person : 1.0)
        end
        units = max(ceil(Int, expected / p.customers_per_labour_unit), length(theatres))
        if own
            for t in theatres; own_plan!(model, t, :ticket, p.customers_per_labour_unit, max(floor(Int, theatre_labour_cap(model, t)), 1), length(theatres)); end
        else
            by_sales!(units, theatres, :ticket)
        end                                                              # 15 Oct: the same logic as bakeries and farms
        if p.shows_per_round > 0                            # a theatre cannot use more labour than its seats take
            for t in theatres
                t.production_target = min(t.production_target, Int(theatre_labour_cap(model, t)))
            end
        end
    end
    return nothing
end

"""Farm/bakery target +1 when demand went unmet, −1 when stock was left, bounded by the living persons' capacity."""
function adapt_targets!(model)
    p = parameters(model)
    p.demand_based_targets && return plan_targets!(model)
    total_capacity = sum(w.capacity for w in persons(model); init = 0.0)
    for e in alive_agents(model)
        is_producer(e) || continue
        if is_theatre(e)                     # service: unmet demand → +1 unit of labour, idle capacity → −1
            r = e.market[:ticket]
            demand_unmet(model, e, :ticket) && (e.production_target += 1)
            r.offered - r.sold > p.unsold_tolerance_units && (e.production_target -= 1)
            e.production_target = clamp(e.production_target, 1, max(floor(Int, min(total_capacity, theatre_labour_cap(model, e))), 1))
            continue
        end
        good = e.kind == :farm ? :grain : :bread
        r = e.market[good]
        stock_left = e.kind == :farm ? grain_units(e) : bread_units(e)
        if demand_unmet(model, e, good) && stock_left <= 1e-9
            e.production_target += 1
        elseif stock_left > (e.kind == :bakery ? p.unsold_tolerance_units : p.unsold_tolerance_units / p.breads_per_grain)
            e.production_target -= 1
        end
        e.production_target = clamp(e.production_target, 1, max(floor(Int, total_capacity), 1))
    end
    return nothing
end

"""
    absorb_surplus!(model)

Once an enterprise's cash reaches `surplus_reserve_multiple` × its standard reserve, next round's wage bid is
raised so that the expected wage bill absorbs everything above the standard reserve (spec v2 §3). Banks apply
the same rule to retained interest against their own wage bill.
"""
function absorb_surplus!(model)
    p = parameters(model)
    for e in alive_agents(model)
        e isa Enterprise || continue
        if is_producer(e)
            standard = reserve_target(model, e)
            standard <= 0 && continue
            surplus = cash(e) - standard
            units = max(e.production_target, 1)
            if cash(e) >= p.surplus_reserve_multiple * standard && surplus > 0
                e.bid[:wage] = max(e.bid[:wage], (units * expected_price(model, :wage) + surplus) / units)
                p.wage_ceiling_in_breads > 0 && (e.bid[:wage] = min(e.bid[:wage], wage_ceiling(model)))
                log_event!(model, :surplus_to_wages; actor = e.id, agent_kind = e.kind, surplus = surplus, wage_bid = e.bid[:wage])
            end
        elseif is_bank(e)
            standard = p.reserve_target_in_rounds * expected_price(model, :wage)
            funds = is_sumsy(model) ? cash(e) : e.retained_interest
            if funds >= p.surplus_reserve_multiple * standard && standard > 0
                e.bid[:wage] = max(e.bid[:wage], expected_price(model, :wage) + (funds - standard))
                log_event!(model, :surplus_to_wages; actor = e.id, agent_kind = e.kind, surplus = funds - standard, wage_bid = e.bid[:wage])
            end
        end
    end
    return nothing
end

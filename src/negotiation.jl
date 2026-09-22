# ---- reservation prices (spec v1 §5 with enterprises as employers/sellers) ----

hired_share(model, e::Enterprise) = e.production_target <= 0 ? 0.0 : 1.0   # enterprises have no own capacity

function seller_reservation(model, seller::Agent, good::Symbol; age::Int = 0)
    p = parameters(model)
    if good == :wage          # person: one meal per round at full capacity, net of tax
        need = meal_price(model)
        p.wage_reservation_includes_savings && (need += max(savings_buffer(model) - cash(seller), 0.0) / p.savings_build_rounds)
        p.wage_reservation_net_of_gi && p.monetary_system == :sumsy && (need = max(need - p.guaranteed_income, 0.0))
        base = need / p.maximum_capacity                        # gross; the tax wedge is left to redistribution (see handoff)
        p.wage_reservation_net_of_tax && (base /= (1 - effective_wage_tax_rate(model)))
        return base * max(1 - p.hunger_wage_discount * seller.hunger, 0.0)
    elseif good == :ticket    # theatre: wages per customer served
        return expected_price(model, :wage) / p.customers_per_labour_unit
    elseif good == :grain     # farm: rent + wages per unit
        return expected_price(model, :rent) + expected_price(model, :wage)
    elseif good == :bread     # bakery: (grain + wages) per grain unit, per bread, at this round's actual input prices; ageing discount
        grain_paid = average_price(model, :grain); wage_paid = average_price(model, :wage)
        g = (isnan(grain_paid) || p.indexed_pricing) ? expected_price(model, :grain) : max(grain_paid, expected_price(model, :grain))
        w = (isnan(wage_paid) || p.indexed_pricing) ? expected_price(model, :wage) : max(wage_paid, expected_price(model, :wage))
        base = (g + w) / p.breads_per_grain
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
        limit = employer_wage_limit(model, buyer)
        return p.wage_ceiling_in_breads > 0 ? min(wage_ceiling(model), limit) : limit
    elseif good == :grain
        return p.breads_per_grain * expected_price(model, :bread) - p.bakery_grain_wage_fraction * expected_price(model, :wage)
    elseif good == :bread
        # willingness to pay is for the price including the consumption tax; the seller sees it net
        return expected_price(model, :bread) * (p.bread_bid_base_multiplier + p.bread_bid_hunger_multiplier * buyer.hunger) / (1 + (buyer isa Person ? consumption_tax_rate(model) : 0.0))
    elseif good == :ticket
        return expected_price(model, :ticket) * p.bread_bid_base_multiplier / (1 + (buyer isa Person ? consumption_tax_rate(model) : 0.0))
    end
end

"""Statutory maximum wage per labour unit: `wage_ceiling_in_breads` loaves per full-time round, at the expected bread price."""
wage_ceiling(model) = parameters(model).wage_ceiling_in_breads * expected_price(model, :bread) / parameters(model).maximum_capacity

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
    seller_floor = seller_reservation(model, seller, good; age = age)
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
missed. Wages always use the original rule (see the parameter).
"""
function demand_unmet(model, a::Agent, good::Symbol)
    r = a.market[good]
    r.unmet_demand || return false
    share = parameters(model).unmet_demand_share
    (share <= 0 || good == :wage) && return true
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

function adapt_prices!(model)
    p = parameters(model)
    for a in alive_agents(model)
        for g in sells(a)
            r = a.market[g]
            r.offered <= 1e-9 && continue
            if r.sold >= r.offered - 1e-9
                r.idle_rounds = 0
                (!p.ask_increase_only_on_unmet_demand || demand_unmet(model, a, g)) && (a.ask[g] *= 1 + p.ask_increase_after_sellout)
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

"""
    plan_targets!(model)

Demand-based production planning: bakeries plan the grain (→ bread) needed to feed the living population next
round, net of the bread they hold; farms plan the grain the bakeries will ask for, net of the grain they hold.
Whole units are allotted round-robin so the total matches demand (no structural glut). Targets do not shrink
with hunger: the population, not last round's sales, sets the plan.
"""
function plan_targets!(model)
    p = parameters(model)
    ps = persons(model)
    bakeries = sort(enterprises(model, :bakery); by = b -> b.id)
    farms = sort(enterprises(model, :farm); by = f -> f.id)
    demand_bread = sum(max(p.breads_per_meal - bread_units(w), 0.0) for w in ps; init = 0.0) * (1 + p.planning_margin)
    # expected gluttony: persons who can pay for a meal plus the extra bread from cash
    if p.plan_for_gluttony
        extra = p.maximum_breads_per_round - p.breads_per_meal
        can_pay = count(w -> w.greed == :none && cash(w) >= p.maximum_breads_per_round * expected_price(model, :bread), ps)
        demand_bread += p.gluttony_probability * extra * can_pay
        bp = expected_price(model, :bread)
        for w in ps
            w.greed == :greedy || continue
            share = (1 - p.greed_hoarding) * (p.entertainment ? 0.5 : 1.0)
            demand_bread += clamp(floor(share * (cash(w) - buffer_target(model, w)) / bp), 0, p.greedy_max_breads_per_round - p.breads_per_meal)
        end
    end
    stock_bread = sum(bread_units(b) for b in bakeries; init = 0.0)
    grain_for_bread = max(ceil(Int, (demand_bread - stock_bread) / p.breads_per_grain), 0)
    allot!(units, group) = for (k, e) in enumerate(group)
        e.production_target = units ÷ length(group) + (k <= units % length(group) ? 1 : 0)
    end
    isempty(bakeries) || allot!(grain_for_bread, bakeries)
    grain_demand = sum(max(b.production_target - floor(Int, grain_units(b) + 1e-9), 0) for b in bakeries; init = 0)
    isempty(farms) || allot!(grain_demand, farms)
    for e in vcat(bakeries, farms)
        e.production_target = max(e.production_target, 1)
    end
    theatres = sort(enterprises(model, :theatre); by = t -> t.id)
    if !isempty(theatres)
        tp = expected_price(model, :ticket)
        expected = 0.0
        for w in ps
            afford = floor(Int, max(cash(w) - buffer_target(model, w), 0.0) / tp)
            afford >= 1 || continue
            if w.greed == :greedy
                expected += p.plan_for_tickets ? min(floor((1 - p.greed_hoarding) * afford / 2), p.greedy_max_tickets_per_round) : 1.0; continue
            end
            expected += p.entertainment_propensity * (p.plan_for_tickets ? sum(min(afford, k) for k in 1:p.max_tickets_per_person) / p.max_tickets_per_person : 1.0)
        end
        units = max(ceil(Int, expected / p.customers_per_labour_unit), length(theatres))
        allot!(units, theatres)
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

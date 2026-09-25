# ---- land market (spec v1 §4.2, v2 §3) ----------------------------------------

land_to_let(a::Agent) = (a isa Person || is_bank(a)) ? a.land - a.land_let : 0

"""A landowner's reservation price for a unit: the value of the rent stream at the cost of holding cash instead."""
function land_reservation(model, o::Person)
    p = parameters(model); rent = expected_price(model, :rent)
    p.land_pricing == :market && return land_worth(model, seller_alternative(model))   # 24 Sept: the seller's best alternative for the money
    p.monetary_system == :sumsy && p.demurrage_rate > 0 && return rent / p.demurrage_rate
    return rent * p.land_reservation_multiple
end

"""
The monthly return on idle money (24 September): under debt money what a deposit earns (interest and loyalty bonus, per month);
under SuMSy what money above the buffer loses (minus the parking fee and the parking tax).
"""
function money_return_rate(model)
    p = parameters(model)
    p.monetary_system == :sumsy && return -(p.demurrage_rate + p.demurrage_tax_rate * model.parking_tax_scale)
    return (p.deposit_interest_rate + p.loyalty_bonus_rate) / max(p.deposit_interest_period, 1)
end

"""The monthly levy on land value: the cost of holding money plus the margin, when `land_levy` is on."""
land_levy_rate(model) = parameters(model).land_levy ? (max(-money_return_rate(model), 0.0) + parameters(model).land_levy_margin) * model.land_levy_scale : 0.0   # scaled by the fiscal policy like any tax

"""
Land's worth to someone whose alternative for the money earns `alternative` a month: holding land yields the rent less the levy,
holding the alternative yields `alternative` × price, so they are indifferent at rent ÷ (levy + alternative). When that is not
positive, land beats the alternative at any price (Inf): under SuMSy without a levy, nobody sells land to hold money.
"""
function land_worth(model, alternative::Float64)
    denominator = land_levy_rate(model) + alternative
    return denominator > 1e-6 ? expected_price(model, :rent) / denominator : Inf
end

"""The credit alternatives around a land sale: the seller's best use of the money and the buyer's best other source of credit."""
function seller_alternative(model)
    p = parameters(model)
    p.monetary_system == :sumsy && return max(money_return_rate(model), p.peer_loan_rate - p.bank_spread)   # lend it through the bank, or hold it
    return money_return_rate(model)                                                                        # the deposit rate
end
function buyer_alternative(model, b::Agent)
    p = parameters(model)
    p.monetary_system == :sumsy && return p.peer_loan_rate
    bank = some_bank(model, b)
    return bank === nothing ? Inf : borrowing_rate(model, bank, b)     # no bank left: no credit to be had
end

"""Seller credit on land: a market rate between the two alternatives (`instalment_bargaining` of the gap to the seller)."""
function instalment_rate(model, b::Agent)
    lo = seller_alternative(model); hi = buyer_alternative(model, b)
    return lo + parameters(model).instalment_bargaining * (hi - lo)
end

"""A buyer's reservation for a unit, by how it pays: its own money (worth the money's return), a loan or instalments (the rate)."""
function land_buyer_reservation(model, b::Agent, via::Symbol)
    via == :cash && return land_worth(model, money_return_rate(model))
    via == :instalment && return land_worth(model, instalment_rate(model, b))
    return land_worth(model, buyer_alternative(model, b))
end

"""
    land_market!(model)

Farms take turns. Purchases first (debt-free, from reserves above target, banks' seized land first, then
landowners); enterprises have first refusal, then persons with surplus savings may buy. Then renting, one unit
at a time from the owner with the lowest rent ask, paid up front; rent income is taxed as capital income.
"""
function land_market!(model)
    rng = stream(model, :land)
    farms = stable_shuffle(rng, enterprises(model, :farm))
    price = land_price(model)
    sellers_cache = Agent[]; sellers_dirty = Ref(true)
    function sellers()
        if sellers_dirty[]
            sellers_cache = vcat(Agent[b for b in enterprises(model, :bank) if land_to_let(b) > 0], Agent[o for o in sort([o for o in persons(model) if land_to_let(o) > 0]; by = o -> o.ask[:rent])])
            sellers_dirty[] = false
        end
        return sellers_cache
    end
    for o in alive_agents(model)
        land_to_let(o) > 0 && (o.market[:rent].offered = land_to_let(o))
    end
    for f in farms
        f.market[:rent].wanted = max(f.production_target - f.land, 0)
    end
    # purchases: enterprises first, then persons
    buyers = vcat(farms, stable_shuffle(rng, persons(model)))
    land_unmet = 0.0; land_sold = 0.0; best_unmet_bid = 0.0
    offering = parameters(model).land_pricing == :market ? [s for s in sellers() if !(s isa Person) || price >= land_reservation(model, s)] : Agent[]
    land_supply = sum(Float64(land_to_let(s)) for s in offering; init = 0.0)
    lowest_ask = isempty(offering) ? 0.0 : minimum(s isa Person ? land_reservation(model, s) : 0.0 for s in offering)   # the least an offering seller accepts
    for b in buyers
        while true
            # a farm wants land it will work; a person wants land only below the value of its rent stream to them
            wants = b isa Enterprise ? b.production_target > b.land : parameters(model).land_pricing == :market ? true :
                    b.greed == :greedy ? price < land_reservation(model, b) - 1e-9 :
                    (parameters(model).land_sales == :reservation ? price < land_reservation(model, b) - 1e-9 : true)
            surplus = available_cash(b) - buffer_target(model, b)
            pm0 = parameters(model)
            # 24 Sept: seller credit (instalments) in both villages — ordinary seller credit exists in debt economies too
            instalment = pm0.instalment_purchases && (pm0.monetary_system == :sumsy || pm0.land_pricing == :market) && surplus < price
            bres = Inf
            if pm0.land_pricing == :market && wants
                via = surplus >= price ? :cash : instalment ? :instalment : :loan
                bres = land_buyer_reservation(model, b, via)
                wants = price <= bres + 1e-9                                      # nobody pays more than the land is worth to them, by how they pay
            end
            if instalment
                (wants && !has_arrears(model, b) && affordable(model, b, price, 0.0)) || break
            elseif pm0.land_loans
                (wants && (surplus >= price || credit_eligible(model, b, price - max(surplus, 0.0)))) || break
            else
                (wants && debt_of(b) <= 1e-9 && surplus >= price) || break
            end
            candidates = [s for s in sellers() if s.id != b.id]
            pm = parameters(model)
            if pm.land_sales == :distress_only
                candidates = [s for s in candidates if !(s isa Person)]                # only banks' seized land is for sale
            elseif pm.land_sales == :reservation
                candidates = [s for s in candidates if !(s isa Person) || price >= land_reservation(model, s)]
            end
            if isempty(candidates)
                land_unmet += b isa Enterprise ? max(b.production_target - b.land, 0) : 1      # wanted, could pay, found no seller at this price
                best_unmet_bid = max(best_unmet_bid, bres)                                     # the most an unserved buyer would pay
                break
            end
            s = candidates[1]
            sellers_dirty[] = true
            if instalment
                bank = bank_of(model, b)
                irate = pm0.land_pricing == :market ? instalment_rate(model, b) : 0.0      # 24 Sept: a market rate, negative under SuMSy
                push!(model.peer_loans, PeerLoan(length(model.peer_loans) + 1, s.id, b.id, bank === nothing ? s.id : bank.id, price, price, price / pm0.instalment_rounds,
                                                 irate, irate, pm0.default_insurance && s isa Person, current_round(model), 0, false, false, 0.0))
                log_event!(model, :instalment_purchase; buyer = b.id, buyer_kind = kind_of(b), seller = s.id, price = price, rounds = pm0.instalment_rounds)
            else
                pay!(model, b, s, price, :land_purchase)
            end
            s.land -= 1; s.market[:rent].offered -= 1
            b.land += 1
            b isa Enterprise && (b.market[:rent].wanted = max(b.production_target - b.land, 0))
            log_event!(model, :land_purchase; buyer = b.id, buyer_kind = kind_of(b), seller = s.id, price = price)
            land_sold += 1
            record_land_sale!(model, price)
            b isa Person && break     # persons buy at most one unit per round
        end
    end
    # price discovery (24 Sept): up when enough demand went unserved, down when enough land on offer went unsold
    pmk = parameters(model)
    if pmk.land_pricing == :market
        demand = land_sold + land_unmet
        # 24 Sept: within what the market supports — never above the most an unserved buyer would pay, never below the least an
        # unsold seller would accept (an order book, not an escalator)
        if demand > 0 && land_unmet >= pmk.unmet_demand_share * demand - 1e-9 && land_unmet > 0 && best_unmet_bid > price
            model.land_price_current = min(price * (1 + pmk.land_price_step), best_unmet_bid)
        elseif land_supply > 0 && land_supply - land_sold >= pmk.unsold_share * land_supply - 1e-9 && land_supply - land_sold > 0 && price > lowest_ask
            model.land_price_current = max(price * (1 - pmk.land_price_step), lowest_ask)
        end
        model.land_supply_this_round = land_supply; model.land_demand_this_round = demand; model.land_sold_this_round = land_sold
    end
    # seller-initiated sales at the best bid (25 September, review 6): a landowner who must sell (distress) or wants to for reasons
    # of their own (a life event, with probability `land_life_event_rate` a month) takes the best bid on the table — the most any
    # buyer both would pay and can pay in cash. Distress sales are fire sales and do not set the valuation price; life-event sales do.
    if parameters(model).land_pricing == :market
        pl = parameters(model)
        distressed(o) = pl.distress_land_sales && (o.hunger > 0 || has_arrears(model, o) || cash(o) < meal_price(model))
        for o in stable_shuffle(rng, [o for o in persons(model) if land_to_let(o) > 0])
            forced = distressed(o)
            forced || rand(rng) < pl.land_life_event_rate || continue
            bids = [(b, min(land_buyer_reservation(model, b, :cash), b isa Person ? cash(b) - buffer_target(model, b) : available_cash(b)))
                    for b in alive_agents(model) if b.id != o.id && !is_government(b) && !is_bank(b) && (b isa Person || is_farm(b))]
            bids = [(b, x) for (b, x) in bids if x > 1e-6]
            isempty(bids) && continue
            b, bid = bids[argmax([x for (_, x) in bids])]
            bid = round(bid, digits = 4)
            forced || bid >= 0.5 * land_valuation_price(model) || continue    # a life-event seller does not give land away
            transfer!(model, b, o, bid, forced ? :distress_land_sale : :land_sale)
            o.land -= 1; o.market[:rent].offered -= 1; b.land += 1
            b isa Enterprise && (b.market[:rent].wanted = max(b.production_target - b.land, 0))
            forced || (record_land_sale!(model, bid); land_sold += 1)
            log_event!(model, :land_purchase; buyer = b.id, buyer_kind = kind_of(b), seller = o.id, price = bid, distress = forced, life_event = !forced)
        end
        model.land_sold_this_round = land_sold
    end
    # distress sales (seller-initiated, immediate settlement) — the old rule, for :multiple pricing
    if parameters(model).distress_land_sales && parameters(model).land_pricing != :market
        dprice = round(price * parameters(model).distress_land_discount, digits = 4)
        for o in stable_shuffle(rng, [o for o in persons(model) if land_to_let(o) > 0 && (o.hunger > 0 || has_arrears(model, o) || cash(o) < meal_price(model))])
            buyers = [b for b in alive_agents(model) if b.id != o.id && !is_government(b) &&
                      (b isa Person ? cash(b) - buffer_target(model, b) : (is_farm(b) ? available_cash(b) : 0.0)) >= dprice]
            isempty(buyers) && continue
            b = first(sort(buyers; by = x -> -(x isa Person ? cash(x) : available_cash(x))))
            transfer!(model, b, o, dprice, :distress_land_sale)   # a fire sale: not a valuation price (24 Sept)
            o.land -= 1; o.market[:rent].offered -= 1; b.land += 1
            b isa Enterprise && (b.market[:rent].wanted = max(b.production_target - b.land, 0))
            log_event!(model, :land_purchase; buyer = b.id, buyer_kind = kind_of(b), seller = o.id, price = dprice, distress = true)
        end
    end
    # renting, round robin
    active = [f for f in farms if f.production_target - f.land - f.rented_land > 0]
    while !isempty(active)
        for f in copy(active)
            need = f.production_target - f.land - f.rented_land
            candidates = [s for s in sellers() if s.id != f.id]
            if need <= 0 || isempty(candidates)
                filter!(x -> x !== f, active); continue
            end
            rented = false
            for o in candidates
                rent = negotiate(model, o, f, :rent)
                rent === nothing && continue
                fund!(model, f, rent, :rent) || continue
                o isa Person ? pay_income!(model, f, o, rent, :rent) : pay!(model, f, o, rent, :rent)
                f.materials_period += rent
                o.land_let += 1; o.market[:rent].sold += 1
                f.rented_land += 1; f.market[:rent].got += 1
                record_transaction!(model, :rent, rent, 1.0)
                sellers_dirty[] = true
                rented = true
                break
            end
            rented || filter!(x -> x !== f, active)
        end
    end
    if any(f -> f.market[:rent].got < f.market[:rent].wanted, farms)
        shortfall = sum(max(f.market[:rent].wanted - f.market[:rent].got, 0.0) for f in farms; init = 0.0)
        for o in alive_agents(model)
            o.market[:rent].offered > 0 && land_to_let(o) == 0 && (o.market[:rent].unmet_demand = true; o.market[:rent].unmet_units += shortfall)
        end
    end
    return nothing
end

# ---- labour supply (spec v2 §2): minimise work -------------------------------------

"""Units a person offers: just enough to cover a meal and the buffer shortfall net of other expected income."""
function labour_supply(model, w::Person)
    p = parameters(model)
    p.offer_full_capacity && return w.effective_capacity
    other = w.land * expected_price(model, :rent) * (1 - p.capital_tax_rate) + w.fee
    need = meal_price(model) + max(savings_buffer(model) - cash(w), 0.0) - other
    wage = max(net_wage(model), 1e-6)
    units = need <= 0 ? 0.0 : ceil(need / wage)
    return min(w.effective_capacity, units)
end

"""Tickets a theatre can sell in a round: shows × seats, or unlimited with `shows_per_round = 0`."""
function ticket_capacity(model, t::Enterprise)
    p = parameters(model)
    p.shows_per_round <= 0 && return Inf
    seats = p.seats_per_show > 0 ? p.seats_per_show :
            ceil(p.number_of_persons / max(p.number_of_theatres, 1) * (1 + p.theatre_seat_margin))   # 25 Sept: fixed at the founding — a new theatre brings its own seats
    return Float64(p.shows_per_round * seats)
end

"""Labour a theatre can put to use: enough to serve its seats, no more."""
theatre_labour_cap(model, t::Enterprise) = ceil(ticket_capacity(model, t) / parameters(model).customers_per_labour_unit)

labour_need(e::Enterprise) = e.kind == :farm ? max(min(e.production_target, e.land + e.rented_land), 0) :
                            e.kind == :bakery ? max(min(e.production_target, floor(grain_units(e) + 1e-9)), 0) : e.kind == :bank ? e.staff_target : e.kind == :theatre ? Float64(max(e.production_target, 0)) : 0.0

"""
    hire!(model, e, w, units, wage)

One hiring: the wage is promised at hiring (priority 2, taxed at source) and settled at clearing.
A worker cooperative takes the worker on as a member, counts the hours as patronage and collects
part of the net wage towards the membership share.
"""
function hire!(model, e::Enterprise, w::Person, units::Float64, wage::Float64)
    e.wage_bill += units * wage
    e.labour_period += units * wage
    w.labour_available -= units; w.labour_sold += units; w.market[:wage].sold += units
    e.hired_labour += units; e.market[:wage].got += units
    net = pay_income!(model, e, w, units * wage, :wage)
    push!(w.worked_for, e.id)
    record_transaction!(model, :wage, wage, units)
    log_event!(model, :hire; employer = e.id, employer_kind = e.kind, worker = w.id, units = units, price = wage)
    if is_worker_coop(model, e)
        admit_worker_member!(model, e, w)
        e.patronage_this_round[w.id] = get(e.patronage_this_round, w.id, 0.0) + units
        deduct_membership_capital!(model, e, w, net)
    end
    return nothing
end

"""
    labour_market!(model, kinds)

Employers of the given kinds take turns hiring one unit at a time from the cheapest worker with labour left.
Wages are promised at hiring (priority 2, taxed at source) and settled at clearing. Farms and banks hire
before the harvest; bakeries hire after the grain market, up to the grain they hold (spec v2 addendum).
"""
function labour_market!(model, kinds)
    rng = stream(model, :labour)
    if :farm in kinds
        for w in persons(model)
            w.labour_available = labour_supply(model, w)
            w.labour_offered = w.labour_available
            w.market[:wage].offered = w.labour_available
        end
        reserve_labour_for_cooperatives!(model, (:bakery,))   # bakery cooperatives hire after the grain market
    else
        release_reserved_labour!(model, kinds)
    end
    allocate_cooperative_labour!(model, kinds)                # members first, the work spread over them
    employers = stable_shuffle(rng, reduce(vcat, [enterprises(model, k) for k in kinds]; init = Enterprise[]))
    for e in employers
        e.market[:wage].wanted = labour_need(e)
    end
    active = [e for e in employers if e.market[:wage].wanted > 1e-9]
    # the pool is sorted once: asks do not change within the market and exhausted workers are skipped
    pool = [w for w in persons(model) if w.labour_available > 1e-9]
    parameters(model).random_hiring_ties && stable_shuffle!(rng, pool)
    sort!(pool; by = w -> w.ask[:wage])
    while !isempty(active)
        for e in copy(active)
            remaining = e.market[:wage].wanted - e.hired_labour
            if remaining <= 1e-9
                filter!(x -> x !== e, active); continue
            end
            unit = min(1.0, remaining)
            filled = 0.0
            for w in pool
                w.labour_available > 1e-9 || continue
                filled >= unit - 1e-9 && break
                wage = negotiate(model, w, e, :wage)
                wage === nothing && continue
                units = min(unit - filled, w.labour_available)
                hire!(model, e, w, units, wage)
                filled += units
            end
            filled <= 1e-9 && filter!(x -> x !== e, active)
        end
    end
    # 25 Sept: the labour employers wanted and could not get is recorded, market-wide, on every worker who sold out — so the
    # 5 % threshold applies to wages as it does to goods (before, any shortfall at all raised every sold-out worker's ask)
    shortfall = sum(max(e.market[:wage].wanted - e.market[:wage].got, 0.0) for e in employers; init = 0.0)
    if shortfall > 1e-9
        for w in persons(model)
            w.labour_offered > 1e-9 && w.labour_available <= 1e-9 && (w.market[:wage].unmet_demand = true; w.market[:wage].unmet_units = shortfall)
        end
    end
    return nothing
end

# ---- production (spec v1 §4.4, §4.7) ----------------------------------------------

function produce_grain!(model)
    for f in enterprises(model, :farm)
        labour = floor(f.hired_labour + 1e-9)
        grain = min(labour, f.land + f.rented_land, f.production_target)
        ps = parameters(model)
        if ps.harvest_shock_start > 0 && ps.harvest_shock_start <= current_round(model) < ps.harvest_shock_start + ps.harvest_shock_length
            grain = floor(grain * ps.harvest_shock_factor)
        end
        grain > 0 && push!(f.grain, StockItem(grain, 0))
        log_event!(model, :harvest; farm = f.id, grain = grain, labour = f.hired_labour, land = f.land + f.rented_land)
    end
    return nothing
end

function take_stock!(items::Vector{StockItem}, units::Float64)
    sort!(items; by = i -> -i.age)
    taken = 0.0
    while units > 1e-9 && !isempty(items)
        i = items[1]; t = min(i.units, units)
        i.units -= t; units -= t; taken += t
        i.units <= 1e-9 && popfirst!(items)
    end
    return taken
end

function bake!(model)
    for b in enterprises(model, :bakery)
        labour = floor(b.hired_labour + 1e-9)
        grain = min(labour, floor(grain_units(b) + 1e-9))
        bread = parameters(model).breads_per_grain * grain
        if bread > 0
            take_stock!(b.grain, grain); push!(b.bread, StockItem(bread, 0))
        end
        log_event!(model, :bake; bakery = b.id, bread = bread, labour = b.hired_labour, grain_in_stock = grain_units(b))
    end
    return nothing
end

# ---- grain market (spec v1 §4.6) ---------------------------------------------------

function grain_market!(model)
    rng = stream(model, :grain)
    bakeries = stable_shuffle(rng, enterprises(model, :bakery))
    for b in bakeries
        b.market[:grain].wanted = max(b.production_target - grain_units(b), 0.0)
    end
    for f in enterprises(model, :farm)
        f.market[:grain].offered = grain_units(f)
    end
    active = [b for b in bakeries if b.market[:grain].wanted > 1e-9]
    while !isempty(active)
        for b in copy(active)
            if b.market[:grain].got >= b.market[:grain].wanted - 1e-9
                filter!(x -> x !== b, active); continue
            end
            sellers = sort([f for f in enterprises(model, :farm) if grain_units(f) >= 1 - 1e-9]; by = f -> f.ask[:grain])
            if isempty(sellers)
                shortfall = max(b.market[:grain].wanted - b.market[:grain].got, 0.0)
                foreach(f -> (f.market[:grain].unmet_demand = true; f.market[:grain].unmet_units += shortfall), enterprises(model, :farm))
                filter!(x -> x !== b, active); continue
            end
            bought = false
            for f in sellers
                price = negotiate(model, f, b, :grain)
                price === nothing && continue
                fund!(model, b, price, :grain) || continue
                pay!(model, b, f, price, :grain)
                b.materials_period += price; f.revenue_period += price; f.revenue_this_round += price
                take_stock!(f.grain, 1.0); push!(b.grain, StockItem(1.0, 0))
                f.market[:grain].sold += 1; b.market[:grain].got += 1
                record_transaction!(model, :grain, price, 1.0)
                bought = true; break
            end
            bought || filter!(x -> x !== b, active)
        end
    end
    return nothing
end

# ---- bread market (spec v1 §3, §4.9) -------------------------------------------------

sellable_bread(b::Enterprise) = bread_units(b)
oldest_bread_age(b::Enterprise) = isempty(b.bread) ? 0 : maximum(i.age for i in b.bread)

"""Buy one bread from cash — savings may be used, no credit; returns true on success."""
function buy_extra_bread!(model, buyer::Person, purpose::Symbol; tier::Bool = false)
    sellers = sort([b for b in enterprises(model, :bakery) if sellable_bread(b) >= 1 - 1e-9]; by = b -> member_ask(model, b, buyer, :bread) * (tier ? b.tier_multiplier : 1.0))
    for s in sellers
        price = negotiate(model, s, buyer, :bread; age = oldest_bread_age(s))
        price === nothing && continue
        tier && (price = round(price * s.tier_multiplier, digits = 4); s.tier_sold += 1)
        available_cash(buyer) >= gross_price(model, buyer, price) || return false            # savings allowed, no credit
        pay_consumption!(model, buyer, s, price, purpose)
        take_stock!(s.bread, 1.0); push!(buyer.bread, StockItem(1.0, 0))
        record_patronage!(model, s, buyer, 1.0)
        s.market[:bread].sold += 1
        tier ? (model.tier_revenue_this_round += price) : record_transaction!(model, :bread, price, 1.0)   # tier sales stay out of the ordinary price
        log_event!(model, :bread_sale; bakery = s.id, buyer = buyer.id, size = 1.0, price = price, purpose = purpose)
        return true
    end
    return false
end

"""
    gluttony_and_stocking!(model, buyer)

With `gluttony_probability`, a person who can pay from surplus buys a third bread for this round (spec v2
addendum). A glutton then stocks up: one more bread with the `stocking_marginality` probability for the
current stock level (EconoSim `Marginality` semantics, model RNG), as long as surplus cash allows.
"""
function gluttony_and_stocking!(model, buyer::Person)
    p = parameters(model); rng = stream(model, :bread)
    if p.bread_rationing && buyer.greed == :greedy     # stage one: a greedy person may take the ration like anyone else
        while bread_units(buyer) < model.ration_this_round && cash(buyer) - buffer_target(model, buyer) >= expected_price(model, :bread) && buy_extra_bread!(model, buyer, :ration); end
        bread_units(buyer) > p.breads_per_meal && (buyer.glutton = true)
        return nothing
    end
    buyer.greed != :none && return nothing        # greedy consumers spend in greed_spending!, hoarders buy no extras
    rand(rng) < p.gluttony_probability || return nothing
    model.gluttony_attempted_this_round += 1
    p.bread_rationing && bread_units(buyer) >= model.ration_this_round && return nothing
    if bread_units(buyer) < p.maximum_breads_per_round && !buy_extra_bread!(model, buyer, :gluttony)
        model.gluttony_refused_this_round += 1
        return nothing
    end
    buyer.glutton = true
    max_stock = p.spoilage_aware_stocking ? p.breads_per_meal * p.spoilage_age_in_rounds : Inf
    p.bread_rationing && (max_stock = min(max_stock, model.ration_this_round))
    for (units, prob) in p.stocking_marginality
        while bread_units(buyer) < min(units, max_stock)
            (rand(rng) <= prob && buy_extra_bread!(model, buyer, :stocking)) || return nothing
        end
    end
    return nothing
end

"""A full meal when affordable, otherwise one bread; persons buy only when they hold less than a meal. Gluttony and stocking follow."""
function bread_market!(model)
    rng = stream(model, :bread); p = parameters(model)
    for b in enterprises(model, :bakery)
        b.market[:bread].offered = sellable_bread(b)
    end
    meal = Float64(p.breads_per_meal)
    if p.bread_rationing
        alive_n = max(length(persons(model)), 1)
        model.ration_this_round = max(p.breads_per_meal, min(p.ration_breads_per_person, floor(Int, sum(b.market[:bread].offered for b in enterprises(model, :bakery); init = 0.0) / alive_n)))
    end
    for buyer in stable_shuffle(rng, persons(model))
        if bread_units(buyer) >= meal - 1e-9
            gluttony_and_stocking!(model, buyer); continue
        end
        buyer.market[:bread].wanted = meal - bread_units(buyer)
        sellers = sort([b for b in enterprises(model, :bakery) if sellable_bread(b) >= 1 - 1e-9]; by = b -> member_ask(model, b, buyer, :bread))
        if isempty(sellers)
            shortfall = buyer.market[:bread].wanted
            foreach(b -> (b.market[:bread].unmet_demand = true; b.market[:bread].unmet_units += shortfall), enterprises(model, :bakery))
            continue
        end
        for s in sellers
            price = negotiate(model, s, buyer, :bread; age = oldest_bread_age(s))
            price === nothing && continue
            done = false
            for size in (buyer.market[:bread].wanted, 1.0)
                size <= sellable_bread(s) + 1e-9 || continue
                cost = round(price * size, digits = 4)
                gross = gross_price(model, buyer, cost)
                can_pay = cash(buyer) >= gross - 1e-6 || (p.credit_for_bread && credit_eligible(model, buyer, gross - cash(buyer)))
                can_pay || continue
                pay_consumption!(model, buyer, s, cost, :bread)
                take_stock!(s.bread, size); push!(buyer.bread, StockItem(size, 0))
                record_patronage!(model, s, buyer, size)
                s.market[:bread].sold += size; buyer.market[:bread].got = size
                record_transaction!(model, :bread, price, size)
                log_event!(model, :bread_sale; bakery = s.id, buyer = buyer.id, size = size, price = price)
                done = true; break
            end
            if !done
                s.market[:bread].failed_for_cash += 1
                s.market[:bread].max_failed_cash = max(s.market[:bread].max_failed_cash, cash(buyer))
            end
            done && break
        end
        gluttony_and_stocking!(model, buyer)
    end
    return nothing
end


# ---- entertainment (13 September 2026) ----------------------------------------------

"""
    ticket_market!(model)

After the bread market. Each person who can afford at least one ticket above their savings buffer wants, with
`entertainment_propensity`, a random number of tickets (1 … `max_tickets_per_person`, capped by what cash allows) and
buys from the cheapest theatre with capacity (hired labour × customers per unit). Tickets are consumed on purchase.
"""
function ticket_market!(model)
    p = parameters(model)
    p.entertainment || return nothing
    rng = stream(model, :tickets)
    theatres = enterprises(model, :theatre)
    isempty(theatres) && return nothing
    for t in theatres
        t.market[:ticket].offered = min(t.hired_labour * p.customers_per_labour_unit, ticket_capacity(model, t))
    end
    for w in stable_shuffle(rng, persons(model))
        tp = expected_price(model, :ticket)
        afford = floor(Int, max(cash(w) - buffer_target(model, w), 0.0) / tp)
        afford >= 1 || continue
        rand(rng) < p.entertainment_propensity || continue
        w.greed != :none && continue
        wanted = min(afford, stable_range(rng, 1:p.max_tickets_per_person))
        w.market[:ticket].wanted = wanted
        bought = 0
        for _ in 1:wanted
            open = [t for t in theatres if t.market[:ticket].offered - t.market[:ticket].sold >= 1 - 1e-9 && !(p.no_self_service && t.id in w.worked_for)]
            if isempty(open)
                foreach(t -> (t.market[:ticket].unmet_demand = true; t.market[:ticket].unmet_units += wanted - bought), theatres); break
            end
            sort!(open; by = t -> member_ask(model, t, w, :ticket))
            done = false
            for t in open
                price = negotiate(model, t, w, :ticket)
                price === nothing && continue
                cash(w) - buffer_target(model, w) >= gross_price(model, w, price) - 1e-6 || continue
                pay_consumption!(model, w, t, price, :ticket)
                record_patronage!(model, t, w, 1.0)
                t.market[:ticket].sold += 1; w.market[:ticket].got += 1; bought += 1
                record_transaction!(model, :ticket, price, 1.0)
                log_event!(model, :ticket; buyer = w.id, theatre = t.id, price = price)
                done = true; break
            end
            done || break
        end
    end
    return nothing
end


"""
    greed_spending!(model)

After the bread and ticket markets. Each greedy consumer spends cash above the reserve one purchase at a time; each
purchase goes to a loaf or a ticket by a coin flip (a side whose cap is reached, or where nothing is on offer, yields
to the other). Loaves bought are eaten this round.
"""
function greed_spending!(model)
    p = parameters(model); rng = stream(model, :greed)
    p.greed || return nothing
    theatres = enterprises(model, :theatre)
    for w in stable_shuffle(rng, [w for w in persons(model) if w.greed == :greedy])
        loaves = 0; tickets = 0
        for _ in 1:(p.greedy_max_breads_per_round + p.greedy_max_tickets_per_round)
            surplus = cash(w) - buffer_target(model, w)
            surplus > 0 || break
            if rand(rng) < p.greed_hoarding
                greedy_capital_act!(model, w, surplus) || break        # nothing to buy: cash is the (last) choice, stop spending
                continue
            end
            tiered = p.tiered_bread_price && bread_units(w) >= (p.bread_rationing ? model.ration_this_round : p.ration_breads_per_person)
            tier_price = tiered ? expected_price(model, :bread) * minimum(b.tier_multiplier for b in enterprises(model, :bakery); init = 1.0) : expected_price(model, :bread)
            stocked = [b for b in enterprises(model, :bakery) if sellable_bread(b) >= 1]
            if tiered && isempty(stocked); foreach(b -> b.tier_unmet = true, enterprises(model, :bakery)); end
            can_bread = bread_units(w) < p.greedy_max_breads_per_round && surplus >= tier_price && !isempty(stocked)
            open = [t for t in theatres if t.market[:ticket].offered - t.market[:ticket].sold >= 1 - 1e-9 && !(p.no_self_service && t.id in w.worked_for)]
            can_ticket = p.entertainment && tickets < p.greedy_max_tickets_per_round && !isempty(open) && surplus >= expected_price(model, :ticket)
            (can_bread || can_ticket) || (p.greed_hoarding > 0 ? continue : break)
            pick_bread = can_bread && (!can_ticket || rand(rng) < 0.5)
            if pick_bread
                buy_extra_bread!(model, w, :greed; tier = tiered) || (can_ticket ? nothing : break)
                loaves += 1
            else
                sort!(open; by = t -> member_ask(model, t, w, :ticket)); done = false
                for t in open
                    price = negotiate(model, t, w, :ticket)
                    price === nothing && continue
                    cash(w) - buffer_target(model, w) >= gross_price(model, w, price) - 1e-6 || continue
                    pay_consumption!(model, w, t, price, :ticket); record_patronage!(model, t, w, 1.0)
                    t.market[:ticket].sold += 1; w.market[:ticket].got += 1; tickets += 1
                    record_transaction!(model, :ticket, price, 1.0); log_event!(model, :ticket; buyer = w.id, theatre = t.id, price = price, greed = true); done = true; break
                end
                done || (isempty(open) ? break : (foreach(t -> (t.market[:ticket].unmet_demand = true; t.market[:ticket].unmet_units += 1.0), theatres); break))
            end
        end
        bread_units(w) > p.breads_per_meal && (w.glutton = true)
        model.greedy_loaves_this_round += loaves; model.greedy_tickets_this_round += tickets
    end
    return nothing
end

"""
    greedy_capital_act!(model, w, surplus)

One act of capital greed: the most profitable of land, shares and cash first. Yields per round — land: rent ÷ price;
shares: dividend per unit ÷ price; cash: the deposit rate (debt money) or minus the parking fee (SuMSy). Buys one unit
of the best option that is on offer and affordable, else the next; keeping the money is the fallthrough. Returns true
when something was bought.
"""
function greedy_capital_act!(model, w::Person, surplus::Float64)
    p = parameters(model)
    price_land = land_price(model)
    y_land = price_land > 0 ? expected_price(model, :rent) / price_land : 0.0
    y_cash = p.monetary_system == :sumsy ? -p.demurrage_rate : (p.deposit_interest_rate + p.loyalty_bonus_rate) / max(p.deposit_interest_period, 1)
    firms = [e for e in alive_agents(model) if e isa Enterprise && e.ownership == :shareholders]
    y_share = isempty(firms) ? -Inf : maximum((v = valuation(model, w, e); v > 0 ? mean_dividend_per_unit(model, e) / v : -Inf) for e in firms)
    for (opt, y) in sort([(:land, y_land), (:shares, y_share), (:cash, y_cash)]; by = x -> -x[2])
        if opt == :cash
            return false
        elseif opt == :land
            surplus >= price_land || continue
            # a villager buys only below the rent stream's value to them (a seller at exactly that value is not a seller); in practice distress sales
            sellers = [o for o in persons(model) if o.id != w.id && land_to_let(o) > 0 && price_land < land_reservation(model, w) - 1e-9 && price_land >= land_reservation(model, o) - 1e-9]
            isempty(sellers) && continue
            o = first(sort(sellers; by = x -> x.ask[:rent]))
            transfer!(model, w, o, price_land, :land_purchase); o.land -= 1; o.market[:rent].offered = max(o.market[:rent].offered - 1, 0); w.land += 1
            log_event!(model, :land_purchase; buyer = w.id, buyer_kind = :person, seller = o.id, price = price_land, greed = true)
            model.greedy_land_this_round += 1
            return true
        else
            for e in sort(firms; by = e -> -valuation(model, w, e))
                v = valuation(model, w, e); v > 0 || continue
                floor_units = parameters(model).founder_minimum_stake * total_share_units(model)
                sellers = Tuple{Person, Float64}[]
                for (h, u) in e.shares
                    o = model[h]; (o isa Person && o.alive && o.id != w.id && u >= 1) || continue
                    if cash(o) < meal_price(model); push!(sellers, (o, max(book_per_unit(model, e), 0.01)))            # distress: at book
                    elseif valuation(model, o, e) < v && (!(o.id in e.founder_ids) || founders_stake(e) - 1 >= floor_units); push!(sellers, (o, valuation(model, o, e))); end   # voluntary: above the seller's own value
                end
                isempty(sellers) && continue
                seller, reservation = first(sort(sellers; by = x -> x[2])); price = (v + reservation) / 2
                surplus >= price || continue
                transfer!(model, w, seller, round(price, digits = 4), :share_purchase)
                e.shares[seller.id] = get(e.shares, seller.id, 0.0) - 1; e.shares[w.id] = get(e.shares, w.id, 0.0) + 1; e.share_price = price
                log_event!(model, :share_trade; enterprise = e.id, seller = seller.id, buyer = w.id, units = 1.0, price = price, greed = true, deferred = false, distress = cash(seller) < meal_price(model))
                model.greedy_shares_this_round += 1
                return true
            end
        end
    end
    return false
end

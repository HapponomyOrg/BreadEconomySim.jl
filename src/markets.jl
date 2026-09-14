# ---- land market (spec v1 §4.2, v2 §3) ----------------------------------------

land_to_let(a::Agent) = (a isa Person || is_bank(a)) ? a.land - a.land_let : 0

"""A landowner's reservation price for a unit: the value of the rent stream at the cost of holding cash instead."""
function land_reservation(model, o::Person)
    p = parameters(model); rent = expected_price(model, :rent)
    p.monetary_system == :sumsy && p.demurrage_rate > 0 && return rent / p.demurrage_rate
    return rent * p.land_reservation_multiple
end

"""
    land_market!(model)

Farms take turns. Purchases first (debt-free, from reserves above target, banks' seized land first, then
landowners); enterprises have first refusal, then persons with surplus savings may buy. Then renting, one unit
at a time from the owner with the lowest rent ask, paid up front; rent income is taxed as capital income.
"""
function land_market!(model)
    rng = abmrng(model)
    farms = shuffle(rng, enterprises(model, :farm))
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
    buyers = vcat(farms, shuffle(rng, persons(model)))
    for b in buyers
        while true
            # a farm wants land it will work; a person wants land only below the value of its rent stream to them
            wants = b isa Enterprise ? b.production_target > b.land : b.greed == :greedy ? price < land_reservation(model, b) - 1e-9 :
                    (parameters(model).land_sales == :reservation ? price < land_reservation(model, b) - 1e-9 : true)
            surplus = available_cash(b) - buffer_target(model, b)
            pm0 = parameters(model)
            instalment = pm0.instalment_purchases && pm0.monetary_system == :sumsy && surplus < price
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
            isempty(candidates) && break
            s = candidates[1]
            sellers_dirty[] = true
            if instalment
                bank = bank_of(model, b)
                push!(model.peer_loans, PeerLoan(length(model.peer_loans) + 1, s.id, b.id, bank === nothing ? s.id : bank.id, price, price, price / pm0.instalment_rounds,
                                                 0.0, 0.0, pm0.default_insurance && s isa Person, current_round(model), 0, false, false, 0.0))
                log_event!(model, :instalment_purchase; buyer = b.id, buyer_kind = kind_of(b), seller = s.id, price = price, rounds = pm0.instalment_rounds)
            else
                pay!(model, b, s, price, :land_purchase)
            end
            s.land -= 1; s.market[:rent].offered -= 1
            b.land += 1
            b isa Enterprise && (b.market[:rent].wanted = max(b.production_target - b.land, 0))
            log_event!(model, :land_purchase; buyer = b.id, buyer_kind = kind_of(b), seller = s.id, price = price)
            b isa Person && break     # persons buy at most one unit per round
        end
    end
    # distress sales (seller-initiated, immediate settlement)
    if parameters(model).distress_land_sales
        dprice = round(price * parameters(model).distress_land_discount, digits = 4)
        for o in shuffle(rng, [o for o in persons(model) if land_to_let(o) > 0 && (o.hunger > 0 || has_arrears(model, o) || cash(o) < meal_price(model))])
            buyers = [b for b in alive_agents(model) if b.id != o.id && !is_government(b) &&
                      (b isa Person ? cash(b) - buffer_target(model, b) : (is_farm(b) ? available_cash(b) : 0.0)) >= dprice]
            isempty(buyers) && continue
            b = first(sort(buyers; by = x -> -(x isa Person ? cash(x) : available_cash(x))))
            transfer!(model, b, o, dprice, :distress_land_sale)
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
        for o in alive_agents(model)
            o.market[:rent].offered > 0 && land_to_let(o) == 0 && (o.market[:rent].unmet_demand = true)
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

labour_need(e::Enterprise) = e.kind == :farm ? max(min(e.production_target, e.land + e.rented_land), 0) :
                            e.kind == :bakery ? max(min(e.production_target, floor(grain_units(e) + 1e-9)), 0) : e.kind == :bank ? 1.0 : e.kind == :theatre ? Float64(max(e.production_target, 0)) : 0.0

"""
    labour_market!(model, kinds)

Employers of the given kinds take turns hiring one unit at a time from the cheapest worker with labour left.
Wages are promised at hiring (priority 2, taxed at source) and settled at clearing. Farms and banks hire
before the harvest; bakeries hire after the grain market, up to the grain they hold (spec v2 addendum).
"""
function labour_market!(model, kinds)
    rng = abmrng(model)
    if :farm in kinds
        for w in persons(model)
            w.labour_available = labour_supply(model, w)
            w.labour_offered = w.labour_available
            w.market[:wage].offered = w.labour_available
        end
    end
    employers = shuffle(rng, reduce(vcat, [enterprises(model, k) for k in kinds]; init = Enterprise[]))
    for e in employers
        e.market[:wage].wanted = labour_need(e)
    end
    active = [e for e in employers if e.market[:wage].wanted > 1e-9]
    # the pool is sorted once: asks do not change within the market and exhausted workers are skipped
    pool = [w for w in persons(model) if w.labour_available > 1e-9]
    parameters(model).random_hiring_ties && shuffle!(rng, pool)
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
                e.wage_bill += units * wage
                w.labour_available -= units; w.labour_sold += units; w.market[:wage].sold += units
                e.hired_labour += units; e.market[:wage].got += units
                filled += units
                pay_income!(model, e, w, units * wage, :wage)
                push!(w.worked_for, e.id)
                record_transaction!(model, :wage, wage, units)
                log_event!(model, :hire; employer = e.id, employer_kind = e.kind, worker = w.id, units = units, price = wage)
            end
            filled <= 1e-9 && filter!(x -> x !== e, active)
        end
    end
    if any(e -> e.market[:wage].got < e.market[:wage].wanted - 1e-9, employers)
        for w in persons(model)
            w.labour_offered > 1e-9 && w.labour_available <= 1e-9 && (w.market[:wage].unmet_demand = true)
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
    rng = abmrng(model)
    bakeries = shuffle(rng, enterprises(model, :bakery))
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
                foreach(f -> f.market[:grain].unmet_demand = true, enterprises(model, :farm))
                filter!(x -> x !== b, active); continue
            end
            bought = false
            for f in sellers
                price = negotiate(model, f, b, :grain)
                price === nothing && continue
                fund!(model, b, price, :grain) || continue
                pay!(model, b, f, price, :grain)
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
    sellers = sort([b for b in enterprises(model, :bakery) if sellable_bread(b) >= 1 - 1e-9]; by = b -> b.ask[:bread] * (tier ? b.tier_multiplier : 1.0))
    for s in sellers
        price = negotiate(model, s, buyer, :bread; age = oldest_bread_age(s))
        price === nothing && continue
        tier && (price = round(price * s.tier_multiplier, digits = 4); s.tier_sold += 1)
        available_cash(buyer) >= price || return false            # savings allowed, no credit
        pay!(model, buyer, s, price, purpose)
        take_stock!(s.bread, 1.0); push!(buyer.bread, StockItem(1.0, 0))
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
    p = parameters(model); rng = abmrng(model)
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
    rng = abmrng(model); p = parameters(model)
    for b in enterprises(model, :bakery)
        b.market[:bread].offered = sellable_bread(b)
    end
    meal = Float64(p.breads_per_meal)
    if p.bread_rationing
        alive_n = max(length(persons(model)), 1)
        model.ration_this_round = max(p.breads_per_meal, min(p.ration_breads_per_person, floor(Int, sum(b.market[:bread].offered for b in enterprises(model, :bakery); init = 0.0) / alive_n)))
    end
    for buyer in shuffle(rng, persons(model))
        if bread_units(buyer) >= meal - 1e-9
            gluttony_and_stocking!(model, buyer); continue
        end
        buyer.market[:bread].wanted = meal - bread_units(buyer)
        sellers = sort([b for b in enterprises(model, :bakery) if sellable_bread(b) >= 1 - 1e-9]; by = b -> b.ask[:bread])
        if isempty(sellers)
            foreach(b -> b.market[:bread].unmet_demand = true, enterprises(model, :bakery))
            continue
        end
        for s in sellers
            price = negotiate(model, s, buyer, :bread; age = oldest_bread_age(s))
            price === nothing && continue
            done = false
            for size in (buyer.market[:bread].wanted, 1.0)
                size <= sellable_bread(s) + 1e-9 || continue
                cost = round(price * size, digits = 4)
                can_pay = cash(buyer) >= cost - 1e-6 || (p.credit_for_bread && credit_eligible(model, buyer, cost - cash(buyer)))
                can_pay || continue
                pay!(model, buyer, s, cost, :bread)
                take_stock!(s.bread, size); push!(buyer.bread, StockItem(size, 0))
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
    rng = abmrng(model)
    theatres = enterprises(model, :theatre)
    isempty(theatres) && return nothing
    for t in theatres
        t.market[:ticket].offered = t.hired_labour * p.customers_per_labour_unit
    end
    for w in shuffle(rng, persons(model))
        tp = expected_price(model, :ticket)
        afford = floor(Int, max(cash(w) - buffer_target(model, w), 0.0) / tp)
        afford >= 1 || continue
        rand(rng) < p.entertainment_propensity || continue
        w.greed != :none && continue
        wanted = min(afford, rand(rng, 1:p.max_tickets_per_person))
        w.market[:ticket].wanted = wanted
        bought = 0
        for _ in 1:wanted
            open = [t for t in theatres if t.market[:ticket].offered - t.market[:ticket].sold >= 1 - 1e-9 && !(p.no_self_service && t.id in w.worked_for)]
            if isempty(open)
                foreach(t -> t.market[:ticket].unmet_demand = true, theatres); break
            end
            sort!(open; by = t -> t.ask[:ticket])
            done = false
            for t in open
                price = negotiate(model, t, w, :ticket)
                price === nothing && continue
                cash(w) - buffer_target(model, w) >= price - 1e-6 || continue
                pay!(model, w, t, price, :ticket)
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
    p = parameters(model); rng = abmrng(model)
    p.greed || return nothing
    theatres = enterprises(model, :theatre)
    for w in shuffle(rng, [w for w in persons(model) if w.greed == :greedy])
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
                sort!(open; by = t -> t.ask[:ticket]); done = false
                for t in open
                    price = negotiate(model, t, w, :ticket)
                    price === nothing && continue
                    cash(w) - buffer_target(model, w) >= price - 1e-6 || continue
                    pay!(model, w, t, price, :ticket); t.market[:ticket].sold += 1; w.market[:ticket].got += 1; tickets += 1
                    record_transaction!(model, :ticket, price, 1.0); log_event!(model, :ticket; buyer = w.id, theatre = t.id, price = price, greed = true); done = true; break
                end
                done || (isempty(open) ? break : (foreach(t -> t.market[:ticket].unmet_demand = true, theatres); break))
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

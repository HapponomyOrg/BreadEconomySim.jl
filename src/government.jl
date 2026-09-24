# ---- government (spec v2 §5) ------------------------------------------------------

"""Gross statutory wage per labour unit: net full-time wage = breads × (1 + premium) × bread price."""
function government_wage_per_unit(model)
    p = parameters(model)
    net_full_time = p.government_wage_in_breads * (1 + p.government_wage_premium) * expected_price(model, :bread)
    return net_full_time / (1 - effective_wage_tax_rate(model)) / p.maximum_capacity
end

"""Employer of last resort: hires leftover labour up to `government_employment_share` of total capacity."""
function government_hiring!(model)
    p = parameters(model); rng = stream(model, :labour)
    gov = government(model)
    limit = floor(p.government_employment_share * sum(w.capacity for w in persons(model); init = 0.0))
    wage = government_wage_per_unit(model)
    hired = 0.0
    for w in stable_shuffle(rng, [w for w in persons(model) if w.labour_available > 1e-9])
        hired >= limit - 1e-9 && break
        units = min(w.labour_available, limit - hired)
        gov.wage_bill += units * wage
        w.labour_available -= units; w.labour_sold += units; w.market[:wage].sold += units
        hired += units
        push!(model.wage_contracts, WageContract(gov.id, w.id, units, wage, :government))
        pay_income!(model, gov, w, units * wage, :wage)
        record_transaction!(model, :wage, wage, units)
        log_event!(model, :hire; employer = gov.id, employer_kind = :government, worker = w.id, units = units, price = wage)
    end
    return nothing
end

unemployed(w::Person) = w.labour_offered > 1e-9 && w.labour_sold <= 1e-9
underemployed(w::Person) = w.labour_offered > 1e-9 && w.labour_sold < w.labour_offered - 1e-9
unsold_share(w::Person) = w.labour_offered > 1e-9 ? (w.labour_offered - w.labour_sold) / w.labour_offered : 0.0

"""
    manage_government_reserve!(model)

The government's reserve and tax policy, once a round after demurrage.

1. Bookkeeping: this round's outlays and revenue enter their trailing windows (`government_expense_window`).
2. Reserve (`government_reserve_in_rounds` > 0): the target is that many rounds of expected spending. Cash above
   the target is disposed of — `surplus_redistribution_share` as an equal payment to every living person,
   `surplus_tax_reduction_share` by lowering taxes.
3. Fiscal policy (`tax_policy` ≠ :none): a shortfall — spending above revenue, plus the reserve gap spread over the
   reserve's rounds — is met by a tax rise sized to cover `tax_response_coverage` of it; a reduction from step 2 goes
   through the same channel. Either way revenue moves by at most `tax_response_step` of itself per round.
   `:scale` moves one multiplier on every tax; `:brackets` moves each progressive bracket in proportion to its own
   rate (plus `bracket_fixed_rise` points), so higher brackets carry more of a rise and get more of a cut.

4. The mix (levers): five families — income, consumption, wealth, profit, parking tax — each with its own scale. Each
   first shifts by |r| × its lever (`tax_levers`; a standing preference — a family with a negative lever is relieved on
   a raise and cut hardest on a cut) and then moves by r with the others. All levers 0 is one scale. The parking *fee*
   is money, not tax, and is never touched.

With `tax_policy = :none` a reduction is applied in full (the 20 September rule) and shortfalls do nothing: under
debt money the government borrows, under SuMSy it runs its balance down.
"""
function manage_government_reserve!(model)
    p = parameters(model)
    push!(model.government_outlay_history, model.government_outlay_this_round)
    push!(model.revenue_history, model.tax_this_round)                     # includes the consumption tax (booked as tax at settlement)
    push!(model.consumption_revenue_history, model.consumption_tax_this_round)
    push!(model.wealth_revenue_history, model.wealth_tax_this_round)
    while length(model.government_outlay_history) > p.government_expense_window
        popfirst!(model.government_outlay_history); popfirst!(model.revenue_history); popfirst!(model.consumption_revenue_history); popfirst!(model.wealth_revenue_history)
    end
    p.government_reserve_in_rounds > 0 || return nothing
    gov = government(model)
    expected = sum(model.government_outlay_history) / length(model.government_outlay_history)
    revenue = sum(model.revenue_history) / length(model.revenue_history)
    target = p.government_reserve_in_rounds * expected
    model.government_reserve_target = target
    surplus = cash(gov) - target
    # -- surplus: pay out, and mark the reduction the tax channel should deliver
    reduction = 0.0
    if surplus > 1e-6
        payout = round(surplus * p.surplus_redistribution_share, digits = 4)
        ps = persons(model)
        if payout > 1e-6 && !isempty(ps)
            each = floor(payout / length(ps) * 1e4) / 1e4                  # rounded down so the sum never exceeds the cash
            paid = 0.0
            for w in ps
                amount = round(min(each, cash(gov)), digits = 4)
                amount > 0 || break
                transfer!(model, gov, w, amount, :surplus_dividend); paid += amount
            end
            model.surplus_redistributed_this_round = paid
            log_event!(model, :surplus_dividend; amount = paid, each = each, reserve = cash(gov), target = target)
        end
        reduction = surplus * p.surplus_tax_reduction_share
    end
    # -- shortfall: what spending exceeds revenue by, plus the reserve gap spread over the reserve's rounds
    shortfall = max(expected - revenue, 0.0) + max(-surplus, 0.0) / p.government_reserve_in_rounds
    model.tax_shortfall = shortfall
    base = max(revenue, 1e-6)
    if p.tax_policy == :none
        # the 20 September rule: reductions in full, no raises; a scale below 1 climbs back when short
        if reduction > 1e-6 && model.tax_this_round > 1e-6
            model.tax_scale = clamp(model.tax_scale * (1 - reduction / model.tax_this_round), 0.0, 1.0)
        elseif surplus < -1e-6 && model.tax_scale < 1 && model.tax_this_round > 1e-6
            model.tax_scale = clamp(model.tax_scale * (1 + (-surplus) * p.surplus_tax_reduction_share / model.tax_this_round), 0.0, 1.0)
        end
        model.tax_policy_step = 0.0
        model.consumption_tax_scale = model.tax_scale; model.wealth_tax_scale = model.tax_scale   # :none — one scale for all five
        model.profit_tax_scale = model.tax_scale; model.parking_tax_scale = model.tax_scale; model.land_levy_scale = model.tax_scale
        return nothing
    end
    # the desired relative change in revenue, then the step limit
    wanted = reduction > 1e-6 ? -reduction / base : shortfall > 1e-6 ? p.tax_response_coverage * shortfall / base : 0.0
    r = clamp(wanted, -p.tax_response_step, p.tax_response_step)
    model.tax_policy_step = r
    # -- shift, then move: family i goes by r × lever_i (the shift) and then by r (the move), each as a multiplier
    abs(r) <= 1e-9 && return nothing
    apply_income!(model, p, mv) = begin
        if p.tax_policy == :brackets && p.income_tax_schedule == :progressive
            for (k, rate) in enumerate(model.bracket_rates)
                model.bracket_rates[k] = clamp(rate * (1 + mv) + sign(mv) * p.bracket_fixed_rise, 0.0, p.bracket_rate_maximum)
            end
        end
        model.tax_scale = clamp(model.tax_scale * (1 + mv), 0.0, p.tax_scale_maximum)   # capital and demurrage tax follow it under :brackets
    end
    scale_field = OrderedDict(:consumption => :consumption_tax_scale, :wealth => :wealth_tax_scale, :profit => :profit_tax_scale, :parking => :parking_tax_scale, :land => :land_levy_scale)
    for family in (:income, :consumption, :wealth, :profit, :parking, :land)
        shift = abs(r) * Float64(get(p.tax_levers, family, 0.0))   # a standing preference, not a direction (21 September)
        if family == :income
            abs(shift) > 1e-12 && apply_income!(model, p, shift); apply_income!(model, p, r)
        else
            f = scale_field[family]
            setproperty!(model, f, clamp(getproperty(model, f) * (1 + shift) * (1 + r), 0.0, p.tax_scale_maximum))
        end
    end
    return nothing
end

"""
    taxable_wealth(model, w)

Book value of what a person holds in land and shares: land at the going land price, shareholder-firm units at book
value per unit, cooperative membership at the capital paid in. Cash, loans and bonds are not in the base.
"""
function taxable_wealth(model, w::Person)
    p = parameters(model)
    value = w.land * land_valuation_price(model)
    for e in alive_agents(model)
        e isa Enterprise || continue
        if e.ownership == :shareholders
            units = get(e.shares, w.id, 0.0)
            units > 0 && (value += units * max(book_per_unit(model, e), 0.0))
        elseif e.ownership == :cooperative && haskey(e.members, w.id)
            value += p.membership_share_price - get(e.membership_unpaid, w.id, 0.0)
        end
    end
    return max(value, 0.0)
end

"""
    collect_wealth_tax!(model)

Every round: `wealth_tax_rate` ÷ `wealth_tax_rounds_per_year` of each person's taxable wealth, times the fiscal
policy's scale, transferred to the government in cash. Arrears from earlier rounds are collected first; what cannot
be paid is carried forward.
"""
function collect_wealth_tax!(model)
    p = parameters(model)
    p.wealth_tax_rate > 0 || return nothing
    gov = government(model)
    rate = p.wealth_tax_rate / p.wealth_tax_rounds_per_year * model.wealth_tax_scale   # its own scale, moved by the policy at its weight
    base = 0.0
    for w in persons(model)
        wealth = taxable_wealth(model, w)
        base += wealth
        due = round(wealth * rate + w.wealth_tax_arrears, digits = 4)
        due > 1e-6 || continue
        paid = round(min(due, cash(w)), digits = 4)
        if paid > 1e-6
            transfer!(model, w, gov, paid, :wealth_tax)
            gov.tax_collected += paid; model.tax_this_round += paid; model.wealth_tax_this_round += paid
        end
        w.wealth_tax_arrears = round(due - paid, digits = 4)
    end
    model.wealth_tax_base = base
    return nothing
end

function pay_unemployment_fees!(model)
    p = parameters(model)
    gov = government(model)
    bread = expected_price(model, :bread)
    for w in persons(model)
        if unemployed(w) || (p.partial_unemployment_fee && underemployed(w))
            w.employed_rounds = 0
            if w.unemployed_rounds == 0
                base = p.unemployment_fee_in_breads * bread
                w.fee = w.last_wage_income >= base ? base : w.last_wage_income
                w.fee = max(w.fee, p.minimum_fee_in_breads * bread)
            end
            w.unemployed_rounds += 1
            if w.unemployed_rounds % p.fee_reduction_interval == 0
                w.fee = max(w.fee * (1 - p.fee_reduction_rate), p.minimum_fee_in_breads * bread)
            end
            fee = p.partial_unemployment_fee ? w.fee * unsold_share(w) : w.fee
            model.government_outlay_this_round += fee
            promise!(model, gov, w, fee, :unemployment_fee, 2, :fee)
        else
            w.labour_sold > 1e-9 && (w.employed_rounds += 1)
            if w.employed_rounds >= p.employment_rounds_to_reset_fee
                w.unemployed_rounds = 0
                w.fee = 0.0
            end
        end
    end
    return nothing
end

"""
    collect_land_levy!(model)

`land_levy`: every landholder pays `land_levy_rate` × the value of its land to the government each month — persons down to the
protected minimum, firms and banks from their cash; what cannot be paid is carried as arrears and collected first next time.
"""
function collect_land_levy!(model)
    rate = land_levy_rate(model)
    rate > 0 || return nothing
    gov = government(model); price = land_valuation_price(model)
    for a in agents_by_id(model)
        (a.alive && !is_government(a) && a.land > 0) || continue
        due = round(a.land_levy_arrears + rate * a.land * price, digits = 4)
        can = a isa Person ? max(cash(a) - collection_floor(model), 0.0) : cash(a)
        paid = round(min(due, can), digits = 4)
        paid > 1e-6 && (transfer!(model, a, gov, paid, :land_levy); gov.tax_collected += paid; model.tax_this_round += paid; model.land_levy_this_round += paid)
        a.land_levy_arrears = round(due - paid, digits = 4)
    end
    return nothing
end

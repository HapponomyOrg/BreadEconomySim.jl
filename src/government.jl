# ---- government (spec v2 §5) ------------------------------------------------------

"""Gross statutory wage per labour unit: net full-time wage = breads × (1 + premium) × bread price."""
function government_wage_per_unit(model)
    p = parameters(model)
    net_full_time = p.government_wage_in_breads * (1 + p.government_wage_premium) * expected_price(model, :bread)
    return net_full_time / (1 - effective_wage_tax_rate(model)) / p.maximum_capacity
end

"""Employer of last resort: hires leftover labour up to `government_employment_share` of total capacity."""
function government_hiring!(model)
    p = parameters(model); rng = abmrng(model)
    gov = government(model)
    limit = floor(p.government_employment_share * sum(w.capacity for w in persons(model); init = 0.0))
    wage = government_wage_per_unit(model)
    hired = 0.0
    for w in shuffle(rng, [w for w in persons(model) if w.labour_available > 1e-9])
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
    pay_unemployment_fees!(model)

Paid before the bread market. Fee: two breads if the last wage income was at least that, otherwise the last
wage income, never below one bread; every `fee_reduction_interval` consecutive unemployed rounds it falls by
`fee_reduction_rate`. The unemployment spell only resets after `employment_rounds_to_reset_fee` rounds of work.
"""
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
            promise!(model, gov, w, p.partial_unemployment_fee ? w.fee * unsold_share(w) : w.fee, :unemployment_fee, 2, :fee)
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

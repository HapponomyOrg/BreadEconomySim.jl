# ---- loan arithmetic ---------------------------------------------------------

outstanding_principal(loan::Loan) = Float64(sum(loan.debt.installments; init = Currency(0)))
rest_interest(loan::Loan) = Float64(loan.debt.rest_interest)
total_due(loan::Loan) = outstanding_principal(loan) + rest_interest(loan)
next_installment(loan::Loan) = isempty(loan.debt.installments) ? 0.0 : Float64(loan.debt.installments[end])
next_payment(loan::Loan) = next_installment(loan) + loan.debt.interest_rate * outstanding_principal(loan) + rest_interest(loan)

debtor_loans(model, a::Agent) = [l for l in model.loans if !l.settled && l.debtor_id == a.id]
creditor_loans(model, a::Agent) = [l for l in model.loans if !l.settled && l.creditor_id == a.id]
peer_loans_of(model, a::Agent) = [l for l in model.peer_loans if !l.settled && l.borrower_id == a.id]
peer_claims_of(model, a::Agent) = [l for l in model.peer_loans if !l.settled && l.lender_id == a.id]
peer_next_payment(l::PeerLoan) = min(l.installment, l.outstanding) + l.rate * l.outstanding
peer_debt_of(model, a::Agent) = sum(l.outstanding for l in peer_loans_of(model, a); init = 0.0)
peer_claims(model, a::Agent) = sum(l.outstanding for l in peer_claims_of(model, a); init = 0.0)
has_arrears(model, a::Agent) = any(l -> l.in_arrears, debtor_loans(model, a)) || any(l -> l.in_arrears, peer_loans_of(model, a))

# ---- expected income and affordability (spec v1 §6, v2 §2, §5) --------------

net_wage(model) = expected_price(model, :wage) * (1 - effective_wage_tax_rate(model))

"""Tax on a full-time gross wage `gross` per round under the schedule (0 for gross ≤ 0)."""
function wage_tax_amount(model, gross::Float64)
    p = parameters(model)
    gross <= 0 && return 0.0
    p.income_tax_schedule == :flat && return gross * p.wage_tax_rate
    ref = p.maximum_capacity * expected_price(model, :wage)          # full-time gross wage per round
    ssc = p.social_contribution_rate * gross
    taxable = gross - ssc
    edges = p.tax_bracket_edges .* ref; rates = p.tax_bracket_rates
    tax = 0.0; lower = 0.0
    for (i, rate) in enumerate(rates)
        upper = i <= length(edges) ? edges[i] : Inf
        taxable > lower && (tax += rate * (min(taxable, upper) - lower))
        lower = upper
    end
    tax = max(tax - rates[1] * min(p.tax_free_share * ref, taxable), 0.0)
    return ssc + tax * (1 + p.municipal_surcharge)
end
"""Effective (average) wage tax rate of a full-time worker under the schedule; the flat rate under :flat."""
function effective_wage_tax_rate(model)
    p = parameters(model)
    p.income_tax_schedule == :flat && return p.wage_tax_rate
    ref = p.maximum_capacity * expected_price(model, :wage)
    return ref > 0 ? wage_tax_amount(model, ref) / ref : p.wage_tax_rate
end

function expected_income(model, a::Agent)
    p = parameters(model)
    if a isa Person
        return a.effective_capacity * net_wage(model) + a.land * expected_price(model, :rent) * (1 - p.capital_tax_rate) + a.fee +
               (p.monetary_system == :sumsy ? p.guaranteed_income : 0.0)
    elseif a.kind == :farm
        return a.production_target * expected_price(model, :grain)
    elseif a.kind == :bakery
        return a.production_target * expected_price(model, :bread) * p.breads_per_grain
    elseif a.kind == :bank
        return sum(l.debt.interest_rate * outstanding_principal(l) for l in creditor_loans(model, a); init = 0.0)
    else
        return model.tax_this_round
    end
end

living_cost(model, a::Agent) = a isa Person ? meal_price(model) : 0.0

loan_term_for(model, borrower::Agent) = (borrower isa Person && parameters(model).bread_loan_term > 0) ? parameters(model).bread_loan_term : parameters(model).loan_term_in_rounds

function affordable(model, borrower::Agent, amount::Float64, rate::Float64)
    p = parameters(model)
    existing = sum(next_payment(l) for l in debtor_loans(model, borrower); init = 0.0) + sum(peer_next_payment(l) for l in peer_loans_of(model, borrower); init = 0.0)
    new_payment = amount / loan_term_for(model, borrower) + rate * amount
    return existing + new_payment + living_cost(model, borrower) <= p.affordability_ratio * expected_income(model, borrower)
end

"""Would a loan of `amount` be granted to `borrower` right now (bank alive, no arrears, affordable)?"""
function credit_eligible(model, borrower::Agent, amount::Float64)
    amount <= 0 && return true
    if parameters(model).monetary_system == :sumsy
        p = parameters(model)
        return p.peer_lending && bank_of(model, borrower) !== nothing && !has_arrears(model, borrower) && affordable(model, borrower, amount, p.peer_loan_rate)
    end
    lender = choose_lender(model, borrower)
    lender === nothing && return false
    has_arrears(model, borrower) && return false
    return affordable(model, borrower, amount, borrowing_rate(model, lender, borrower))
end

# ---- lender choice and issuance ---------------------------------------------

function choose_lender(model, borrower::Agent)
    candidates = [b for b in enterprises(model, :bank) if b.id != borrower.id]
    isempty(candidates) && return nothing
    lowest = minimum(b.interest_rate for b in candidates)
    return rand(abmrng(model), [b for b in candidates if b.interest_rate == lowest])
end

"""Rate a borrower pays: banks and the government borrow at a discount, everyone else at the posted rate."""
function borrowing_rate(model, lender::Enterprise, borrower::Agent)
    p = parameters(model)
    is_bank(borrower) && return lender.interest_rate * p.interbank_rate_discount
    is_government(borrower) && return lender.interest_rate * p.government_rate_discount
    return lender.interest_rate
end

"""
    request_loan!(model, borrower, amount, purpose)

Cheapest bank (ties random). Refused when in arrears, no bank alive, or unaffordable.
Banks and the government skip the affordability test (interbank lending; the state is always allowed to borrow).
"""
function request_loan!(model, borrower::Agent, amount::Float64, purpose::Symbol)
    amount = ceil(amount * 1e4) / 1e4
    amount <= 0 && return true
    if parameters(model).startup_financing == :paid_in_capital && borrower isa Enterprise && borrower.ownership == :shareholders && !isempty(borrower.shares)
        # the founders borrow personally (largest holder first) and pay the money in as capital
        holders = sort([(model[h], u) for (h, u) in borrower.shares if model[h] isa Person && model[h].alive]; by = x -> -x[2])
        raised = 0.0
        for (f, u) in holders
            need = round(amount - raised, digits = 4); need <= 1e-6 && break
            before = cash(f)
            request_loan!(model, f, need, :founder_capital) || continue
            got = round(min(cash(f) - before, need), digits = 4)
            got > 0 && (transfer!(model, f, borrower, got, :paid_in_capital); borrower.paid_in_capital += got; raised += got)
        end
        return raised >= amount - 1e-6
    end
    parameters(model).monetary_system == :sumsy && return request_peer_loan!(model, borrower, amount, purpose)
    if parameters(model).government_bonds && is_government(borrower)
        funded = issue_bonds!(model, borrower, amount)
        amount = round(amount - funded, digits = 4)
        amount <= 1e-6 && return true
    end
    p = parameters(model)
    model.credit_demand_this_round += amount
    lender = choose_lender(model, borrower)
    reason = nothing
    if lender === nothing
        reason = :no_bank
    elseif !is_government(borrower) && has_arrears(model, borrower)
        reason = :arrears
    elseif !(is_bank(borrower) || is_government(borrower)) && !affordable(model, borrower, amount, borrowing_rate(model, lender, borrower))
        reason = :unaffordable
    end
    if reason !== nothing
        model.cumulative_credit_refusals += 1
        log_event!(model, :credit_refused; actor = borrower.id, agent_kind = kind_of(borrower), amount = amount, purpose = purpose, reason = reason)
        return false
    end
    rate = borrowing_rate(model, lender, borrower)
    debt = bank_loan(lender.balance, borrower.balance, amount, rate, loan_term_for(model, borrower), 1, current_round(model))
    push!(model.loans, Loan(length(model.loans) + 1, lender.id, borrower.id, debt, 0, false, current_round(model), false, 0.0))
    model.money_created_this_round += amount
    model.cumulative_money_created += amount
    log_event!(model, :loan; actor = borrower.id, agent_kind = kind_of(borrower), lender = lender.id, amount = amount, rate = rate, purpose = purpose)
    return true
end

# ---- promises instead of payments (clearing system) ---------------------------

"""Persons protect a savings buffer; producers a reserve target; the government and banks have none."""
function buffer_target(model, a::Agent)
    a isa Person && return savings_buffer(model)
    return is_producer(a) ? reserve_target(model, a) : 0.0
end

"""Standard reserve: `reserve_target_in_rounds` × expected input cost per round."""
function reserve_target(model, a::Enterprise)
    p = parameters(model)
    labour = max(a.production_target, 0) * expected_price(model, :wage)
    input = a.kind == :farm ? a.production_target * expected_price(model, :rent) : a.kind == :bakery ? a.production_target * expected_price(model, :grain) : 0.0
    return p.reserve_target_in_rounds * (labour + input)
end

"""Under clearing every purchase is a promise; the credit decision is taken once, on the net position, in `clear!`."""
fund!(model, a::Agent, amount::Float64, purpose::Symbol) = true

function promise!(model, from::Agent, to::Agent, amount::Float64, purpose::Symbol, priority::Int, income_kind::Symbol = :none)
    amount = round(amount, digits = 4)
    amount <= 0 && return nothing
    if parameters(model).clearing
        push!(model.promises, Promise(from.id, to.id, amount, purpose, priority, income_kind, 0.0))
        return nothing
    end
    # immediate settlement: cash, then credit for the shortfall, the rest becomes a trade arrear
    short = round(amount - cash(from), digits = 4)
    if short > 1e-6 && !is_bank(from)
        request_loan!(model, from, short, :immediate)
    elseif short > 1e-6 && is_bank(from)
        monetise_equity!(model, from, short)
    end
    paid = round(min(amount, cash(from)), digits = 4)
    paid > 0 && transfer!(model, from, to, paid, purpose)
    if to isa Person
        income_kind == :wage && (to.labour_income += paid)
        income_kind == :rent && (to.rent_income += paid)
        income_kind == :fee && (to.fee_received += paid)
        income_kind == :dividend && (to.dividend_income += paid)
    end
    income_kind == :tax && (government(model).tax_collected += paid; model.tax_this_round += paid)
    rest = round(amount - paid, digits = 4)
    rest > 1e-6 && push!(model.trade_arrears, Promise(from.id, to.id, rest, purpose, 0, income_kind, 0.0))
    return nothing
end

"""Immediate transfer, used only outside the clearing cycle (estates, seizure refunds)."""
function transfer!(model, from::Agent, to::Agent, amount::Float64, purpose::Symbol)
    amount = round(amount, digits = 4)
    amount <= 0 && return 0.0
    cash(from) < amount && amount - cash(from) < 1e-3 && (amount = cash(from))
    transfer_asset!(from.balance, to.balance, DEPOSIT, amount; timestamp = current_round(model)) ||
        error("payment failed: $(kind_of(from)) $(from.id) → $(kind_of(to)) $(to.id) $amount for $purpose (cash $(cash(from)))")
    log_event!(model, :payment; from = from.id, to = to.id, amount = amount, purpose = purpose)
    return amount
end

"""Payment for goods or land: a priority-3 promise."""
pay!(model, from::Agent, to::Agent, amount::Float64, purpose::Symbol) = (promise!(model, from, to, amount, purpose, 3); amount)

"""
    pay_income!(model, payer, person, gross, kind)

Income of a person (`:wage` or `:rent`): tax promise to the government (priority 1) and net promise to the
person (priority 2). Government wages: tax is withheld, only the net is promised.
"""
function pay_income!(model, payer::Agent, person::Person, gross::Float64, kind::Symbol)
    p = parameters(model)
    if kind == :dividend
        tax = round(gross * p.dividend_tax_rate, digits = 4)
    elseif kind == :wage && p.income_tax_schedule == :flat
        tax = round(gross * p.wage_tax_rate, digits = 4)
        person.gross_wage_this_round += gross
    elseif kind == :wage
        tax = round(wage_tax_amount(model, person.gross_wage_this_round + gross) - wage_tax_amount(model, person.gross_wage_this_round), digits = 4)
        person.gross_wage_this_round += gross
    else
        tax = round(gross * p.capital_tax_rate, digits = 4)
    end
    net = round(gross - tax, digits = 4)
    gov = government(model)
    if tax > 0
        if payer === gov
            gov.tax_collected += tax; model.tax_this_round += tax
        else
            promise!(model, payer, gov, tax, Symbol(kind, :_tax), 1, :tax)
        end
    end
    promise!(model, payer, person, net, kind, 2, kind)
    return net
end

obligations(model, a::Agent) = [pr for pr in model.promises if pr.from_id == a.id]
receipts(model, a::Agent) = [pr for pr in model.promises if pr.to_id == a.id]

"""
    clear!(model)

Simultaneous settlement of all promises (spec v2 addendum). 1) Each agent's net deficit at full receipts is
financed: banks monetise equity, everyone else asks for credit on the net (savings/reserve rule applied to the
net). 2) Payments are settled by fixed-point iteration: each agent pays its obligations in priority order from
cash plus (estimated) receipts; estimates only fall, so the iteration converges. 3) Net positions are booked,
income is recorded, unpaid tails become priority-0 trade arrears carried to the next round, and receipts of
landless persons in loan arrears are garnished.
"""
function clear!(model)
    p = parameters(model); rng = abmrng(model)
    promises = model.promises
    isempty(promises) && return nothing
    agents = Dict(a.id => a for a in allagents(model))
    # one pass over the books: obligations, receipts and peer debt service per agent (used by lendable and issue_bonds!)
    empty!(model.clearing_obligations); empty!(model.clearing_receipts); empty!(model.clearing_debt_service)
    for pr in promises
        model.clearing_obligations[pr.from_id] = get(model.clearing_obligations, pr.from_id, 0.0) + pr.amount
        model.clearing_receipts[pr.to_id] = get(model.clearing_receipts, pr.to_id, 0.0) + pr.amount
    end
    for l in model.peer_loans
        l.settled && continue
        model.clearing_debt_service[l.borrower_id] = get(model.clearing_debt_service, l.borrower_id, 0.0) + max(peer_next_payment(l), 0.0)
    end

    # 1) finance net deficits
    for a in shuffle(rng, alive_agents(model))
        O = get(model.clearing_obligations, a.id, 0.0)
        R = get(model.clearing_receipts, a.id, 0.0)
        O <= 0 && continue
        net_after = cash(a) + R - O
        if is_bank(a)
            net_after < 0 && monetise_equity!(model, a, -net_after)
            net_after = cash(a) + R - O
            net_after < 0 && request_loan!(model, a, -net_after, :clearing)
            continue
        end
        shortfall = max(-net_after, 0.0)
        dip = min(O, max(buffer_target(model, a) - net_after, 0.0))   # the part of this round's spending that eats into savings/reserves
        protection = a isa Person ? p.savings_protection_probability : is_producer(a) ? p.reserve_protection_probability : 0.0
        if dip > 1e-9 && rand(rng) < protection
            request_loan!(model, a, dip, :clearing) || (shortfall > 1e-9 && request_loan!(model, a, shortfall, :clearing))
        elseif shortfall > 1e-9
            request_loan!(model, a, shortfall, :clearing)
        end
    end

    # 2) fixed point of priority settlement
    for pr in promises
        pr.paid = pr.amount
    end
    by_from = Dict{Int, Vector{Promise}}()
    for pr in promises
        push!(get!(by_from, pr.from_id, Promise[]), pr)
    end
    for v in values(by_from)
        sort!(v; by = pr -> pr.priority)
    end
    for iteration in 1:100
        change = 0.0
        for (id, obs) in by_from
            a = agents[id]
            avail = cash(a) + sum(pr.paid for pr in promises if pr.to_id == id; init = 0.0)
            for pr in obs
                new = round(max(min(pr.amount, avail), 0.0), digits = 4)
                change = max(change, abs(new - pr.paid))
                pr.paid = new
                avail -= new
            end
        end
        change < 1e-6 && break
    end

    # 3) book net positions, record income, carry arrears, garnish
    for a in allagents(model)
        net = sum(pr.paid for pr in promises if pr.to_id == a.id; init = 0.0) - sum(pr.paid for pr in promises if pr.from_id == a.id; init = 0.0)
        net = round(net, digits = 4)
        a isa Enterprise && (a.operating_net = net)
        net == 0 && continue
        book_asset!(a.balance, DEPOSIT, net) || book_asset!(a.balance, DEPOSIT, -cash(a))   # residue from rounding
    end
    gov = government(model)
    for pr in promises
        to = agents[pr.to_id]
        pr.paid > 0 && log_event!(model, :payment; from = pr.from_id, to = pr.to_id, amount = pr.paid, purpose = pr.purpose)
        if to isa Person
            pr.income_kind == :wage && (to.labour_income += pr.paid)
            pr.income_kind == :rent && (to.rent_income += pr.paid)
            pr.income_kind == :fee && (to.fee_received += pr.paid)
            pr.income_kind == :dividend && (to.dividend_income += pr.paid)
        elseif pr.income_kind == :tax
            gov.tax_collected += pr.paid; model.tax_this_round += pr.paid
        end
        pr.income_kind == :fee && (gov.fees_paid += pr.paid; model.fees_this_round += pr.paid)
        tail = round(pr.amount - pr.paid, digits = 4)
        if tail > 1e-6 && agents[pr.from_id].alive && to.alive
            push!(model.trade_arrears, Promise(pr.from_id, pr.to_id, tail, pr.purpose, 0, pr.income_kind, 0.0))
            model.cumulative_trade_arrears += tail
            log_event!(model, :trade_arrears; from = pr.from_id, to = pr.to_id, amount = tail, purpose = pr.purpose)
        end
    end
    for a in persons(model)
        garnish!(model, a, sum(pr.paid for pr in promises if pr.to_id == a.id; init = 0.0))
    end
    return nothing
end

function garnish!(model, a::Agent, incoming::Float64)
    (a.alive && a isa Person) || return nothing
    a.land > 0 && return nothing
    loans = [l for l in debtor_loans(model, a) if l.in_arrears]
    isempty(loans) && return nothing
    garnished = min(round(parameters(model).garnishment_rate * incoming, digits = 4), cash(a))
    for l in loans
        garnished <= 1e-9 && break
        paid = repay_extra!(model, l, min(garnished, total_due(l)))
        garnished -= paid
        paid > 0 && log_event!(model, :garnishment; actor = a.id, loan = l.id, amount = paid)
    end
    return nothing
end

"""
    repay_extra!(model, loan, amount) -> paid

Unscheduled repayment from the debtor's cash: rest interest first, then principal from the latest
installments. Same bookings as EconoSim `process_debt!` for a bank debt.
"""
function repay_extra!(model, loan::Loan, amount::Float64)
    debtor = model[loan.debtor_id]; creditor = model[loan.creditor_id]
    amount = round(min(amount, cash(debtor), total_due(loan)), digits = 4)
    amount <= 1e-9 && return 0.0
    interest = min(amount, rest_interest(loan))
    loan.debt.rest_interest -= Currency(interest)
    principal = round(amount - interest, digits = 4)
    remaining = principal
    inst = loan.debt.installments
    while remaining > 1e-9 && !isempty(inst)
        i = Float64(inst[end])
        if remaining >= i - 1e-9
            pop!(inst); remaining -= i
        else
            inst[end] = Currency(i - remaining); remaining = 0.0
        end
    end
    book_asset!(debtor.balance, DEPOSIT, -amount) || error("extra repayment failed on loan $(loan.id)")
    book_liability!(debtor.balance, DEBT, -principal)
    book_liability!(creditor.balance, DEPOSIT, -amount)
    book_asset!(creditor.balance, DEBT, -principal)
    creditor.retained_interest += interest
    model.cumulative_interest_paid += interest
    model.money_destroyed_this_round += amount
    model.cumulative_money_destroyed += amount
    loan.settled = debt_settled(loan.debt)
    loan.settled && (loan.in_arrears = false)
    return amount
end

"""A bank turns retained interest (equity) into a deposit of its own, up to `amount`."""
function monetise_equity!(model, bank::Enterprise, amount::Float64)
    amount = round(min(amount, bank.retained_interest), digits = 4)
    amount <= 0 && return 0.0
    book_asset!(bank.balance, DEPOSIT, amount)
    book_liability!(bank.balance, DEPOSIT, amount)
    bank.retained_interest -= amount
    model.money_created_this_round += amount
    model.cumulative_money_created += amount
    log_event!(model, :equity_monetised; bank = bank.id, amount = amount)
    return amount
end

# ---- scheduled debt service (spec v1 §4.10, §7) -------------------------------

"""
    service_debt!(model)

Every live loan is serviced through EconoSim `process_debt!`. A shortfall (installment or interest)
puts the loan in arrears; arrears clear on the next full payment. After `arrears_rounds_until_seizure`
consecutive shortfalls the bank seizes: persons lose land; enterprises lose cash and land and are closed
when that does not cover the debt.
"""
function service_debt!(model)
    p = parameters(model)
    for debtor in shuffle(abmrng(model), alive_agents(model))
        for loan in sort(debtor_loans(model, debtor); by = l -> l.created)
            loan.created == current_round(model) && continue      # first payment falls in the round after issuance
            creditor = model[loan.creditor_id]
            is_bank(debtor) && monetise_equity!(model, debtor, next_payment(loan) - cash(debtor))
            due_interest = loan.debt.interest_rate * outstanding_principal(loan) + rest_interest(loan)
            _, (paid_installment, paid_interest, shortfall) = process_debt!(loan.debt)
            paid_installment = Float64(paid_installment); paid_interest = Float64(paid_interest); shortfall = Float64(shortfall)
            creditor.retained_interest += paid_interest
            creditor.interest_received += paid_interest
            debtor isa Enterprise && (debtor.interest_paid += paid_interest)
            model.cumulative_interest_paid += paid_interest
            model.money_destroyed_this_round += paid_installment + paid_interest
            model.cumulative_money_destroyed += paid_installment + paid_interest
            missed = shortfall + rest_interest(loan) > p.arrears_de_minimis_in_meals * meal_price(model)
            if missed
                loan.in_arrears = true
                loan.arrears_rounds += 1
                log_event!(model, :missed_payment; actor = debtor.id, agent_kind = kind_of(debtor), loan = loan.id,
                           paid = paid_installment + paid_interest, shortfall = shortfall, rest_interest = rest_interest(loan), arrears_rounds = loan.arrears_rounds)
            else
                loan.in_arrears = false
                loan.arrears_rounds = 0
            end
            loan.settled = debt_settled(loan.debt)
            loan.settled && log_event!(model, :loan_settled; actor = debtor.id, loan = loan.id)
            if !loan.settled && loan.arrears_rounds >= p.arrears_rounds_until_seizure && !is_government(debtor)
                debtor isa Person ? seize_land!(model, loan) : seize_enterprise!(model, loan)
            end
        end
    end
    return nothing
end

"""Land of a debtor to the creditor at the current land price until the debt is covered (principal covered by collateral is not money destruction)."""
function seize_land!(model, loan::Loan)
    debtor = model[loan.debtor_id]; creditor = model[loan.creditor_id]
    price = land_price(model)
    units = 0
    while debtor.land > 0 && total_due(loan) > 1e-9
        debtor.land -= 1; creditor.land += 1; units += 1
        value = price
        interest = min(value, rest_interest(loan))
        loan.debt.rest_interest -= Currency(interest)
        value -= interest
        principal = 0.0
        inst = loan.debt.installments
        while value > 1e-9 && !isempty(inst)
            i = Float64(inst[end])
            if value >= i - 1e-9
                pop!(inst); principal += i; value -= i
            else
                inst[end] = Currency(i - value); principal += value; value = 0.0
            end
        end
        book_liability!(debtor.balance, DEBT, -principal)
        book_asset!(creditor.balance, DEBT, -principal)
        creditor.retained_interest += interest
        if value > 1e-9
            refund = min(value, cash(creditor))
            refund > 0 && transfer!(model, creditor, debtor, refund, :seizure_refund)
        end
    end
    loan.settled = debt_settled(loan.debt)
    loan.settled && (loan.in_arrears = false; loan.arrears_rounds = 0)
    units > 0 && log_event!(model, :seizure; actor = debtor.id, agent_kind = kind_of(debtor), creditor = creditor.id, loan = loan.id, units = units, price = price, remaining_due = total_due(loan))
    return nothing
end

"""Enterprise failure: cash first, then land; closure when the debt is still uncovered (spec v2 §3)."""
function seize_enterprise!(model, loan::Loan)
    debtor = model[loan.debtor_id]
    repay_extra!(model, loan, cash(debtor))
    total_due(loan) > 1e-9 && debtor.land > 0 && seize_land!(model, loan)
    if !loan.settled && total_due(loan) > parameters(model).closure_debt_threshold_in_breads * expected_price(model, :bread)
        close_enterprise!(model, debtor, :uncovered_debt)
    elseif !loan.settled
        loan.in_arrears = false; loan.arrears_rounds = 0      # de minimis: carry the tail, keep the business
    end
    return nothing
end

function close_enterprise!(model, e::Enterprise, reason::Symbol)
    e.alive = false
    e.closed_round = current_round(model)
    model.closures += 1
    log_event!(model, :closure; actor = e.id, agent_kind = e.kind, reason = reason, cash = cash(e), debt = debt_of(e), land = e.land)
    settle_estate!(model, e)
    return nothing
end

# ---- rate setting (spec v2 §4) ------------------------------------------------

"""
    set_interest_rates!(model)

From round 2: `rate = expected wage bill / (affordability_ratio × (outstanding loans + projected credit demand))`,
with projected demand = last round's credit demand. Unchanged when the base is zero.
"""
function set_interest_rates!(model)
    p = parameters(model)
    current_round(model) == 1 && return nothing
    for bank in enterprises(model, :bank)
        base = sum(outstanding_principal(l) for l in creditor_loans(model, bank); init = 0.0) + model.credit_demand_previous_round
        base <= 0 && continue
        deposits = sum(cash(a) for a in alive_agents(model) if (a isa Person || (p.deposit_interest_to_enterprises && is_producer(a))) && bank_of(model, a) === bank; init = 0.0)
        deposit_cost = (p.deposit_interest_rate + p.loyalty_bonus_rate) * deposits / max(p.deposit_interest_period, 1)
        bank.interest_rate = (bank.bid[:wage] + deposit_cost) / (p.affordability_ratio * base)
    end
    return nothing
end

# ---- estates (spec v2 §2, §3) ------------------------------------------------

"""
    settle_estate!(model, dead)

Creditors are paid pro rata from cash, then land; the rest goes to a random living person
(cash and land alike). A closed enterprise's stock is lost. Loans of a dead bank are written off when
`debt_dies_with_bank`, otherwise debtors keep paying into the dead bank's balance.
"""
function settle_estate!(model, dead::Agent)
    p = parameters(model)
    loans = debtor_loans(model, dead)
    owed = sum(total_due(l) for l in loans; init = 0.0)
    if owed > 1e-9
        estate_cash = cash(dead)
        for l in sort(loans; by = l -> -total_due(l))
            repay_extra!(model, l, min(round(total_due(l) / owed * estate_cash, digits = 4), cash(dead)))
        end
        for l in loans
            total_due(l) > 1e-9 && dead.land > 0 && seize_land!(model, l)
        end
        for l in loans
            remaining = total_due(l)
            if remaining > 1e-9
                creditor = model[l.creditor_id]
                principal = outstanding_principal(l)
                book_liability!(dead.balance, DEBT, -principal; skip_check = true)
                book_asset!(creditor.balance, DEBT, -principal; skip_check = true)
                l.write_off = remaining
                model.cumulative_write_offs += remaining
                log_event!(model, :write_off; actor = dead.id, loan = l.id, amount = remaining)
            end
            l.settled = true
        end
    end
    # peer loans: pro rata from cash, then land, then written off; claims pass to the heir
    ploans = peer_loans_of(model, dead)
    powed = sum(l.outstanding for l in ploans; init = 0.0)
    if powed > 1e-9
        estate_cash = cash(dead)
        for l in ploans
            share = round(min(l.outstanding / powed * estate_cash, cash(dead)), digits = 4)
            share > 0 && (transfer!(model, dead, model[l.lender_id], share, :estate_peer_loan); l.outstanding = round(l.outstanding - share, digits = 4))
        end
        for l in ploans
            l.outstanding > 1e-9 && dead.land > 0 && seize_land_peer!(model, l)
        end
        for l in ploans
            l.outstanding > 1e-9 && (l.write_off = l.outstanding; model.cumulative_write_offs += l.outstanding; log_event!(model, :write_off; actor = dead.id, peer_loan = l.id, amount = l.outstanding))
            l.outstanding = 0.0; l.settled = true
        end
    end
    heirs = [h for h in persons(model) if h.id != dead.id]
    left = cash(dead)
    if !isempty(heirs)
        heir = rand(abmrng(model), heirs)
        left > 0 && transfer!(model, dead, heir, left, :inheritance)
        heir.land += dead.land
        for l in peer_claims_of(model, dead); l.lender_id = heir.id; end
        (left > 0 || dead.land > 0) && log_event!(model, :inheritance; from = dead.id, heir = heir.id, cash = left, land = dead.land)
    elseif left > 0
        book_asset!(dead.balance, DEPOSIT, -left)
        model.cumulative_money_lost += left
        model.cumulative_money_destroyed += left
    end
    dead.land = 0
    dead isa Enterprise && (empty!(dead.grain); empty!(dead.bread))
    dead isa Person && empty!(dead.bread)
    if is_bank(dead) && p.debt_dies_with_bank
        for l in creditor_loans(model, dead)
            amount = outstanding_principal(l)
            debtor = model[l.debtor_id]
            book_liability!(debtor.balance, DEBT, -amount; skip_check = true)
            book_asset!(dead.balance, DEBT, -amount; skip_check = true)
            l.write_off = total_due(l); l.settled = true
            model.cumulative_write_offs += l.write_off
        end
    end
    return nothing
end


# ---- enterprise taxation (12 September 2026) ------------------------------------

"""
    tax_enterprises!(model)

After debt service. `:income`: farms and bakeries pay `enterprise_income_tax_rate` on max(operating net − interest
paid, 0); banks on interest received (paid by monetising retained interest). `:reserves`: `enterprise_reserve_tax_rate`
on cash held (optionally only above the standard working reserve); banks on retained interest. Paid immediately to
the government from cash; any shortfall is carried as a priority-0 arrear to the government.
"""
function tax_enterprises!(model)
    p = parameters(model)
    p.enterprise_tax == :none && return nothing
    gov = government(model)
    for e in alive_agents(model)
        e isa Enterprise && e.kind in (:farm, :bakery, :theatre, :bank) || continue
        if p.enterprise_tax == :income
            base = is_bank(e) ? e.interest_received : max(e.operating_net - e.interest_paid, 0.0)
            tax = round(p.enterprise_income_tax_rate * base, digits = 4)
        else
            if is_bank(e)
                base = e.retained_interest
            else
                base = cash(e) - (p.reserve_tax_exempts_standard_reserve ? reserve_target(model, e) : 0.0)
            end
            tax = round(p.enterprise_reserve_tax_rate * max(base, 0.0), digits = 4)
        end
        tax <= 1e-9 && continue
        is_bank(e) && monetise_equity!(model, e, tax)
        paid = min(tax, cash(e))
        paid > 0 && transfer!(model, e, gov, paid, :enterprise_tax)
        tail = round(tax - paid, digits = 4)
        tail > 1e-6 && push!(model.trade_arrears, Promise(e.id, gov.id, tail, :enterprise_tax, 0, :tax, 0.0))
        e.enterprise_tax_paid = paid
        gov.tax_collected += paid; model.tax_this_round += paid; model.enterprise_tax_this_round += paid
        log_event!(model, :enterprise_tax; actor = e.id, agent_kind = e.kind, base = base, tax = tax, paid = paid)
    end
    return nothing
end


# ---- deposit interest (12 September 2026) --------------------------------------

"""
    pay_deposit_interest!(model)

Debt system only. Every round the end-of-round balance of each account holder is recorded; every
`deposit_interest_period` rounds the holder's bank pays `deposit_interest_rate` on the average balance of the period
plus `loyalty_bonus_rate` on the lowest balance, out of retained interest (monetised). If the bank's retained interest
does not cover its depositors' claims, each is paid the same fraction.
"""
function pay_deposit_interest!(model)
    p = parameters(model)
    p.monetary_system == :debt || return nothing
    (p.deposit_interest_rate > 0 || p.loyalty_bonus_rate > 0) || return nothing
    holders = [a for a in alive_agents(model) if !is_bank(a) && !is_authority(a) && !is_government(a) && (a isa Person || p.deposit_interest_to_enterprises)]
    for a in holders
        push!(get!(model.balance_history, a.id, Float64[]), cash(a))
    end
    current_round(model) % max(p.deposit_interest_period, 1) == 0 || return nothing
    for bank in enterprises(model, :bank)
        claims = Tuple{Agent, Float64}[]
        for a in holders
            bank_of(model, a) === bank || continue
            h = model.balance_history[a.id]; window = h[max(1, end - p.deposit_interest_period + 1):end]
            due = round(p.deposit_interest_rate * sum(window) / length(window) + p.loyalty_bonus_rate * minimum(window), digits = 4)
            due > 0 && push!(claims, (a, due))
        end
        total = sum(c[2] for c in claims; init = 0.0)
        total <= 0 && continue
        fraction = min(1.0, bank.retained_interest / total)
        for (a, due) in claims
            amount = round(due * fraction, digits = 4)
            amount <= 0 && continue
            monetise_equity!(model, bank, amount)
            amount = round(min(amount, cash(bank)), digits = 4)     # rounding over many accounts can leave the bank a fraction short
            amount <= 0 && continue
            transfer!(model, bank, a, amount, :deposit_interest)
            model.deposit_interest_this_round += amount
        end
        log_event!(model, :deposit_interest; bank = bank.id, claims = total, paid_fraction = fraction)
    end
    return nothing
end


# ---- government bonds (13 September 2026) --------------------------------------

bonds_outstanding(model) = sum(b.principal for b in model.bonds if !b.settled; init = 0.0)
bond_holdings(model, a::Agent) = sum(b.principal for b in model.bonds if !b.settled && b.holder_id == a.id; init = 0.0)

"""Coupon per round: midway between what a deposit earns and what the bank would charge the government."""
function bond_coupon_rate(model)
    p = parameters(model)
    banks = enterprises(model, :bank)
    bank_rate = isempty(banks) ? p.initial_interest_rate : minimum(b.interest_rate for b in banks) * p.government_rate_discount
    deposit_rate = (p.deposit_interest_rate + p.loyalty_bonus_rate) / max(p.deposit_interest_period, 1)
    return round((deposit_rate + bank_rate) / 2, digits = 6)
end

"""Long bonds when the bank rate is below its running median, short when above."""
function bond_term(model)
    p = parameters(model); h = model.bank_rate_history
    isempty(h) && return p.bond_term_long
    banks = enterprises(model, :bank)
    r = isempty(banks) ? p.initial_interest_rate : minimum(b.interest_rate for b in banks)
    return r <= sort(h)[(length(h) + 1) ÷ 2] ? p.bond_term_long : p.bond_term_short
end

"""Sell bonds to holders with surplus above their buffer / reserve (largest first); returns the amount raised."""
function issue_bonds!(model, gov::Agent, amount::Float64)
    p = parameters(model); rng = abmrng(model)
    rate = bond_coupon_rate(model); term = bond_term(model)
    holders = [a for a in alive_agents(model) if !is_government(a) && !is_bank(a) && !is_authority(a)]
    shuffle!(rng, holders)
    avail = Dict(a.id => lendable(model, a) for a in holders)
    filter!(a -> avail[a.id] >= 0.01, holders)
    sort!(holders; by = a -> -avail[a.id])
    raised = 0.0
    for h in holders
        s = round(min(lendable(model, h), amount - raised), digits = 4)
        s < 0.01 && continue
        book_asset!(h.balance, DEPOSIT, -s) || continue
        book_asset!(gov.balance, DEPOSIT, s)
        push!(model.bonds, Bond(length(model.bonds) + 1, h.id, s, rate, current_round(model), current_round(model) + term, false))
        log_event!(model, :bond_issued; holder = h.id, holder_kind = kind_of(h), amount = s, rate = rate, term = term)
        raised += s
        raised >= amount - 1e-6 && break
    end
    model.bonds_issued_this_round += raised
    return raised
end

"""Coupons every round and principal at maturity, from government cash; what cannot be paid is promised (priority 1) for next round's clearing, i.e. rolled over."""
function service_bonds!(model)
    p = parameters(model)
    (p.government_bonds && p.monetary_system == :debt) || return nothing
    gov = government(model)
    push!(model.bank_rate_history, minimum(b.interest_rate for b in enterprises(model, :bank); init = p.initial_interest_rate))
    for b in model.bonds
        b.settled && continue
        holder = model[b.holder_id]
        due = round(b.rate * b.principal, digits = 4)
        if current_round(model) >= b.maturity
            due = round(due + b.principal, digits = 4); b.settled = true
        end
        pay = round(min(due, cash(gov)), digits = 4)
        pay > 0 && transfer!(model, gov, holder, pay, :bond_service)
        rest = round(due - pay, digits = 4)
        rest > 1e-6 && promise!(model, gov, holder, rest, :bond_service, 1)
        model.coupons_this_round += min(pay, b.rate * b.principal)
    end
    return nothing
end


# ---- ownership: dividends and the share market (13 September 2026) -----------------

book_value(model, e::Enterprise) = cash(e) + e.land * land_price(model) - debt_of(e) - peer_debt_of(model, e)
total_share_units(model) = (p = parameters(model); p.shares_per_person > 0 ? float(p.shares_per_person * p.number_of_persons) : 100.0)
book_per_unit(model, e::Enterprise) = book_value(model, e) / total_share_units(model)
mean_dividend_per_unit(model, e::Enterprise) = isempty(e.dividend_history) ? 0.0 : sum(e.dividend_history[max(1, end - 11):end]) / min(length(e.dividend_history), 12) / total_share_units(model)

"""Cash above the reserve target is paid out to the holders over `dividend_build_rounds`, taxed as dividend income."""
function pay_dividends!(model)
    p = parameters(model)
    p.ownership == :none && return nothing
    for e in alive_agents(model)
        (e isa Enterprise && e.ownership != :none) || continue
        excess = cash(e) - reserve_target(model, e)
        payout = round(max(excess, 0.0) / p.dividend_build_rounds, digits = 4)
        push!(e.dividend_history, payout); push!(e.net_history, e.operating_net)
        payout <= 1e-6 && continue
        gov = government(model)
        claims = e.ownership == :cooperative ? [(hid, 1.0) for hid in keys(e.members)] : [(hid, u) for (hid, u) in e.shares]
        total = sum(c[2] for c in claims; init = 0.0)
        total <= 0 && continue
        for (hid, units) in claims
            h = model[hid]
            (h isa Person && h.alive) || continue
            amt = round(min(payout * units / total, cash(e)), digits = 4)
            amt <= 0 && continue
            tax = round(amt * p.dividend_tax_rate, digits = 4); net = round(amt - tax, digits = 4)
            tax > 0 && (transfer!(model, e, gov, tax, :dividend_tax); gov.tax_collected += tax; model.tax_this_round += tax)
            net > 0 && (transfer!(model, e, h, net, :dividend); h.dividend_income += net)
        end
        log_event!(model, :dividend; actor = e.id, agent_kind = e.kind, ownership = e.ownership, amount = payout)
    end
    return nothing
end

"""
    forward_value_per_unit(model, e, y; growth = 0)

Expected dividend per share unit once the firm's loans are repaid, discounted at yield `y` (minus an expected price
growth): dividends are the trailing operating net (before debt service) once debt service stops, zero until then; the
repayment horizon is outstanding debt ÷ current debt service per round. Falls back to book value when nothing is known.
"""
function forward_value_per_unit(model, e::Enterprise, y::Float64; growth::Float64 = 0.0)
    p = parameters(model)
    h = e.net_history; n = min(length(h), 12)
    n == 0 && return max(book_per_unit(model, e), 0.0)
    steady = max(sum(h[end - n + 1:end]) / n, 0.0)
    debt = debt_of(e) + peer_debt_of(model, e)
    service = sum(next_payment(l) for l in debtor_loans(model, e); init = 0.0) + sum(peer_next_payment(l) for l in peer_loans_of(model, e); init = 0.0)
    horizon = debt > 1e-6 && service > 1e-6 ? debt / service : 0.0
    r = max(y - growth, 1e-4)
    return steady / r / (1 + r)^horizon / total_share_units(model)
end

"""A person's value for one unit of `e`: forward-looking when switched on, else trailing dividend ÷ yield floored at book."""
valuation(model, w::Person, e::Enterprise) = parameters(model).forward_valuation ?
    forward_value_per_unit(model, e, w.required_yield; growth = parameters(model).expected_price_growth) :
    max(book_per_unit(model, e), mean_dividend_per_unit(model, e) / max(w.required_yield - parameters(model).expected_price_growth, 1e-4))

founders_stake(e::Enterprise) = sum(get(e.shares, f, 0.0) for f in e.founder_ids; init = 0.0)

"""
    share_market!(model)

Shares of shareholder-owned enterprises trade once a round. Sellers: holders who cannot afford a meal offer a tenth of
their holding at a falling ask (distress); founders sell voluntarily, together never below `founder_minimum_stake`,
when a buyer values the unit above the founder's own valuation, or — under debt money — to retire a bank loan whose
rate exceeds the founder's required yield. Buyers are persons with cash above their buffer who value the unit above
the seller's reservation and above what their cash earns; the keenest buyer takes the unit at the midpoint. A founder's
proceeds retire dearer bank debt first.
"""
function share_market!(model)
    p = parameters(model); rng = abmrng(model)
    (p.share_market && p.ownership != :none) || return nothing
    cash_yield = p.monetary_system == :sumsy ? -p.demurrage_rate : (p.deposit_interest_rate + p.loyalty_bonus_rate) / max(p.deposit_interest_period, 1)
    for e in alive_agents(model)
        (e isa Enterprise && e.ownership == :shareholders) || continue
        buyers = shuffle(rng, [w for w in persons(model) if cash(w) - buffer_target(model, w) > 0])
        sort!(buyers; by = w -> (w.greed == :greedy ? 0 : 1, -valuation(model, w, e)))
        # --- distress sellers (unchanged): a tenth of the holding at a falling ask ---
        for (hid, units) in collect(e.shares)
            seller = model[hid]
            (seller isa Person && seller.alive && cash(seller) < meal_price(model) && units >= 1) || continue
            seller.share_ask <= 0 && (seller.share_ask = max(valuation(model, seller, e), 0.01))
            sold = trade_units!(model, e, seller, buyers, min(units, 10.0), seller.share_ask, cash_yield; distress = true)
            seller.share_ask = sold > 0 ? seller.share_ask : max(seller.share_ask * (1 - p.share_step), 0.01)
        end
        # --- founders: voluntary sales down to the control floor ---
        floor_units = p.founder_minimum_stake * total_share_units(model)
        for fid in shuffle(rng, e.founder_ids)
            f = model[fid]; (f isa Person && f.alive && get(e.shares, fid, 0.0) >= 1) || continue
            room = founders_stake(e) - floor_units; room < 1 && break
            own = valuation(model, f, e)
            dear = [l for l in debtor_loans(model, f) if l.debt.interest_rate > f.required_yield]      # debt money: loans costing more than the shares earn
            want = !isempty(dear)                                                                   # sell to retire them
            reservation = want ? max(own * 0.9, 0.01) : own * (1 + 1e-6)                                # else only above own valuation
            sold = trade_units!(model, e, f, buyers, min(get(e.shares, fid, 0.0), floor(room)), reservation, cash_yield)
            sold > 0 && !isempty(dear) && for l in sort(dear; by = l -> -l.debt.interest_rate); repay_extra!(model, l, cash(f) - buffer_target(model, f)); end
        end
        filter!(kv -> kv.second > 1e-6, e.shares)
    end
    return nothing
end

"""Sell up to `offer` units of `e` from `seller` to the keenest buyers above `reservation`; returns units sold."""
deferred_rate(model) = (p = parameters(model); isnan(p.deferred_payment_rate) ? (p.monetary_system == :sumsy ? p.peer_loan_rate : 0.005) : p.deferred_payment_rate)

function trade_units!(model, e::Enterprise, seller::Person, buyers, offer::Float64, reservation::Float64, cash_yield::Float64; distress::Bool = false)
    p = parameters(model); sold = 0.0
    for b in buyers
        b === seller && continue
        v = valuation(model, b, e)
        v > reservation || continue
        surplus = cash(b) - buffer_target(model, b)
        price = (v + reservation) / 2
        q = min(offer - sold, floor(surplus / price))
        deferred = false
        if p.deferred_payment && q < offer - sold && bank_of(model, b) !== nothing && !has_arrears(model, b)
            # pay in instalments: as many units as the affordability test allows beyond what cash covers
            rate = deferred_rate(model); qd = offer - sold
            while qd >= 1 && !affordable(model, b, qd * price, rate); qd = floor(qd / 2); end
            qd >= 1 && (q = qd; deferred = true)
        end
        q < 1 && continue
        total = round(q * price, digits = 4)
        if deferred
            bank = bank_of(model, b); rate = deferred_rate(model)
            push!(model.peer_loans, PeerLoan(length(model.peer_loans) + 1, seller.id, b.id, bank.id, total, total, total / p.deferred_payment_rounds, rate, rate - p.bank_spread, false, current_round(model), 0, false, false, 0.0))
            model.share_collateral[length(model.peer_loans)] = (e.id, q)
        else
            transfer!(model, b, seller, total, :share_purchase)
        end
        e.shares[seller.id] = get(e.shares, seller.id, 0.0) - q; e.shares[b.id] = get(e.shares, b.id, 0.0) + q
        e.share_price = price; sold += q
        log_event!(model, :share_trade; enterprise = e.id, seller = seller.id, buyer = b.id, units = q, price = price, seller_valuation = reservation, buyer_valuation = v, deferred = deferred, distress = distress)
        sold >= offer - 1e-9 && break
    end
    return sold
end

share_wealth(model, w::Person) = sum(e.share_price * get(e.shares, w.id, 0.0) for e in alive_agents(model) if e isa Enterprise && e.ownership == :shareholders; init = 0.0) +
                                 sum((parameters(model).startup_financing == :paid_in_capital ? parameters(model).membership_share_price * get(e.members, w.id, 0) : book_per_unit(model, e) * get(e.shares, w.id, 0.0)) for e in alive_agents(model) if e isa Enterprise && e.ownership == :cooperative; init = 0.0)


# ---- cooperative membership (13 September 2026) --------------------------------------

"""
    join_cooperatives!(model)

A person with cash above the buffer who is not yet a member of a cooperative joins one (at random) with
`cooperative_join_probability`, buying one share at par; the share capital is the cooperative's working capital.
A member who cannot afford a meal redeems one share at par if the cooperative has the cash. Dividends are per member.
"""
function join_cooperatives!(model)
    p = parameters(model); rng = abmrng(model)
    (p.ownership in (:cooperative, :mixed) && p.startup_financing == :paid_in_capital) || return nothing
    coops = [e for e in alive_agents(model) if e isa Enterprise && e.ownership == :cooperative]
    isempty(coops) && return nothing
    par = p.membership_share_price
    for w in shuffle(rng, persons(model))
        open = [c for c in coops if !haskey(c.members, w.id)]
        if !isempty(open) && cash(w) - buffer_target(model, w) >= par && rand(rng) < p.cooperative_join_probability
            c = rand(rng, open)
            transfer!(model, w, c, par, :membership_share); c.members[w.id] = 1; c.paid_in_capital += par
            log_event!(model, :membership; actor = w.id, cooperative = c.id, price = par)
        elseif cash(w) < meal_price(model)
            for c in coops
                get(c.members, w.id, 0) > 0 && cash(c) >= par || continue
                transfer!(model, c, w, par, :share_redemption); c.members[w.id] -= 1; c.paid_in_capital -= par
                c.members[w.id] == 0 && delete!(c.members, w.id)
                log_event!(model, :redemption; actor = w.id, cooperative = c.id, price = par)
                break
            end
        end
    end
    return nothing
end

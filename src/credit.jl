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
    p.income_tax_schedule == :flat && return gross * p.wage_tax_rate * model.tax_scale
    ref = p.maximum_capacity * expected_price(model, :wage)          # full-time gross wage per round
    ssc = p.social_contribution_rate * gross
    taxable = gross - ssc
    edges = p.tax_bracket_edges .* ref; rates = model.bracket_rates          # the live rates: the fiscal policy moves them
    tax = 0.0; lower = 0.0
    for (i, rate) in enumerate(rates)
        upper = i <= length(edges) ? edges[i] : Inf
        taxable > lower && (tax += rate * (min(taxable, upper) - lower))
        lower = upper
    end
    tax = max(tax - rates[1] * min(p.tax_free_share * ref, taxable), 0.0)
    scale = p.tax_policy == :brackets ? 1.0 : model.tax_scale                 # under :brackets the bracket rates carry the policy
    return (ssc + tax * (1 + p.municipal_surcharge)) * scale
end
"""Effective (average) wage tax rate of a full-time worker under the schedule; the flat rate under :flat."""
function effective_wage_tax_rate(model)
    p = parameters(model)
    p.income_tax_schedule == :flat && return p.wage_tax_rate * model.tax_scale
    ref = p.maximum_capacity * expected_price(model, :wage)
    return ref > 0 ? wage_tax_amount(model, ref) / ref : p.wage_tax_rate * model.tax_scale
end

function expected_income(model, a::Agent)
    p = parameters(model)
    if a isa Person
        return a.effective_capacity * net_wage(model) + a.land * expected_price(model, :rent) * (1 - p.capital_tax_rate) + a.fee +
               (p.monetary_system == :sumsy ? p.guaranteed_income : 0.0)
    elseif a.kind == :farm                                       # the operating margin, not the turnover (review 1, §4.2)
        return max(a.production_target * (expected_price(model, :grain) - expected_price(model, :wage) - expected_price(model, :rent)), 0.0)
    elseif a.kind == :bakery
        return max(a.production_target * (expected_price(model, :bread) * p.breads_per_grain - expected_price(model, :grain) - expected_price(model, :wage)), 0.0)
    elseif a.kind == :bank
        return sum(l.debt.interest_rate * outstanding_principal(l) for l in creditor_loans(model, a); init = 0.0)
    else
        return model.tax_this_round
    end
end

living_cost(model, a::Agent) = a isa Person ? meal_price(model) : 0.0

loan_term_for(model, borrower::Agent) = (borrower isa Person && parameters(model).bread_loan_term > 0) ? parameters(model).bread_loan_term : parameters(model).loan_term_in_rounds

"""Open invoices owed *to* an agent (its receivables)."""
receivables(model, a::Agent) = sum(iv.amount for iv in model.invoices if iv.to_id == a.id; init = 0.0)

function affordable(model, borrower::Agent, amount::Float64, rate::Float64)
    p = parameters(model)
    # invoice financing: a loan covered by the borrower's receivables is secured by them (settlement = :invoicing)
    if p.settlement == :invoicing && borrower isa Enterprise && p.receivables_advance_rate > 0
        secured = sum(total_due(l) for l in debtor_loans(model, borrower); init = 0.0) + amount
        secured <= p.receivables_advance_rate * receivables(model, borrower) + 1e-9 && return true
    end
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
    return stable_pick(stream(model, :credit), [b for b in candidates if b.interest_rate == lowest])
end

"""Rate a borrower pays: banks and the government borrow at a discount, everyone else at the posted rate."""
function borrowing_rate(model, lender::Enterprise, borrower::Agent)
    p = parameters(model)
    is_bank(borrower) && return lender.interest_rate * p.interbank_rate_discount
    is_government(borrower) && return isnan(p.government_rate) ? lender.interest_rate * p.government_rate_discount : p.government_rate
    return lender.interest_rate
end

"""
    request_loan!(model, borrower, amount, purpose)

Cheapest bank (ties random). Refused when in arrears, no bank alive, or unaffordable.
Banks and the government skip the affordability test (interbank lending; the state is always allowed to borrow).
"""
function request_loan!(model, borrower::Agent, amount::Float64, purpose::Symbol)
    # invoice financing is the firm's own credit (23 Sept): under :invoicing a loan covered by the firm's receivables is made to
    # the firm directly — before any call on its founders or members, which would otherwise answer for it
    let p = parameters(model)
        if p.settlement == :invoicing && borrower isa Enterprise && p.receivables_advance_rate > 0 && is_producer(borrower)
            owed = sum(total_due(l) for l in debtor_loans(model, borrower); init = 0.0) + amount
            if owed <= p.receivables_advance_rate * receivables(model, borrower) + 1e-9
                bank = bank_of(model, borrower); bank === nothing && (bank = first(enterprises(model, :bank)))
                p.monetary_system == :sumsy || (make_loan!(model, bank, borrower, amount, purpose); return true)
            end
        end
    end
    amount = ceil(amount * 1e4) / 1e4
    amount <= 0 && return true
    if parameters(model).cooperative_founding == :symmetric && borrower isa Enterprise && borrower.ownership == :cooperative && !isempty(borrower.members)
        return cooperative_capital_call!(model, borrower, amount)   # members are called on, as a shareholder firm's founders are
    end
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
    make_loan!(model, lender, borrower, amount, purpose)
    return true
end

"""Book a bank loan: the deposit is created, the debt recorded, the money counted. No credit decision — see `request_loan!`."""
function make_loan!(model, lender::Enterprise, borrower::Agent, amount::Float64, purpose::Symbol; term::Int = loan_term_for(model, borrower))
    rate = borrowing_rate(model, lender, borrower)
    debt = bank_loan(lender.balance, borrower.balance, amount, rate, term, 1, current_round(model))
    push!(model.loans, Loan(length(model.loans) + 1, lender.id, borrower.id, debt, 0, false, current_round(model), false, 0.0))
    model.money_created_this_round += amount
    model.cumulative_money_created += amount
    log_event!(model, :loan; actor = borrower.id, agent_kind = kind_of(borrower), lender = lender.id, amount = amount, rate = rate, purpose = purpose)
    return nothing
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

"""Under clearing every purchase is a promise and the credit decision is taken once, on the net position, in `clear!`;
with immediate settlement a buyer must hold the cash or be credit-eligible for the shortfall (review 1, §4.3)."""
fund!(model, a::Agent, amount::Float64, purpose::Symbol) =
    parameters(model).clearing || cash(a) >= amount - 1e-9 || credit_eligible(model, a, amount - cash(a))

function promise!(model, from::Agent, to::Agent, amount::Float64, purpose::Symbol, priority::Int, income_kind::Symbol = :none)
    amount = round(amount, digits = 4)
    amount <= 0 && return nothing
    way = settlement_way(model, from, to, purpose, income_kind)
    if way == :clearing
        push!(model.promises, Promise(from.id, to.id, amount, purpose, priority, income_kind, 0.0))
        return nothing
    elseif way == :endround
        push!(model.end_round_obligations, Promise(from.id, to.id, amount, purpose, priority, income_kind, 0.0))
        return nothing
    elseif way == :invoice
        push!(model.invoices, Invoice(from.id, to.id, amount, amount, purpose, income_kind, current_round(model)))
        model.invoices_issued_this_round += amount
        log_event!(model, :invoice; from = from.id, to = to.id, amount = amount, purpose = purpose)
        return nothing
    end
    # cash: immediate settlement — cash, then credit for the shortfall, the rest becomes a trade arrear
    short = round(amount - cash(from), digits = 4)
    if short > 1e-6 && !is_bank(from)
        request_loan!(model, from, short, :immediate)
    elseif short > 1e-6 && is_bank(from)
        monetise_equity!(model, from, short)
    end
    paid = round(min(amount, cash(from)), digits = 4)
    paid > 0 && transfer!(model, from, to, paid, purpose)
    # operating result: with clearing on this is netted once at clearing; here it is accumulated payment by payment.
    # (Until 20 September 2026 it was never set on this path, so `net_history` stayed at zero, every forward valuation
    # was zero and the share market could not trade at all with clearing off — see HANDOFF_2026-09-18.)
    book_settled!(model, from, to, paid, income_kind)
    rest = round(amount - paid, digits = 4)
    rest > 1e-6 && push!(model.trade_arrears, Promise(from.id, to.id, rest, purpose, 0, income_kind, 0.0))
    return nothing
end

"""
    settlement_way(model, from, to, purpose, income_kind) → :cash | :endround | :invoice | :clearing

Which way a payment is settled (design of 21 September 2026). Under `settlement = :clearing_all` (the old system)
everything clears (or, with `clearing = false`, everything is cash). Under `:invoicing` (the design): the government keeps its own financing at clearing;
wages and rent are end-of-round obligations; anything a person is party to is cash; between firms, clearing among
clearing members, an invoice where both are members of the invoicing or the clearing system, cash otherwise.
"""
function settlement_way(model, from::Agent, to::Agent, purpose::Symbol, income_kind::Symbol)
    p = parameters(model)
    p.settlement == :invoicing || return p.clearing ? :clearing : :cash
    is_government(from) && return :clearing
    income_kind in (:wage, :rent) && return :endround
    (from isa Person || to isa Person) && return :cash
    kf, kt = kind_of(from), kind_of(to)
    (kf in p.settlement_clearing && kt in p.settlement_clearing) && return :clearing
    members = union(p.settlement_clearing, p.settlement_invoicing)
    (kf in members && kt in members) && return :invoice
    return :cash
end

"""Book a settled payment on the two parties: operating result, income by kind, tax."""
function book_settled!(model, from::Agent, to::Agent, paid::Float64, income_kind::Symbol)
    from isa Enterprise && (from.operating_net -= paid)
    to isa Enterprise && (to.operating_net += paid)
    if to isa Person
        income_kind == :wage && (to.labour_income += paid)
        income_kind == :rent && (to.rent_income += paid)
        income_kind == :fee && (to.fee_received += paid)
        income_kind == :dividend && (to.dividend_income += paid)
    end
    income_kind == :tax && (government(model).tax_collected += paid; model.tax_this_round += paid)
    return nothing
end

"""Cash, then credit for the shortfall (a bank monetises its equity); returns what the payer can now pay."""
function fund_from_cash!(model, from::Agent, amount::Float64)
    short = round(amount - cash(from), digits = 4)
    if short > 1e-6 && is_bank(from)
        monetise_equity!(model, from, short)
    elseif short > 1e-6 && !is_government(from)
        request_loan!(model, from, short, :settlement)
    end
    return round(min(amount, cash(from)), digits = 4)
end

"""
    settle_end_of_round!(model)

Wages and rent (settlement = :invoicing): each payer pays its obligations of the round from its cash, in priority order,
borrowing for the shortfall; what cannot be paid becomes a trade arrear (garnishable, as before).
"""
function settle_end_of_round!(model)
    obligations = model.end_round_obligations
    isempty(obligations) && return nothing
    for from in alive_agents(model)
        mine = sort([pr for pr in obligations if pr.from_id == from.id]; by = pr -> pr.priority)
        isempty(mine) && continue
        available = fund_from_cash!(model, from, sum(pr.amount for pr in mine))
        for pr in mine
            paid = round(min(pr.amount, available), digits = 4)
            to = model[pr.to_id]
            if paid > 1e-6
                transfer!(model, from, to, paid, pr.purpose); book_settled!(model, from, to, paid, pr.income_kind)
                available = round(available - paid, digits = 4)
            end
            rest = round(pr.amount - paid, digits = 4)
            rest > 1e-6 && (push!(model.trade_arrears, Promise(from.id, to.id, rest, pr.purpose, 0, pr.income_kind, 0.0)); model.cumulative_trade_arrears += rest)
        end
    end
    empty!(obligations)
    return nothing
end

"""
    settle_invoices!(model)

Invoices issued in earlier rounds fall due: each payer pays them oldest first from cash, borrowing for the shortfall;
what stays unpaid stays open and ages (the liquidation rule reads the age). Invoices of this round are not yet due.
"""
function settle_invoices!(model)
    isempty(model.invoices) && return nothing
    now = current_round(model)
    for from in alive_agents(model)
        due = sort([iv for iv in model.invoices if iv.from_id == from.id && iv.round_issued < now && iv.amount > 1e-6]; by = iv -> iv.round_issued)
        isempty(due) && continue
        available = fund_from_cash!(model, from, sum(iv.amount for iv in due))
        for iv in due
            paid = round(min(iv.amount, available), digits = 4)
            paid > 1e-6 || break
            to = model[iv.to_id]
            if to.alive
                transfer!(model, from, to, paid, iv.purpose); book_settled!(model, from, to, paid, iv.income_kind)
            end
            iv.amount = round(iv.amount - paid, digits = 4); available = round(available - paid, digits = 4)
            model.invoices_paid_this_round += paid
        end
    end
    filter!(iv -> iv.amount > 1e-6 && model[iv.from_id].alive, model.invoices)
    return nothing
end

"""Open invoices a firm owes, and those overdue by at least `rounds` rounds."""
invoices_owed(model, a::Agent) = sum(iv.amount for iv in model.invoices if iv.from_id == a.id; init = 0.0)
invoices_overdue(model, a::Agent, rounds::Int) = sum(iv.amount for iv in model.invoices if iv.from_id == a.id && current_round(model) - iv.round_issued >= rounds; init = 0.0)

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

"""The consumption tax rate in force: the statutory rate times its scale (the fiscal policy moves the scale)."""
consumption_tax_rate(model) = parameters(model).consumption_tax_rate * model.consumption_tax_scale

"""What a person pays for a consumption good priced at `price`: the price plus the consumption tax."""
gross_price(model, buyer::Agent, price::Float64) = buyer isa Person ? round(price * (1 + consumption_tax_rate(model)), digits = 4) : price

"""
    pay_consumption!(model, buyer, seller, price, purpose)

A person buys bread or a ticket: the negotiated price goes to the seller, the consumption tax on it to the government
(priority 3, booked as tax at settlement). Enterprises buying bread (none do) or grain are not taxed.
"""
function pay_consumption!(model, buyer::Agent, seller::Agent, price::Float64, purpose::Symbol)
    pay!(model, buyer, seller, price, purpose)
    seller isa Enterprise && (seller.revenue_period += price; seller.revenue_this_round += price)
    buyer isa Person || return price
    tax = round(price * consumption_tax_rate(model), digits = 4)
    if tax > 1e-6
        promise!(model, buyer, government(model), tax, :consumption_tax, 3, :tax)
        model.consumption_tax_this_round += tax
    end
    return price + tax
end

"""
    pay_income!(model, payer, person, gross, kind)

Income of a person (`:wage` or `:rent`): tax promise to the government (priority 1) and net promise to the
person (priority 2). Government wages: tax is withheld, only the net is promised.
"""
function pay_income!(model, payer::Agent, person::Person, gross::Float64, kind::Symbol)
    p = parameters(model)
    if kind == :dividend
        tax = round(gross * p.dividend_tax_rate * model.tax_scale, digits = 4)
    elseif kind == :wage && p.income_tax_schedule == :flat
        tax = round(gross * p.wage_tax_rate * model.tax_scale, digits = 4)      # the fiscal policy's multiplier applies here too
        person.gross_wage_this_round += gross
    elseif kind == :wage
        tax = round(wage_tax_amount(model, person.gross_wage_this_round + gross) - wage_tax_amount(model, person.gross_wage_this_round), digits = 4)
        person.gross_wage_this_round += gross
    else
        tax = round(gross * p.capital_tax_rate * model.tax_scale, digits = 4)
    end
    if p.income_tax_period > 1 && tax > 0                    # accrued, charged at the end of the tax year (`charge_income_tax!`)
        person.income_tax_accrued += tax
        tax = 0.0
    end
    net = round(gross - tax, digits = 4)
    gov = government(model)
    if tax > 0
        if payer === gov
            gov.tax_collected += tax; model.tax_this_round += tax
            model.government_outlay_this_round += tax          # the imputed tax on its own wages is an outlay it books as revenue
        else
            promise!(model, payer, gov, tax, Symbol(kind, :_tax), 1, :tax)
        end
    end
    payer === gov && (model.government_outlay_this_round += net)
    promise!(model, payer, person, net, kind, 2, kind)
    return net
end

obligations(model, a::Agent) = [pr for pr in model.promises if pr.from_id == a.id]
receipts(model, a::Agent) = [pr for pr in model.promises if pr.to_id == a.id]

"""Instalments, interest and bond service the government owes this round."""
function government_service_due(model)
    gov = government(model); due = 0.0
    for l in debtor_loans(model, gov); l.created == current_round(model) && continue; due += next_payment(l); end
    for b in model.bonds; b.settled && continue; due += b.rate * b.principal + (current_round(model) >= b.maturity ? b.principal : 0.0); end
    return round(due, digits = 4)
end


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
    model.after_clearing = true
    p = parameters(model); rng = stream(model, :credit)
    promises = model.promises
    isempty(promises) && return nothing
    agents = OrderedDict(a.id => a for a in agents_by_id(model))
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
    for a in stable_shuffle(rng, alive_agents(model))
        O = get(model.clearing_obligations, a.id, 0.0)
        R = get(model.clearing_receipts, a.id, 0.0)
        if is_government(a)
            # the government holds no cash of its own: it borrows at clearing for this round's debt service and bond coupons and
            # maturities as well as for its spending — an explicit roll-over, so interest is paid and the debt figure is honest
            O += government_service_due(model)
        end
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
    by_from = OrderedDict{Int, Vector{Promise}}()
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
    for a in agents_by_id(model)
        net = sum(pr.paid for pr in promises if pr.to_id == a.id; init = 0.0) - sum(pr.paid for pr in promises if pr.from_id == a.id; init = 0.0)
        net = round(net, digits = 4)
        a isa Enterprise && (a.operating_net = net)
        net == 0 && continue
        if !book_asset!(a.balance, DEPOSIT, net)                       # the net cannot be booked: record the residue instead of dropping it (review 1, §4.4)
            residue = round(-net - cash(a), digits = 4)
            book_asset!(a.balance, DEPOSIT, -cash(a))
            model.clearing_residue += residue
            log_event!(model, :clearing_residue; actor = a.id, amount = residue)
        end
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

"""The protected minimum on debt collection: `collection_floor_in_breads` loaves at the expected bread price."""
collection_floor(model) = parameters(model).collection_floor_in_breads * expected_price(model, :bread)

function garnish!(model, a::Agent, incoming::Float64)
    (a.alive && a isa Person) || return nothing
    a.land > 0 && return nothing
    loans = [l for l in debtor_loans(model, a) if l.in_arrears]
    isempty(loans) && return nothing
    garnished = min(round(parameters(model).garnishment_rate * incoming, digits = 4), max(cash(a) - collection_floor(model), 0.0))   # never below the protected minimum
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
    for debtor in stable_shuffle(stream(model, :credit), alive_agents(model))
        for loan in sort(debtor_loans(model, debtor); by = l -> l.created)
            loan.created == current_round(model) && continue      # first payment falls in the round after issuance
            # a loan paid off outside the schedule (a refounding, an estate) can have an empty debt while still marked open;
            # EconoSim's process_debt! fails on a settled debt (its return values are only defined inside `if !debt_settled`),
            # so close the loan here instead (22 September; the upstream bug is noted in the handoff)
            if debt_settled(loan.debt)
                loan.settled = true
                continue
            end
            creditor = model[loan.creditor_id]
            is_bank(debtor) && monetise_equity!(model, debtor, next_payment(loan) - cash(debtor))
            due_interest = loan.debt.interest_rate * outstanding_principal(loan) + rest_interest(loan)
            if debtor isa Person && cash(debtor) - collection_floor(model) < next_payment(loan) - 1e-9
                # the protected minimum: a payment that would leave less than the floor is missed instead (arrears)
                paid_installment, paid_interest, shortfall = 0.0, 0.0, next_payment(loan)
            else
                _, (paid_installment, paid_interest, shortfall) = process_debt!(loan.debt)
            end
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
    p = parameters(model)
    if p.settlement == :invoicing && debtor.kind in (:farm, :bakery, :theatre)
        return nothing              # 23 Sept: loan arrears are overdue obligations in the liquidation test; no separate seizure
    end
    if p.settlement == :invoicing && p.bank_bailout && is_bank(debtor)
        # banks do not fail (22 September): a bank behind on an interbank loan is recapitalised by the government for what it owes,
        # at the government's clearing (next round's if this one has passed), instead of being seized and closed
        due = round(total_due(loan) - cash(debtor), digits = 4)
        if due > 1e-6
            gov = government(model)
            model.after_clearing ? push!(model.trade_arrears, Promise(gov.id, debtor.id, due, :bank_bailout, 1, :none, 0.0)) :
                                   promise!(model, gov, debtor, due, :bank_bailout, 1)
            model.cumulative_bailouts += due
            log_event!(model, :bailout; bank = debtor.id, amount = due, reason = :interbank_arrears)
        end
        loan.in_arrears = false; loan.arrears_rounds = 0
        return nothing
    end
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

# ---- liquidation (design of 21 September 2026, §2) -----------------------------------------

"""Bank debt, peer debt and open invoices of a firm, together."""
total_debt(model, e::Enterprise) = debt_of(e) + peer_debt_of(model, e) + invoices_owed(model, e)

"""Book value net of everything owed, invoices included."""
book_value_net(model, e::Enterprise) = book_value(model, e) - invoices_owed(model, e)

"""
    insolvent(model, e) → Bool

The trigger: invoices overdue by `liquidation_overdue_rounds` or more add up to at least `liquidation_arrears_share`
of the firm's book value — or the book value is nil or negative while anything is overdue.
"""
function insolvent(model, e::Enterprise)
    p = parameters(model)
    e.kind in (:farm, :bakery, :theatre) || return false
    if p.liquidation_test == :book
        overdue = invoices_overdue(model, e, p.liquidation_overdue_rounds)
        overdue > 1e-6 || return false
        book = book_value_net(model, e)
        return book <= 1e-6 || overdue >= p.liquidation_arrears_share * book - 1e-9
    end
    # :cash_flow — persistent non-payment, measured against what the firm sells, and shaken credit
    overdue = obligations_overdue(model, e, p.liquidation_overdue_rounds)
    overdue > 1e-6 || return false
    turnover = isempty(e.turnover_history) ? 0.0 : sum(e.turnover_history) / length(e.turnover_history)
    overdue >= p.liquidation_arrears_share * turnover - 1e-9 || return false
    # the credit test: a firm that can still borrow the money to catch up is not insolvent — it borrows and pays
    if request_loan!(model, e, overdue, :catch_up)
        pay_overdue_invoices!(model, e)
        log_event!(model, :caught_up; actor = e.id, agent_kind = e.kind, amount = overdue)
        return false
    end
    return true
end

"""What a firm owes that is at least `rounds` months behind: invoices, and bank and peer loan instalments in arrears."""
function obligations_overdue(model, e::Enterprise, rounds::Int)
    total = invoices_overdue(model, e, rounds)
    for l in debtor_loans(model, e)
        (l.in_arrears && l.arrears_rounds >= rounds && !l.settled) || continue
        d = l.debt
        isempty(d.installments) && continue
        due = Float64(d.installments[end]) + Float64(sum(d.installments)) * Float64(d.interest_rate) + Float64(d.rest_interest)
        total += l.arrears_rounds * due
    end
    for l in model.peer_loans
        (l.borrower_id == e.id && l.in_arrears && l.arrears_rounds >= rounds && !l.settled) || continue
        total += l.arrears_rounds * l.installment
    end
    return round(total, digits = 4)
end

"""Pay a firm's overdue invoices from its cash, oldest first (after a catch-up loan)."""
function pay_overdue_invoices!(model, e::Enterprise)
    now = current_round(model)
    for iv in sort([iv for iv in model.invoices if iv.from_id == e.id && iv.round_issued < now]; by = iv -> iv.round_issued)
        amt = round(min(iv.amount, cash(e)), digits = 4); amt > 1e-6 || break
        to = model[iv.to_id]
        to.alive && (transfer!(model, e, to, amt, iv.purpose); book_settled!(model, e, to, amt, iv.income_kind))
        iv.amount = round(iv.amount - amt, digits = 4); model.invoices_paid_this_round += amt
    end
    filter!(iv -> iv.amount > 1e-6, model.invoices)
    return nothing
end

"""Spare cash a would-be buyer can put into a firm: above the cushion for a person, above the reserve for a producer."""
function spare_for_purchase(model, a::Agent)
    a isa Person && return max(cash(a) - buffer_target(model, a), 0.0)
    (a isa Enterprise && a.kind in (:farm, :bakery, :theatre) && a.alive) || return 0.0
    return max(cash(a) - reserve_target(model, a), 0.0)
end

"""
    refound!(model, e) → Bool

Stage 1 of a liquidation: the firm is sold as a going concern — the founding mechanism reused. Asking price is
`liquidation_price_share` × book value, never below the debt left after the firm's cash has been applied to it. Up to
`shareholder_count` buyers with the most spare cash (persons and producers, never the firm itself) put up the price
together and hold the new shares pro rata; the old owners get nothing. The proceeds pay overdue invoices first (oldest
first), then peer loans, then bank loans; what is left stays in the firm. Target, staff, stock and land are untouched.
A cooperative is refounded as a shareholder firm unless `liquidated_coop_stays_coop` (then its members refound it, each
with one share at par, if their spare cash reaches the price). Returns false when no group can reach the price.
"""
function refound!(model, e::Enterprise)
    p = parameters(model)
    book = max(book_value_net(model, e), 0.0)
    price = round(max(p.liquidation_price_share * book, total_debt(model, e) - cash(e), 0.0), digits = 4)
    price <= 1e-6 && return false
    stays_coop = e.ownership == :cooperative && p.liquidated_coop_stays_coop
    pool = stays_coop ? [model[id] for id in keys(e.members) if model[id] isa Person && model[id].alive] :
                        [a for a in alive_agents(model) if a !== e && spare_for_purchase(model, a) > 1e-6]
    sort!(pool; by = a -> -spare_for_purchase(model, a))
    buyers = stays_coop ? pool : pool[1:min(length(pool), p.shareholder_count)]
    total_spare = sum(spare_for_purchase(model, a) for a in buyers; init = 0.0)
    total_spare >= price - 1e-6 || return false
    contributions = OrderedDict{Int, Float64}()
    left = price
    for (k, a) in enumerate(buyers)
        c = k == length(buyers) ? left : round(min(price * spare_for_purchase(model, a) / total_spare, spare_for_purchase(model, a), left), digits = 4)
        c = round(min(c, spare_for_purchase(model, a), left), digits = 4)
        c <= 1e-6 && continue
        transfer!(model, a, e, c, :refounding)
        contributions[a.id] = c
        left = round(left - c, digits = 4)
        left <= 1e-6 && break
    end
    # the proceeds settle what is owed, oldest invoices first
    for iv in sort([iv for iv in model.invoices if iv.from_id == e.id]; by = iv -> iv.round_issued)
        amt = round(min(iv.amount, cash(e)), digits = 4); amt > 1e-6 || break
        to = model[iv.to_id]
        to.alive && (transfer!(model, e, to, amt, iv.purpose); book_settled!(model, e, to, amt, iv.income_kind))
        iv.amount = round(iv.amount - amt, digits = 4); model.invoices_paid_this_round += amt
    end
    filter!(iv -> iv.amount > 1e-6, model.invoices)
    for l in peer_loans_of(model, e)
        amt = round(min(l.outstanding, cash(e)), digits = 4); amt > 1e-6 || break
        transfer!(model, e, model[l.lender_id], amt, :peer_loan_repayment); l.outstanding = round(l.outstanding - amt, digits = 4)
        l.outstanding <= 1e-6 && (l.settled = true)
    end
    for l in sort(debtor_loans(model, e); by = l -> -total_due(l))
        amt = round(min(total_due(l), cash(e)), digits = 4); amt > 1e-6 || break
        repay_extra!(model, l, amt)
    end
    # new owners
    old_owners = e.ownership == :cooperative ? collect(keys(e.members)) : collect(keys(e.shares))
    if e.ownership == :cooperative && !stays_coop
        e.retained_reserve > 1e-6 && (locked = round(min(e.retained_reserve, cash(e)), digits = 4); locked > 1e-6 && transfer!(model, e, government(model), locked, :cooperative_reserve))
        e.retained_reserve = 0.0
        empty!(e.members); empty!(e.membership_unpaid); empty!(e.member_since); empty!(e.patronage_log); empty!(e.patronage_this_round)
        release_all_pledges!(model, e)
        e.ownership = :shareholders
    end
    if e.ownership == :cooperative
        empty!(e.members); empty!(e.membership_unpaid); empty!(e.member_since)
        for (id, c) in contributions
            e.members[id] = 1; e.membership_unpaid[id] = 0.0; e.member_since[id] = current_round(model)
        end
    else
        empty!(e.shares)
        units = total_share_units(model)
        for (id, c) in contributions
            e.shares[id] = round(units * c / price, digits = 6)
        end
        e.founder_ids = collect(keys(contributions))
    end
    e.paid_in_capital = price
    e.refoundings += 1
    model.refoundings += 1
    log_event!(model, :refounding; actor = e.id, agent_kind = e.kind, price = price, book = book, buyers = collect(keys(contributions)), old_owners = old_owners)
    return true
end

"""
    liquidate!(model, e, reason)

The one procedure for a failing producer under settlement = :invoicing, whoever the creditor is (22 September): it is first
offered for sale as a going concern (`refound!`), and only when no group of buyers can reach the price is it closed and its
assets divided among its creditors (`close_enterprise!`). Loan-arrears seizure and overdue invoices both end here.
"""
function liquidate!(model, e::Enterprise, reason::Symbol)
    model.liquidations += 1
    log_event!(model, :liquidation; actor = e.id, agent_kind = e.kind, reason = reason,
               overdue = invoices_overdue(model, e, parameters(model).liquidation_overdue_rounds), book = book_value_net(model, e), debt = total_debt(model, e))
    refound!(model, e) || close_enterprise!(model, e, reason)
    return nothing
end

"""
    liquidate_insolvent_firms!(model)

Once a round, after the invoices have fallen due: every producer that meets the trigger is sold as a going concern
(`refound!`), or, when no group of buyers can reach the price, closed and liquidated — assets to creditors, the rest
struck (`close_enterprise!`, which writes off what is left: bank loans with the deposits they created kept in
circulation and the bank recapitalised if needed, peer loans covered from the insurance pool where there is one,
unpaid invoices lost by the suppliers).
"""
function liquidate_insolvent_firms!(model)
    parameters(model).settlement == :invoicing || return nothing
    for e in [x for x in alive_agents(model) if x isa Enterprise && x.alive && x.kind in (:farm, :bakery, :theatre)]
        insolvent(model, e) || continue
        liquidate!(model, e, :overdue_invoices)
    end
    return nothing
end

"""
    write_off_invoices!(model, dead)

A dead firm's unpaid invoices are the suppliers' loss (bad debt, no cover); invoices owed *to* it are cancelled.
Suppliers that cannot bear the loss meet the trigger themselves next round — chains are allowed and counted.
"""
function write_off_invoices!(model, dead::Agent)
    for iv in model.invoices
        if iv.from_id == dead.id && iv.amount > 1e-6
            model.cumulative_bad_debt += iv.amount
            log_event!(model, :write_off; actor = dead.id, invoice_to = iv.to_id, amount = iv.amount, kind = :invoice)
        end
    end
    filter!(iv -> iv.from_id != dead.id && iv.to_id != dead.id, model.invoices)
    return nothing
end

"""
    recapitalise_banks!(model)

Banks do not fail: a bank whose net worth has gone below zero after write-offs is recapitalised by the government,
which pays in the shortfall (settled at its own clearing, so funded by borrowing). Bank failure — the bank ceases and
its depositors lose — is a possible future design option, not modelled.
"""
function recapitalise_banks!(model)
    p = parameters(model)
    (p.bank_bailout && p.settlement == :invoicing) || return nothing        # part of the 21 September design; the old rule let a bank sit under water
    gov = government(model)
    for bank in enterprises(model, :bank)
        shortfall = round(-net_wealth(model, bank), digits = 4)
        shortfall > 1e-6 || continue
        model.after_clearing ? push!(model.trade_arrears, Promise(gov.id, bank.id, shortfall, :bank_bailout, 1, :none, 0.0)) :
                               promise!(model, gov, bank, shortfall, :bank_bailout, 1)
        # (22 Sept: no `retained_interest += shortfall` here — that granted equity the bank could monetise on top of the cash the
        # government pays in, so the bank spent the bailout twice, its net worth kept falling and every closure bailed it out again)
        model.cumulative_bailouts += shortfall
        log_event!(model, :bailout; bank = bank.id, amount = shortfall)
    end
    return nothing
end


"""
    charge_income_tax!(model)

`income_tax_period` > 1: in the last month of each tax year every person's accrued income tax is charged — paid in cash
where there is cash, credit for the rest where credit is granted, arrears (garnishable) otherwise.
"""
function charge_income_tax!(model)
    p = parameters(model)
    (p.income_tax_period > 1 && current_round(model) % p.income_tax_period == 0) || return nothing
    gov = government(model)
    for w in persons(model)
        due = round(w.income_tax_accrued, digits = 4)
        due > 1e-6 || continue
        promise!(model, w, gov, due, :income_tax, 1, :tax)
        w.income_tax_accrued = 0.0
        model.income_tax_charged_this_round += due
    end
    return nothing
end

"""The profit a firm is taxed on for the period: revenue less deductible costs, never below zero."""
profit_tax_base(model, e::Enterprise) = max(e.revenue_period - parameters(model).deductible_materials * e.materials_period -
                                            parameters(model).deductible_labour * e.labour_period, 0.0)

"""
    tax_profits!(model)

Every round the firm's interest is added to its costs for the period; at the end of each `profit_tax_period` farms,
bakeries and theatres are charged `profit_tax_rate` × the profit family's scale × their period profit, and the period's
accounts start again. Under settlement = :invoicing the tax is an invoice to the government, payable next month; under
the old system it is paid at once, with arrears for what cannot be paid.
"""
function tax_profits!(model)
    p = parameters(model)
    producers = [e for e in alive_agents(model) if e isa Enterprise && e.kind in (:farm, :bakery, :theatre)]
    for e in producers; e.materials_period += e.interest_paid; end
    if p.profit_tax_rate <= 0                                         # no profit tax: keep the period accounts from growing
        foreach(e -> (e.revenue_period = 0.0; e.materials_period = 0.0; e.labour_period = 0.0), producers)
        return nothing
    end
    current_round(model) % p.profit_tax_period == 0 || return nothing  # mid-period: keep accruing
    gov = government(model)
    for e in producers
        base = profit_tax_base(model, e)
        tax = round(p.profit_tax_rate * model.profit_tax_scale * base, digits = 4)
        e.revenue_period = 0.0; e.materials_period = 0.0; e.labour_period = 0.0
        tax > 1e-6 || continue
        if p.settlement == :invoicing
            promise!(model, e, gov, tax, :profit_tax, 1, :tax)
        else
            paid = round(min(tax, cash(e)), digits = 4)
            paid > 0 && (transfer!(model, e, gov, paid, :profit_tax); gov.tax_collected += paid; model.tax_this_round += paid)
            tail = round(tax - paid, digits = 4)
            tail > 1e-6 && push!(model.trade_arrears, Promise(e.id, gov.id, tail, :profit_tax, 0, :tax, 0.0))
        end
        model.profit_tax_this_round += tax
        log_event!(model, :profit_tax; actor = e.id, agent_kind = e.kind, base = base, tax = tax)
    end
    return nothing
end


"""
    pay_in_founding_equity!(model)

`founding_equity`: at the founding, the founders of every shareholder firm pay in equity equal to the firm's working
reserve (three months of costs), in equal parts — from their savings above the cushion first, the rest by a personal loan
(a bank loan under debt money; a peer loan under SuMSy, as far as lenders can be found). A Belgian BV must start with
sufficient equity; the rest of a firm's needs are financed by loans and trade credit. A cooperative has founding members
who do the same (23 Sept): `shareholder_count` villagers not already founding another firm, in order of id, become its
first members and pay in its reserve between them.
"""
function pay_in_founding_equity!(model)
    p = parameters(model)
    taken = Set{Int}(id for e in model.enterprise_list if e.ownership == :shareholders for id in keys(e.shares))
    for e in [x for x in model.enterprise_list if x.alive && is_producer(x) && (x.ownership == :cooperative || !isempty(x.shares))]
        target = reserve_target(model, e)
        target > 1e-6 || continue
        if e.ownership == :cooperative
            free = [w for w in model.person_list if w.alive && !(w.id in taken)]
            isempty(free) && (free = collect(model.person_list))
            founders = free[1:min(p.shareholder_count, length(free))]
            for w in founders
                push!(taken, w.id); e.members[w.id] = 1; e.membership_unpaid[w.id] = 0.0; e.member_since[w.id] = 0
            end
        else
            founders = sort([model[id] for id in keys(e.shares) if model[id] isa Person]; by = w -> w.id)
        end
        isempty(founders) && continue
        each = round(target / length(founders), digits = 4)
        for w in founders
            own = round(min(max(cash(w) - buffer_target(model, w), 0.0), each), digits = 4)
            short = round(each - own, digits = 4)
            if short > 1e-6
                if p.monetary_system == :sumsy
                    request_loan!(model, w, short, :founding_equity)
                else
                    # business terms (24 Sept): only what the founder can carry over `founding_loan_term` months
                    bank = bank_of(model, w); bank === nothing && (bank = first(enterprises(model, :bank)))
                    rate = borrowing_rate(model, bank, w)
                    existing = sum(next_payment(l) for l in debtor_loans(model, w); init = 0.0)
                    room = p.affordability_ratio * expected_income(model, w) - living_cost(model, w) - existing
                    loan = round(min(short, max(room, 0.0) / (1 / p.founding_loan_term + rate)), digits = 4)
                    loan > 1e-6 && make_loan!(model, bank, w, loan, :founding_equity; term = p.founding_loan_term)
                end
            end
            amount = round(min(each, cash(w)), digits = 4)
            amount > 1e-6 || continue
            transfer!(model, w, e, amount, :paid_in_capital)
            e.paid_in_capital += amount
            log_event!(model, :founding_equity; actor = w.id, firm = e.id, amount = amount)
        end
    end
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
        bank.interest_rate = min((bank.bid[:wage] + deposit_cost) / (p.affordability_ratio * base), p.maximum_interest_rate)
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
    dead isa Enterprise && write_off_invoices!(model, dead)
    dead isa Enterprise && recapitalise_banks!(model)
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
            if l.outstanding > 1e-9 && ((l.insured && p.default_insurance) || p.peer_loan_insurance)
                # the insurance pool covers what it can; the rest is the lender's loss
                bank = model[l.bank_id]; lender = model[l.lender_id]
                pool = round(max(bank.insurance_premiums - bank.insurance_payouts, 0.0), digits = 4)
                cover = round(min(l.outstanding, pool, cash(bank)), digits = 4)
                if cover > 1e-6 && lender.alive
                    transfer!(model, bank, lender, cover, :insurance_payout); bank.insurance_payouts += cover
                    l.outstanding = round(l.outstanding - cover, digits = 4)
                    log_event!(model, :insurance_payout; bank = bank.id, lender = lender.id, borrower = dead.id, amount = cover, struck = true)
                end
            end
            l.outstanding > 1e-9 && (l.write_off = l.outstanding; model.cumulative_write_offs += l.outstanding; log_event!(model, :write_off; actor = dead.id, peer_loan = l.id, amount = l.outstanding))
            l.outstanding = 0.0; l.settled = true
        end
    end
    dead isa Enterprise && dead.ownership == :cooperative && release_all_pledges!(model, dead)
    if dead isa Enterprise && dead.ownership == :cooperative && coop_form(model, dead) != :member
        # members are redeemed at par out of what is left; the indivisible reserve is not theirs and goes to the public purse
        for id in sort(collect(keys(dead.members)))
            h = model[id]
            (h isa Person && h.alive) || continue
            paid_in = round(p.membership_share_price - get(dead.membership_unpaid, id, 0.0), digits = 4)
            amount = round(min(paid_in, cash(dead)), digits = 4)
            amount > 1e-6 && transfer!(model, dead, h, amount, :share_redemption)
        end
        locked = cash(dead)
        locked > 1e-6 && transfer!(model, dead, government(model), locked, :cooperative_reserve)
        if dead.land > 0
            government(model).land += dead.land; dead.land = 0
        end
        log_event!(model, :asset_lock; actor = dead.id, amount = locked)
    end
    if dead isa Person
        for e in alive_agents(model)
            (e isa Enterprise && haskey(e.buffer_pledged_by, dead.id)) && release_pledge!(model, e, dead.id)
        end
    end
    heirs = [h for h in persons(model) if h.id != dead.id]
    left = cash(dead)
    if !isempty(heirs)
        heir = stable_pick(stream(model, :estates), heirs)
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
    bank_rate = isnan(p.government_rate) ? (isempty(banks) ? p.initial_interest_rate : minimum(b.interest_rate for b in banks) * p.government_rate_discount) : p.government_rate
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
    p = parameters(model); rng = stream(model, :credit)
    rate = bond_coupon_rate(model); term = bond_term(model)
    holders = [a for a in alive_agents(model) if !is_government(a) && !is_bank(a) && !is_authority(a)]
    stable_shuffle!(rng, holders)
    avail = OrderedDict(a.id => lendable(model, a) for a in holders)
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
        excess = cash(e) - distributable_floor(model, e)
        payout = round(max(excess, 0.0) / p.dividend_build_rounds, digits = 4)
        push!(e.dividend_history, payout); push!(e.net_history, e.operating_net)
        if e.ownership == :cooperative && coop_form(model, e) != :member
            distribute_patronage!(model, e, payout)      # patronage, with a share retained in the indivisible reserve
            continue
        end
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
    p = parameters(model); rng = stream(model, :shares)
    (p.share_market && p.ownership != :none) || return nothing
    cash_yield = p.monetary_system == :sumsy ? -p.demurrage_rate : (p.deposit_interest_rate + p.loyalty_bonus_rate) / max(p.deposit_interest_period, 1)
    for e in alive_agents(model)
        (e isa Enterprise && e.ownership == :shareholders) || continue
        buyers = stable_shuffle(rng, [w for w in persons(model) if cash(w) - buffer_target(model, w) > 0])
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
        for fid in stable_shuffle(rng, e.founder_ids)
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
    p = parameters(model); rng = stream(model, :cooperatives)
    manage_new_form_membership!(model)                   # worker and consumer cooperatives have their own rules
    (p.ownership in (:cooperative, :mixed) && p.startup_financing == :paid_in_capital) || return nothing
    coops = [e for e in alive_agents(model) if e isa Enterprise && e.ownership == :cooperative && coop_form(model, e) == :member]
    isempty(coops) && return nothing
    par = p.membership_share_price
    for w in stable_shuffle(rng, persons(model))
        open = [c for c in coops if !haskey(c.members, w.id)]
        if !isempty(open) && plan_contribution(model, w) !== nothing && rand(rng) < p.cooperative_join_probability
            c = stable_pick(rng, open)
            if contribute_membership!(model, w, c)
                log_event!(model, :membership; actor = w.id, cooperative = c.id, price = par, pledge = get(c.buffer_pledged_by, w.id, 0.0))
            end
        elseif cash(w) < meal_price(model)
            for c in coops
                get(c.members, w.id, 0) > 0 || continue
                paid = round(p.membership_share_price - get(c.membership_unpaid, w.id, 0.0), digits = 4)
                (paid <= 1e-6 || cash(c) >= paid) || continue
                paid > 1e-6 && (transfer!(model, c, w, paid, :share_redemption); c.paid_in_capital -= paid)
                released = release_pledge!(model, c, w.id)
                c.members[w.id] -= 1
                c.members[w.id] == 0 && (delete!(c.members, w.id); delete!(c.membership_unpaid, w.id); delete!(c.member_since, w.id))
                log_event!(model, :redemption; actor = w.id, cooperative = c.id, price = paid, pledge = released)
                break
            end
        end
    end
    return nothing
end

# ---- SuMSy variant (12 September 2026) ---------------------------------------------
# Money is created as a guaranteed income (a deposit for the person, a liability of the authority) and destroyed by
# demurrage on balances above the buffer (persons only hold a buffer). No bank credit: loans are transfers of existing
# money from surplus holders through a bank, which keeps a spread. Banks charge account fees. A demurrage tax is a
# surcharge on the demurrage base transferred to the government.

is_sumsy(model) = parameters(model).monetary_system == :sumsy
authority(model) = first(enterprises(model, :authority))

function create_money!(model, to::Agent, amount::Float64)
    amount = round(amount, digits = 4)
    amount <= 0 && return 0.0
    auth = authority(model)
    book_asset!(to.balance, DEPOSIT, amount)
    book_liability!(auth.balance, DEPOSIT, amount)
    model.money_created_this_round += amount
    model.cumulative_money_created += amount
    return amount
end

function destroy_money!(model, from::Agent, amount::Float64)
    amount = round(min(amount, cash(from)), digits = 4)
    amount <= 0 && return 0.0
    auth = authority(model)
    book_asset!(from.balance, DEPOSIT, -amount)
    book_liability!(auth.balance, DEPOSIT, -amount)
    model.money_destroyed_this_round += amount
    model.cumulative_money_destroyed += amount
    return amount
end

"""Guaranteed income: created for every living person at the start of the round."""
function pay_guaranteed_income!(model)
    is_sumsy(model) || return nothing
    p = parameters(model)
    gi = p.guaranteed_income_in_breads > 0 ? round(p.guaranteed_income_in_breads * expected_price(model, :bread), digits = 4) : p.guaranteed_income
    for w in persons(model)
        model.gi_this_round += create_money!(model, w, gi)
    end
    return nothing
end

demurrage_buffer(model, a::Agent) = a isa Person ? max(parameters(model).demurrage_free_buffer - a.buffer_lent - a.buffer_pledged, 0.0) :
                                    is_bank(a) ? a.buffer_received + a.buffer_pledged : a.buffer_pledged

# ---- buffer pool: opted-in persons lend part of their buffer (money and exemption) to their bank; callable ----
function manage_buffer_pool!(model)
    p = parameters(model)
    (is_sumsy(model) && p.buffer_lending) || return nothing
    if current_round(model) == 1
        rng = stream(model, :credit)
        for w in persons(model); w.buffer_lender = rand(rng) < p.buffer_lending_participation; end
    end
    for w in persons(model)
        bank = bank_of(model, w); bank === nothing && continue
        if w.buffer_lender
            target = p.buffer_lend_fraction * p.demurrage_free_buffer
            room = cash(w) - meal_price(model)                       # never lend what this round's meal needs
            lend = round(min(target - w.buffer_lent, room), digits = 4)
            if lend > 1e-6
                transfer!(model, w, bank, lend, :buffer_lent); w.buffer_lent += lend; bank.buffer_received += lend
            end
        end
        if w.buffer_lent > 1e-6 && cash(w) < meal_price(model)
            back = round(min(w.buffer_lent, meal_price(model) - cash(w), cash(bank)), digits = 4)
            if back > 1e-6
                transfer!(model, bank, w, back, :buffer_recalled); w.buffer_lent -= back; bank.buffer_received -= back
            end
        end
    end
    return nothing
end

"""Demurrage destroys money above the buffer; the demurrage tax on the same base goes to the government."""
function apply_demurrage!(model)
    is_sumsy(model) || return nothing
    p = parameters(model); gov = government(model)
    for a in alive_agents(model)
        is_authority(a) && continue
        excess = cash(a) - demurrage_buffer(model, a)
        excess <= 1e-9 && continue
        dem = destroy_money!(model, a, round(p.demurrage_rate * excess, digits = 4))
        model.demurrage_this_round += dem
        a isa Person && (model.demurrage_persons_this_round += dem)
        if p.demurrage_tax_rate > 0 && a !== gov
            tax = round(min(p.demurrage_tax_rate * model.parking_tax_scale * excess, cash(a)), digits = 4)
            if tax > 0
                transfer!(model, a, gov, tax, :demurrage_tax)
                gov.tax_collected += tax; model.tax_this_round += tax; model.demurrage_tax_this_round += tax
            end
        end
    end
    return nothing
end

"""The bank that manages an agent's account (round robin by id; a bank's account is at another bank)."""
function bank_of(model, a::Agent)
    banks = sort(enterprises(model, :bank); by = b -> b.id)
    isempty(banks) && return nothing
    others = [b for b in banks if b.id != a.id]
    isempty(others) && return first(banks)
    return others[mod(a.id, length(others)) + 1]
end

"""Account fees: a priority-1 promise from every account holder to its bank."""
function charge_account_fees!(model)
    p = parameters(model)
    (p.account_fee_person > 0 || p.account_fee_enterprise > 0) || return nothing
    for a in alive_agents(model)
        (is_bank(a) || is_authority(a)) && continue
        bank = bank_of(model, a)
        bank === nothing && continue
        is_government(a) && continue                    # 23 Sept: the government pays no account fee (with no revenue of its own it borrowed 1.5 a month for it)
        fee = a isa Person ? p.account_fee_person : p.account_fee_enterprise
        fee <= 0 && continue
        promise!(model, a, bank, fee, :account_fee, 1)
        model.account_fees_this_round += fee
    end
    return nothing
end

# ---- peer lending -----------------------------------------------------------------

"""Cash an agent can lend this round: above its buffer / working reserve, net of this round's obligations and debt service."""
function lendable(model, a::Agent)
    (is_authority(a) || is_government(a)) && return 0.0
    O = get(model.clearing_obligations, a.id, 0.0)          # filled once per clearing (see clear!)
    R = get(model.clearing_receipts, a.id, 0.0)
    debt_service = get(model.clearing_debt_service, a.id, 0.0)
    keep = a isa Person ? parameters(model).demurrage_free_buffer : is_producer(a) ? reserve_target(model, a) : 0.0
    return max(cash(a) - keep - max(O - R, 0.0) - debt_service, 0.0)
end

"""
    request_peer_loan!(model, borrower, amount, purpose)

The borrower's bank gathers surplus from other agents (largest surplus first) and transfers it; one `PeerLoan` per
lender. Refused when lending is off, there is no bank, the borrower is in arrears, or the loan is unaffordable (the
government is always eligible). Returns true when anything was lent.
"""
function request_peer_loan!(model, borrower::Agent, amount::Float64, purpose::Symbol)
    p = parameters(model); rng = stream(model, :credit)
    model.credit_demand_this_round += amount
    bank = bank_of(model, borrower)
    reason = nothing
    if !p.peer_lending
        reason = :no_lending
    elseif bank === nothing
        reason = :no_bank
    elseif !is_government(borrower) && has_arrears(model, borrower)
        reason = :arrears
    elseif !is_government(borrower) && !affordable(model, borrower, amount, p.peer_loan_rate)
        reason = :unaffordable
    end
    if reason !== nothing
        model.cumulative_credit_refusals += 1
        log_event!(model, :credit_refused; actor = borrower.id, agent_kind = kind_of(borrower), amount = amount, purpose = purpose, reason = reason)
        return false
    end
    lenders = [a for a in alive_agents(model) if a.id != borrower.id && !is_authority(a) && !is_government(a)]
    stable_shuffle!(rng, lenders)
    avail = OrderedDict(a.id => lendable(model, a) for a in lenders)
    filter!(a -> avail[a.id] >= 0.01, lenders)
    sort!(lenders; by = a -> -avail[a.id])
    disc = (borrower isa Person && borrower.buffer_lender) ? p.buffer_lender_spread_discount : 0.0
    rate_l = p.peer_loan_rate - p.bank_spread
    rate_b = p.peer_loan_rate - disc * p.bank_spread
    funded = 0.0
    for l in lenders
        s = round(min(lendable(model, l), amount - funded), digits = 4)
        s < 0.01 && continue
        book_asset!(l.balance, DEPOSIT, -s) || continue
        book_asset!(borrower.balance, DEPOSIT, s)
        push!(model.peer_loans, PeerLoan(length(model.peer_loans) + 1, l.id, borrower.id, bank.id, s, s, s / loan_term_for(model, borrower),
                                         rate_b, rate_l, false, current_round(model), 0, false, false, 0.0))
        log_event!(model, :peer_loan; actor = borrower.id, agent_kind = kind_of(borrower), lender = l.id, lender_kind = kind_of(l), bank = bank.id, amount = s, rate = p.peer_loan_rate, purpose = purpose)
        funded += s
        funded >= amount - 1e-6 && break
    end
    model.peer_lent_this_round += funded
    if funded < amount - 1e-6
        model.cumulative_credit_refusals += 1
        log_event!(model, :credit_refused; actor = borrower.id, agent_kind = kind_of(borrower), amount = amount - funded, purpose = purpose, reason = :no_surplus)
    end
    return funded > 0
end

"""Installment plus (possibly negative) interest; the bank keeps the spread. Shortfalls go to arrears, then seizure."""
function service_peer_loans!(model)
    (is_sumsy(model) || !isempty(model.peer_loans)) || return nothing
    p = parameters(model)
    for l in model.peer_loans
        (l.settled || l.created == current_round(model)) && continue
        borrower = model[l.borrower_id]; lender = model[l.lender_id]; bank = model[l.bank_id]
        borrower.alive || (l.settled = true; continue)
        inst = min(l.installment, l.outstanding)
        interest = round(l.rate * l.outstanding, digits = 4)
        lender_interest = round(l.lender_rate * l.outstanding, digits = 4)
        due = round(max(inst + interest, 0.0), digits = 4)
        pay = round(min(due, borrower isa Person ? max(cash(borrower) - collection_floor(model), 0.0) : cash(borrower)), digits = 4)   # the protected minimum (24 Sept)
        share = due > 1e-9 ? pay / due : 1.0
        to_lender = round(share * (inst + lender_interest), digits = 4)
        to_bank = round(pay - to_lender, digits = 4)
        pay > 0 && (book_asset!(borrower.balance, DEPOSIT, -pay) || error("peer loan payment failed"))
        to_lender > 0 && book_asset!(lender.balance, DEPOSIT, to_lender)
        to_bank > 0 && book_asset!(bank.balance, DEPOSIT, to_bank)
        l.outstanding = round(l.outstanding - share * inst, digits = 4)
        model.cumulative_interest_paid += share * interest
        if share < 1 - 1e-6 && due - pay > p.arrears_de_minimis_in_meals * meal_price(model)
            l.in_arrears = true; l.arrears_rounds += 1
            log_event!(model, :missed_payment; actor = borrower.id, agent_kind = kind_of(borrower), peer_loan = l.id, paid = pay, shortfall = due - pay, arrears_rounds = l.arrears_rounds)
        else
            l.in_arrears = false; l.arrears_rounds = 0
        end
        pay > 0 && log_event!(model, :payment; from = borrower.id, to = lender.id, amount = to_lender, purpose = :peer_loan_service)
        if (l.insured && p.default_insurance) || p.peer_loan_insurance
            prem = round(p.insurance_premium_rate * to_lender, digits = 4)
            prem > 0 && cash(lender) >= prem && (transfer!(model, lender, bank, prem, :insurance_premium); bank.insurance_premiums += prem)
            short = round(due - pay, digits = 4)
            if short > 1e-6
                cover = round(min(short, cash(bank)), digits = 4)
                if cover > 0
                    transfer!(model, bank, lender, cover, :insurance_payout); bank.insurance_payouts += cover
                    l.outstanding = round(l.outstanding - cover, digits = 4)
                    push!(model.peer_loans, PeerLoan(length(model.peer_loans) + 1, bank.id, borrower.id, bank.id, cover, cover, cover / p.instalment_rounds, 0.0, 0.0, false, current_round(model), 0, false, false, 0.0))
                    log_event!(model, :insurance_payout; bank = bank.id, seller = lender.id, buyer = borrower.id, amount = cover)
                end
            end
        end
        l.outstanding <= 1e-6 && (l.settled = true; log_event!(model, :loan_settled; actor = borrower.id, peer_loan = l.id))
        if !l.settled && l.arrears_rounds >= p.arrears_rounds_until_seizure && !is_government(borrower)
            if haskey(model.share_collateral, l.id)
                seize_shares_peer!(model, l)
            else
                borrower isa Person ? seize_land_peer!(model, l) : seize_enterprise_peer!(model, l)
            end
        end
    end
    return nothing
end

"""Land of the borrower to the lender (or its bank when the lender cannot hold land) at the land price."""
function seize_land_peer!(model, l::PeerLoan)
    borrower = model[l.borrower_id]; lender = model[l.lender_id]
    receiver = (lender isa Person || is_farm(lender) || is_bank(lender)) ? lender : model[l.bank_id]
    price = land_price(model); units = 0
    while borrower.land > 0 && l.outstanding > 1e-9
        borrower.land -= 1; receiver.land += 1; units += 1
        settled_now = min(price, l.outstanding)
        l.outstanding = round(l.outstanding - settled_now, digits = 4)
        rest = price - settled_now
        rest > 1e-9 && transfer!(model, receiver, borrower, min(rest, cash(receiver)), :seizure_refund)
    end
    l.outstanding <= 1e-6 && (l.settled = true; l.in_arrears = false; l.arrears_rounds = 0)
    units > 0 && log_event!(model, :seizure; actor = borrower.id, agent_kind = kind_of(borrower), creditor = receiver.id, peer_loan = l.id, units = units, price = price, remaining_due = l.outstanding)
    return nothing
end

function seize_enterprise_peer!(model, l::PeerLoan)
    b = model[l.borrower_id]
    if parameters(model).settlement == :invoicing && b isa Enterprise && b.kind in (:farm, :bakery, :theatre)
        return nothing              # 23 Sept: peer-loan arrears are overdue obligations in the liquidation test; no separate seizure
    end
    borrower = model[l.borrower_id]; lender = model[l.lender_id]
    pay = round(min(cash(borrower), l.outstanding), digits = 4)
    pay > 0 && (transfer!(model, borrower, lender, pay, :seizure); l.outstanding = round(l.outstanding - pay, digits = 4))
    l.outstanding > 1e-9 && borrower.land > 0 && seize_land_peer!(model, l)
    l.outstanding <= 1e-6 && (l.settled = true; l.in_arrears = false)
    l.settled && return nothing
    if l.outstanding > parameters(model).closure_debt_threshold_in_breads * expected_price(model, :bread)
        close_enterprise!(model, borrower, :uncovered_debt)
    else
        l.in_arrears = false; l.arrears_rounds = 0      # de minimis: carry the tail, keep the business
    end
    return nothing
end


"""Pledged shares return to the seller in proportion to what is still owed; the contract is settled."""
function seize_shares_peer!(model, l::PeerLoan)
    eid, units = model.share_collateral[l.id]; e = model[eid]; borrower = model[l.borrower_id]; lender = model[l.lender_id]
    back = min(units, round(units * l.outstanding / max(l.principal, 1e-9)), get(e.shares, borrower.id, 0.0))
    e.shares[borrower.id] = get(e.shares, borrower.id, 0.0) - back; e.shares[lender.id] = get(e.shares, lender.id, 0.0) + back
    log_event!(model, :seizure; actor = borrower.id, agent_kind = :person, creditor = lender.id, peer_loan = l.id, units = back, collateral = :shares, remaining_due = l.outstanding)
    l.outstanding = 0.0; l.settled = true; l.in_arrears = false; delete!(model.share_collateral, l.id)
    return nothing
end

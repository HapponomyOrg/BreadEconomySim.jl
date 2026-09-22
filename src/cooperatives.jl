# ---- cooperative forms (14 September 2026) -------------------------------------------
#
# Three forms of cooperative, chosen per enterprise kind:
#
#   :member    the original rule (13 September): anyone with surplus joins any cooperative at par,
#              every member gets the same dividend. Kept as a switch for comparison.
#   :worker    membership follows employment. Members are served first and the work is spread over
#              them; the membership share is collected out of wages; the surplus is distributed in
#              proportion to hours worked and taxed as wage income.
#   :consumer  membership follows purchases. The surplus is returned as a patronage rebate in
#              proportion to units bought (a price reduction, so untaxed), and members net the
#              expected rebate off the posted price when they choose where to buy.
#
# Both new forms retain `retained_surplus_share` of every distribution in an indivisible reserve
# (`retained_reserve`) that can never be paid out and, on dissolution, goes to the government after
# members have been redeemed at par.

"""The form configured for a kind of cooperative."""
function coop_form(p::SimulationParameters, kind::Symbol)
    kind == :farm && return p.cooperative_form_farms
    kind == :bakery && return p.cooperative_form_bakeries
    kind == :theatre && return p.cooperative_form_theatres
    return :member
end

"""The cooperative form of an enterprise: `:none` when it is not a cooperative."""
coop_form(model, e::Enterprise) =
    (e isa Enterprise && e.ownership == :cooperative) ? coop_form(parameters(model), e.kind) : :none

is_worker_coop(model, e) = e isa Enterprise && coop_form(model, e) == :worker
is_consumer_coop(model, e) = e isa Enterprise && coop_form(model, e) == :consumer
is_member_coop(model, e) = e isa Enterprise && coop_form(model, e) == :member
cooperatives(model) = Enterprise[e for e in alive_agents(model) if e isa Enterprise && e.ownership == :cooperative]

"""Members are redeemed and distributions are proportional to patronage over the trailing window."""
patronage_total(e::Enterprise, id::Int) = sum(get(d, id, 0.0) for d in e.patronage_log; init = 0.0)
patronage_units(e::Enterprise) = sum(sum(values(d); init = 0.0) for d in e.patronage_log; init = 0.0)

"""End of round: this round's patronage enters the window, the oldest round leaves it."""
function roll_patronage_window!(model)
    p = parameters(model)
    for e in alive_agents(model)
        (e isa Enterprise && e.ownership == :cooperative) || continue
        coop_form(model, e) == :member && continue
        push!(e.patronage_log, copy(e.patronage_this_round))
        while length(e.patronage_log) > p.patronage_window
            popfirst!(e.patronage_log)
        end
    end
    return nothing
end

# ---- what a member brings in: money, pledged buffer, or a mix ------------------------

"""
A pledged unit of buffer is only worth something where there is demurrage to be spared, so under debt money it
counts for nothing: a `:mixed_flexible` member must then meet the whole requirement in money, and the buffer half
of `:buffer` and `:mixed_fixed` collects nothing.
"""
buffer_value(model) = is_sumsy(model) ? parameters(model).buffer_contribution_value : 0.0

"""Exemption a person still has to give: their buffer less what is already lent to a bank or pledged to a cooperative."""
buffer_headroom(model, w::Person) =
    max(parameters(model).demurrage_free_buffer - w.buffer_lent - w.buffer_pledged, 0.0)

"""Money and buffer required of a joining member, by contribution form."""
function membership_requirement(model)
    p = parameters(model)
    p.membership_contribution == :money && return (p.membership_share_price, 0.0)
    p.membership_contribution == :buffer && return (0.0, p.membership_buffer_pledge)
    return (p.membership_share_price, p.membership_buffer_pledge)      # both mixed forms
end

"""
    plan_contribution(model, w)

What this person would bring in, or `nothing` when they cannot meet the requirement.

`:mixed_flexible` asks for one total — the money requirement plus the buffer requirement valued at
`buffer_contribution_value` — and lets the member choose the split. The rule is to pledge the buffer that is
currently idle first (exemption above the cash they hold costs them nothing today) and to pay the rest in money;
a member short of money pledges more buffer, a member short of buffer pays more money.
"""
function plan_contribution(model, w::Person)
    p = parameters(model)
    money_required, buffer_required = membership_requirement(model)
    spare = round(max(cash(w) - buffer_target(model, w), 0.0), digits = 4)
    headroom = buffer_headroom(model, w)
    if p.membership_contribution != :mixed_flexible
        pledge = min(buffer_required, headroom)
        (buffer_value(model) > 0 && pledge < buffer_required - 1e-9) && return nothing   # cannot give the exemption asked for
        spare >= money_required - 1e-9 || return nothing
        return (money_required, buffer_value(model) > 0 ? pledge : 0.0)
    end
    total = money_required + buffer_required * buffer_value(model)
    value = buffer_value(model)
    if value <= 0
        spare >= total - 1e-9 || return nothing
        return (total, 0.0)
    end
    idle = round(max(headroom - cash(w), 0.0), digits = 4)              # exemption they are not using today
    pledge = round(min(idle, total / value), digits = 4)
    money = round(max(total - pledge * value, 0.0), digits = 4)
    if money > spare + 1e-9                                             # short of cash: pledge more, up to the headroom
        pledge = round(min(headroom, total / value), digits = 4)
        money = round(max(total - pledge * value, 0.0), digits = 4)
    end
    money <= spare + 1e-9 || return nothing
    return (money, pledge)
end

"""Move the exemption: the member's buffer shrinks by the pledge, the cooperative's grows by it."""
function pledge_buffer!(model, w::Person, e::Enterprise, amount::Float64)
    amount <= 1e-9 && return nothing
    w.buffer_pledged += amount
    e.buffer_pledged += amount
    e.buffer_pledged_by[w.id] = get(e.buffer_pledged_by, w.id, 0.0) + amount
    log_event!(model, :buffer_pledge; actor = w.id, cooperative = e.id, amount = amount)
    return nothing
end

"""Give the exemption back — on redemption, on death, on closure."""
function release_pledge!(model, e::Enterprise, id::Int)
    amount = get(e.buffer_pledged_by, id, 0.0)
    amount <= 1e-9 && (delete!(e.buffer_pledged_by, id); return 0.0)
    w = model[id]
    w isa Person && (w.buffer_pledged = max(w.buffer_pledged - amount, 0.0))
    e.buffer_pledged = max(e.buffer_pledged - amount, 0.0)
    delete!(e.buffer_pledged_by, id)
    log_event!(model, :buffer_release; actor = id, cooperative = e.id, amount = amount)
    return amount
end

"""Every pledge back at once (the cooperative is closing)."""
release_all_pledges!(model, e::Enterprise) = for id in collect(keys(e.buffer_pledged_by)); release_pledge!(model, e, id); end

"""
    contribute_membership!(model, w, e; collect_money_now = true)

Admit a member and collect what they bring in. Worker cooperatives collect the money out of wages instead
(`collect_money_now = false`), so only the pledge is made at admission. Returns false when the person cannot
meet the requirement, in which case nothing is changed.
"""
function contribute_membership!(model, w::Person, e::Enterprise; collect_money_now::Bool = true)
    plan = plan_contribution(model, w)
    plan === nothing && return false
    money, pledge = plan
    if collect_money_now && money > 1e-6
        transfer!(model, w, e, money, :membership_share)
        e.paid_in_capital += money
        e.membership_unpaid[w.id] = 0.0
    else
        e.membership_unpaid[w.id] = money
    end
    pledge_buffer!(model, w, e, pledge)
    e.members[w.id] = 1
    e.member_since[w.id] = current_round(model)
    return true
end

# ---- labour: members first, work spread over the members -----------------------------

"""
    reserve_labour_for_cooperatives!(model)

Worker cooperatives that hire later in the round (bakeries) reserve capacity from their members at
the start of the round, before the farms hire, so that a member is not sold out before their own
cooperative gets its turn. The expected need is the production target. Reserved units that the
cooperative does not use stay with the worker and are released into the later stage of the market.
"""
function reserve_labour_for_cooperatives!(model, later_kinds)
    p = parameters(model)
    p.members_first_hiring || return nothing
    for e in alive_agents(model)
        (e isa Enterprise && e.alive && e.kind in later_kinds && is_worker_coop(model, e)) || continue
        need = Float64(max(e.production_target, 0))
        need > 1e-9 || continue
        members = [w for w in persons(model) if haskey(e.members, w.id) && w.labour_available > 1e-9]
        isempty(members) && continue
        total = sum(w.labour_available for w in members)
        share = min(need, total)
        left = share
        for (k, w) in enumerate(sort(members; by = w -> w.id))
            units = k == length(members) ? left : round(share * w.labour_available / total, digits = 6)
            units = min(max(units, 0.0), w.labour_available, left)
            units <= 1e-9 && continue
            w.labour_available -= units
            w.labour_reserved[e.id] = get(w.labour_reserved, e.id, 0.0) + units
            model.reserved_labour_this_round += units
            left = round(left - units, digits = 6)
        end
    end
    return nothing
end

"""Give reserved capacity back to the workers now that the cooperative that reserved it is hiring."""
function release_reserved_labour!(model, kinds)
    for w in persons(model)
        isempty(w.labour_reserved) && continue
        for (eid, units) in collect(w.labour_reserved)
            e = model[eid]
            (e isa Enterprise && e.kind in kinds) || continue
            w.labour_available += units
            delete!(w.labour_reserved, eid)
        end
    end
    return nothing
end

"""
    allocate_cooperative_labour!(model, kinds)

Before the open labour market, every worker cooperative of these kinds allocates its need to its own
members: the wage is negotiated as usual (a member whose reservation is not met simply does not take
the work), and what the cooperative needs is spread over the accepting members in proportion to the
capacity they have left. Whatever the cooperative still needs, and whatever capacity the members have
left over, goes into the open market afterwards.
"""
function allocate_cooperative_labour!(model, kinds)
    p = parameters(model)
    p.members_first_hiring || return nothing
    coops = [e for e in alive_agents(model) if e isa Enterprise && e.alive && e.kind in kinds && is_worker_coop(model, e)]
    isempty(coops) && return nothing
    for e in sort(coops; by = e -> e.id)
        need = labour_need(e) - e.hired_labour
        need > 1e-9 || continue
        members = sort([w for w in persons(model) if haskey(e.members, w.id) && w.labour_available > 1e-9]; by = w -> w.id)
        isempty(members) && continue
        accepted = Tuple{Person, Float64}[]
        for w in members
            wage = negotiate(model, w, e, :wage)
            wage === nothing && continue
            push!(accepted, (w, wage))
        end
        isempty(accepted) && continue
        total = sum(w.labour_available for (w, _) in accepted)
        total > 1e-9 || continue
        share = min(need, total)
        left = share
        for (k, (w, wage)) in enumerate(accepted)
            units = k == length(accepted) ? left : round(share * w.labour_available / total, digits = 6)
            units = min(max(units, 0.0), w.labour_available, left)
            units <= 1e-9 && continue
            hire!(model, e, w, units, wage)
            left = round(left - units, digits = 6)
            left <= 1e-9 && break
        end
    end
    return nothing
end

# ---- membership --------------------------------------------------------------------

"""A worker cooperative takes on every worker it hires as a member; the share is paid out of wages."""
function admit_worker_member!(model, e::Enterprise, w::Person)
    haskey(e.members, w.id) && return nothing
    contribute_membership!(model, w, e; collect_money_now = false) || return nothing   # the pledge is made now, the money comes out of wages
    log_event!(model, :membership; actor = w.id, cooperative = e.id, price = 0.0,
               pledge = get(e.buffer_pledged_by, w.id, 0.0), route = :employment)
    return nothing
end

"""Collect part of a member's net wage towards the unpaid membership share."""
function deduct_membership_capital!(model, e::Enterprise, w::Person, net::Float64)
    p = parameters(model)
    unpaid = get(e.membership_unpaid, w.id, 0.0)
    (unpaid > 1e-6 && net > 0) || return nothing
    contribution = round(min(p.capital_deduction_share * net, unpaid), digits = 4)
    contribution <= 1e-6 && return nothing
    promise!(model, w, e, contribution, :membership_capital, 3)
    e.membership_unpaid[w.id] = round(unpaid - contribution, digits = 4)
    e.paid_in_capital += contribution
    model.membership_capital_this_round += contribution
    return nothing
end

"""A purchase at a consumer cooperative counts as patronage."""
function record_patronage!(model, seller::Agent, buyer::Person, units::Float64)
    is_consumer_coop(model, seller) || return nothing
    units > 0 || return nothing
    seller.patronage_this_round[buyer.id] = get(seller.patronage_this_round, buyer.id, 0.0) + units
    return nothing
end

"""The price a buyer compares: members of a consumer cooperative net the expected rebate off the ask."""
function member_ask(model, e::Enterprise, w::Person, good::Symbol)
    ask = e.ask[good]
    (parameters(model).member_price_awareness && is_consumer_coop(model, e) && haskey(e.members, w.id)) || return ask
    return max(ask - e.rebate_per_unit, 0.0)
end

"""Cash a member can get back: par, out of cash above the reserve, for the new forms."""
function redeem_membership!(model, e::Enterprise, w::Person, reason::Symbol)
    p = parameters(model)
    get(e.members, w.id, 0) > 0 || return false
    par = p.membership_share_price
    paid = round(par - get(e.membership_unpaid, w.id, 0.0), digits = 4)     # only what was actually paid in
    available = cash(e) - reserve_target(model, e)
    if paid > 1e-6
        available >= paid || return false                                   # queued: tried again next round
        transfer!(model, e, w, paid, :share_redemption)
        e.paid_in_capital -= paid
    end
    released = release_pledge!(model, e, w.id)
    delete!(e.members, w.id); delete!(e.membership_unpaid, w.id); delete!(e.member_since, w.id)
    log_event!(model, :redemption; actor = w.id, cooperative = e.id, price = paid, pledge = released, reason = reason)
    return true
end

"""
    manage_new_form_membership!(model)

Worker and consumer cooperatives. Consumers join a cooperative they have bought from; workers are
admitted at hiring, so nothing joins here. Membership lapses when patronage dries up: a worker whose
hours over the window average less than `minimum_member_hours`, a consumer who bought nothing in the
whole window. Members in hardship may still redeem early.
"""
function manage_new_form_membership!(model)
    p = parameters(model); rng = stream(model, :cooperatives)
    coops = [e for e in cooperatives(model) if coop_form(model, e) in (:worker, :consumer)]
    isempty(coops) && return nothing
    par = p.membership_share_price
    round_now = current_round(model)
    for w in stable_shuffle(rng, persons(model))
        # consumers join a cooperative they have actually bought from
        open = [c for c in coops if coop_form(model, c) == :consumer && !haskey(c.members, w.id) && patronage_total(c, w.id) > 0]
        if !isempty(open) && plan_contribution(model, w) !== nothing && rand(rng) < p.cooperative_join_probability
            c = length(open) == 1 ? open[1] : stable_pick(rng, open)
            if contribute_membership!(model, w, c)
                log_event!(model, :membership; actor = w.id, cooperative = c.id, price = par,
                           pledge = get(c.buffer_pledged_by, w.id, 0.0), route = :purchase)
            end
        end
        # hardship: a member who cannot afford a meal takes the paid-in capital back
        if cash(w) < meal_price(model)
            for c in coops
                get(c.members, w.id, 0) > 0 || continue
                redeem_membership!(model, c, w, :hardship) && break
            end
        end
    end
    # lapse
    for e in coops
        form = coop_form(model, e)
        grace = form == :worker ? p.membership_lapse_rounds_worker : p.membership_lapse_rounds_consumer
        window = length(e.patronage_log)
        window >= grace || continue
        for id in sort(collect(keys(e.members)))
            since = get(e.member_since, id, 0)
            round_now - since >= grace || continue
            w = model[id]
            (w isa Person && w.alive) || continue
            total = patronage_total(e, id)
            lapsed = form == :worker ? total / window < p.minimum_member_hours : total <= 0
            lapsed && redeem_membership!(model, e, w, :lapse)
        end
    end
    return nothing
end

# ---- distribution -------------------------------------------------------------------

"""Cash that may never be paid out: the working reserve plus the indivisible reserve."""
distributable_floor(model, e::Enterprise) = reserve_target(model, e) + e.retained_reserve

"""
    distribute_patronage!(model, e, payout)

Worker and consumer cooperatives. `retained_surplus_share` of the payout is locked in the indivisible
reserve; the rest goes to the members in proportion to their patronage over the window — as wage
income for a worker cooperative (taxed on the wage schedule), as an untaxed rebate for a consumer
cooperative. Returns the amount actually distributed.
"""
function distribute_patronage!(model, e::Enterprise, payout::Float64)
    p = parameters(model)
    form = coop_form(model, e)
    retained = round(payout * p.retained_surplus_share, digits = 4)
    e.retained_reserve += retained
    distributable = round(payout - retained, digits = 4)
    units = sum(patronage_total(e, id) for id in keys(e.members); init = 0.0)
    if distributable <= 1e-6 || units <= 1e-9
        e.rebate_per_unit = 0.5 * e.rebate_per_unit
        return 0.0
    end
    gov = government(model)
    paid = 0.0
    for id in sort(collect(keys(e.members)))
        w = model[id]
        (w isa Person && w.alive) || continue
        share = patronage_total(e, id)
        share > 0 || continue
        amount = round(min(distributable * share / units, cash(e)), digits = 4)
        amount <= 1e-6 && continue
        if form == :worker
            tax = round(wage_tax_amount(model, w.gross_wage_this_round + amount) - wage_tax_amount(model, w.gross_wage_this_round), digits = 4)
            tax = clamp(tax, 0.0, amount)
            net = round(amount - tax, digits = 4)
            if tax > 0
                transfer!(model, e, gov, tax, :patronage_tax); gov.tax_collected += tax; model.tax_this_round += tax
            end
            net > 0 && transfer!(model, e, w, net, :patronage)
            w.gross_wage_this_round += amount
            w.labour_income += net
            model.patronage_wages_this_round += net
        else
            transfer!(model, e, w, amount, :rebate)
            w.rebate_income += amount
            model.rebates_this_round += amount
        end
        paid += amount
    end
    rate = paid / units
    e.rebate_per_unit = 0.5 * e.rebate_per_unit + 0.5 * rate
    log_event!(model, :patronage; actor = e.id, agent_kind = e.kind, form = form, amount = paid, retained = retained)
    return paid
end

# ---- capital -------------------------------------------------------------------------

"""
    cooperative_capital_call!(model, e, amount)

`cooperative_founding = :symmetric`: a cooperative short of capital calls on its members, who borrow
personally and pay the money in — the same route a shareholder firm's founders take, so that a
difference between the two ownership forms is not a difference in access to capital. Members are
called on in order of the cash they already hold. Returns true when the whole amount was raised.
"""
function cooperative_capital_call!(model, e::Enterprise, amount::Float64)
    raised = 0.0
    members = sort([model[id] for id in keys(e.members) if model[id] isa Person && model[id].alive]; by = w -> (-cash(w), w.id))
    for w in members
        need = round(amount - raised, digits = 4)
        need <= 1e-6 && break
        before = cash(w)
        own = round(max(before - buffer_target(model, w), 0.0), digits = 4)
        got = 0.0
        if own > 1e-6                                   # spare cash first
            got = min(own, need)
        else
            request_loan!(model, w, need, :member_capital) || continue
            got = round(min(cash(w) - before, need), digits = 4)
        end
        got > 1e-6 || continue
        transfer!(model, w, e, got, :paid_in_capital)
        e.paid_in_capital += got
        raised += got
    end
    return raised >= amount - 1e-6
end

# ---- parameter validation -------------------------------------------------------------

"""Cooperative settings that cannot be simulated are rejected at construction rather than silently ignored."""
function validate_cooperatives(p::SimulationParameters)
    forms = (:member, :worker, :consumer)
    p.cooperative_form_farms in forms || throw(ArgumentError("cooperative_form_farms must be one of $forms"))
    p.cooperative_form_bakeries in forms || throw(ArgumentError("cooperative_form_bakeries must be one of $forms"))
    p.cooperative_form_theatres in forms || throw(ArgumentError("cooperative_form_theatres must be one of $forms"))
    p.cooperative_form_farms == :consumer &&
        throw(ArgumentError("farms sell to bakeries, not to persons: a consumer cooperative farm is a secondary cooperative and is not modelled"))
    p.cooperative_founding in (:par_only, :symmetric) || throw(ArgumentError("cooperative_founding must be :par_only or :symmetric"))
    p.membership_contribution in (:money, :buffer, :mixed_fixed, :mixed_flexible) ||
        throw(ArgumentError("membership_contribution must be :money, :buffer, :mixed_fixed or :mixed_flexible"))
    p.membership_buffer_pledge >= 0 || throw(ArgumentError("membership_buffer_pledge cannot be negative"))
    p.buffer_contribution_value >= 0 || throw(ArgumentError("buffer_contribution_value cannot be negative"))
    (p.membership_contribution != :buffer || p.membership_buffer_pledge > 0) ||
        throw(ArgumentError("membership_contribution = :buffer needs a positive membership_buffer_pledge"))
    p.cooperative_farms <= p.number_of_farms || throw(ArgumentError("cooperative_farms exceeds number_of_farms"))
    p.cooperative_bakeries <= p.number_of_bakeries || throw(ArgumentError("cooperative_bakeries exceeds number_of_bakeries"))
    p.cooperative_theatres <= p.number_of_theatres || throw(ArgumentError("cooperative_theatres exceeds number_of_theatres"))
    (0 <= p.retained_surplus_share < 1) || throw(ArgumentError("retained_surplus_share must be in [0, 1)"))
    (0 <= p.capital_deduction_share <= 1) || throw(ArgumentError("capital_deduction_share must be in [0, 1]"))
    p.patronage_window >= 1 || throw(ArgumentError("patronage_window must be at least 1"))
    p.consumption_tax_rate >= 0 || throw(ArgumentError("consumption_tax_rate cannot be negative"))
    p.wealth_tax_rate >= 0 || throw(ArgumentError("wealth_tax_rate cannot be negative"))
    p.wealth_tax_rounds_per_year >= 1 || throw(ArgumentError("wealth_tax_rounds_per_year must be at least 1"))
    all(x -> x isa Real && isfinite(x), values(p.tax_levers)) || throw(ArgumentError("tax_levers must be finite numbers"))
    all(in((:income, :consumption, :wealth, :profit, :parking)), keys(p.tax_levers)) || throw(ArgumentError("tax_levers families: income, consumption, wealth, profit, parking"))
    (p.income_tax_period >= 1 && p.profit_tax_period >= 1) || throw(ArgumentError("tax periods must be at least 1"))
    (0 <= p.deductible_materials <= 1 && 0 <= p.deductible_labour <= 1) || throw(ArgumentError("deductible shares must be in [0, 1]"))
    p.profit_tax_rate >= 0 || throw(ArgumentError("profit_tax_rate cannot be negative"))
    return nothing
end

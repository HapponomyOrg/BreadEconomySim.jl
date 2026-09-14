struct WageContract
    employer_id::Int
    worker_id::Int
    units::Float64
    price::Float64
    stage::Symbol   # :farm, :bakery, :bank, :government
end

"""
    Promise

An intra-round payment obligation. All payments during a round are promises; `clear!` settles them
simultaneously. Priority: 0 trade arrears carried from earlier rounds, 1 tax, 2 wages and fees, 3 inputs
(rent, grain, bread, land). Debt service is not a promise; it runs on cash after clearing.
"""
mutable struct Promise
    from_id::Int
    to_id::Int
    amount::Float64
    purpose::Symbol
    priority::Int
    income_kind::Symbol      # :wage, :rent, :fee, :tax or :none — what the receipt counts as for the receiver
    paid::Float64
end

const ROUND_BEHAVIORS = Function[]

function create_bread_economy(parameters::SimulationParameters = SimulationParameters())
    model = create_econo_model(Agent, copy(ROUND_BEHAVIORS))
    Random.seed!(abmrng(model), parameters.seed)
    props = abmproperties(model)
    props[:parameters] = parameters
    props[:loans] = Loan[]
    props[:wage_contracts] = WageContract[]
    props[:promises] = Promise[]
    props[:trade_arrears] = Promise[]
    props[:cumulative_trade_arrears] = 0.0
    props[:expected_prices] = Dict{Symbol, Float64}(k => v * parameters.initial_price_multiplier for (k, v) in parameters.initial_prices)
    props[:transactions] = Dict{Symbol, Vector{Tuple{Float64, Float64}}}(g => Tuple{Float64, Float64}[] for g in GOODS)
    props[:credit_demand_this_round] = 0.0
    props[:credit_demand_previous_round] = 0.0
    props[:cumulative_interest_paid] = 0.0
    props[:cumulative_write_offs] = 0.0
    props[:cumulative_credit_refusals] = 0
    props[:cumulative_money_created] = 0.0
    props[:cumulative_money_destroyed] = 0.0
    props[:cumulative_money_lost] = 0.0
    props[:money_created_this_round] = 0.0
    props[:money_destroyed_this_round] = 0.0
    props[:tax_this_round] = 0.0
    props[:enterprise_tax_this_round] = 0.0
    props[:fees_this_round] = 0.0
    props[:events] = NamedTuple[]
    props[:data] = NamedTuple[]
    props[:stationary_counter] = 0
    props[:finished] = false
    props[:termination_reason] = ""
    props[:initial_person_count] = parameters.number_of_persons
    props[:closures] = 0
    props[:peer_loans] = PeerLoan[]
    props[:bonds] = Bond[]
    props[:share_collateral] = Dict{Int, Tuple{Int, Float64}}()   # peer loan id → (enterprise id, share units pledged)
    props[:clearing_obligations] = Dict{Int, Float64}()
    props[:clearing_receipts] = Dict{Int, Float64}()
    props[:clearing_debt_service] = Dict{Int, Float64}()
    props[:agent_list] = Agent[]
    props[:person_list] = Person[]
    props[:enterprise_list] = Enterprise[]
    props[:event_start] = 1
    props[:gluttony_attempted_this_round] = 0
    props[:greedy_loaves_this_round] = 0
    props[:ration_this_round] = 0
    props[:tier_revenue_this_round] = 0.0
    props[:greedy_tickets_this_round] = 0
    props[:greedy_land_this_round] = 0
    props[:greedy_shares_this_round] = 0
    props[:gluttony_refused_this_round] = 0
    props[:demurrage_persons_this_round] = 0.0
    props[:bank_rate_history] = Float64[]
    props[:bonds_issued_this_round] = 0.0
    props[:coupons_this_round] = 0.0
    props[:balance_history] = Dict{Int, Vector{Float64}}()
    props[:deposit_interest_this_round] = 0.0
    props[:gi_this_round] = 0.0
    props[:demurrage_this_round] = 0.0
    props[:demurrage_tax_this_round] = 0.0
    props[:account_fees_this_round] = 0.0
    props[:peer_lent_this_round] = 0.0

    prices = Dict{Symbol, Float64}(k => v * parameters.initial_price_multiplier for (k, v) in parameters.initial_prices)
    sumsy = parameters.monetary_system == :sumsy
    sumsy && add_agent!(Enterprise, model; kind = :authority, balance = Balance(), ask = Dict{Symbol, Float64}(prices), bid = Dict{Symbol, Float64}(prices))
    for k in 1:parameters.number_of_banks
        # A bank's deposit liability may go negative: repayments made with deposits another bank created (or made to a bank
        # that has closed) then book as an interbank claim instead of leaking out of the accounting (EconoSim process_debt!).
        bank_balance = Balance(); min_liability!(bank_balance, DEPOSIT, typemin(Currency))
        add_agent!(Enterprise, model; kind = :bank, balance = bank_balance, interest_rate = sumsy ? 0.0 : parameters.initial_interest_rate,
                   ask = Dict{Symbol, Float64}(prices), bid = Dict{Symbol, Float64}(prices))
    end
    for k in 1:parameters.number_of_farms
        add_agent!(Enterprise, model; kind = :farm, balance = Balance(), production_target = parameters.initial_production_target,
                   ask = Dict{Symbol, Float64}(prices), bid = Dict{Symbol, Float64}(prices))
    end
    for k in 1:parameters.number_of_bakeries
        add_agent!(Enterprise, model; kind = :bakery, balance = Balance(), production_target = parameters.initial_production_target,
                   ask = Dict{Symbol, Float64}(prices), bid = Dict{Symbol, Float64}(prices))
    end
    add_agent!(Enterprise, model; kind = :government, balance = Balance(), ask = Dict{Symbol, Float64}(prices), bid = Dict{Symbol, Float64}(prices))

    land = land_units_per_landowner(parameters)
    for k in 1:parameters.number_of_persons
        landowner = k <= parameters.number_of_landowners
        add_agent!(Person, model; balance = Balance(), capacity = parameters.maximum_capacity,
                   land = landowner ? land : 0, initial_landowner = landowner,
                   bread = parameters.initial_breads_per_person > 0 ? [StockItem(parameters.initial_breads_per_person, 0)] : StockItem[],
                   ask = Dict{Symbol, Float64}(prices), bid = Dict{Symbol, Float64}(prices))
    end
    if parameters.entertainment
        target0 = max(ceil(Int, parameters.number_of_persons * parameters.entertainment_propensity / parameters.customers_per_labour_unit / parameters.number_of_theatres), 1)
        for k in 1:parameters.number_of_theatres
            add_agent!(Enterprise, model; kind = :theatre, balance = Balance(), production_target = target0,
                       ask = Dict{Symbol, Float64}(prices), bid = Dict{Symbol, Float64}(prices))
        end
    end
    if parameters.ownership != :none
        ps = sort([a for a in allagents(model) if a isa Person]; by = a -> a.id)
        units_total = parameters.shares_per_person > 0 ? float(parameters.shares_per_person * parameters.number_of_persons) : 100.0
        holders = ps[1:min(parameters.shareholder_count, length(ps))]
        for kind in (:farm, :bakery, :theatre)
            es = sort([a for a in allagents(model) if a isa Enterprise && a.kind == kind]; by = a -> a.id)
            ncoop = parameters.ownership == :cooperative ? length(es) : parameters.ownership == :shareholders ? 0 :
                    kind == :farm ? parameters.cooperative_farms : kind == :bakery ? parameters.cooperative_bakeries : 0
            for (k, e) in enumerate(es)
                if k <= ncoop
                    e.ownership = :cooperative
                    if parameters.startup_financing == :paid_in_capital
                        # members join by buying shares at par; nobody is a member at the start
                    else
                        for w in ps; e.shares[w.id] = units_total / length(ps); e.members[w.id] = 1; end
                    end
                else
                    e.ownership = :shareholders
                    for w in holders; e.shares[w.id] = units_total / length(holders); end
                    e.founder_ids = [w.id for w in holders]
                end
            end
        end
    end
    for a in allagents(model)
        push!(model.agent_list, a)
        a isa Person ? push!(model.person_list, a) : push!(model.enterprise_list, a)
    end
    if parameters.required_yield_dispersion > 0           # drawn only when a spread exists, so the random stream is untouched otherwise
        let rng = abmrng(model)
            for w in model.person_list
                w.required_yield = parameters.required_yield + parameters.required_yield_dispersion * (2 * rand(rng) - 1)
            end
        end
    else
        for w in model.person_list; w.required_yield = parameters.required_yield; end
    end
    if parameters.greed
        ps = collect(persons(model)); n = round(Int, parameters.greed_share * length(ps))
        wealth(w) = cash(w) + w.land * parameters.land_price_rent_multiple * prices[:rent] + sum(get(e.shares, w.id, 0.0) for e in allagents(model) if e isa Enterprise; init = 0.0)
        chosen = parameters.greed_selection == :rich ? sort(ps; by = w -> (-wealth(w), w.id))[1:n] : shuffle(abmrng(model), ps)[1:n]
        for w in chosen; w.greed = :greedy; end
    end
    if sumsy && parameters.start_at_saturation != :none
        b = parameters.demurrage_free_buffer; n = parameters.number_of_persons; gi_d = parameters.guaranteed_income / parameters.demurrage_rate
        if parameters.start_at_saturation == :upper
            for w in persons(model); create_money!(model, w, b + gi_d); end
        else
            create_money!(model, first(sort(persons(model); by = w -> w.id)), b + n * gi_d)
        end
        parameters.initial_endowment == :norm && for e in alive_agents(model); is_producer(e) && create_money!(model, e, reserve_target(model, e)); end
    elseif parameters.initial_endowment == :norm && parameters.startup_financing == :paid_in_capital
        # owned businesses start empty. Villagers start with their savings target: created by the authority under SuMSy;
        # under debt money borrowed by the founders personally (a founding loan, no affordability test) and paid out as
        # start-up wages through their businesses, so all money is born as debt and the founders carry it.
        if sumsy
            for w in persons(model); create_money!(model, w, savings_buffer(model)); end
        else
            founders = [w for w in persons(model) if any(e -> e isa Enterprise && e.ownership == :shareholders && haskey(e.shares, w.id), alive_agents(model))]
            banks = sort(enterprises(model, :bank); by = b -> b.id)
            if !isempty(founders) && !isempty(banks)
                ps = persons(model); per_founder = ceil(savings_buffer(model) * length(ps) / length(founders) * 1e4) / 1e4
                for (k, f) in enumerate(founders)
                    bank = banks[mod(k - 1, length(banks)) + 1]
                    debt = bank_loan(bank.balance, f.balance, per_founder, parameters.startup_loan_rate, parameters.startup_loan_term, 1, 0)
                    push!(model.loans, Loan(length(model.loans) + 1, bank.id, f.id, debt, 0, false, 0, false, 0.0))
                    model.cumulative_money_created += per_founder
                    log_event!(model, :loan; actor = f.id, agent_kind = :person, lender = bank.id, amount = per_founder, rate = parameters.startup_loan_rate, purpose = :founding)
                end
                k = 1
                for w in ps
                    remaining = savings_buffer(model)
                    while remaining > 1e-6
                        f = founders[mod(k - 1, length(founders)) + 1]; k += 1
                        amt = round(min(remaining, cash(f)), digits = 4)
                        amt <= 0 && continue
                        transfer!(model, f, w, amt, :startup_wage); remaining -= amt
                    end
                end
            end
        end
    elseif parameters.initial_endowment == :norm && parameters.inherited_money && !sumsy
        # persons: debt-free money booked as a bank deposit liability against negative bank equity (loans of the deceased, written off)
        banks = sort(enterprises(model, :bank); by = b -> b.id)
        for (k, w) in enumerate(persons(model))
            bank = banks[mod(k - 1, length(banks)) + 1]; amt = savings_buffer(model)
            book_asset!(w.balance, DEPOSIT, amt); book_liability!(bank.balance, DEPOSIT, amt)   # the write-off lowers the bank's net worth, not its operating funds
            model.cumulative_money_created += amt
        end
        # producers: their working reserve as a start-up loan (the founders' share, if any, is the enterprise's own here)
        for e in [x for x in alive_agents(model) if is_producer(x)]
            bank = banks[mod(e.id, length(banks)) + 1]; amt = round(reserve_target(model, e), digits = 4)
            debt = bank_loan(bank.balance, e.balance, amt, parameters.startup_loan_rate, parameters.startup_loan_term, 1, 0)
            push!(model.loans, Loan(length(model.loans) + 1, bank.id, e.id, debt, 0, false, 0, false, 0.0)); model.cumulative_money_created += amt
        end
    elseif parameters.initial_endowment == :norm
        endow_at_norm!(model)
    elseif sumsy && parameters.initial_money_per_person > 0
        for w in persons(model)
            create_money!(model, w, parameters.initial_money_per_person)
        end
    end
    return model
end

"""
    endow_at_norm!(model)

Persons start with their savings target, producers with their standard working reserve. SuMSy: created by the
authority. Debt: each producer takes a start-up loan for its own reserve plus an equal share of the persons'
endowment and pays that share out to the persons (start-up wages), so all initial money is enterprise debt.
"""
function endow_at_norm!(model)
    p = parameters(model)
    ps = persons(model); producers = [e for e in alive_agents(model) if is_producer(e)]
    person_amount = savings_buffer(model)
    if p.monetary_system == :sumsy
        for w in ps; create_money!(model, w, person_amount); end
        for e in producers; create_money!(model, e, reserve_target(model, e)); end
        return nothing
    end
    banks = sort(enterprises(model, :bank); by = b -> b.id)
    isempty(banks) && return nothing
    share = ceil(person_amount * length(ps) / length(producers) * 1e4) / 1e4      # round up: the payout loop below must be able to finish
    paid = zeros(length(ps))
    for (k, e) in enumerate(producers)
        bank = banks[mod(k - 1, length(banks)) + 1]
        amount = round(reserve_target(model, e) + share, digits = 4)
        debt = bank_loan(bank.balance, e.balance, amount, p.startup_loan_rate, p.startup_loan_term, 1, 0)
        push!(model.loans, Loan(length(model.loans) + 1, bank.id, e.id, debt, 0, false, 0, false, 0.0))
        model.cumulative_money_created += amount
        log_event!(model, :loan; actor = e.id, agent_kind = e.kind, lender = bank.id, amount = amount, rate = p.startup_loan_rate, purpose = :startup)
    end
    # start-up wages: producers pay the persons' endowment round robin
    k = 1
    for w in ps
        remaining = person_amount; idle = 0
        while remaining > 1e-6 && idle < length(producers)
            e = producers[mod(k - 1, length(producers)) + 1]; k += 1
            amt = round(min(remaining, max(cash(e) - reserve_target(model, e), 0.0)), digits = 4)
            amt <= 0 && (idle += 1; continue)
            idle = 0
            transfer!(model, e, w, amt, :startup_wage); remaining -= amt
        end
    end
    return nothing
end

current_round(model) = get_step(model)
parameters(model) = model.parameters
expected_price(model, good::Symbol) = model.expected_prices[good]
meal_price(model) = parameters(model).breads_per_meal * expected_price(model, :bread)
land_price(model) = parameters(model).land_price_rent_multiple * expected_price(model, :rent)
savings_buffer(model) = parameters(model).savings_target_in_meals * meal_price(model)

function log_event!(model, kind::Symbol; kwargs...)
    push!(model.events, (round = current_round(model), kind = kind, kwargs...))
    return nothing
end

function record_transaction!(model, good::Symbol, price::Float64, units::Float64)
    push!(model.transactions[good], (price, units))
    return nothing
end

function begin_round!(model)
    p = parameters(model)
    for a in alive_agents(model)
        empty!(a.negotiated)
        a.land_let = 0
        for g in GOODS
            r = a.market[g]
            r.offered = 0.0; r.sold = 0.0; r.unmet_demand = false; r.wanted = 0.0; r.got = 0.0; r.failed_for_cash = 0; r.max_failed_cash = 0.0
        end
        if a isa Person
            a.effective_capacity = a.last_meal == :half ? a.capacity * p.half_meal_capacity_fraction : a.capacity
            a.labour_available = 0.0; a.labour_offered = 0.0; a.labour_sold = 0.0
            a.labour_income = 0.0; a.rent_income = 0.0; a.fee_received = 0.0
            a.ate_this_round = :none; a.glutton = false
        else
            a.reserved_cash = 0.0; a.hired_labour = 0.0; a.rented_land = 0; a.wage_bill = 0.0
            a.operating_net = 0.0; a.interest_paid = 0.0; a.interest_received = 0.0; a.enterprise_tax_paid = 0.0
        end
    end
    for g in GOODS
        empty!(model.transactions[g])
    end
    empty!(model.wage_contracts)
    empty!(model.promises)
    append!(model.promises, model.trade_arrears); empty!(model.trade_arrears)
    model.money_created_this_round = 0.0
    model.money_destroyed_this_round = 0.0
    model.credit_demand_this_round = 0.0
    model.tax_this_round = 0.0
    model.fees_this_round = 0.0
    model.enterprise_tax_this_round = 0.0
    model.deposit_interest_this_round = 0.0
    model.event_start = length(model.events) + 1
    model.gluttony_attempted_this_round = 0; model.gluttony_refused_this_round = 0; model.demurrage_persons_this_round = 0.0
    model.greedy_loaves_this_round = 0; model.greedy_tickets_this_round = 0; model.tier_revenue_this_round = 0.0
    model.greedy_land_this_round = 0; model.greedy_shares_this_round = 0
    for w in model.person_list; w.gross_wage_this_round = 0.0; w.dividend_income = 0.0; empty!(w.worked_for); end
    for e in model.enterprise_list; e.tier_sold = 0; e.tier_unmet = false; end
    model.bonds_issued_this_round = 0.0; model.coupons_this_round = 0.0
    model.gi_this_round = 0.0; model.demurrage_this_round = 0.0; model.demurrage_tax_this_round = 0.0
    model.account_fees_this_round = 0.0; model.peer_lent_this_round = 0.0
    return nothing
end

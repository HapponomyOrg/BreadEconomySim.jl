mutable struct StockItem
    units::Float64
    age::Int
end

const GOODS = (:bread, :grain, :rent, :wage, :ticket)

Base.@kwdef mutable struct MarketRecord
    offered::Float64 = 0.0
    sold::Float64 = 0.0
    unmet_demand::Bool = false
    unmet_units::Float64 = 0.0  # units that went unserved this round, market-wide, recorded on every seller of the good
    wanted::Float64 = 0.0
    got::Float64 = 0.0
    idle_rounds::Int = 0      # consecutive rounds with nothing sold although offered
    starved_rounds::Int = 0   # consecutive rounds in which the buyer missed out
    failed_for_cash::Int = 0  # buyers who wanted to buy but could not pay
    max_failed_cash::Float64 = 0.0
end

"""
    Loan

Contract issued through EconoSim `bank_loan`; serviced through EconoSim `process_debt!`
(partial payments capitalise the shortfall into the remaining installments). This wrapper
keeps the arrears bookkeeping needed for credit blocking, garnishment and seizure.
"""
mutable struct Loan
    id::Int
    creditor_id::Int
    debtor_id::Int
    debt::Debt
    arrears_rounds::Int
    in_arrears::Bool
    created::Int
    settled::Bool
    write_off::Float64
end

"""
    PeerLoan

SuMSy credit: existing money lent by one agent to another through a bank (the intermediary keeps `rate − lender_rate`
on the outstanding balance). Equal installments; interest on the outstanding balance, may be negative.
"""
mutable struct PeerLoan
    id::Int
    lender_id::Int
    borrower_id::Int
    bank_id::Int
    principal::Float64
    outstanding::Float64
    installment::Float64
    rate::Float64
    lender_rate::Float64
    insured::Bool
    created::Int
    arrears_rounds::Int
    in_arrears::Bool
    settled::Bool
    write_off::Float64
end

"""A government bond: bullet, coupon every round, principal at maturity."""
mutable struct Bond
    id::Int
    holder_id::Int
    principal::Float64
    rate::Float64
    issued::Int
    maturity::Int
    settled::Bool
end

"""A person: eats, works, may own land, borrows, pays tax, dies."""
@agent struct Person(NoSpaceAgent)
    balance::Balance{Currency}
    alive::Bool = true
    capacity::Float64 = 3.0
    hunger::Int = 0
    last_meal::Symbol = :whole
    land::Int = 0
    bread::Vector{StockItem} = StockItem[]
    ask::OrderedDict{Symbol, Float64} = OrderedDict{Symbol, Float64}()
    bid::OrderedDict{Symbol, Float64} = OrderedDict{Symbol, Float64}()
    market::OrderedDict{Symbol, MarketRecord} = OrderedDict(g => MarketRecord() for g in GOODS)
    negotiated::OrderedDict{Tuple{Symbol, Int}, Float64} = OrderedDict{Tuple{Symbol, Int}, Float64}()
    effective_capacity::Float64 = 0.0
    labour_available::Float64 = 0.0
    labour_offered::Float64 = 0.0
    labour_sold::Float64 = 0.0
    labour_income::Float64 = 0.0        # net labour income this round
    last_wage_income::Float64 = 0.0     # last positive net labour income
    rent_income::Float64 = 0.0
    fee_received::Float64 = 0.0
    dividend_income::Float64 = 0.0
    share_ask::Float64 = 0.0            # posted ask per share unit when selling
    required_yield::Float64 = 0.01      # this person's required dividend yield per round (drawn once)
    unemployed_rounds::Int = 0          # consecutive rounds unemployed
    employed_rounds::Int = 0            # consecutive rounds employed (resets the fee counter after 3)
    fee::Float64 = 0.0                  # current unemployment fee entitlement
    land_let::Int = 0
    ate_this_round::Symbol = :none
    glutton::Bool = false               # hit by gluttony this round
    death_round::Int = 0
    initial_landowner::Bool = false
    gross_wage_this_round::Float64 = 0.0 # for the progressive schedule
    greed::Symbol = :none               # :none | :greedy (each act of greed: capital with greed_hoarding, consumption otherwise)
    worked_for::Set{Int} = Set{Int}()   # employers this round (a theatre worker is not served at their own theatre)
    buffer_lender::Bool = false         # opted into lending part of the buffer to the bank
    buffer_lent::Float64 = 0.0
    buffer_pledged::Float64 = 0.0       # demurrage-free buffer pledged to cooperatives (no money moves: the exemption does)
    labour_reserved::OrderedDict{Int, Float64} = OrderedDict{Int, Float64}()   # capacity held back for a worker cooperative that hires later in the round
    rebate_income::Float64 = 0.0        # consumer cooperative patronage rebate received this round (untaxed: a price reduction)
    wealth_tax_arrears::Float64 = 0.0   # wealth tax due but unpaid for want of cash; collected first from later cash
    income_tax_accrued::Float64 = 0.0   # income tax owed but not yet charged (income_tax_period > 1)
end

"""An enterprise: bank, farm, bakery or government. No capacity, no hunger."""
@agent struct Enterprise(NoSpaceAgent)
    kind::Symbol
    balance::Balance{Currency}
    alive::Bool = true
    land::Int = 0
    grain::Vector{StockItem} = StockItem[]
    bread::Vector{StockItem} = StockItem[]
    ask::OrderedDict{Symbol, Float64} = OrderedDict{Symbol, Float64}()
    bid::OrderedDict{Symbol, Float64} = OrderedDict{Symbol, Float64}()
    market::OrderedDict{Symbol, MarketRecord} = OrderedDict(g => MarketRecord() for g in GOODS)
    negotiated::OrderedDict{Tuple{Symbol, Int}, Float64} = OrderedDict{Tuple{Symbol, Int}, Float64}()
    production_target::Int = 0
    interest_rate::Float64 = 0.0
    retained_interest::Float64 = 0.0    # bank equity earned from interest, not yet paid out as wages
    reserved_cash::Float64 = 0.0
    hired_labour::Float64 = 0.0
    rented_land::Int = 0
    land_let::Int = 0
    wage_bill::Float64 = 0.0            # gross wages committed this round
    tax_collected::Float64 = 0.0        # government
    fees_paid::Float64 = 0.0            # government
    closed_round::Int = 0
    operating_net::Float64 = 0.0        # receipts − outlays this round: netted at clearing, or accumulated per payment with clearing off
    interest_paid::Float64 = 0.0        # this round
    interest_received::Float64 = 0.0    # banks, this round
    enterprise_tax_paid::Float64 = 0.0  # this round
    buffer_received::Float64 = 0.0      # bank: pooled buffers (demurrage-free)
    ownership::Symbol = :none           # producers: :none | :cooperative | :shareholders
    shares::OrderedDict{Int, Float64} = OrderedDict{Int, Float64}()   # holder id → share units (100 units per enterprise)
    dividend_history::Vector{Float64} = Float64[]        # total dividend paid per round
    net_history::Vector{Float64} = Float64[]             # operating net per round (for forward valuation)
    founder_ids::Vector{Int} = Int[]                     # the original shareholders (the control floor applies to them together)
    share_price::Float64 = 0.0          # last traded price per unit (book value until a trade)
    members::OrderedDict{Int, Int} = OrderedDict{Int, Int}()           # cooperative: member id → shares held (dividends are per member, not per share)
    paid_in_capital::Float64 = 0.0      # founders' capital (shareholders) or members' capital (cooperative)
    tier_multiplier::Float64 = 1.5      # bakery: price of loaves beyond the ration relative to the ordinary ask (tiered pricing)
    tier_sold::Int = 0                  # this round
    tier_unmet::Bool = false
    patronage_this_round::OrderedDict{Int, Float64} = OrderedDict{Int, Float64}()  # cooperative: member id -> hours worked / units bought this round
    patronage_log::Vector{OrderedDict{Int, Float64}} = OrderedDict{Int, Float64}[]  # the trailing patronage_window rounds
    membership_unpaid::OrderedDict{Int, Float64} = OrderedDict{Int, Float64}()      # worker cooperative: share capital still to be collected from wages
    member_since::OrderedDict{Int, Int} = OrderedDict{Int, Int}()                   # member id -> round of admission
    buffer_pledged::Float64 = 0.0       # cooperative: exemption pledged by its members (demurrage-free headroom)
    buffer_pledged_by::OrderedDict{Int, Float64} = OrderedDict{Int, Float64}()  # member id -> pledge, released on redemption
    retained_reserve::Float64 = 0.0     # cooperative: indivisible reserve, never distributed, not members' property
    rebate_per_unit::Float64 = 0.0      # consumer cooperative: expected rebate per unit bought (smoothed)
    refoundings::Int = 0                # times the firm has been sold as a going concern at a liquidation
    staff_target::Float64 = 1.0         # bank: labour units it employs (set at creation from bank_customers_per_labour_unit)
    revenue_period::Float64 = 0.0       # profit tax: sales since the last assessment (accrued at the sale)
    revenue_this_round::Float64 = 0.0   # sales this month (for the turnover in the liquidation test)
    turnover_history::Vector{Float64} = Float64[]   # the last three months' sales
    materials_period::Float64 = 0.0     # grain, rent and interest since the last assessment
    labour_period::Float64 = 0.0        # wages since the last assessment
    insurance_premiums::Float64 = 0.0   # bank: cumulative
    insurance_payouts::Float64 = 0.0    # bank: cumulative
end

const Agent = Union{Person, Enterprise}

is_person(a) = a isa Person
is_enterprise(a) = a isa Enterprise
is_bank(a) = a isa Enterprise && a.kind == :bank
is_farm(a) = a isa Enterprise && a.kind == :farm
is_bakery(a) = a isa Enterprise && a.kind == :bakery
is_government(a) = a isa Enterprise && a.kind == :government
is_authority(a) = a isa Enterprise && a.kind == :authority
is_producer(a) = a isa Enterprise && a.kind in (:farm, :bakery, :theatre)
is_theatre(a) = a isa Enterprise && a.kind == :theatre
kind_of(a) = a isa Person ? :person : a.kind

cash(a::Agent) = Float64(asset_value(a.balance, DEPOSIT))
available_cash(a::Person) = cash(a)
available_cash(a::Enterprise) = max(cash(a) - a.reserved_cash, 0.0)
debt_of(a::Agent) = Float64(liability_value(a.balance, DEBT))
deposits_created(a::Agent) = Float64(liability_value(a.balance, DEPOSIT))
loans_held(a::Agent) = Float64(asset_value(a.balance, DEBT))

stock_units(items::Vector{StockItem}) = sum(i.units for i in items; init = 0.0)
grain_units(a::Enterprise) = stock_units(a.grain)
bread_units(a::Agent) = stock_units(a.bread)

# Typed agent lists snapshotted at creation in the agent container's iteration order (nothing is added or removed
# after creation, the dead just stay flagged), so results are identical to iterating the container.
alive_agents(model) = Agent[a for a in model.agent_list if a.alive]
persons(model) = Person[a for a in model.person_list if a.alive]
enterprises(model, kind::Symbol) = Enterprise[a for a in model.enterprise_list if a.alive && a.kind == kind]
government(model) = first(enterprises(model, :government))

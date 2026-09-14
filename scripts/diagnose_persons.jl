# Person-level diagnostics: who dies, and what their wage / fee / credit / meal history looked like.
#   julia --project=. scripts/diagnose_persons.jl [seeds...]
# Writes results/persons_seed<S>.csv (per person per round) and results/deaths.csv (all seeds), prints summaries.
using BreadEconomySim, DataFrames, CSV, Statistics
const B = BreadEconomySim

# usage: diagnose_persons.jl [seeds...] [key=value ...]  (key=value pairs are SimulationParameters overrides)
parseval(v) = v in ("true", "false") ? parse(Bool, v) : occursin(".", v) ? parse(Float64, v) : parse(Int, v)
overrides = (; (Symbol(split(a, "=")[1]) => parseval(split(a, "=")[2]) for a in ARGS if occursin("=", a))...)
seedargs = [a for a in ARGS if !occursin("=", a)]
seeds = isempty(seedargs) ? collect(1:6) : parse.(Int, seedargs)
tag = isempty(overrides) ? "" : "_" * join(["$(k)=$(v)" for (k, v) in pairs(overrides)], "_")

function person_rows!(rows, m, r)
    ev = [e for e in m.events if e.round == r]
    refused = Dict{Int, Int}(); garn = Dict{Int, Float64}(); loans = Dict{Int, Float64}()
    for e in ev
        e.kind == :credit_refused && (refused[e.actor] = get(refused, e.actor, 0) + 1)
        e.kind == :garnishment && (garn[e.actor] = get(garn, e.actor, 0.0) + e.amount)
        e.kind == :loan && e.agent_kind == :person && (loans[e.actor] = get(loans, e.actor, 0.0) + e.amount)
    end
    for a in B.allagents(m)
        a isa Person || continue
        (a.alive || a.death_round == r) || continue
        push!(rows, (round = r, id = a.id, landowner = a.initial_landowner, land = a.land, alive = a.alive,
                     cash = round(B.cash(a), digits = 2), debt = round(B.debt_of(a), digits = 2),
                     in_arrears = B.has_arrears(m, a), capacity = a.capacity, effective_capacity = a.effective_capacity,
                     offered = a.labour_offered, sold = a.labour_sold, ask_wage = round(a.ask[:wage], digits = 2),
                     labour_income = round(a.labour_income, digits = 2), rent_income = round(a.rent_income, digits = 2),
                     fee = round(a.fee_received, digits = 2), unemployed_rounds = a.unemployed_rounds,
                     borrowed = round(get(loans, a.id, 0.0), digits = 2), refusals = get(refused, a.id, 0),
                     garnished = round(get(garn, a.id, 0.0), digits = 2),
                     meal = a.ate_this_round, hunger = a.hunger, bread_stock = B.bread_units(a)))
    end
end

deaths = NamedTuple[]
for s in seeds
    m = create_bread_economy(SimulationParameters(; seed = s, overrides...))
    rows = NamedTuple[]
    while !m.finished
        B.econo_step!(m, 1)
        person_rows!(rows, m, B.current_round(m) - 1)
    end
    df = DataFrame(rows)
    CSV.write(joinpath(@__DIR__, "..", "results", "persons_seed$(s)$(tag).csv"), df)
    rd = round_data(m)
    CSV.write(joinpath(@__DIR__, "..", "results", "rounds_seed$(s)$(tag).csv"), rd)
    for a in B.allagents(m)
        a isa Person && !a.alive || continue
        h = df[(df.id .== a.id) .& (df.round .< a.death_round), :]      # pre-death state (the death row is post-estate)
        last5 = h[max(1, nrow(h) - 4):end, :]
        starving = h[max(1, nrow(h) - 1):end, :]
        rr = rd[rd.round .>= a.death_round - 2, :][1:min(3, end), :]
        first_none = findfirst(==(:none), h.meal)
        push!(deaths, (seed = s, id = a.id, landowner = a.initial_landowner, death_round = a.death_round, of = nrow(rd),
                       rounds_employed = count(>(0), h.sold), rounds_unemployed = count(r -> r.offered > 0 && r.sold == 0, eachrow(h)),
                       first_no_meal = something(first_none, 0),
                       mean_wage_income_last5 = round(mean(last5.labour_income), digits = 2),
                       mean_fee_last5 = round(mean(last5.fee), digits = 2),
                       refusals_total = sum(h.refusals), refusals_last3 = sum(h.refusals[max(1, end - 2):end]),
                       ever_borrowed = sum(h.borrowed) > 0, debt_at_death = h.debt[end], cash_at_death = h.cash[end],
                       min_cash_starving = minimum(starving.cash), bread_price = round(rd.price_bread[a.death_round], digits = 2),
                       bread_baked_starving = join(string.(Int.(round.(rr.bread_baked))), ","), bread_unsold_starving = join(string.(Int.(round.(rr.bread_baked .- rr.bread_sold))), ","),
                       without_bread_starving = join(string.(rr.without_bread), ","),
                       arrears_at_death = h.in_arrears[end], garnished_total = round(sum(h.garnished), digits = 2),
                       meals_last3 = join(string.(h.meal[max(1, end - 1):end]), ",") * ",none",
                       capacity_at_death = h.capacity[end]))
    end
    println("seed $s: $(nrow(rd)) rounds, $(m.termination_reason); deaths by round: ",
            join(["$(r.round)→$(r.deaths)" for r in eachrow(rd) if r.deaths > 0], " "))
    # survivors at the end
    surv = df[(df.round .== nrow(rd)) .& df.alive, :]
    println("   survivors: ", join(["$(r.id)$(r.landowner ? "L" : "")(cash $(r.cash), land $(r.land))" for r in eachrow(surv)], "; "))
end
dd = DataFrame(deaths)
CSV.write(joinpath(@__DIR__, "..", "results", "deaths$(tag).csv"), dd)
println("\n=== deaths ($(nrow(dd))) ===")
show(stdout, dd; allrows = true, allcols = true); println()
println("\nlandowners dead: $(count(dd.landowner)) of $(nrow(dd)); ever borrowed: $(count(dd.ever_borrowed)); in arrears at death: $(count(dd.arrears_at_death))")
println("mean refusals (total / last 3): $(round(mean(dd.refusals_total), digits=1)) / $(round(mean(dd.refusals_last3), digits=1))")
println("mean wage income last 5: $(round(mean(dd.mean_wage_income_last5), digits=2)); mean fee last 5: $(round(mean(dd.mean_fee_last5), digits=2)); meal price 10")
println("rounds employed / unemployed before death: $(round(mean(dd.rounds_employed), digits=1)) / $(round(mean(dd.rounds_unemployed), digits=1))")

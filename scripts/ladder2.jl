include(joinpath(@__DIR__, "ladder2_rungs.jl"))
only_rung = length(ARGS) >= 5 ? ARGS[5] : ""
only_rung != "" && filter!(r -> startswith(r[1], only_rung), rungs)
path = joinpath(@__DIR__, "..", "results", SETTLEMENT == :invoicing ? "ladder2_$(N)_rounds.csv" : "ladder2_$(N)_$(SETTLEMENT)_rounds.csv")
done = isfile(path) ? Set(Tuple.(eachrow(unique(CSV.read(path, DataFrame; select = [:rung, :system, :seed]))))) : Set()
for (name, kd, ks) in rungs, (system, base, kw) in (("debt", BARE_DEBT, kd), ("sumsy", BARE_SUMSY, ks)), s in 1:nseeds
    (name, system, s) in done && continue
    (startswith(name, "X1") && system == "debt") && continue          # X rungs run one side only
    (startswith(name, "X2") && system == "sumsy") && continue
    m = run_simulation(SimulationParameters(; seed = s, base..., kw...)); d = round_data(m)
    d.rung .= name; d.system .= system; d.seed .= s; d.identity .= money_identity_gap(m)
    # append, never rewrite: rewriting a growing file on every run segfaulted the process on 21 September and left the
    # file truncated (rungs 4–12 and S1–S3 lost). All runs share one column set, so appending is safe.
    CSV.write(path, d; append = isfile(path), header = !isfile(path))
    println(name, " ", system, " seed ", s, " alive ", d.persons_alive[end]); flush(stdout)
end
println("DONE")

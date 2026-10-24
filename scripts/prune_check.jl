# ======================================================================================================================
# prune_check.jl — does pruning settled loans and indexing the loan accessors change any result? (24 October 2026)
#
#     julia --project=. scripts/prune_check.jl debt  [months]     # step 8, debt money, package T, seed 1 (default 36 months)
#     julia --project=. scripts/prune_check.jl sumsy [months]
#
# Runs the same village twice — `prune_settled_loans = false, index_loans = false` (the old behaviour) and both on — and
# compares every column of the results month by month, bit for bit, except the two audit columns that differ by design
# (loans_active, peer_loans_active). Also prints the wall time of each run and the loan lists' final lengths.
# ======================================================================================================================
using DataFrames
include(joinpath(@__DIR__, "ladder_definition.jl"))
system = length(ARGS) >= 1 ? ARGS[1] : "debt"; months = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 36
def = ladder_definition(512, months, :invoicing; fiscal = :taxes)
(name, kd, ks) = only(r for r in def.rungs if startswith(r[1], "8 "))
base, kw = system == "debt" ? (def.BARE_DEBT, kd) : (def.BARE_SUMSY, ks)
run_one(m; on) = (t = @elapsed(df = round_data(run_simulation(SimulationParameters(; seed = 1, base..., kw..., maximum_rounds = m, prune_settled_loans = on, index_loans = on)))); (df, t))
run_one(3; on = false); run_one(3; on = true)                       # compile both paths first
(old, t_old) = run_one(months; on = false)
(new, t_new) = run_one(months; on = true)
audit = (:loans_active, :peer_loans_active)
same(a, b) = length(a) == length(b) && all(isequal(x, y) for (x, y) in zip(a, b))
bad = [c for c in propertynames(old) if !(c in audit) && !same(old[!, c], new[!, c])]
first_off = isempty(bad) ? nothing : minimum(findfirst(i -> !isequal(old[i, c], new[i, c]), 1:min(nrow(old), nrow(new))) for c in bad)
println("PRUNE CHECK ", name, " | ", system, " | ", months, " months: ", isempty(bad) ? "IDENTICAL in all $(ncol(old) - length(audit)) result columns" : "DIFFERS in $bad, first at month $first_off")
println("  wall time: old $(round(t_old, digits = 1)) s, new $(round(t_new, digits = 1)) s (", round(t_old / t_new, digits = 2), "× faster); final loan lists: old ", old.loans_active[end], " + ", old.peer_loans_active[end], " peer, new ", new.loans_active[end], " + ", new.peer_loans_active[end], " peer, of ", new.loans_issued[end], " + ", new.peer_loans_issued[end], " issued")

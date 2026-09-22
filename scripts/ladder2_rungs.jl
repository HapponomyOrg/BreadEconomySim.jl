# The ladder's definitions (rules, the two base villages, the rungs). Included by ladder2.jl (runs) and dump_rungs.jl (documents).
using BreadEconomySim, DataFrames, CSV, Statistics
include(joinpath(@__DIR__, "ladder_definition.jl"))

nseeds = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 6
rounds = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 50

# Behaviour rules needed for any village to function at all (Section 5 of the report); not components.
N = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 512
# 22 September: the base village is 512 villagers over 120 months (a round is a month: ten years) with the same twelve firms —
# four farms, four bakeries and (from rung 7) four theatres — so that the poorest tenth is 51 people and the rich–poor gap is not
# one family's fortune. Founders stay four a firm (48 owners, 9 % of the village: ownership concentration as in reality, and a
# test of what SuMSy does with it). Starting targets scale with the village (10 a firm per 128 villagers). The 128-villager
# ladder is the size comparison. SETTLEMENT=clearing_all runs the old settlement for the before/after comparison.
SETTLEMENT = Symbol(get(ENV, "SETTLEMENT", "invoicing"))
(; BARE_DEBT, BARE_SUMSY, rungs) = ladder_definition(N, rounds, SETTLEMENT)

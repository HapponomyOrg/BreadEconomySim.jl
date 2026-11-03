# The planning ablation study (coder brief of 1 November 2026, task 3; Stef, 3 November): the realistic set's planning
# rules switched off one at a time, on a few cells and seeds, each variant written as a ladder-style folder so that
# `scripts/stylized_facts.py` scores it and `scripts/paired_tests.py` compares the villages.
#
#     include("scripts/planning_ablation.jl")
#     ablation()                                   # the defaults below: 3 cells × 2 villages × 4 seeds × 7 variants, 120 months
#     ablation(cells = ["8 "], seeds = 1:2, variants = [:base, :no_contracts], months = 120)
#
# Then, per variant folder (e.g. results/parts/ablation_2026-11-03.3_no_contracts):
#     python3 scripts/stylized_facts.py results/parts/ablation_<version>_<variant>
#     python3 scripts/paired_tests.py   results/parts/ablation_<version>_<variant>
# and compare the variants' summaries side by side: the measures the brief names first are `ac1_gdp` (the oscillation:
# −0.31 at step 11 on the .3 runs against about +0.85 in the data), `sd_gdp`, `rel_sd_unemp`, `mean_unemp`, and the count
# of liquidations and hungry months per run (in `ablation_<version>_<variant>_runs.csv`, written here).
#
# The variants (each one rule of the realistic set turned off, or one remedy turned on, against the base):
#   :base               the ladder's base as it stands
#   :no_turned_away     respond_to_turned_away = false       (firms do not plan on customers turned away)
#   :no_bake_to_target  bakeries_bake_to_target = false
#   :no_expected_sales  price_on_expected_sales = false, price_rise_band = false   (the older pricing)
#   :no_contracts       supply_contracts = false              (3 Nov: the farms back on their own guess of the market)
#   :no_storage         grain_spoilage_age_in_rounds = 0      (grain spoils like bread, 3 months)
#   :partial            plan_adjustment_share = 0.5           (half the way to the plan each month)
# Runs are sequential (one process); 168 runs of 120 months take a working day on a laptop — run a subset first.

include(joinpath(@__DIR__, "run_all.jl"))
using CSV, DataFrames

const ABLATION_VARIANTS = Dict(
    :base => (;),
    :no_turned_away => (; respond_to_turned_away = false),
    :no_bake_to_target => (; bakeries_bake_to_target = false),
    :no_expected_sales => (; price_on_expected_sales = false, price_rise_band = false),
    :no_contracts => (; supply_contracts = false),
    :no_storage => (; grain_spoilage_age_in_rounds = 0),
    :partial => (; plan_adjustment_share = 0.5),
)

function ablation(; cells = ["8 ", "B ", "V8 "], seeds = 1:4, variants = collect(keys(ABLATION_VARIANTS)), months = 120, villagers = 512)
    def = ladder_definition(villagers, months, :invoicing)
    for var in variants
        extra = ABLATION_VARIANTS[var]
        folder = joinpath(@__DIR__, "..", "results", "parts", "ablation_$(MODEL_VERSION)_$(var)"); mkpath(folder)
        runs = DataFrame()
        for cell in cells
            (name, kd, ks) = only(r for r in def.rungs if startswith(r[1], cell))
            slug = replace(strip(name), r"[^A-Za-z0-9]+" => "_")
            for (sysn, base, kw) in (("debt", def.BARE_DEBT, kd), ("sumsy", def.BARE_SUMSY, ks)), seed in seeds
                isempty(kw) && continue
                file = joinpath(folder, "$(slug)__$(sysn)__$(seed).csv")
                isfile(file) && continue                                      # resume: skip what is written
                m = run_simulation(SimulationParameters(; seed, base..., kw..., REALISTIC_LABOUR..., extra...))
                d = round_data(m); d.rung .= name; d.system .= sysn; d.seed .= seed
                CSV.write(file, d)
                push!(runs, (variant = String(var), rung = name, system = sysn, seed = seed, alive = d.persons_alive[end],
                             liquidations = count(e -> e.kind == :liquidation, m.events), hungry_months = count(i -> d.hungry[i] > 0.3 * d.persons_alive[i], 1:nrow(d)),
                             bread_y10 = d.price_bread[end], unemployed_y10 = d.unemployed[end]); promote = true)
                println("ablation ", var, " ", strip(name)[1:min(end, 12)], " ", sysn, " seed ", seed, ": alive ", d.persons_alive[end], ", liquidations ", runs.liquidations[end], ", hungry months ", runs.hungry_months[end])
            end
        end
        isempty(runs) || CSV.write(joinpath(@__DIR__, "..", "results", "ablation_$(MODEL_VERSION)_$(var)_runs.csv"), runs)
    end
    return nothing
end

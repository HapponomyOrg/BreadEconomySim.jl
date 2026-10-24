# ======================================================================================================================
# talk_run.jl — every run the talk ("A simulated economy: what it takes to survive") needs, on ONE code version (24 Oct 2026)
#
# Unpack one package, run this, and do not unpack a newer package until it has finished: every folder then carries the same
# version in its name (…_2026-10-24.9 with this package) and the talk's numbers all come from the same code. The last block
# lists the folders of this version with their run counts, so you can see that nothing is missing.
#
#     include("scripts/talk_run.jl")                              # everything on one machine (344 runs)
#     TALK_PART = :taxes;   include("scripts/talk_run.jl")        # machine 1: the income-tax package — the talk's tables (184 runs)
#     TALK_PART = :parking; include("scripts/talk_run.jl")        # machine 2: the parking package — the Q&A (160 runs)
#     TALK_JOBS = 15                                              # set before the include to choose the number of workers
#
# Executing the file from the editor (VS Code: Julia: Execute File) works too, whatever the REPL's working directory: the file
# finds scripts/run_all.jl next to itself, in the working directory, or at Stef's repository path, and run_all.jl activates the
# project. TALK_PART and TALK_JOBS keep the value they had in the session; set them in the REPL before executing to change them.
#
# Finished runs are skipped, so an interrupted call is resumed by including the file again. Afterwards, the paired tests per
# folder (counts, not significance, at four seeds): `python scripts/paired_tests.py results/parts/<folder>` for each folder.
# ======================================================================================================================
talk_scripts = let candidates = [@__DIR__, joinpath(pwd(), "scripts"), pwd(), "/Users/stef/Programming/Visual Studio/BreadEconomySim.jl/scripts"]
    i = findfirst(d -> isfile(joinpath(d, "run_all.jl")) && isfile(joinpath(d, "ladder_definition.jl")), candidates)
    i === nothing && error("talk_run.jl: cannot find scripts/run_all.jl — looked in " * join(unique(candidates), ", ") * ". Open the BreadEconomySim.jl folder, or cd() into it, and run again.")
    candidates[i]
end
println("talk_run.jl: scripts in ", talk_scripts)
include(joinpath(talk_scripts, "run_all.jl"))
isdefined(Main, :TALK_PART) || (global TALK_PART = :all)
isdefined(Main, :TALK_JOBS) || (global TALK_JOBS = max(Sys.CPU_THREADS ÷ 2, 1))   # physical cores, roughly
TALK_PART in (:all, :taxes, :parking) || error("TALK_PART must be :all, :taxes or :parking")

# the talk's cells: the bare village, the government, shares, VAT, the productive village, the best village, with gold, everyone
# greedy, and the best village with the land tax kept as revenue. Step 0 has no government, so it runs under one package only.
# Plus the debt-money cells that employ everyone, by paying everyone (for the Q&A): DGI8 (a basic income of 5 in debt money),
# DDGL8 (debt money given SuMSy's arrangement) — both debt village only — and RV8 (the income halved from month 60, both villages).
# Under a package their taxes are the package's (as in the 22.13 runs these figures came from); the basic income is a money setting and stays.
talk_employ_all    = ["DGI8", "DDGL8 ", "RV8 "]
talk_rungs_taxes   = vcat(["0 ", "2 ", "8 ", "11 ", "V8 ", "B ", "BG", "SB2", "B-nodiv"], talk_employ_all)
talk_rungs_parking = vcat(["2 ", "8 ", "11 ", "V8 ", "B ", "BG", "SB2", "B-nodiv"], talk_employ_all)
realistic_levybase = merge(REALISTIC_LABOUR, (; levy_dividend_target_in_breads = 0.0))   # Q&A: the land tax at its base rate, paid out (no lever)

if TALK_PART in (:all, :taxes)
    # 1. the talk's main tables: the realistic labour market (contracts, own-market planning, …), income taxes        88 runs
    run_all(seeds = 4, jobs = TALK_JOBS, fiscal = :taxes, rungs = talk_rungs_taxes, variant = REALISTIC_LABOUR, variant_label = "realistic")
    # 2. the same cells on the base labour market, for "what the realistic rules change"                              88 runs
    run_all(seeds = 4, jobs = TALK_JOBS, fiscal = :taxes, rungs = talk_rungs_taxes)
    # 3. Q&A: does paying out the land tax reduce the debt village's borrowing? (with B and B-nodiv above)               8 runs
    run_all(seeds = 4, jobs = TALK_JOBS, fiscal = :taxes, rungs = ["B "], variant = realistic_levybase, variant_label = "realistic_levybase")
end

if TALK_PART in (:all, :parking)
    # 4. Q&A: the same cells under the tax on idle money (a meal for everyone; no separate benefit)                    80 runs
    run_all(seeds = 4, jobs = TALK_JOBS, fiscal = :parking, rungs = talk_rungs_parking, variant = REALISTIC_LABOUR, variant_label = "realistic")
    # 5. and on the base labour market                                                                                 80 runs
    run_all(seeds = 4, jobs = TALK_JOBS, fiscal = :parking, rungs = talk_rungs_parking)
end

# what this version has produced so far: one line per folder, with its run count
let parts = joinpath(talk_scripts, "..", "results", "parts")
    println("\nfolders on version $(MODEL_VERSION):")
    for d in sort(readdir(parts))
        endswith(d, MODEL_VERSION) || continue
        println("  ", d, ": ", count(f -> endswith(f, ".csv"), readdir(joinpath(parts, d))), " runs")
    end
end

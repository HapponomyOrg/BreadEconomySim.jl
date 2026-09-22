# Running the 512-villager ladder on your own machine

The container used in the chat sessions is suspended between messages, and a background job only advances while a message is being answered. The ladder needs about 460 runs of one to two minutes each, per settlement system — so it has to run on a machine that stays on.

Requirements: Julia 1.12, this repository, and EconoSim.jl checked out next to it (the Manifest points at `../EconoSim.jl`; adjust with `] dev ../EconoSim.jl` if your layout differs).

    cd BreadEconomySim.jl
    julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
    julia --project=. test/runtests.jl                           # 497 tests, ~2 minutes

    # everything: tests, the 512 ladder under both settlements, the 128 ladder, summaries and panel tables
    julia --project=. scripts/run_all.jl

    # a quick check first, if you like (a few minutes)
    SEEDS=1 ROUNDS=6 LADDERS=128:invoicing RUNGS=0,2 SKIP_TESTS=1 julia --project=. scripts/run_all.jl

`run_all.jl` uses all but one of your CPU threads (`JOBS=` to change), saves each run as its own file under `results/parts/`, and can be stopped and restarted at will. The header of the script lists every setting. The older one-ladder commands still work:

    # the new settlement (invoicing) — results/ladder2_512_rounds.csv
    julia --project=. -O1 scripts/ladder2.jl 10 120 all 512
    # the old settlement, for the before/after comparison — results/ladder2_512_clearing_all_rounds.csv
    SETTLEMENT=clearing_all julia --project=. -O1 scripts/ladder2.jl 10 120 all 512

Both are resumable: stop and restart at will, finished runs are skipped. On a machine with several cores, run them side by side, or split one ladder by rung with the fifth argument (a rung-name prefix), e.g. `... all 512 "1"` in one terminal and `... all 512 "S"` in another — every process appends to the same file, so do not start two processes on the *same* rung.

The "what is there" panels come from `julia --project=. scripts/dump_rungs.jl 10 120 all 512`; the report page from `python3 scripts/build_report_html.py` once the CSVs are in `results/`.

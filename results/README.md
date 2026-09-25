# Results

This folder holds the output of the current model version only (`MODEL_VERSION` in `scripts/run_all.jl`). Earlier results were removed on 25 September 2026; they remain in the Git history and belong to superseded models.

What `julia --project=. scripts/run_all.jl` writes here:
- `parts/<ladder>_<months>months_<model version>/` — one CSV per run, written the moment the run finishes; this is what makes the script resumable. Keep only the folders of the current model version; older folders are runs on superseded models.
- `ladder2_<N>_rounds.csv` (or `…_rounds_part1.csv`, `…_part2.csv`, … when over 90 MB, cut between runs; GitHub refuses files over 100 MB) — every month of every run, combined. Read either form with `read_split` in `scripts/run_all.jl`.
- `ladder2_<N>_summary.csv` — one row per step and village: survivors, runs whole and collapsed, unemployment, tickets, bread price, public debt and its course, the Ginis, the rich–poor gap in meals with the poorest tenth's holding, under water, without cash, liquidations, bailouts, land held by households.
- `ladder2_<N>_rungs.csv` — what each step contains (the report's "what is there" panels).
- `ladder2_512_clearing_all_*` — the same ladder under the old settlement, for comparison.

The summaries and step tables can always be rebuilt from `parts/` without rerunning: `SKIP_TESTS=1 julia --project=. scripts/run_all.jl`.

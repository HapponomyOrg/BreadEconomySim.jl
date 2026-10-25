# Handover to the code chat: the talk's cells without co-ops

*25 October 2026, from the talk chat. The talk is today. Stef has decided to take the co-operatives out of the talk completely.*

---

## 1. Why

The talk's main cells are rung B and its variants (BG, SB2, B-nodiv). All four have `ownership = :mixed` and `cooperative_theatres = 2`: half the farms, bakeries and theatres are co-ops. Their co-op-free versions are step 10 and its variants.

## 2. Two new rungs

Add these to `ladder_definition.jl`, next to BG and B-nodiv. Each one is a copy of an existing rung with only the co-op settings dropped, the same on both sides.

| New rung | Copy of | What to drop |
|---|---|---|
| `10G step 10 with gold` | `BG` | `cooperative_theatres = 2` and `ownership = :mixed` (step 10's `:shareholders` stays) |
| `10-nodiv step 10, the land tax kept as revenue` | `B-nodiv` | the same two settings; keep whatever makes B-nodiv keep the land tax as revenue |

Keep the names as above. The run calls below match by prefix:

- `"10 "` (with the space) matches only `10 + government reserve`;
- `"10G"` and `"10-nodiv"` match only themselves;
- `"S3 "` matches only `S3 step 10 + everyone greedy`.

## 3. The runs (realistic set, income taxes, four seeds, the current version)

```julia
include("scripts/run_all.jl")
run_all(seeds = 4, fiscal = :taxes, rungs = ["10 ", "10G", "S3 ", "10-nodiv"], variant = REALISTIC_LABOUR, variant_label = "realistic")
run_all(summary_only = true, fiscal = :taxes, variant = REALISTIC_LABOUR, variant_label = "realistic")
```

That is 4 rungs × 2 villages × 4 seeds = **32 jobs**.

- **Version.** If adding the two rungs leaves the model code unchanged, the folder stays on `2026-10-24.13`, next to the talk's other cells. If `MODEL_VERSION` has to move, also rerun step 0 on the new version (`"0 "`, 8 jobs), so that every slide is on one version.
- **Optional, only if there is time:** the same four rungs under `fiscal = :parking`, for the Q&A. Another 32 jobs.

## 4. Report back (a new §4l in `handoff_talk_2026-10-22.md`)

For each of the four cells, both villages:

- alive (mean and worst);
- public debt at month 120, its peak, and the month repaid;
- the poorest tenth's money and wealth in meals;
- the three Ginis (money, wealth, wealth with gold);
- work looked for and not found (as a share of capacity, as in §4k);
- unemployed;
- bread price change per year;
- tickets;
- land tax paid out over ten years.

Give the folder name of the part files for `10` (the public-debt chart).

Add one line per cell: the same figures with co-ops (B, BG, SB2, B-nodiv on `.13`) beside the figures without, so the talk can see what the co-ops were doing.

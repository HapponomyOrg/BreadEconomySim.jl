#!/bin/bash
# 12 October 2026: remove the SuMSy part files of the cells where the reserve block had overridden the land dividend,
# so that `julia --project=. scripts/run_all.jl` reruns only them (260 runs) and rebuilds the summaries.
cd "$(dirname "$0")/../results/parts/ladder2_512_120months_2026-09-27" || exit 1
for p in "10_government_reserve" "11_fiscal_policy" "S1_" "S2_" "S3_" "S4_" "B_best_SuMSy" "SB1_" "SB2_" "E10_" "EB_" "L2_" "G10_" "N10_" "NB_" "P10_" "UP8_" "T10_" "GP10_" "X1_"; do
  rm -f ${p}*__sumsy__*.csv
done
ls | grep -c csv

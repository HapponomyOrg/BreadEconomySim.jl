run_all(seeds = 4, fiscal = :parking, rungs = ["B ", "BG", "SB2"], variant_label = "B_parking");
run_all(seeds = 4, fiscal = :parking, rungs = ["B ", "BG", "SB2"], variant = REALISTIC_LABOUR, variant_label = "B_realistic_parking");
run_all(seeds = 4, fiscal = :taxes,   rungs = ["B ", "BG", "SB2"], variant_label = "B_taxes");
run_all(seeds = 4, fiscal = :taxes,   rungs = ["B ", "BG", "SB2"], variant = REALISTIC_LABOUR, variant_label = "B_realistic_taxes");
run_all(seeds = 4, fiscal = :taxes,   rungs = ["1 "], variant = OWN_PLANNING, variant_label = "1_ownplan_taxes");
run_all(seeds = 4, fiscal = :taxes,   rungs = ["V8 "], variant_label = "V8_taxes");
run_all(seeds = 4, fiscal = :parking, rungs = ["V8 "], variant_label = "V_8_parking");
run_all(seeds = 4, fiscal = :taxes, rungs = ["V8 "], variant = (; customers_per_labour_unit = 1.0), variant_label = "V8_full")
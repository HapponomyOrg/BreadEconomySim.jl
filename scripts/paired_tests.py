"""Paired tests between the debt and SuMSy villages, seed by seed (roadmap step 3, 18 October 2026; on time averages since the
coder brief of 1 November 2026, task 2).

    python3 scripts/paired_tests.py results/parts/ladder2_512_120months_<version> [--from-month 25]

For every rung run on both sides: the Wilcoxon signed-rank test on the paired differences (same seed, same village, different
money) for each measure, with Holm's correction over the rungs in HEADLINE. Two kinds of measure (the `basis` column):
  end    the last month — `persons_alive` (deaths accumulate), `government_debt` (a stock whose end value is the finding);
  mean   the mean over the months from --from-month (default 25, the first two years being burn-in) to the end —
         `unemployed`, `wealth_gap_meals`, `wealth_bottom10_meals`; one month's value carried a six-month swing of
         35–149 unemployed into every test (step 11, realistic, seed 1, months 37–42);
  trend  `infl_annual`, the annualised growth of `price_bread` from --from-month to the end, replacing the price level,
         which mixed level and drift.
Pairs where either village ends below half its starting population are kept (collapse is an outcome) and counted in
`collapsed_pairs`. `p_min_holm` is the smallest p Holm could return for that n and the number of headline rungs
(with 10 pairs and 13 rungs about 0.025): a result just under 0.05 needs every pair to agree. Four seeds at least.
Writes results/<ladder>_paired_tests_from<month>.csv and prints the headline rows.
"""
import argparse, os, sys
import numpy as np, pandas as pd
from scipy.stats import wilcoxon

END = ['persons_alive', 'government_debt']
MEAN = ['unemployed', 'wealth_gap_meals', 'wealth_bottom10_meals']
MEASURES = END + MEAN + ['infl_annual']
BASIS = {**{m: 'end' for m in END}, **{m: 'mean' for m in MEAN}, 'infl_annual': 'trend'}
HEADLINE = ['0 bare', '2 government', '5 ', '8 share', '11 ', 'V8 productive', 'S3 step', 'DGI8', 'RV8', 'T8 ', 'A8 ', 'NJ8', 'PL8 step']


def summarise_run(df, from_month):
    """The measures of one run from its monthly data frame."""
    kept = df[df['round'] >= from_month]
    if kept.empty: kept = df.iloc[[-1]]
    out = {m: float(df[m].iloc[-1]) for m in END}
    out.update({m: float(kept[m].mean()) for m in MEAN})
    p0, p1 = float(kept['price_bread'].iloc[0]), float(kept['price_bread'].iloc[-1]); months = len(kept) - 1
    out['infl_annual'] = 100 * ((p1 / p0) ** (12 / months) - 1) if months > 0 and p0 > 0 and p1 > 0 else np.nan
    out['collapsed'] = bool(df['persons_alive'].iloc[-1] < 0.5 * df['persons_alive'].iloc[0])
    return out


def paired_tests(folder, from_month):
    files = [f for f in os.listdir(folder) if f.endswith('.csv')]
    rows = {}
    for f in files:
        step, system, seed = f[:-4].rsplit('__', 2)
        df = pd.read_csv(os.path.join(folder, f), usecols=['round', 'price_bread'] + END + MEAN)
        rows.setdefault(step, {}).setdefault(system, {})[int(seed)] = summarise_run(df, from_month)
    out = []
    for step, sides in rows.items():
        if 'debt' not in sides or 'sumsy' not in sides: continue
        seeds = sorted(set(sides['debt']) & set(sides['sumsy']))
        collapsed = int(sum(sides['debt'][s]['collapsed'] or sides['sumsy'][s]['collapsed'] for s in seeds))
        for mcol in MEASURES:
            a = np.array([sides['debt'][s][mcol] for s in seeds], float); b = np.array([sides['sumsy'][s][mcol] for s in seeds], float)
            ok = ~(np.isnan(a) | np.isnan(b)); a, b = a[ok], b[ok]
            if len(a) < 4: continue                                    # 22 Oct: four seeds give counts, not significance (the exact two-sided p is at least 0.125)
            diff = b - a
            if np.allclose(diff, 0): p = 1.0
            else:
                try: p = wilcoxon(b, a, zero_method='wilcox', alternative='two-sided', method='exact').pvalue
                except ValueError: p = wilcoxon(b, a, alternative='two-sided').pvalue
            out.append(dict(rung=step, measure=mcol, basis=BASIS[mcol], from_month=from_month, n=len(a), collapsed_pairs=collapsed,
                            debt_mean=a.mean(), sumsy_mean=b.mean(), debt_median=np.median(a), sumsy_median=np.median(b), diff_median=np.median(diff),
                            pairs_sumsy_higher=int((diff > 0).sum()), pairs_debt_higher=int((diff < 0).sum()), p=p))
    res = pd.DataFrame(out)
    if res.empty: return res
    res['headline'] = res.rung.apply(lambda r: any(r.startswith(h.replace(' ', '_')) for h in HEADLINE))
    res['p_holm'] = np.nan; res['p_min_holm'] = np.nan
    for mcol in MEASURES:
        sel = res[(res.measure == mcol) & res.headline].sort_values('p')
        m = len(sel); holm = []
        for k, (i, r) in enumerate(sel.iterrows()):
            holm.append(min(1.0, (m - k) * r.p))
        holm = np.maximum.accumulate(holm) if holm else holm
        res.loc[sel.index, 'p_holm'] = holm
        res.loc[sel.index, 'p_min_holm'] = [min(1.0, m * 2.0 ** (1 - r.n)) for _, r in sel.iterrows()]   # the exact two-sided minimum 2^(1-n), times m under Holm
    return res


def selfcheck():
    """Fake runs in a temporary folder (four seeds a side, the test's minimum): the means and end values must match hand-computed ones."""
    import tempfile
    tmp = tempfile.mkdtemp()
    for sysn, base in (('debt', 100.0), ('sumsy', 200.0)):
        for seed in (1, 2, 3, 4):
            n = 30; r = np.arange(1, n + 1)
            df = pd.DataFrame(dict(round=r, persons_alive=512 - r, government_debt=base * r, unemployed=r + seed, price_bread=np.full(n, 2.0) * (1.01 ** r),
                                   wealth_gap_meals=np.full(n, 10.0 + seed), wealth_bottom10_meals=np.full(n, 1.0)))
            df.to_csv(os.path.join(tmp, f'X__{sysn}__{seed}.csv'), index=False)
    res = paired_tests(tmp, 25)
    ok = True
    r = res[res.measure == 'unemployed'].iloc[0]; good = abs(r.debt_mean - np.mean([np.mean(range(25 + sd, 31 + sd)) for sd in (1, 2, 3, 4)])) < 1e-9; print("mean of unemployed over months 25-30, by hand:", good); ok &= good
    r = res[res.measure == 'government_debt'].iloc[0]; good = abs(r.debt_mean - 3000.0) < 1e-9 and abs(r.sumsy_mean - 6000.0) < 1e-9; print("end value of public debt:", good); ok &= good
    r = res[res.measure == 'infl_annual'].iloc[0]; good = abs(r.debt_mean - 100 * (1.01 ** 12 - 1)) < 1e-6; print("annualised price trend 1 %/month:", good); ok &= good
    print("basis column:", dict(res.groupby('measure').basis.first()))
    print("SELFCHECK", "PASSED" if ok else "FAILED"); return ok


if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('folder', nargs='?'); ap.add_argument('--from-month', type=int, default=25); ap.add_argument('--selfcheck', action='store_true')
    a = ap.parse_args()
    if a.selfcheck: sys.exit(0 if selfcheck() else 1)
    if not a.folder: ap.error("a ladder folder is needed (or --selfcheck)")
    d = a.folder.rstrip('/')
    res = paired_tests(d, a.from_month)
    if res.empty: print('no rung has both villages with at least four common seeds in', d); sys.exit(0)
    name = os.path.basename(d).split('_120months')[0]
    outp = f'results/{name}_paired_tests_from{a.from_month}.csv'; os.makedirs('results', exist_ok=True); res.to_csv(outp, index=False)
    print("wrote", outp, len(res), "rows")
    for mcol in ('persons_alive', 'government_debt', 'wealth_bottom10_meals', 'unemployed', 'infl_annual'):
        print(f"\n{mcol} ({BASIS[mcol]}): rung | debt | SuMSy | pairs SuMSy higher / debt higher | collapsed pairs | p (Holm; floor)")
        for _, r in res[(res.measure == mcol) & res.headline].iterrows():
            print(f"  {r.rung[:34]:34s} {r.debt_median:9.2f} {r.sumsy_median:9.2f}   {r.pairs_sumsy_higher:2d} / {r.pairs_debt_higher:2d}   {r.collapsed_pairs:2d}   {r.p:.3f} ({r.p_holm:.3f}; {r.p_min_holm:.3f})")

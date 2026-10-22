"""Paired tests between the debt and SuMSy villages, seed by seed (roadmap step 3, 18 October 2026).
   For every rung run on both sides: the Wilcoxon signed-rank test on the paired differences (same seed, same village, different
   money) for each measure, with Holm's correction over the rungs in HEADLINE. Writes results/<ladder>_paired_tests.csv and prints
   the headline rows. Ten seeds give an exact two-sided p of at least 0.002 (all ten pairs the same way); with ten pairs the test
   cannot see a difference smaller than the spread, and the report says so where it quotes these.
   python3 scripts/paired_tests.py results/parts/ladder2_512_120months_<version>"""
import pandas as pd, numpy as np, os, sys
from scipy.stats import wilcoxon
d = sys.argv[1].rstrip('/') + '/'; files = [f for f in os.listdir(d) if f.endswith('.csv')]
MEASURES = ['persons_alive', 'unemployed', 'price_bread', 'government_debt', 'wealth_gap_meals', 'wealth_bottom10_meals']
HEADLINE = ['0 bare', '2 government', '5 ', '8 share', '11 ', 'V8 productive', 'S3 step', 'DGI8', 'RV8', 'T8 ', 'A8 ', 'NJ8', 'PL8 step']
rows = {}
for f in files:
    step, system, seed = f[:-4].rsplit('__', 2)
    x = pd.read_csv(d + f, usecols=['round', 'persons_alive'] + MEASURES[1:]).iloc[-1]
    rows.setdefault(step, {}).setdefault(system, {})[int(seed)] = x
out = []
for step, sides in rows.items():
    if 'debt' not in sides or 'sumsy' not in sides: continue
    seeds = sorted(set(sides['debt']) & set(sides['sumsy']))
    for mcol in MEASURES:
        a = np.array([sides['debt'][s][mcol] for s in seeds], float); b = np.array([sides['sumsy'][s][mcol] for s in seeds], float)
        ok = ~(np.isnan(a) | np.isnan(b)); a, b = a[ok], b[ok]
        if len(a) < 4: continue                                        # 22 Oct: four seeds give counts, not significance (the exact two-sided p is at least 0.125)
        diff = b - a
        if np.allclose(diff, 0): p = 1.0
        else:
            try: p = wilcoxon(b, a, zero_method='wilcox', alternative='two-sided', method='exact').pvalue
            except ValueError: p = wilcoxon(b, a, alternative='two-sided').pvalue
        out.append(dict(rung=step, measure=mcol, n=len(a), debt_mean=a.mean(), sumsy_mean=b.mean(), debt_median=np.median(a), sumsy_median=np.median(b), diff_median=np.median(diff), pairs_sumsy_higher=int((diff > 0).sum()), pairs_debt_higher=int((diff < 0).sum()), p=p))
res = pd.DataFrame(out)
if res.empty: print('no rung has both villages with at least four common seeds in', d); sys.exit(0)
# Holm over the headline rungs, per measure
res['headline'] = res.rung.apply(lambda r: any(r.startswith(h.replace(' ', '_')) for h in HEADLINE))
res['p_holm'] = np.nan
for mcol in MEASURES:
    sel = res[(res.measure == mcol) & res.headline].sort_values('p')
    m = len(sel); holm = []
    for k, (i, r) in enumerate(sel.iterrows()):
        holm.append(min(1.0, (m - k) * r.p))
    holm = np.maximum.accumulate(holm) if holm else holm
    res.loc[sel.index, 'p_holm'] = holm
name = os.path.basename(d.rstrip('/')).split('_120months')[0]
outp = f'results/{name}_paired_tests.csv'; res.to_csv(outp, index=False)
print("wrote", outp, len(res), "rows")
for mcol in ('persons_alive', 'government_debt', 'wealth_bottom10_meals'):
    print(f"\n{mcol}: rung | debt median | SuMSy median | pairs SuMSy higher / debt higher | p (Holm)")
    for _, r in res[(res.measure == mcol) & res.headline].iterrows():
        print(f"  {r.rung[:34]:34s} {r.debt_median:9.1f} {r.sumsy_median:9.1f}   {r.pairs_sumsy_higher:2d} / {r.pairs_debt_higher:2d}   {r.p:.3f} ({r.p_holm:.3f})")

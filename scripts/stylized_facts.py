"""Business-cycle and distribution facts per run, scored against empirical values (coder brief of 1 November 2026, task 1;
roadmap step 11, item 1).

    python3 scripts/stylized_facts.py results/parts/<ladder folder> [--from-month 25] [--rungs "11_,V8_"] [--lambda 1600]
    python3 scripts/stylized_facts.py --selftest

Reads the per-run files `<step>__<system>__<seed>.csv`, drops the burn-in, aggregates to quarters, takes cyclical components
with a Hodrick–Prescott filter (scipy.sparse, no statsmodels), computes the measures per run, then per rung × system the
count, the number of collapsed runs (excluded from the medians), the median, the quartiles and a score — matched, partly,
failed — from the median. Writes two files beside the ladder folder:
  results/<ladder>_stylized_facts_runs.csv   one row per run
  results/<ladder>_stylized_facts.csv        per rung × system
Targets marked approx. in TARGETS come from general knowledge; confirm them before quoting a score. The SuMSy village is
scored the same way, labelled "for comparison": it need not reproduce debt-money facts.
"""
import argparse, glob, math, os, sys
import numpy as np, pandas as pd
import scipy.sparse as sp
import scipy.sparse.linalg as spla

FLOWS = ['gdp_in_loaves', 'gdp_consumption', 'bread_sold']
STOCKS = ['unemployed', 'persons_alive', 'price_bread', 'outstanding_debt', 'bread_stocked']
NEEDED = ['round'] + FLOWS + STOCKS + ['gini_net_wealth_persons']

# measure: (target text, matched test, partly test, source) — tests take the median
TARGETS = {
    'sd_gdp':          ('about 1.5 %',          lambda m: 1.0 <= m <= 2.5,   lambda m: 0.5 <= m <= 4.0,   'US post-war, approx.'),
    'rel_sd_cons':     ('0.80',                 lambda m: 0.6 <= m <= 1.0,   lambda m: 0.4 <= m <= 1.2,   'Carlin and Soskice 2015, via Caiani et al. 2016'),
    'rel_sd_unemp':    ('8.2',                  lambda m: 5 <= m <= 14,      lambda m: 3 <= m <= 20,      'same; Caiani: 13.3'),
    'corr_gdp_unemp':  ('strongly negative',    lambda m: m <= -0.6,         lambda m: m < 0,             'FRED, via Caiani et al.'),
    'unemp_lag':       ('+1 (unemployment lags)', lambda m: m == 1,          lambda m: m == 0,            'same'),
    'ac1_gdp':         ('about 0.85',           lambda m: m >= 0.6,          lambda m: m > 0,             'approx.'),
    'okun':            ('-0.3 to -0.5',         lambda m: -0.6 <= m <= -0.2, lambda m: m < 0,             'approx.; Ball et al. 2013'),
    'phillips':        ('negative',             lambda m: m <= -0.2,         lambda m: m < 0,             'Fitzgerald et al. 2013, via Ponta et al.'),
    'infl_cycle':      ('positive, lagging',    None,                        lambda m: m > 0,             'Caiani et al., Fig. 6'),   # matched needs the lag too (see score_row)
    'inv_sales_cycle': ('negative',             lambda m: m <= -0.2,         lambda m: m < 0,             'Bils and Kahn 2000, via Caiani et al.'),
    'kurt_growth':     ('positive (fat tails)', lambda m: m > 1,             lambda m: m > 0,             'Fagiolo et al. 2008'),
    'corr_gdp_credit': ('positive',             lambda m: m > 0.2,           lambda m: m > 0,             'Lown and Morgan 2006, via Caiani et al.'),
    'mean_unemp':      ('about 6 %',            lambda m: 4 <= m <= 9,       lambda m: 2 <= m <= 12,      'Belgium, approx.'),
    'infl_annual':     ('about 2 %',            lambda m: 0 <= m <= 4,       lambda m: -2 <= m <= 6,      'euro-area target'),
    'gini_wealth_end': ('to fill (HFCS Belgium)', None,                      None,                        'leave empty until supplied'),
}
MEASURES = list(TARGETS) + ['infl_cycle_lag']


def hp_filter(y, lam=1600.0):
    """Hodrick–Prescott trend and cycle of a 1-d array: minimise sum (y - t)^2 + lam * sum (d2 t)^2 — solve (I + lam D'D) t = y
    with D the second-difference matrix, sparse."""
    y = np.asarray(y, float); n = len(y)
    if n < 3: return y.copy(), np.zeros(n)
    d = sp.diags([np.ones(n - 2), -2 * np.ones(n - 2), np.ones(n - 2)], [0, 1, 2], shape=(n - 2, n))
    a = sp.eye(n, format='csc') + lam * (d.T @ d)
    trend = spla.spsolve(a.tocsc(), y)
    return trend, y - trend


def corr(a, b):
    a = np.asarray(a, float); b = np.asarray(b, float)
    ok = np.isfinite(a) & np.isfinite(b)
    if ok.sum() < 4 or np.std(a[ok]) == 0 or np.std(b[ok]) == 0: return np.nan
    return float(np.corrcoef(a[ok], b[ok])[0, 1])


def lagged_corr(x, y, k):
    """corr(x_t, y_{t+k}) for k in -3..3."""
    if k >= 0: return corr(x[:len(x) - k] if k else x, y[k:])
    return corr(x[-k:], y[:len(y) + k])


def excess_kurtosis(x):
    x = np.asarray(x, float); x = x[np.isfinite(x)]
    if len(x) < 8 or np.std(x) == 0: return np.nan
    z = (x - x.mean()) / x.std()
    return float(np.mean(z ** 4) - 3.0)


def quarters(d, from_month):
    d = d[d['round'] >= from_month].copy()
    d['q'] = (d['round'] - 1) // 3
    full = d.groupby('q')['round'].count()
    d = d[d['q'].isin(full[full == 3].index)]
    g = d.groupby('q')
    out = pd.concat([g[FLOWS].sum(), g[STOCKS].mean()], axis=1).reset_index(drop=True)
    return out


def measures_of_run(d, from_month, lam):
    """The measures of one run (a per-run data frame). Returns a dict, or None if the run is too short."""
    q = quarters(d, from_month)
    if len(q) < 20: return None
    y = np.log(q['gdp_in_loaves'].clip(lower=1e-9)); _, cy = hp_filter(y, lam)
    cons = q['gdp_consumption'] / q['price_bread']; _, cc = hp_filter(np.log(cons.clip(lower=1e-9)), lam)
    u = (q['unemployed'] / q['persons_alive']).to_numpy(); _, cu = hp_filter(100 * u, lam)                      # levels, pp
    mean_u = float(np.mean(u))
    sd_gdp = 100 * float(np.std(cy, ddof=1))
    rel_sd_unemp = np.nan
    if mean_u >= 0.02:
        _, clu = hp_filter(np.log(np.clip(u, 1e-6, None)), lam); rel_sd_unemp = float(np.std(clu, ddof=1)) / (sd_gdp / 100) if sd_gdp > 0 else np.nan
    infl = np.diff(np.log(q['price_bread'].clip(lower=1e-9)))                                                    # quarterly
    growth = 100 * np.diff(np.log(q['gdp_in_loaves'].clip(lower=1e-9)))                                           # %
    du = 100 * np.diff(u)                                                                                          # pp
    ok = np.isfinite(growth) & np.isfinite(du)
    okun = float(np.polyfit(growth[ok], du[ok], 1)[0]) if ok.sum() >= 4 and np.std(growth[ok]) > 0 else np.nan
    lags = {k: lagged_corr(cy, cu, k) for k in range(-3, 4)}
    unemp_lag = min(lags, key=lambda k: (lags[k] if np.isfinite(lags[k]) else np.inf)) if any(np.isfinite(v) for v in lags.values()) else np.nan
    infl_q = np.full(len(q), np.nan); infl_q[1:] = infl                                                           # inflation *in* quarter j: log p_j - log p_{j-1}
    ic = {k: lagged_corr(cy, infl_q, k) for k in range(0, 4)}                                                     # GDP cycle at t, inflation at t+k
    ic_lag = max(ic, key=lambda k: (ic[k] if np.isfinite(ic[k]) else -np.inf))
    ratio = np.log((q['bread_stocked'] / q['bread_sold']).clip(lower=1e-9)); _, cr = hp_filter(ratio, lam)
    _, cd = hp_filter(np.log(q['outstanding_debt'].clip(lower=1e-9)), lam)
    kept = d[d['round'] >= from_month]
    p0, p1 = float(kept['price_bread'].iloc[0]), float(kept['price_bread'].iloc[-1]); months = len(kept) - 1
    infl_annual = 100 * ((p1 / p0) ** (12 / months) - 1) if months > 0 and p0 > 0 and p1 > 0 else np.nan
    return dict(
        sd_gdp=sd_gdp,
        rel_sd_cons=(float(np.std(cc, ddof=1)) / (sd_gdp / 100)) if sd_gdp > 0 else np.nan,
        rel_sd_unemp=rel_sd_unemp,
        corr_gdp_unemp=corr(cy, cu), unemp_lag=unemp_lag,
        ac1_gdp=corr(cy[:-1], cy[1:]), okun=okun,
        phillips=corr(100 * u[1:], infl),
        infl_cycle=ic[ic_lag], infl_cycle_lag=ic_lag,
        inv_sales_cycle=corr(cy, cr), kurt_growth=excess_kurtosis(growth),
        corr_gdp_credit=corr(cy, cd), mean_unemp=100 * mean_u, infl_annual=infl_annual,
        gini_wealth_end=float(d['gini_net_wealth_persons'].iloc[-1]) if 'gini_net_wealth_persons' in d else np.nan,
        quarters=len(q))


def score(measure, median, lag=None):
    if not np.isfinite(median): return 'missing'
    target, matched, partly, _ = TARGETS[measure]
    if measure == 'infl_cycle': return 'matched' if (median > 0.2 and lag is not None and lag >= 1) else ('partly' if median > 0 else 'failed')
    if matched is None and partly is None: return ''
    if matched and matched(median): return 'matched'
    if partly and partly(median): return 'partly'
    return 'failed'


def run_folder(folder, from_month, rungs, lam):
    files = sorted(glob.glob(os.path.join(folder, '*__*__*.csv')))
    if rungs: files = [f for f in files if any(os.path.basename(f).startswith(r) for r in rungs)]
    rows = []
    for f in files:
        name = os.path.basename(f)[:-4]; cell, sysn, seed = name.rsplit('__', 2)
        d = pd.read_csv(f)
        missing = [c for c in NEEDED if c not in d.columns and c != 'gini_net_wealth_persons']
        if missing: print(f"skip {name}: missing {missing}", file=sys.stderr); continue
        m = measures_of_run(d, from_month, lam)
        if m is None: print(f"skip {name}: fewer than 20 quarters", file=sys.stderr); continue
        m.update(rung=cell, system=sysn, seed=int(seed), collapsed=bool(d['persons_alive'].iloc[-1] < 0.5 * d['persons_alive'].iloc[0]))
        rows.append(m)
    runs = pd.DataFrame(rows)
    if runs.empty: print("no runs", file=sys.stderr); return runs, pd.DataFrame()
    out = []
    for (cell, sysn), g in runs.groupby(['rung', 'system']):
        kept = g[~g.collapsed]; row = dict(rung=cell, system=sysn, n=len(g), collapsed=int(g.collapsed.sum()), label='for comparison' if sysn == 'sumsy' else '')
        for meas in MEASURES:
            v = kept[meas].astype(float)
            if meas == 'rel_sd_unemp' and kept['mean_unemp'].median() < 2.0: v = v * np.nan                       # below 2 % unemployment the log measure explodes: missing for the cell
            med = float(v.median()) if v.notna().any() else np.nan
            row[meas + '_median'] = med; row[meas + '_p25'] = float(v.quantile(0.25)) if v.notna().any() else np.nan; row[meas + '_p75'] = float(v.quantile(0.75)) if v.notna().any() else np.nan
            if meas in TARGETS: row[meas + '_score'] = score(meas, med, row.get('infl_cycle_lag_median'))
        out.append(row)
    return runs, pd.DataFrame(out)


def headline(summary):
    try:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); from paired_tests import HEADLINE
    except Exception: HEADLINE = ['0 bare', '2 government', '8 share', '11 ', 'V8 productive']
    keys = [h.replace(' ', '_').rstrip('_') for h in HEADLINE]
    show = ['sd_gdp', 'rel_sd_cons', 'rel_sd_unemp', 'corr_gdp_unemp', 'ac1_gdp', 'okun', 'phillips', 'infl_cycle', 'kurt_growth', 'mean_unemp', 'infl_annual']
    print(f"{'rung':34s} {'sys':5s} {'n':>2s} {'col':>3s} " + ' '.join(f"{s[:14]:>14s}" for s in show))
    for _, r in summary.iterrows():
        if not any(r.rung.startswith(k) for k in keys): continue
        print(f"{r.rung[:34]:34s} {r.system:5s} {r.n:2d} {r.collapsed:3d} " + ' '.join(f"{r[s + '_median']:7.2f} {r[s + '_score'][:6]:>6s}" for s in show))


def selftest():
    ok = True
    t = np.arange(120, dtype=float)
    _, c = hp_filter(np.log(100 + 2 * t)); line = np.max(np.abs(hp_filter(0.5 + 0.01 * t)[1])) < 1e-9; print("HP of a straight line gives a zero cycle:", line); ok &= line
    s = np.sin(2 * np.pi * np.arange(400) / 8); _, cs = hp_filter(s); ac1 = corr(cs[:-1], cs[1:]); good = abs(ac1 - math.cos(2 * math.pi / 8)) < 0.03; print(f"sine of period 8: ac1 {ac1:.3f} vs cos(2π/8) {math.cos(2*math.pi/8):.3f}:", good); ok &= good
    rng = np.random.default_rng(1); a = rng.standard_normal(5000); b = -0.7 * a + math.sqrt(1 - 0.49) * rng.standard_normal(5000); r = corr(a, b); good = abs(r + 0.7) < 0.05; print(f"known correlation -0.7: {r:.3f}:", good); ok &= good
    g = rng.laplace(size=20000); k = excess_kurtosis(g); good = abs(k - 3) < 0.4; print(f"Laplace growth, excess kurtosis {k:.2f} (expected 3):", good); ok &= good
    print("SELFTEST", "PASSED" if ok else "FAILED"); return ok


if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('folder', nargs='?'); ap.add_argument('--from-month', type=int, default=25); ap.add_argument('--rungs', default=''); ap.add_argument('--lambda', dest='lam', type=float, default=1600.0); ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest: sys.exit(0 if selftest() else 1)
    if not a.folder: ap.error("a ladder folder is needed (or --selftest)")
    rungs = [r.strip() for r in a.rungs.split(',') if r.strip()]
    runs, summary = run_folder(a.folder, a.from_month, rungs, a.lam)
    ladder = os.path.basename(os.path.normpath(a.folder)); results = os.path.dirname(os.path.dirname(os.path.normpath(a.folder)))
    runs.to_csv(os.path.join(results, f"{ladder}_stylized_facts_runs.csv"), index=False); summary.to_csv(os.path.join(results, f"{ladder}_stylized_facts.csv"), index=False)
    print(f"{len(runs)} runs, {len(summary)} cells; written {ladder}_stylized_facts_runs.csv and {ladder}_stylized_facts.csv beside the folder")
    headline(summary)

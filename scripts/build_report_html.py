"""Build the English HTML report from docs/report_v3_en_public.md with charts drawn as inline SVG from results/.
   python3 scripts/build_report_html.py  →  docs/html/bread_economy_report_en.html
   Charts are generated from the CSVs at build time, so they are as current as the results directory."""
import re, html, markdown, pandas as pd, numpy as np, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESULTS = os.environ.get('RESULTS_DIR', os.path.join(ROOT, 'results'))   # RESULTS_DIR=results/pre_review2 builds from an archived set
R = lambda p: os.path.join(RESULTS, p)
DEBT, SUMSY, GREY = '#b8541c', '#2a7f62', '#8a8a8a'

# ---------- data ----------
lad = pd.read_csv(R('ladder2_64_summary.csv'))
order = ['0 bare bones','1 + planning margin','2 + government','3 + interest on deposits','4 + theatre','5 + government bonds','6 + charge on balances','7 + second theatre','8 + shareholders & share market','9 co-ops (side rung)','10 + responsive prices','11 + government reserve','12 + fiscal policy and VAT']
short = ['0 bare','1 plan','2 gov','3 int','4 theatre','5 bonds','6 charge','7 2nd th.','8 shares','9 co-ops','10 prices','11 reserve','12 fiscal']
def series(col, system): return [float(lad[(lad.rung==r)&(lad.system==system)][col].iloc[0]) for r in order]

# ---------- svg helpers ----------
def esc(s): return html.escape(str(s))
def chart(title, groups, labels, ymax=None, yfmt=lambda v: f'{v:g}', unit='', note='', w=760, h=330, kind='bar'):
    """groups: list of (name, color, values). Grouped bars or lines over categorical x."""
    ml, mr, mt, mb = 48, 16, 34, 64; pw, ph = w-ml-mr, h-mt-mb
    allv = [v for _,_,vs in groups for v in vs if v==v]
    ymax = ymax or (max(allv) * 1.08 if allv else 1); ymax = ymax if ymax > 0 else 1
    def Y(v): return mt + ph - (v/ymax)*ph
    n = len(labels); slot = pw/n
    out = [f'<svg viewBox="0 0 {w} {h}" role="img" aria-label="{esc(title)}" style="width:100%;height:auto;font-family:inherit">',
           f'<text x="{ml}" y="18" font-size="14" font-weight="600" fill="currentColor">{esc(title)}</text>']
    for k in range(5):
        v = ymax*k/4; y = Y(v)
        out.append(f'<line x1="{ml}" x2="{w-mr}" y1="{y:.1f}" y2="{y:.1f}" stroke="currentColor" stroke-opacity="0.15"/>')
        out.append(f'<text x="{ml-6}" y="{y+4:.1f}" font-size="10" text-anchor="end" fill="currentColor" fill-opacity="0.7">{esc(yfmt(v))}</text>')
    if kind == 'bar':
        bw = slot*0.8/len(groups)
        for gi,(name,color,vals) in enumerate(groups):
            for i,v in enumerate(vals):
                if v != v: continue
                x = ml + i*slot + slot*0.1 + gi*bw; y = Y(v)
                out.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{bw-2:.1f}" height="{mt+ph-y:.1f}" fill="{color}"><title>{esc(name)}, {esc(labels[i])}: {esc(yfmt(v))}{esc(unit)}</title></rect>')
    else:
        for name,color,vals in groups:
            pts = [(ml + i*slot + slot/2, Y(v)) for i,v in enumerate(vals) if v==v]
            out.append('<polyline fill="none" stroke="%s" stroke-width="2.5" points="%s"/>' % (color, ' '.join(f'{x:.1f},{y:.1f}' for x,y in pts)))
            for (x,y),v in zip(pts,[v for v in vals if v==v]):
                out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3.5" fill="{color}"><title>{esc(name)}: {esc(yfmt(v))}{esc(unit)}</title></circle>')
    for i,l in enumerate(labels):
        out.append(f'<text x="{ml + i*slot + slot/2:.1f}" y="{mt+ph+14}" font-size="10" text-anchor="middle" fill="currentColor" fill-opacity="0.8">{esc(l)}</text>')
    lx = ml
    for name,color,_ in groups:
        out.append(f'<rect x="{lx}" y="{h-18}" width="12" height="12" fill="{color}"/><text x="{lx+16}" y="{h-8}" font-size="11" fill="currentColor">{esc(name)}</text>'); lx += 16 + 7*len(name) + 22
    if note: out.append(f'<text x="{w-mr}" y="{h-8}" font-size="10" text-anchor="end" fill="currentColor" fill-opacity="0.7">{esc(note)}</text>')
    out.append('</svg>'); return '\n'.join(out)

def fig(svg, caption): return f'<figure class="chart">{svg}<figcaption>{caption}</figcaption></figure>'

# ---------- charts ----------
F = {}
F['alive'] = fig(chart('Alive at the end, of 64', [('Debt money', DEBT, series('alive','debt')), ('SuMSy', SUMSY, series('alive','sumsy'))], short, ymax=68, note='ten runs, mean'),
    'Figure 1. Who is alive after a hundred months, step by step. Debt money needs a government (step 2); SuMSy needs only a planning margin (step 1). Step 12 costs the debt village eleven people.')
F['debt'] = fig(chart('Public debt, % of yearly output', [('Debt money', DEBT, series('debt_gdp','debt'))], short, yfmt=lambda v: f'{v:.0f} %', note='SuMSy: none at any step'),
    'Figure 2. What the debt village\'s government owes, as a share of what the village produces in a year. It never falls below 170 %; the SuMSy government owes nothing.')
F['tickets'] = fig(chart('Theatre tickets sold a month', [('Debt money', DEBT, series('tickets','debt')), ('SuMSy', SUMSY, series('tickets','sumsy'))], short, note='last twelve months, mean'),
    'Figure 3. Tickets — the village\'s only spending beyond bread. The stock market (step 8) halves them in both villages; the cooperatives (side step 9) restore them on the SuMSy side.')
F['gini'] = fig(chart('How unevenly the cash is spread (Gini, 0 = equal)', [('Debt money', DEBT, series('gini_c','debt')), ('SuMSy', SUMSY, series('gini_c','sumsy'))], short, ymax=1, yfmt=lambda v: f'{v:.2f}', kind='line'),
    'Figure 4. SuMSy\'s money stays almost evenly spread until shares arrive at step 8; the responsive prices of step 10 spread it further apart.')
F['unempl'] = fig(chart('Without work, of 64', [('Debt money', DEBT, series('unempl','debt')), ('SuMSy', SUMSY, series('unempl','sumsy'))], short, note='mean over the run'),
    'Figure 5. Unemployment. The theatre (step 4) is the biggest employer in both villages; SuMSy\'s falls to ten, the debt village\'s to sixteen.')

# greed matrix (Section 10) from block results
def survived(path, variant, system='sumsy'):
    r = pd.read_csv(path); r = r[(r.variant==variant)&(r.system==system)]
    last = r.sort_values('round').groupby('seed').tail(1); return float((last.persons_alive >= 60).sum()), int(last.seed.nunique())
g = []
for lab, path, var in [('everyone, report prices', R('all64_capacity_rounds.csv'), 'mixed greed, capacity 4'), ('everyone, responsive', R('all64_responsive_rounds.csv'), 'mixed greed, 2 shows, fully responsive'),
                       ('everyone, responsive, full money', R('all64_responsive_rounds.csv'), 'mixed greed, 2 shows, responsive, equilibrium start'),
                       ('quarter, report prices', R('all64_threshold_rounds.csv'), 'greedy rich 25 %, unmet 5 %'), ('quarter, responsive', R('all64_floor_rounds.csv'), 'greedy rich 25 %, 2 shows, responsive'),
                       ('quarter, responsive, full money', R('all64_responsive_rounds.csv'), 'greedy rich 25 %, 2 shows, fully responsive, equilibrium start')]:
    try: s, n = survived(path, var); g.append((lab, s))
    except Exception: g.append((lab, float('nan')))
F['greed'] = fig(chart('Greedy SuMSy villages: runs (of ten) that stayed whole', [('runs whole', SUMSY, [v for _,v in g])], [l for l,_ in g], ymax=10, w=760, h=360),
    'Figure 6. Greed in the SuMSy village. "Everyone" and "quarter" say who is greedy; "report prices" are the first report\'s rules, "responsive" the rules of step 10 with a higher ceiling for bread; "full money" starts the village with its money at the level the guaranteed income and parking fee imply.')

# stress (Section 13)
st = lad[lad.rung.str.startswith(('11','12','S'))]
def sv(rung, system): 
    x = st[(st.rung.str.startswith(rung))&(st.system==system)]; return float(x.alive.iloc[0]) if len(x) else float('nan')
labels = ['no greed','richest quarter','everyone']
F['stress'] = fig(chart('Alive at the end under greed, of 64', [('debt, best surviving (11)', DEBT, [sv('11','debt'), sv('S1','debt'), sv('S3','debt')]), ('debt, least indebted (12)', '#e0a070', [sv('12','debt'), sv('S2','debt'), sv('S4','debt')]),
    ('SuMSy, step 11', SUMSY, [sv('11','sumsy'), sv('S1','sumsy'), sv('S3','sumsy')]), ('SuMSy, step 12', '#8fc7b1', [sv('12','sumsy'), sv('S2','sumsy'), sv('S4','sumsy')])], labels, ymax=68, w=760, h=360),
    'Figure 7. The stress test. The best-surviving villages survive greed; the least-indebted ones are the fragile ones.')

# taxes (Section 11): wage-tax ceiling sweep
try:
    c = pd.read_csv(R('all64_ceiling_rounds.csv')); cl = c.sort_values('round').groupby(['variant','seed']).tail(1)
    cc = cl.groupby('variant').agg(alive=('persons_alive','mean')).reindex(['ceiling 1.2 (18 %)','ceiling 1.33 (20 %)','ceiling 1.5 (22.5 %)','ceiling 1.67 (25 %)','ceiling 2.0 (30 %)','ceiling 2.33 (35 %)'])
    F['tax'] = fig(chart('Alive at the end as the wage tax is allowed to rise', [('Debt money', DEBT, list(cc.alive))], ['18 %','20 %','22.5 %','25 %','30 %','35 %'], ymax=68),
        'Figure 8. The debt village bears a wage tax of thirty percent; at thirty-five it starts to die. The shortfall it closes on the way is less than half.')
except Exception as e: F['tax'] = ''

# ---------- "what is there" panels, one per step, from the configuration dump ----------
def pct(v): return f'{100*float(v):g} %'
def money(v): return f'{float(v):g}'
def panel_for(step):
    try: cfg = pd.read_csv(R('ladder2_128_rungs.csv'))
    except Exception: return ''
    rows = cfg[cfg.rung.str.match(rf'^{step}\b')]
    if rows.empty: return ''
    d = rows[rows.system=='debt']; u = rows[rows.system=='sumsy']
    d = d.iloc[0] if len(d) else None; u = u.iloc[0] if len(u) else None
    def col(r, system):
        if r is None: return '<td>—</td>'
        firms = f"{int(r.farms)} farms, {int(r.bakeries)} bakeries" + (f", {int(r.theatres)} theatres" if r.theatres else "")
        if r.coops: firms += f" ({int(r.coops)} of them cooperatives)"
        if r.theatres and r.seats_per_theatre: firms += f"; {int(r.shows)} show a month, {int(r.seats_per_theatre)} seats a theatre"
        own = f"{int(r.founders)} founders hold shares" + (", shares trade" if r.share_market else "") if r.founders else "no owners"
        if system == 'debt':
            gov = ("none" if not r.public_jobs_share else f"public jobs for {pct(r.public_jobs_share)} of the village's work, {r.benefit_loaves:g} loaves for the workless; taxes: wages {pct(r.wage_tax)}, capital income {pct(r.capital_tax)}, dividends {pct(r.dividend_tax)}" + (f", bread and tickets {pct(r.consumption_tax)}" if r.consumption_tax else "") + (", borrows by bonds" if r.bonds else ", borrows from the banks"))
            money_ = f"created by bank loans; banks start at {pct(r.bank_rate_start)} a month, capped at {pct(r.bank_rate_cap)}; the government borrows at {pct(r.government_rate)}" + (f"; savings earn {pct(r.deposit_interest)} a year" if r.deposit_interest else "")
        else:
            gov = ("none" if not r.public_jobs_share else f"public jobs for {pct(r.public_jobs_share)} of the village's work; no benefit, no tax on income; parking tax {pct(r.parking_tax)} a month on idle money" + (f"; bread and tickets {pct(r.consumption_tax)}" if r.consumption_tax else ""))
            money_ = f"guaranteed income {money(r.guaranteed_income)} a month; cushion {money(r.buffer)}; parking fee {pct(r.parking_fee)} a month above it; banks at −1 %"
        if r.charge_on_balances: money_ += f"; charge on firms' idle balances {pct(r.charge_on_balances)} a month"
        fiscal = "" if r.tax_policy == 'none' and not r.reserve_rounds else (f"reserve of {int(r.reserve_rounds)} months of spending" if r.reserve_rounds else "") + (f"; tax policy, levers {r.levers}" if r.tax_policy != 'none' else "")
        prices = f"bread {money(r.price_bread)}, grain {money(r.price_grain)}, wage {money(r.price_wage)} a unit (a full month's work {money(4*float(r.price_wage))}), rent {money(r.price_rent)}, ticket {money(r.price_ticket)}; a buyer pays up to {r.bread_ceiling:g} × last month's bread price" + (", never below cost" if r.ask_floor == 'cost' else "")
        greed = f"; greed: {r.greed}" if isinstance(r.greed, str) and r.greed else ""
        return f"<td><b>{int(r.villagers)} villagers</b>, {int(r.landowners)} of them landowners · {firms} · {own}<br>Money: {money_}<br>Government: {gov}{('<br>Public finance: ' + fiscal) if fiscal else ''}<br>Starting prices: {prices}{greed}</td>"
    return ('<div class="wrap"><table class="whatis"><thead><tr><th>Debt money</th><th>SuMSy</th></tr></thead><tbody><tr>' + col(d,'debt') + col(u,'sumsy') + '</tr></tbody></table></div>')

# ---------- markdown → html ----------
md = open(os.path.join(ROOT, 'docs', 'report_v3_en_public.md')).read()
# style checks (docs/report_style.md §3): the disclaimer and the navigation line must be present
assert 'This is an AI-generated report' in md, 'disclaimer missing (report_style.md §3)'
assert 'Previous report:' in md and 'Next report:' in md, 'navigation line missing (report_style.md §3)'
assert 'allowance' not in md.lower() or 'benefit' in md, 'terminology: allowance (report_style.md §2)'
# frames
# the frames: render their markdown separately (Python-Markdown leaves raw HTML blocks alone), then drop the HTML in
md = re.sub(r'\\\[ KADER\s*\n(.*?)\n\\\]', lambda m: '\n<aside class="frame">\n' + markdown.markdown(m.group(1).strip(), extensions=['tables']) + '\n</aside>\n', md, flags=re.S)
# figure placement markers by section heading
place = {'## 7. The ladder': 'alive', '### What the ladder says': 'debt', '### Step 8. Owners and a stock market': 'tickets', '### Step 10. Prices that respond': 'gini', '### Step 4. A theatre': 'unempl', '## 10. Greed': 'greed', '## 13. The stress test: greed on the best villages': 'stress', '## 11. Taxes, and why the debt village\'s books do not balance': 'tax'}
body = markdown.markdown(md, extensions=['tables'])
body = re.sub(r'<a href="(https?://[^"]+)"', r'<a href="\1" target="_blank" rel="noopener"', body)   # new tab: in-frame navigation is blocked (report_style.md §8)
# every address that appears as plain text becomes a link too, so it can be right-clicked (report_style.md §8); an address
# already inside an <a> is left alone
def _linkify(m):
    url = m.group(0).rstrip('.,;:)')
    tail = m.group(0)[len(url):]
    return f'<a href="{url}" target="_blank" rel="noopener">{url}</a>{tail}'
body = re.sub(r'(?<!href=")(?<!>)https?://[^\s<"\)]+[.,;:)]?', _linkify, body)
for heading, key in place.items():
    hh = markdown.markdown(heading).strip()
    if hh in body and F.get(key): body = body.replace(hh, hh + '\n' + F[key], 1)
import re as _re
def _step_panel(m):
    n = int(m.group(1)); pan = panel_for(n)
    return m.group(0) + ('\n' + pan if pan else '')
body = _re.sub(r'<h3>Step (\d+)[^<]*</h3>', _step_panel, body)
stamp = datetime.date.today().isoformat()
page = f'''<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>The Bread Economy — what happens to a village when you change its money</title>
<style>
:root {{ --bg:#fbf8f2; --fg:#1f1d1a; --muted:#6b675f; --frame:#f0ebe0; --rule:#d9d2c3; --accent:#b8541c; --link:#9a4413; box-sizing:border-box; padding-top:env(safe-area-inset-top,0px); padding-bottom:env(safe-area-inset-bottom,0px); }}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{ --bg:#181613; --fg:#ece7dd; --muted:#a9a397; --frame:#242019; --rule:#3a352c; --link:#f0a06a; }} }}
:root[data-theme="dark"] {{ --bg:#181613; --fg:#ece7dd; --muted:#a9a397; --frame:#242019; --rule:#3a352c; --link:#f0a06a; }}
html {{ scroll-padding-top:env(safe-area-inset-top,0px); }}
body {{ margin:0; background:var(--bg); color:var(--fg); font:17px/1.6 Georgia, "Times New Roman", serif; }}
main {{ max-width:46rem; margin:0 auto; padding:2rem 1.2rem 4rem; }}
h1 {{ font-size:2.2rem; line-height:1.15; margin:1rem 0 .3rem; }} h2 {{ font-size:1.5rem; margin-top:2.6rem; border-top:1px solid var(--rule); padding-top:1.2rem; }}
h3 {{ font-size:1.15rem; margin-top:1.8rem; }} p {{ margin:.8rem 0; }} em {{ color:var(--muted); }}
a, a:visited {{ color:var(--link); text-decoration:underline; text-underline-offset:2px; }} a:hover {{ color:var(--accent); }}
aside.frame {{ background:var(--frame); border-left:4px solid var(--accent); padding:.6rem 1rem; margin:1.2rem 0; font:15px/1.5 system-ui, sans-serif; overflow-x:auto; }}
aside.frame p {{ margin:.4rem 0; }}
figure.chart {{ margin:1.4rem 0; padding:.6rem .4rem; border:1px solid var(--rule); border-radius:6px; }}
figure.chart figcaption {{ font:14px/1.45 system-ui, sans-serif; color:var(--muted); padding:.3rem .5rem 0; }}
table.whatis {{ font:13px/1.45 system-ui, sans-serif; margin:.4rem 0 1rem; }} table.whatis td {{ width:50%; vertical-align:top; background:var(--frame); }}
table {{ border-collapse:collapse; width:100%; font:14px/1.4 system-ui, sans-serif; }} th, td {{ border-bottom:1px solid var(--rule); padding:.3rem .5rem; text-align:left; vertical-align:top; }}
.wrap {{ overflow-x:auto; }} nav.reportnav {{ font:14px/1.5 system-ui, sans-serif; color:var(--muted); }}
.colophon {{ color:var(--muted); font-size:.9rem; margin-top:3rem; border-top:1px solid var(--rule); padding-top:1rem; }}
</style></head><body><main>
{body}
<p class="colophon">Built {stamp} from the results directory of BreadEconomySim.jl (second ladder, ten runs per configuration). Charts are drawn from the data at build time.</p>
</main></body></html>'''
out = os.path.join(ROOT, 'docs', 'html', 'bread_economy_report_en.html')
open(out, 'w').write(page); print('wrote', out, len(page), 'bytes; charts:', [k for k,v in F.items() if v])

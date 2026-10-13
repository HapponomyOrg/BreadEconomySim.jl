"""Build the English HTML report from docs/report_v4_en_public.md with charts drawn as inline SVG from results/ (the 512-villager
   ladder of 12 October 2026) and the "what is there" panels from results/ladder2_512_rungs.csv.
   python3 scripts/build_report_v4_html.py  →  docs/html/bread_economy_report_v4_en.html"""
import re, html, markdown, pandas as pd, numpy as np, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESULTS = os.environ.get('RESULTS_DIR', os.path.join(ROOT, 'results'))
R = lambda p: os.path.join(RESULTS, p)
DEBT, SUMSY, GREY = '#b8541c', '#2a7f62', '#8a8a8a'

# ---------- data ----------
lad = pd.read_csv(R('ladder2_512_summary.csv'))
order = ['0 bare bones','1 + planning margin','2 + government','3 + interest on deposits','4 + theatres','5 + government bonds','6 + charge on balances','7 + two more theatres','8 + shareholders & share market','9 co-ops (side rung)','10 + government reserve','11 + fiscal policy and VAT']
short = ['0 bare','1 plan','2 gov','3 int','4 theatres','5 bonds','6 charge','7 4 th.','8 shares','9 co-ops','10 reserve','11 fiscal']
def series(col, system): return [float(lad[(lad.rung==r)&(lad.system==system)][col].iloc[0]) for r in order]
def cell(prefix, system, col):
    x = lad[lad.rung.str.startswith(prefix) & (lad.system==system)]; return float(x[col].iloc[0]) if len(x) else float('nan')

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
F['alive'] = fig(chart('Alive at the end, of 512', [('Debt money', DEBT, series('alive_at_end','debt')), ('SuMSy', SUMSY, series('alive_at_end','sumsy'))], short, ymax=540, note='ten runs, mean'),
    'Figure 1. Who is alive after ten years, step by step. Without a government the debt village keeps 150 and the SuMSy village 458; from step 2 the SuMSy village keeps everyone at every step. The tax on bread (step 11) costs the debt village ninety people.')
F['unempl'] = fig(chart('Without work, of 512', [('Debt money', DEBT, series('unemployed','debt')), ('SuMSy', SUMSY, series('unemployed','sumsy'))], short, note='at month 120, mean'),
    'Figure 2. Unemployment. From step 2 on the SuMSy village has none: its people work for the village, for themselves and for the work, and the work is shared. A third of the debt village has no work at every step.')
F['debt'] = fig(chart('Public debt at month 120', [('Debt money', DEBT, series('public_debt','debt')), ('SuMSy', SUMSY, series('public_debt','sumsy'))], short, yfmt=lambda v: f'{v/1000:.0f}k', note='SuMSy: repaid at every step'),
    'Figure 3. What the government owes after ten years. The debt village borrows every month to feed the people without work; the SuMSy government borrows once, while its money fills the village, and repays within three years.')
F['bread'] = fig(chart('The price of a loaf at month 120 (from 5)', [('Debt money', DEBT, series('bread_price','debt')), ('SuMSy', SUMSY, series('bread_price','sumsy'))], short, ymax=6, yfmt=lambda v: f'{v:.1f}'),
    'Figure 4. Both villages deflate; the SuMSy village faster, to 2, because its people work two units in three and want no more. A village that has enough lets its prices fall; a money that is not a debt can afford to let them.')
F['poor'] = fig(chart('What the poorest tenth hold, in meals', [('Debt money', DEBT, series('wealth_bottom10_meals','debt')), ('SuMSy', SUMSY, series('wealth_bottom10_meals','sumsy'))], short, yfmt=lambda v: f'{v:.0f}', note='land and shares counted, gold not'),
    'Figure 5. The poorest tenth. In the debt village they hold a meal or less at every step and go under water at step 11; in the SuMSy village they hold sixteen meals from step 8, when the land dividend arrives, and twenty with cooperatives.')
F['tickets'] = fig(chart('Theatre tickets sold a month', [('Debt money', DEBT, series('tickets','debt')), ('SuMSy', SUMSY, series('tickets','sumsy'))], short, note='last twelve months, mean'),
    'Figure 6. Tickets, the village\'s only spending beyond bread. The SuMSy village fills four theatres; the debt village fills one, and the other three fail and are started again.')
pol = [('step 8', cell('8 + share','debt','alive_at_end')), ('austerity', cell('A8','debt','alive_at_end')), ('ceiling 1×', cell('D8-100','debt','alive_at_end')), ('ceiling 0.5×', cell('D8-50','debt','alive_at_end')), ('taxes balance (UP8)', cell('UP8','debt','alive_at_end')), ('tax on bread (11)', cell('11','debt','alive_at_end'))]
F['policies'] = fig(chart('The debt village: alive at the end under each policy, of 512', [('Debt money', DEBT, [v for _,v in pol])], [l for l,_ in pol], ymax=540, w=760, h=340),
    'Figure 7. Every policy that brings the debt village\'s debt down costs it people: austerity thirty-eight, a debt ceiling up to two hundred, taxes raised until the budget balances three hundred, the tax on bread ninety. The SuMSy village keeps 512 under each.')
emp = [('step 8', cell('8 + share','debt','public_debt'), cell('8 + share','debt','alive_at_end')), ('productive (V8)', cell('V8','debt','public_debt'), cell('V8','debt','alive_at_end')), ('premium loaf (K8)', cell('K8','debt','public_debt'), cell('K8','debt','alive_at_end')), ('public jobs 40 % (U8)', cell('U8','debt','public_debt'), cell('U8','debt','alive_at_end')), ('transport line (T8)', cell('T8','debt','public_debt'), cell('T8','debt','alive_at_end'))]
F['employment'] = fig(chart('The debt village: public debt at month 120 under each way to employment', [('Debt money', DEBT, [v for _,v,_ in emp])], [l for l,_,_ in emp], yfmt=lambda v: f'{v/1000:.0f}k', w=760, h=340),
    'Figure 8. Full employment and the debt. The productive village halves the debt; public jobs raise it; the premium loaf raises it; the transport line lowers it by a quarter. None of them repays it.')
land = [('debt village', cell('8 + share','debt','wealth_gap_meals')), ('SuMSy, levy & dividend', cell('8 + share','sumsy','wealth_gap_meals')), ('SuMSy, co-ops', cell('B best','sumsy','wealth_gap_meals')), ('SuMSy, entry', cell('N8','sumsy','wealth_gap_meals')), ('SuMSy, no levy', cell('Z8','sumsy','wealth_gap_meals'))]
F['land'] = fig(chart('The rich–poor gap in meals, step 8', [('gap', GREY, [v for _,v in land])], [l for l,_ in land], yfmt=lambda v: f'{v:.0f}', w=760, h=340),
    'Figure 9. The gap between the richest and poorest tenth. Without the levy the SuMSy gap is the price of land and nothing else; with the levy and dividend it is half the debt village\'s, with cooperatives a third, with market entry an eighth.')

# ---------- "what is there" panels, one per step, from the configuration dump ----------
def pct(v): return f'{100*float(v):g} %'
def money(v): return f'{float(v):g}'
def panel_for(step):
    try: cfg = pd.read_csv(R('ladder2_512_rungs.csv'))
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
            gov = ("none" if not r.public_jobs_share else f"public jobs for {pct(r.public_jobs_share)} of the village's work, {r.benefit_loaves:g} loaves for the workless" + (f"; wage tax {pct(r.wage_tax)}, capital tax {pct(r.capital_tax)}" if r.wage_tax or r.capital_tax else "") + (f", VAT {pct(r.consumption_tax)}" if r.consumption_tax else "") + ("; bonds" if r.bonds else "; borrows from its bank"))
            money_ = f"created by bank loans; banks start at {pct(r.bank_rate_start)} a month, capped at {pct(r.bank_rate_cap)}; the government borrows at {pct(r.government_rate)}" + (f"; interest on deposits {pct(r.deposit_interest)}" if r.deposit_interest else "")
        else:
            gov = ("none" if not r.public_jobs_share else f"public jobs for {pct(r.public_jobs_share)} of the village's work, {r.benefit_loaves:g} loaf for the workless; parking tax {pct(r.parking_tax)} a month; no tax on income" + ("; the levy on land, paid out as the dividend" if int(step) >= 8 else ""))
            money_ = f"guaranteed income {money(r.guaranteed_income)} a month; cushion {money(r.buffer)}; parking fee {pct(r.parking_fee)} a month above it; banks lend idle balances at −1 % a month"
        if r.charge_on_balances: money_ += f"; charge on firms' idle reserves {pct(r.charge_on_balances)} a month"
        fiscal = "" if r.tax_policy == 'none' and not r.reserve_rounds else (f"reserve of {int(r.reserve_rounds)} months of spending" if r.reserve_rounds else "") + (f"; tax policy: {r.tax_policy}" if r.tax_policy != 'none' else "")
        prices = f"bread {money(r.price_bread)}, grain {money(r.price_grain)}, wage {money(r.price_wage)} a unit, rent {money(r.price_rent)} a month" + (f", ticket {money(r.price_ticket)}" if r.theatres else "")
        return f"<td><b>{int(r.villagers)} villagers</b>, {int(r.landowners)} of them landowners · {firms} · {own}<br>Money: {money_}<br>Government: {gov}{('<br>Public finance: ' + fiscal) if fiscal else ''}<br>Starting prices: {prices}</td>"
    return ('<div class="wrap"><table class="whatis"><thead><tr><th>Debt money</th><th>SuMSy</th></tr></thead><tbody><tr>' + col(d,'debt') + col(u,'sumsy') + '</tr></tbody></table></div>')

# ---------- markdown → html ----------
md = open(os.path.join(ROOT, 'docs', 'report_v4_en_public.md')).read()
assert 'This is an AI-generated report' in md, 'disclaimer missing (report_style.md §3)'
assert 'Previous report:' in md and 'Next report:' in md, 'navigation line missing (report_style.md §3)'
md = re.sub(r'\\\[ KADER\s*\n(.*?)\n\\\]', lambda m: '\n<aside class="frame">\n' + markdown.markdown(m.group(1).strip(), extensions=['tables']) + '\n</aside>\n', md, flags=re.S)
place = {'## 7. The ladder': 'alive', '### What the ladder says': 'debt', '### Step 8. Owners and a stock market, and the land dividend': 'tickets', '## 9. What prices do with the debt': 'bread', '## 10. Full employment': 'unempl', '## 11. Where the debt village': 'employment', '## 12. Land': 'land', '## 13. Three policies, tried': 'policies', '### Step 9, a side step. Cooperatives': 'poor'}
body = markdown.markdown(md, extensions=['tables'])
body = re.sub(r'<a href="(https?://[^"]+)"', r'<a href="\1" target="_blank" rel="noopener"', body)
def _linkify(m):
    url = m.group(0).rstrip('.,;:)'); tail = m.group(0)[len(url):]
    return f'<a href="{url}" target="_blank" rel="noopener">{url}</a>{tail}'
body = re.sub(r'(?<!href=")(?<!>)https?://[^\s<"\)]+[.,;:)]?', _linkify, body)
for heading, key in place.items():
    hh = markdown.markdown(heading).strip()
    hits = [h for h in re.findall(r'<h[23]>[^<]*</h[23]>', body) if h.startswith(hh[:len(hh)-5])]
    if hits and F.get(key): body = body.replace(hits[0], hits[0] + '\n' + F[key], 1)
def _step_panel(m):
    n = int(m.group(1)); pan = panel_for(n)
    return m.group(0) + ('\n' + pan if pan else '')
body = re.sub(r'<h3>Step (\d+)[^<]*</h3>', _step_panel, body)
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
out = os.path.join(ROOT, 'docs', 'html', 'bread_economy_report_v4_en.html')
open(out, 'w').write(page); print('wrote', out, len(page), 'bytes; charts:', [k for k,v in F.items() if v])

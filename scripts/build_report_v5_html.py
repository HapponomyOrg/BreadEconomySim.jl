"""Build the English HTML report, version 5, from docs/report_v5_en_public.md with charts drawn as inline SVG from the
   2026-11-10.1 summaries in results/ (both ladders and the two fiscal packages).
   python3 scripts/build_report_v5_html.py  →  docs/html/bread_economy_report_v5_en.html"""
import re, html, markdown, pandas as pd, numpy as np, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESULTS = os.environ.get('RESULTS_DIR', os.path.join(ROOT, 'results'))
R = lambda p: os.path.join(RESULTS, p)
DEBT, SUMSY, GREY = '#b8541c', '#2a7f62', '#8a8a8a'

V = '2026-11-10.1'
real = pd.read_csv(R(f'ladder2_512_realistic_{V}_summary.csv')); std = pd.read_csv(R(f'ladder2_512_{V}_summary.csv'))
tax = pd.read_csv(R(f'ladder2_512_realistic_fiscal_taxes_{V}_summary.csv')); park = pd.read_csv(R(f'ladder2_512_realistic_fiscal_parking_{V}_summary.csv'))
steps = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '11']
short = ['0 bare', '1 plan', '2 gov', '3 int', '4 serv', '5 bonds', '6 charge', '7 more', '8 shares', '9 co-ops', '11 fiscal']
def cell(df, prefix, system, col):
    r = df[(df.rung.str.split(' ').str[0] == prefix) & (df.system == system)]
    v = r[col].iloc[0] if len(r) else float('nan')
    return 0.0 if pd.isna(v) else float(v)
def series(col, system, df=real): return [cell(df, s, system, col) for s in steps]
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
F['alive'] = fig(chart('Alive at the end, of 512', [('Debt money', DEBT, series('alive_at_end', 'debt')), ('SuMSy', SUMSY, series('alive_at_end', 'sumsy'))], short, ymax=540, note='ten runs, mean; realistic ladder'),
    'Figure 1. Who is alive after ten years, step by step. Without a government the debt village keeps 34 and the SuMSy village 487; from step 2 on both villages keep nearly everyone.')
F['debt'] = fig(chart('Public debt at month 120', [('Debt money', DEBT, series('public_debt', 'debt')), ('SuMSy', SUMSY, series('public_debt', 'sumsy'))], short, yfmt=lambda v: f'{v/1000:.0f}k', note='SuMSy: none at any step'),
    'Figure 2. What the government owes after ten years. The debt village borrows to pay the benefit that keeps its people alive; the SuMSy government owes nothing at any step.')
F['poor'] = fig(chart('What the poorest tenth own, in meals', [('Debt money', DEBT, [max(v, 0) for v in series('wealth_bottom10_meals', 'debt')]), ('SuMSy', SUMSY, [max(v, 0) for v in series('wealth_bottom10_meals', 'sumsy')])], short, yfmt=lambda v: f'{v:.0f}', note='values below zero shown as zero'),
    'Figure 3. The poorest tenth. In the debt village they own a meal or less at every step and owe more than they own at step 11; in the SuMSy village they own twelve meals from step 8, when the land levy is paid out.')
lab, dv, sv = [], [], []
for name, pre in (('step 8', '8'), ('step 9', 'B'), ('productive', 'V8')):
    for pk, df in (('own rules', real), ('income taxes', tax), ('parking tax', park)):
        lab.append(f'{name}: {pk}'); dv.append(cell(df, pre, 'debt', 'gini_wealth')); sv.append(cell(df, pre, 'sumsy', 'gini_wealth'))
F['packages'] = fig(chart('How unevenly wealth is spread (0 = everyone the same, 1 = one owner)', [('Debt money', DEBT, dv), ('SuMSy', SUMSY, sv)], lab, ymax=1.0, yfmt=lambda v: f'{v:.1f}', w=760, h=360),
    'Figure 4. The same taxes in both villages. At steps 8 and 9 the SuMSy village stays far more equal under either package; in the productive village the parking-tax package brings the debt village almost level.')
F['work'] = fig(chart('Labour sold a villager a month, in units', [('Debt money', DEBT, series('employment_per_head', 'debt')), ('SuMSy', SUMSY, series('employment_per_head', 'sumsy'))], short, ymax=3.2, yfmt=lambda v: f'{v:.1f}'),
    'Figure 5. Work done. From step 2 on the two villages do almost the same amount of work a head; the people counted as without work in the debt village (about 120) are people who offer more work than the village has, because they need it.')
F['bread'] = fig(chart('The price of a loaf at month 120', [('Debt money', DEBT, series('bread_price', 'debt')), ('SuMSy', SUMSY, series('bread_price', 'sumsy'))], short, yfmt=lambda v: f'{v:.1f}'),
    'Figure 6. Prices. With wages that are not cut, the debt village holds its price level and the SuMSy village inflates by about four per cent a year.')
lab, dv, sv = ['nobody', 'richest 1 %', 'richest quarter', 'everyone'], [], []
g11 = pd.read_csv(R('ladder2_512_realistic_2026-11-11.0_summary.csv'))
for pre in ('8', 'H8', 'S1', 'S3'): dv.append(cell(g11, pre, 'debt', 'gini_wealth')); sv.append(cell(g11, pre, 'sumsy', 'gini_wealth'))
F['greed'] = fig(chart('Greed at step 8: how unevenly wealth is spread', [('Debt money', DEBT, dv), ('SuMSy', SUMSY, sv)], lab, ymax=1.0, yfmt=lambda v: f'{v:.1f}'),
    'Figure 7. Who is greedy, and what it does to the spread of wealth. A greedy hundredth or quarter changes little; with everyone greedy the SuMSy village is plainly less equal, and still more equal than the debt village.')
place = {'## 6. The ladder': 'alive', '### What the ladder says': 'debt', '### Step 8. Owners, a stock market, and the land levy': 'poor', '## 7. The same taxes in both villages': 'packages', '## 8. Work, and wanting work': 'work', '## 10. Prices, and a floor under wages': 'bread', '### Greed': 'greed'}
md = open(os.path.join(ROOT, 'docs', 'report_v5_en_public.md')).read()
assert 'This is an AI-generated report' in md, 'disclaimer missing (report_style.md §3)'
assert 'Previous report:' in md and 'Next report:' in md, 'navigation line missing (report_style.md §3)'
md = re.sub(r'\\\[ KADER\s*\n(.*?)\n\\\]', lambda m: '\n<aside class="frame">\n' + markdown.markdown(m.group(1).strip(), extensions=['tables']) + '\n</aside>\n', md, flags=re.S)
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
<p class="colophon">Built {stamp} from the results directory of BreadEconomySim.jl (model version 2026-11-10.1, ten runs per village, both ladders). Charts are drawn from the data at build time.</p>
</main></body></html>'''
out = os.path.join(ROOT, 'docs', 'html', 'bread_economy_report_v5_en.html')
open(out, 'w').write(page); print('wrote', out, len(page), 'bytes; charts:', [k for k,v in F.items() if v])


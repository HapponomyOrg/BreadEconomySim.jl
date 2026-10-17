"""Every figure the report quotes, from one run's part files (ten-run means), as JSON.
   python3 scripts/report_numbers.py results/parts/ladder2_512_120months_<version> > numbers.json   (16 October 2026)"""
import pandas as pd, numpy as np, os, sys, json
d = sys.argv[1].rstrip('/') + '/'
files = os.listdir(d)
def parts(prefix, sys_):
    return [pd.read_csv(d + f) for f in files if f.startswith(prefix) and f'__{sys_}__' in f]
def m(fs, fn): return float(np.nanmean([fn(f) for f in fs]))
KEYS = [('s0d','0_bare','debt'),('s0s','0_bare','sumsy'),('s2d','2_government','debt'),('s2s','2_government','sumsy'),('s5d','5_','debt'),('s5s','5_','sumsy'),('s8d','8_share','debt'),('s8s','8_share','sumsy'),('s11d','11_','debt'),('s11s','11_','sumsy'),('Bd','B_best','debt'),('Bs','B_best','sumsy'),
 ('P8d','P8_','debt'),('P8s','P8_','sumsy'),('V8d','V8_productive_village_standard','debt'),('V8s','V8_productive_village_standard','sumsy'),('V8Pd','V8_P_','debt'),('V8Ps','V8_P_','sumsy'),
 ('U8d','U8_step','debt'),('U8s','U8_step','sumsy'),('U8Pd','U8_P_','debt'),('UP8d','UP8_step','debt'),('UP8s','UP8_step','sumsy'),('UP8Pd','UP8_P_','debt'),('UP8Ps','UP8_P_','sumsy'),
 ('T8d','T8_','debt'),('T8s','T8_','sumsy'),('A8d','A8_','debt'),('D100','D8_100','debt'),('D50','D8_50','debt'),('D60','D8_60','debt'),('EU8','EU8_','debt'),('RV8d','RV8_','debt'),('RV8s','RV8_','sumsy'),
 ('K8d','K8_','debt'),('K8s','K8_','sumsy'),('KV8d','KV8','debt'),('Q8d','Q8_','debt'),('Q8s','Q8_','sumsy'),('H8d','H8_','debt'),('H8s','H8_','sumsy'),('HC8d','HC8_step','debt'),('HC8s','HC8_step','sumsy'),('HC10d','HC8_10','debt'),('HC10s','HC8_10','sumsy'),
 ('CT8d','CT8','debt'),('CT8s','CT8','sumsy'),('C8d','C8_','debt'),('R8d','R8_','debt'),('R8s','R8_','sumsy'),('RZ8','RZ8','sumsy'),('Z8','Z8_','sumsy'),('L2','L2_','sumsy'),('LPT8','LPT8','sumsy'),
 ('DGI8','DGI8','debt'),('DD8','DD8_','debt'),('DDL8','DDL8_debt','debt'),('DDLPT','DDL8_PT','debt'),('DDGL8','DDGL8_debt','debt'),('DDGL35','DDGL8_35','debt'),
 ('W11','W2_11','debt'),('W13','W2_13','debt'),('W20','W2_20','debt'),('F2','F8_2','sumsy'),('F3','F8_3','sumsy'),('F4','F8_4','sumsy'),
 ('M00s','M0_0','sumsy'),('M05s','M0_5','sumsy'),('M020s','M0_20','sumsy'),('M80s','M8_0','sumsy'),('Yn_d','Y8_nonotice','debt'),('Yn_s','Y8_nonotice','sumsy'),('Ynl_d','Y8_noloyalty','debt'),('Ynl_s','Y8_noloyalty','sumsy'),('Yf_d','Y8_floor3','debt'),('Yf_s','Y8_floor3','sumsy'),
 ('S1s','S1_','sumsy'),('S1d','S1_','debt'),('S3d','S3_step','debt'),('S3s','S3_step','sumsy'),('SB2s','SB2','sumsy'),('S3W20d','S3_W20','debt'),('S3W20s','S3_W20','sumsy'),('S3W11s','S3_W11','sumsy'),('S3W13s','S3_W13','sumsy'),('S3NGPs','S3_NGP','sumsy'),('S3NGPd','S3_NGP','debt'),('S3NDPs','S3_NDP','sumsy'),('S3NDPd','S3_NDP','debt'),('SP10','S3_SP10_','sumsy'),('SP100','S3_SP100','sumsy'),('SP300','S3_SP300','sumsy'),
 ('I8','I8_','debt'),('N8s','N8_','sumsy'),('N8d','N8_','debt'),('X1','X1_','sumsy'),('X2','X2_','debt'),('G40d','G10_40','debt'),('NDC8d','NDC8','debt'),('V8NDCd','V8_NDC','debt')]
out = {}
for key, pre, s_ in KEYS:
    fs = parts(pre, s_)
    if not fs: out[key] = None; continue
    c = fs[0].columns
    g = lambda col: m(fs, lambda f: f[col].iloc[-1]) if col in c else float('nan')
    def rep(f):
        i = int(f.government_debt.idxmax()); t = f.government_debt.iloc[i:] < 1
        return float(t.idxmax() + 1) if t.any() else np.nan
    def infl(f):
        a, b = f.price_bread.iloc[-1], f.price_bread.iloc[min(11, len(f) - 1)]
        return 100 * ((a / b) ** (1 / 9) - 1) if a == a and b == b and a > 0 and b > 0 else np.nan
    out[key] = dict(n=len(fs), alive=g('persons_alive'), worst=float(min(f.persons_alive.iloc[-1] for f in fs)), unemp=g('unemployed'), bread=g('price_bread'), infl=m(fs, infl),
        debt5=m(fs, lambda f: f.government_debt.iloc[min(59, len(f) - 1)]), debt10=g('government_debt'), peak=m(fs, lambda f: f.government_debt.max()), peak_month=m(fs, lambda f: f.government_debt.idxmax() + 1),
        repaid=float(sum(1 for f in fs if f.government_debt.iloc[-1] < 1)), repaid_month=m(fs, rep), bailouts=g('bank_bailouts'), writeoff=g('bad_debt'), liq=g('liquidations'), restarted=g('new_firms'),
        gap=g('wealth_gap_meals'), bottom=g('wealth_bottom10_meals'), money=g('money_in_circulation'), land=g('land_price_traded'), rent=g('price_rent'), grain=g('price_grain'), hh=g('land_households_share'),
        tax12=m(fs, lambda f: f.tax.tail(12).sum()), outlay12=m(fs, lambda f: f.government_outlay.tail(12).sum()), hungry_peak=m(fs, lambda f: f.hungry.max()), hungry_after60=m(fs, lambda f: f.hungry.iloc[60:].max() if len(f) > 60 else np.nan),
        tickets=g('tickets_sold'), proj_cost=g('project_cost'), proj_rev=g('project_revenue'), rides=g('rides'), rides_un=g('rides_unaffordable'), gold=g('gold_price'), premium=g('premium_loaves'), dividend=g('surplus_redistributed'),
        levy_div=g('levy_dividend'), basic=g('basic_income'), hoard_cash=g('cash_hoarders'), death_month=m(fs, lambda f: float(len(f)) if f.persons_alive.iloc[-1] == 0 else np.nan),
        debt_in_bread=m(fs, lambda f: (f.government_debt.iloc[-1] / f.price_bread.iloc[-1]) / max(f.government_debt.iloc[11] / f.price_bread.iloc[11], 1e-9) if f.price_bread.iloc[-1] == f.price_bread.iloc[-1] else np.nan),
        spending_scale=g('spending_scale'))
json.dump(out, sys.stdout)

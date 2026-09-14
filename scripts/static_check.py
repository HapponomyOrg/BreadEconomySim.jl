# Static consistency check of the v2 bread economy at output = demand (32 breads, 16 grain, 16 land).
b = 5.0          # bread price (numeraire: meal = 10)
i = 0.03         # interest per round (order of magnitude from the runs)
t_r = 0.15
N, LO, LAND = 16, 2, 14
def check(t_w, term, r):
    a = 1/term + i                              # amortisation + interest share on working capital
    w = 2*b/(3*(1-t_w))                          # min gross wage: full-time nets one meal
    g = (1+a)*(r+w)                              # farm margin exactly covers a
    bak_max_g = 2*b/(1+a) - w                    # bakery margin >= a requires g <= this
    ok = g <= bak_max_g + 1e-9 and w >= 2*b/3 and w <= g - r and w <= 2*b - g and r <= 0.6*g
    # flows
    wg = 2*b*1.10/(3*(1-t_w))                    # gross government wage per unit
    Lp, Lg = 34, 4
    Mf, Mb = 16*(g-r-w), 16*(2*b-g-w)
    tax = t_w*(Lp*w + Lg*wg) + t_r*LAND*LO*r
    gov_wages_net = (1-t_w)*Lg*wg
    hh_income = (1-t_w)*Lp*w + gov_wages_net + (1-t_r)*LAND*LO*r + 2*w*(1-t_w)   # + bank wage (2 units)
    need = N*2*b
    return dict(t_w=t_w, term=term, r=r, w=round(w,3), g=round(g,3), g_max=round(bak_max_g,3), feasible=ok,
                Mf=round(Mf,1), Mb=round(Mb,1), tax=round(tax,1), gov_out=round(gov_wages_net,1),
                hh_net=round(hh_income,1), hh_need=need, gap=round(hh_income-need,1))
print(f"{'t_w':>5}{'term':>5}{'r':>5}{'w':>7}{'g':>7}{'g_max':>7}{'feas':>6}{'Mf':>7}{'Mb':>7}{'tax':>7}{'govW':>7}{'hh_net':>8}{'gap':>7}")
for t_w in (0.0, 0.05, 0.10, 0.15, 0.20, 0.30):
    for term in (5, 10, 20, 40):
        for r in (0.5, 0.75):
            d = check(t_w, term, r)
            print(f"{d['t_w']:>5}{d['term']:>5}{d['r']:>5}{d['w']:>7}{d['g']:>7}{d['g_max']:>7}{str(d['feasible']):>6}{d['Mf']:>7}{d['Mb']:>7}{d['tax']:>7}{d['gov_out']:>7}{d['hh_net']:>8}{d['gap']:>7}")

"""
Static consistency check for the v2 bread economy (one round, steady state, full needs met).
Persons: N=16 (2 landowners, L=14 land each). Demand fixed: 2 breads per person -> B = 32 breads = 16 grain = 16 land.
Labour: 16 farm + 16 bakery + 2 bank units (private), government hires up to 4 leftover units.
Prices: b bread, g grain, r rent, w wage (gross). Taxes t_w on wages, t_r on rent.
Conditions:
 (1) worker net full-time >= meal:            3 w (1 - t_w) >= 2 b
 (2) farm margin covers amortisation:         g - r - w >= (r + w) (1/term + i)
 (3) bakery margin covers amortisation:       2b - g - w >= (g + w) (1/term + i)
 (4) zones of agreement:  2b/3 <= w <= min(g - r, 2b - g);  r <= 0.6 g;  g <= 2b - 0.5 w
 (5) household budget: sum of net incomes + fees >= 32 b (no structural household deficit)
 (6) government balance: tax >= gov net wages + fees
"""
import itertools, math
N, L, B, G = 16, 14, 32, 16
def check(b, g, r, w, t_w, t_r, term, i=0.03, gov_units=4):
    over = 1/term + i
    c1 = 3*w*(1-t_w) - 2*b
    c2 = (g - r - w) - (r + w)*over
    c3 = (2*b - g - w) - (g + w)*over
    c4 = min(w - 2*b/3, (g - r) - w, (2*b - g) - w, 0.6*g - r, (2*b - 0.5*w) - g)
    wage_g = 2*1.1*b/(1-t_w)/3                      # gross government wage per unit
    tax = t_w*(34*w + gov_units*wage_g) + t_r*(2*L*r)
    gov_net_wages = gov_units*wage_g*(1-t_w)
    # households: private wages (34 units incl. bank), rent, government wages; unemployed persons get fees
    # persons needed for 34+4 units at 3 units each = 12.7 -> assume 13 persons work, 3 (incl. landowners) partly idle
    fees_needed = max(0.0, 32*b - (34*w*(1-t_w) + 2*L*r*(1-t_r) + gov_net_wages))
    c6 = tax - gov_net_wages - fees_needed
    margins = G*(g - r - w) + G*(2*b - g - w)
    return dict(b=b, g=g, r=r, w=w, t_w=t_w, term=term, worker=round(c1,2), farm=round(c2,2), bakery=round(c3,2), zones=round(c4,2),
                fees_needed=round(fees_needed,1), gov_balance=round(c6,1), margins=round(margins,1), bank_wage=round(2*w,1),
                feasible = c1 >= 0 and c2 >= 0 and c3 >= 0 and c4 >= 0 and c6 >= 0)

b = 5.0
best = []
for t_w in [0.30, 0.20, 0.15, 0.10, 0.05, 0.0]:
    for term in [5, 10, 20, 30]:
        found = None
        for w in [x/20 for x in range(60, 101)]:
            for r in [x/20 for x in range(5, 41)]:
                for g in [x/20 for x in range(80, 181)]:
                    res = check(b, g, r, w, t_w, 0.15, term)
                    if res['feasible']:
                        slack = min(res['farm'], res['bakery'], res['zones'], res['worker'])
                        if found is None or slack > found[0]:
                            found = (slack, res)
        print(f"t_w={t_w:.2f} term={term:>2}:", "INFEASIBLE" if found is None else found[1])

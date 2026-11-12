"""The table of the bread pre-order experiment (coder brief docs/future_work/coder_brief_bread_preorders_2026-11-11.md, §8.3).

    python3 scripts/preorder_report.py 2026-11-11.1 [--standard] [--variants base,preorders_at_risk,...]

Reads results/parts/ablation_<version>_<variant>[_standard]/<step>__<system>__<seed>.csv (written by `ablation` in
scripts/planning_ablation.jl) and, if present, results/ablation_<version>_<variant>[_standard]_stylized_facts_runs.csv (written by
scripts/stylized_facts.py on that folder). Prints one block per measure group, one row per cell × village × variant (means over
the seeds; deaths also as a total), and writes results/preorders_<version>[_standard]_table.csv.

Measures (per run, then the mean over runs):
  purpose   deaths (all months), deaths_with_cash, missed_bread_with_cash, hungry villager-months (sum of `hungry`)
  orders    share of bread sold on order; orders refused, failed, unpaid (sums); the bakeries' shares of the orders: the largest
            share (mean over months), the month-to-month swing (half the sum of absolute changes in shares, mean over months),
            and the share of orders taken by bakeries founded during the run (id > 100: the founding bakeries have small ids)
  bakeries  bread baked a month against the 1,024 a village of 512 needs; bread donated and thrown away a month; firms wound up
            (liquidation events are not in the rows: the run table's `liquidations` if present); bakeries open at the end;
            bakeries' wealth at the end
  prices    bread price in the last year; its yearly change from year one; sd_gdp and ac1_gdp (stylized facts, median-free here:
            the mean over runs)
  others    unemployed and work sold a villager in the last year, wealth Gini and the poorest tenth (meals) at the end, public debt
"""
import argparse, glob, os, re, sys
import numpy as np, pandas as pd

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DEFAULT_VARIANTS = ["base", "preorders_at_risk", "preorders_after_hunger_1", "preorders_after_hunger_3", "preorders_after_hunger_12",
                    "preorders_at_risk_growth_50", "preorders_at_risk_no_limit"]


def order_shares(s):
    """'8:512.0;9:480.0' -> {8: 512.0, 9: 480.0}"""
    if not isinstance(s, str) or not s:
        return {}
    out = {}
    for part in s.split(";"):
        k, v = part.split(":")
        out[int(k)] = float(v)
    return out


def run_measures(d):
    d = d.sort_values("round")
    last = d.tail(12)
    r = {}
    r["alive_end"] = d.persons_alive.iloc[-1]
    r["deaths"] = d.deaths.sum()
    r["deaths_with_cash"] = d.deaths_with_cash.sum() if "deaths_with_cash" in d else np.nan
    r["missed_with_cash"] = d.missed_bread_with_cash.sum() if "missed_bread_with_cash" in d else np.nan
    r["hungry_months"] = d.hungry.sum()
    r["share_on_order"] = d.bread_delivered_on_order.sum() / max(d.bread_sold.sum(), 1) if "bread_delivered_on_order" in d else np.nan
    r["refused"] = d.bread_orders_refused.sum() if "bread_orders_refused" in d else np.nan
    r["failed"] = d.bread_orders_failed.sum() if "bread_orders_failed" in d else np.nan
    r["unpaid"] = d.bread_orders_unpaid.sum() if "bread_orders_unpaid" in d else np.nan
    tops, swings, newshare, nb = [], [], [], []
    prev = None
    for s in (d.bread_orders_by_bakery if "bread_orders_by_bakery" in d else []):
        o = order_shares(s)
        tot = sum(o.values())
        if tot <= 0:
            prev = None
            continue
        sh = {k: v / tot for k, v in o.items()}
        tops.append(max(sh.values())); nb.append(len(sh))
        newshare.append(sum(v for k, v in sh.items() if k > 100))
        if prev is not None:
            keys = set(sh) | set(prev)
            swings.append(0.5 * sum(abs(sh.get(k, 0) - prev.get(k, 0)) for k in keys))
        prev = sh
    r["top_bakery_share"] = np.mean(tops) if tops else np.nan
    r["order_swing"] = np.mean(swings) if swings else np.nan
    r["new_bakery_share"] = np.mean(newshare) if newshare else np.nan
    r["bakeries_with_orders"] = np.mean(nb) if nb else np.nan
    r["bread_baked"] = d.bread_baked.mean()
    r["bread_donated"] = d.bread_donated.mean() if "bread_donated" in d else np.nan
    r["bread_discarded"] = d.bread_discarded.mean() if "bread_discarded" in d else np.nan
    r["bakeries_open_end"] = d.bakeries_open.iloc[-1]
    r["liquidations_rows"] = d.liquidations.sum() if "liquidations" in d else np.nan
    r["wealth_bakeries_end"] = d.wealth_bakeries.iloc[-1] if "wealth_bakeries" in d else np.nan
    pb_end = last.price_bread.mean()
    pb_y1 = d[d["round"] == min(12, d["round"].max())].price_bread.mean()
    years = max((d["round"].max() - 12) / 12, 1)
    r["bread_price_y10"] = pb_end
    r["bread_change_pct_yr"] = 100 * ((pb_end / pb_y1) ** (1 / years) - 1) if pb_y1 > 0 and pb_end > 0 else np.nan
    r["unemployed"] = last.unemployed.mean()
    r["work_per_villager"] = (last.labour_sold / last.persons_alive.clip(lower=1)).mean()
    r["gini_wealth"] = d.gini_net_wealth_persons.iloc[-1]
    r["bottom10_meals"] = d.wealth_bottom10_meals.iloc[-1]
    r["public_debt"] = d.government_debt.iloc[-1]
    return r


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("version")
    ap.add_argument("--standard", action="store_true")
    ap.add_argument("--variants", default=",".join(DEFAULT_VARIANTS))
    a = ap.parse_args()
    suffix = "_standard" if a.standard else ""
    rows = []
    for var in a.variants.split(","):
        folder = os.path.join(ROOT, "results", "parts", f"ablation_{a.version}_{var}{suffix}")
        if not os.path.isdir(folder):
            print(f"(no folder for {var})", file=sys.stderr)
            continue
        sf = os.path.join(ROOT, "results", f"ablation_{a.version}_{var}{suffix}_stylized_facts_runs.csv")
        facts = pd.read_csv(sf) if os.path.isfile(sf) else None
        runs_table = os.path.join(ROOT, "results", f"ablation_{a.version}_{var}{suffix}_runs.csv")
        liq = pd.read_csv(runs_table) if os.path.isfile(runs_table) else None
        for f in sorted(glob.glob(os.path.join(folder, "*__*__*.csv"))):
            step, system, seed = re.match(r"(.+)__(debt|sumsy)__(\d+)\.csv$", os.path.basename(f)).groups()
            d = pd.read_csv(f)
            r = {"variant": var, "cell": step.split("_")[0], "system": system, "seed": int(seed)}
            r.update(run_measures(d))
            if facts is not None:
                x = facts[(facts.system == system) & (facts.seed == int(seed)) & (facts.rung.astype(str).str.replace(r"[^A-Za-z0-9]+", "_", regex=True).str.strip("_") == step.strip("_"))]
                r["sd_gdp"] = x.sd_gdp.iloc[0] if len(x) and "sd_gdp" in x else np.nan
                r["ac1_gdp"] = x.ac1_gdp.iloc[0] if len(x) and "ac1_gdp" in x else np.nan
            if liq is not None:
                x = liq[(liq.system == system) & (liq.seed == int(seed)) & (liq.rung.astype(str).str.split().str[0] == r["cell"])]
                r["liquidations"] = x.liquidations.iloc[0] if len(x) else np.nan
            rows.append(r)
    runs = pd.DataFrame(rows)
    if runs.empty:
        sys.exit("no runs found")
    out = os.path.join(ROOT, "results", f"preorders_{a.version}{suffix}_runs.csv")
    runs.to_csv(out, index=False)
    g = runs.groupby(["cell", "system", "variant"], sort=False)
    table = g.mean(numeric_only=True).drop(columns=["seed"]).join(g.size().rename("runs")).join(g.deaths.sum().rename("deaths_total"))
    order = {v: i for i, v in enumerate(a.variants.split(","))}
    table = table.reset_index().sort_values(["cell", "system", "variant"], key=lambda c: c.map(order) if c.name == "variant" else c)
    tout = os.path.join(ROOT, "results", f"preorders_{a.version}{suffix}_table.csv")
    table.to_csv(tout, index=False)
    groups = {
        "purpose": ["runs", "deaths_total", "deaths", "deaths_with_cash", "missed_with_cash", "hungry_months", "alive_end"],
        "orders": ["share_on_order", "refused", "failed", "unpaid", "top_bakery_share", "order_swing", "new_bakery_share", "bakeries_with_orders"],
        "bakeries": ["bread_baked", "bread_donated", "bread_discarded", "liquidations", "bakeries_open_end", "wealth_bakeries_end"],
        "prices": ["bread_price_y10", "bread_change_pct_yr", "sd_gdp", "ac1_gdp"],
        "others": ["unemployed", "work_per_villager", "gini_wealth", "bottom10_meals", "public_debt"],
    }
    pd.set_option("display.width", 250); pd.set_option("display.max_columns", 30)
    for name, cols in groups.items():
        cols = [c for c in cols if c in table]
        print(f"\n== {name}")
        print(table[["cell", "system", "variant"] + cols].to_string(index=False, float_format=lambda x: f"{x:.3g}"))
    print(f"\nwrote {out} and {tout}")


if __name__ == "__main__":
    main()

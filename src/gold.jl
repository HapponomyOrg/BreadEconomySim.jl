# Gold (5 October 2026, Stef): a fixed stock, a pure store of value, traded on a market like land's.
#
# A gram yields nothing, pays no fee and never spoils. Its only value is the belief that it can be sold again. Under SuMSy idle
# money loses value and gold does not, so gold is where a hoarder goes; under debt money deposits earn and gold does not.
# Buyers: villagers with money to spare beyond `gold_buyer_margin_in_meals` meals (and the cushion) buy a gram a month when the
# price is within that spare. Sellers: holders short of cash (below the cushion, or hungry) sell a gram; so, with probability
# `gold_sale_rate` a month, does any holder for reasons of their own. Trades are at the quoted price. The quote moves by
# `gold_price_step` on unserved demand (never above the most a buyer could pay) or on unsold offers (never below zero). Gold is
# valued in wealth at the median price of the last twelve months' trades.

"""The gold the village holds and who holds it."""
gold_in_village(model) = sum(w.gold for w in persons(model); init = 0.0)

"""Record a trade and revalue gold at the median of the last twelve months' trades."""
function record_gold_sale!(model, price::Float64)
    now = current_round(model)
    push!(model.gold_sales_log, (now, price))
    filter!(x -> now - x[1] < 12, model.gold_sales_log)
    v = sort([x[2] for x in model.gold_sales_log]); n = length(v)
    model.gold_valuation = isodd(n) ? v[(n + 1) ÷ 2] : (v[n ÷ 2] + v[n ÷ 2 + 1]) / 2
    return nothing
end

"""
    gold_market!(model)

One month of the gold market: sellers who must or wish to sell meet buyers with money to spare; then the quote moves.
"""
function gold_market!(model)
    p = parameters(model)
    p.gold_grams_per_villager > 0 || return nothing
    rng = stream(model, :gold)
    price = model.gold_price
    spare(w) = cash(w) - buffer_target(model, w) - p.gold_buyer_margin_in_meals * meal_price(model)
    buyers = stable_shuffle(rng, [w for w in persons(model) if spare(w) >= price])
    sellers = Person[]
    for w in stable_shuffle(rng, [w for w in persons(model) if w.gold >= 1.0])
        forced = w.hunger > 0 || cash(w) < buffer_target(model, w)
        (forced || rand(rng) < p.gold_sale_rate) && push!(sellers, w)
    end
    demand = Float64(length(buyers)); supply = Float64(length(sellers)); sold = 0.0
    for s in sellers
        isempty(buyers) && break
        b = popfirst!(buyers)
        b === s && (isempty(buyers) ? break : (b = popfirst!(buyers)))
        transfer!(model, b, s, price, :gold)
        s.gold -= 1.0; b.gold += 1.0; sold += 1.0
        record_gold_sale!(model, price)
        log_event!(model, :gold_sale; seller = s.id, buyer = b.id, price = price)
    end
    model.gold_sold_this_round = sold
    unmet = demand - sold; unsold = supply - sold
    if demand > 0 && unmet >= p.unmet_demand_share * demand - 1e-9 && unmet > 0
        best_bid = maximum(spare(w) for w in persons(model); init = 0.0)
        model.gold_price = min(price * (1 + p.gold_price_step), max(best_bid, price))
    elseif supply > 0 && unsold >= p.unsold_share * supply - 1e-9 && unsold > 0
        model.gold_price = price * (1 - p.gold_price_step)
    end
    return nothing
end

"""Persons eat from their own stock: a full meal (two breads), one bread, or nothing (spec v1 §2)."""
function eat!(model)
    p = parameters(model)
    meal = Float64(p.breads_per_meal)
    # 11 Nov (bread pre-orders, measured whatever the switch says): a villager who eats no bread while holding at least five meals'
    # worth of money at this month's bread price did not go hungry for want of money
    pb = average_price(model, :bread); pb = (isfinite(pb) && pb > 0) ? pb : expected_price(model, :bread)
    five_meals = 5 * meal * pb
    for a in persons(model)
        have = bread_units(a)
        if have >= meal - 1e-9
            take_stock!(a.bread, a.glutton ? min(have, Float64(a.greed == :greedy ? p.greedy_max_breads_per_round : p.maximum_breads_per_round)) : meal); a.ate_this_round = :whole
        elseif have >= 1 - 1e-9
            take_stock!(a.bread, 1.0); a.ate_this_round = :half
        else
            a.ate_this_round = :none
        end
        m = a.ate_this_round
        if m == :whole
            a.hunger = 0
            a.capacity = min(a.capacity + p.capacity_recovery_per_round, p.maximum_capacity)
        elseif m == :none
            a.hunger += 1
            a.capacity = max(a.capacity - 1, 0.0)
        end
        a.last_meal = m
        a.labour_income > 0 && (a.last_wage_income = a.labour_income)
        log_event!(model, :meal; actor = a.id, meal = m, hunger = a.hunger, capacity = a.capacity)
        with_cash = m == :none && cash(a) >= five_meals - 1e-9
        with_cash && (model.missed_bread_with_cash_this_round += 1)
        if a.hunger >= p.rounds_without_food_until_death
            with_cash && (model.deaths_with_cash_this_round += 1)
            die!(model, a)
        end
    end
    return nothing
end

function die!(model, a::Person)
    a.alive = false
    a.death_round = current_round(model)
    clear_bread_order!(model, a); a.bread_order_failed = false            # 11 Nov: a dead villager's order is gone
    log_event!(model, :death; actor = a.id, cash = cash(a), debt = debt_of(a), land = a.land)
    settle_estate!(model, a)
    return nothing
end

"""Grain and bread age one round; anything at `spoilage_age_in_rounds` is discarded."""
function age_stock!(model)
    p = parameters(model)
    for a in alive_agents(model)
        stocks = a isa Person ? ((:bread, a.bread),) : ((:grain, a.grain), (:bread, a.bread))
        for (name, items) in stocks
            foreach(i -> i.age += 1, items)
            life = (name == :grain && p.grain_spoilage_age_in_rounds > 0) ? p.grain_spoilage_age_in_rounds : p.spoilage_age_in_rounds   # 3 Nov
            spoiled = sum(i.units for i in items if i.age >= life; init = 0.0)
            spoiled > 0 && log_event!(model, :spoilage; actor = a.id, good = name, units = spoiled)
            a isa Enterprise && (a.spoiled_this_round += spoiled)             # 22 Oct: for the floor per unit sold
            filter!(i -> i.age < life, items)
        end
    end
    return nothing
end

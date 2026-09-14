"""Persons eat from their own stock: a full meal (two breads), one bread, or nothing (spec v1 §2)."""
function eat!(model)
    p = parameters(model)
    meal = Float64(p.breads_per_meal)
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
        a.hunger >= p.rounds_without_food_until_death && die!(model, a)
    end
    return nothing
end

function die!(model, a::Person)
    a.alive = false
    a.death_round = current_round(model)
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
            spoiled = sum(i.units for i in items if i.age >= p.spoilage_age_in_rounds; init = 0.0)
            spoiled > 0 && log_event!(model, :spoilage; actor = a.id, good = name, units = spoiled)
            filter!(i -> i.age < p.spoilage_age_in_rounds, items)
        end
    end
    return nothing
end

# Calibration anchors (1 November 2026, Stef): the real-world numbers a run is calibrated to, by country, so that a run made
# on one country's anchors can be compared with a run made on another's. Every anchor carries its source; `confirm = true`
# marks a value taken from general knowledge that has not yet been checked against the source named. A run records the
# name of the set it used in the `calibration` column of its output.
#
# Two things a set supplies:
#   anchors    the numbers themselves, with sources — for the report and the dashboard;
#   overrides  the model parameters the anchors fix — applied with `calibrated(name)` (a NamedTuple to splat into
#              `SimulationParameters`); everything the anchors do not fix stays as set elsewhere.
# Add a country as another entry; keep the same anchor names so the sets line up column by column.

struct Anchor
    value::Float64
    unit::String
    source::String
    confirm::Bool
end
Anchor(value, unit, source; confirm = false) = Anchor(Float64(value), unit, source, confirm)

const CALIBRATIONS = Dict{Symbol, NamedTuple}(
    :belgium => (;
        # taxes
        vat_food = Anchor(0.06, "share of the net price", "FPS Finance, VAT rate table: 6 % on basic foodstuffs including bread"),
        vat_services = Anchor(0.21, "share of the net price", "FPS Finance, VAT rate table: the standard 21 % on most services (hospitality 12 %, hairdressing 21 %)"),
        land_transfer_duty = Anchor(0.12, "share of the sale price", "Flemish registration duty since 2022, 12 % (3 % for the buyer's sole own home; 12.5 % in Wallonia and Brussels)"),
        land_transfer_duty_own_home = Anchor(0.03, "share of the sale price", "Flemish registration duty, the sole own home, since 2022"),
        # household budgets (Engel)
        food_share_of_spending = Anchor(0.139, "share of household consumption", "Statbel, Household Budget Survey 2022: food and non-alcoholic drinks 13.9 % (14.0 % in 2018)"),
        housing_share_of_spending = Anchor(0.307, "share of household consumption", "Statbel, HBS 2022: housing (rent, energy, water, upkeep) 30.7 %; 30.6 % in 2024"),
        leisure_share_of_spending = Anchor(0.077, "share of household consumption", "Statbel, HBS 2022: culture and leisure 7.7 % (6.3 % in 2020, 7.2 % in 2018); hospitality rose 16.9 % from 2022 to 2024"),
        services_share_of_spending = Anchor(0.55, "share of household consumption", "Statbel, HBS 2022: services (housing services, transport services, health, recreation, restaurants and hotels, personal care, other services) against goods — to compute from the COICOP table; approx."; confirm = true),
        food_share_lowest_decile = Anchor(0.18, "share of household consumption", "Statbel, HBS 2022, food and non-alcoholic drinks, first income decile; approx."; confirm = true),
        food_share_highest_decile = Anchor(0.11, "share of household consumption", "Statbel, HBS 2022, food and non-alcoholic drinks, tenth income decile; approx."; confirm = true),
        services_employment_share = Anchor(0.78, "share of employment", "Statbel, labour force survey: services' share of employment, approx."; confirm = true),
        # time use (Becker 1965: consumption takes time)
        free_time_hours_per_day = Anchor(6.65, "hours a day", "OECD, Society at a Glance 2009: Belgium first of 18 countries with 6 h 39 min of free time a day (average 5 h 47 min); HETUS 2010: leisure and social life 4.5–6 h a day"),
        sleep_and_care_hours_per_day = Anchor(11.0, "hours a day", "HETUS 2010 (18 countries, 2008–2015): sleep 8–9 h, eating 1.5–2 h, other personal care about 1 h"; confirm = true),
        household_hours_per_day = Anchor(3.0, "hours a day", "HETUS 2010: household and family care 2.5–3.5 h a day; Statbel/TOR time-use survey for the Belgian value"; confirm = true),
        full_time_hours_per_month = Anchor(165.0, "hours a month", "the Belgian legal full-time week of 38 hours × 52 / 12"),
        services_consumption_hours_per_day = Anchor(1.25, "hours a day", "HETUS 2010: entertainment and culture 10–20 min, social life about 1 h, eating out inside eating; a ceiling of 1–1.5 h a day for purchased services; approx."; confirm = true),
        staff_hours_per_customer_hour = Anchor(0.4, "staff-hours per customer-hour", "sector average: restaurants about 0.5, cinemas and theatres far less, hairdressing 1; to confirm against Belgian hospitality labour productivity"; confirm = true),
        # labour and prices
        unemployment_rate = Anchor(0.056, "share of the labour force", "Statbel, LFS 2023, 15–64; approx."; confirm = true),
        inflation_target = Anchor(0.02, "a year", "ECB, the symmetric 2 % target"),
        # wealth
        wealth_gini = Anchor(0.60, "Gini of net household wealth", "ECB HFCS 2021, Belgium; approx."; confirm = true),
    ),
)

"""The model parameters a calibration set fixes, to splat into `SimulationParameters`. Belgium: bread at the 6 % VAT, services
at 21 %, the time budget from the time-use anchors (the Engel demand itself stays a switch until it is traced and calibrated
against the decile shares, roadmap step 10)."""
function calibrated(name::Symbol)
    name == :none && return (;)
    haskey(CALIBRATIONS, name) || error("no calibration named $name; known: $(collect(keys(CALIBRATIONS)))")
    c = CALIBRATIONS[name]
    return (; calibration = name, consumption_tax_rate = c.vat_food.value, consumption_tax_rate_services = c.vat_services.value,
              services_time_budget = true, services_engel_demand = true, sleep_and_care_hours_per_day = c.sleep_and_care_hours_per_day.value, household_hours_per_day = c.household_hours_per_day.value,
              hours_per_labour_unit = c.full_time_hours_per_month.value / 3, staff_hours_per_customer_hour = c.staff_hours_per_customer_hour.value,
              services_time_share = c.services_consumption_hours_per_day.value / c.free_time_hours_per_day.value)
end

"""The anchors of a set as a table (name, value, unit, source, confirm) — for reports and the dashboard."""
anchor_table(name::Symbol) = [(name = String(k), value = a.value, unit = a.unit, source = a.source, confirm = a.confirm) for (k, a) in pairs(CALIBRATIONS[name])]

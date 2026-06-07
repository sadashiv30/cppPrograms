#include "scheduler.h"
#include "cli.h"
#include <iostream>
#include <filesystem>
#include <string>

static void seedDemo(Scheduler& sched) {
    // Appliances  {id, name, brand, model, serial, location, install_date, warranty_expiry, notes}
    sched.addAppliance({0, "Refrigerator", "Samsung", "RF28R7551SR", "SN-10001", "Kitchen",      "2020-03-10", "2025-03-10", "Side-by-side, stainless"});
    sched.addAppliance({0, "Washer",       "LG",      "WM4000HWA",  "SN-10002", "Laundry Room", "2022-01-15", "2027-01-15", ""});
    sched.addAppliance({0, "Dryer",        "LG",      "DLEX4000V",  "SN-10003", "Laundry Room", "2022-01-15", "2027-01-15", ""});
    sched.addAppliance({0, "Dishwasher",   "Bosch",   "SHPM88Z75N", "SN-10004", "Kitchen",      "2019-06-01", "2024-06-01", "Stainless tub"});
    sched.addAppliance({0, "Water Heater", "Rheem",   "XG40T09HE",  "SN-10005", "Basement",     "2018-04-20", "2023-04-20", "40-gal gas"});
    sched.addAppliance({0, "HVAC System",  "Carrier", "24ACC636A",  "SN-10006", "Attic",        "2015-07-12", "2020-07-12", "3-ton central AC+heat"});

    // Home features  {id, category, name, location, install_date, last_serviced, notes}
    sched.addFeature({0, "HVAC",        "Central AC & Heat", "Attic",    "2015-07-12", "2024-09-10", "R-410A refrigerant, annual service contract"});
    sched.addFeature({0, "Plumbing",    "Main Water Line",   "Basement", "2005-01-01", "2023-06-01", "Copper pipes, shutoff near water meter"});
    sched.addFeature({0, "Roof",        "Asphalt Shingles",  "",         "2010-08-01", "2022-10-05", "30-year architectural shingles, 2 layers"});
    sched.addFeature({0, "Electrical",  "Main Panel 200A",   "Basement", "2005-01-01", "2021-03-15", "Square D, recently inspected"});
    sched.addFeature({0, "Landscaping", "Irrigation System", "Yard",     "2017-05-01", "2025-10-15", "6 zones, winterized each fall"});

    // Tasks  {id, title, item_type, item_id, freq_days, last_done, next_due, priority, completed, notes}
    // Overdue (before 2026-06-07)
    sched.addTask({0, "Replace HVAC Filter",      "Feature",   1, 90,  "", "2026-05-01", 1, false, "MERV-13, 20x25x1 inch"});
    sched.addTask({0, "Inspect Roof for Damage",  "Feature",   3, 365, "", "2026-04-15", 2, false, "Check flashing & gutters too"});
    sched.addTask({0, "Clean Dishwasher Filter",  "Appliance", 4, 30,  "", "2026-05-25", 2, false, "Rinse under warm water"});

    // Upcoming within 30 days (2026-06-07 to 2026-07-07)
    sched.addTask({0, "Check Smoke Detectors",    "Feature",   4, 365, "", "2026-06-20", 1, false, "Test all 5 detectors, replace batteries"});
    sched.addTask({0, "Clean Dryer Vent",         "Appliance", 3, 365, "", "2026-06-25", 2, false, "Use lint brush kit, check exterior vent cap"});
    sched.addTask({0, "Run Washer Cleaning Cycle","Appliance", 2, 30,  "", "2026-07-01", 3, false, "Use affresh tablet"});

    // Future
    sched.addTask({0, "Flush Water Heater",       "Appliance", 5, 365, "", "2026-08-20", 2, false, "Drain sediment, check anode rod"});
    sched.addTask({0, "Service AC Unit",          "Feature",   1, 365, "", "2026-09-01", 1, false, "Annual professional service"});
    sched.addTask({0, "Winterize Irrigation",     "Feature",   5, 365, "", "2026-10-15", 2, false, "Blow out lines before first frost"});
    sched.addTask({0, "Check Electrical Panel",   "Feature",   4, 730, "", "2027-03-15", 3, false, "Look for breakers that trip frequently"});

    sched.save();
    std::cout << "  Demo data loaded: 6 appliances, 5 features, 10 tasks.\n";
}

int main(int argc, char* argv[]) {
    std::string data_dir = "data";
    bool demo_mode = false;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--demo") demo_mode = true;
        else                 data_dir  = arg;
    }

    if (demo_mode) data_dir = "data-demo";

    try {
        std::filesystem::create_directories(data_dir);
    } catch (const std::exception& e) {
        std::cerr << "Error creating data directory: " << e.what() << "\n";
        return 1;
    }

    Scheduler sched(data_dir);

    if (demo_mode && sched.getAppliances().empty()) {
        std::cout << "\n  Seeding demo data...\n";
        seedDemo(sched);
    }

    CLI cli(sched);
    cli.run();
    return 0;
}

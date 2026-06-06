#pragma once
#include <string>
#include <vector>

struct Appliance {
    int id = 0;
    std::string name;
    std::string brand;
    std::string model;
    std::string serial_number;
    std::string location;
    std::string install_date;
    std::string warranty_expiry;
    std::string notes;
};

struct HomeFeature {
    int id = 0;
    std::string category;    // HVAC, Plumbing, Roof, Electrical, Foundation, Landscaping
    std::string name;
    std::string location;
    std::string install_date;
    std::string last_serviced;
    std::string notes;
};

struct MaintenanceTask {
    int id = 0;
    std::string title;
    std::string item_type;   // "Appliance" or "Feature"
    int item_id = 0;
    int frequency_days = 0;  // 0 = one-time
    std::string last_done;
    std::string next_due;
    int priority = 2;        // 1=High, 2=Medium, 3=Low
    bool completed = false;
    std::string notes;
};

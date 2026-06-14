#include "cli.h"
#include <iostream>
#include <iomanip>
#include <limits>
#include <ctime>
#include <sstream>

CLI::CLI(Scheduler& sched) : m_sched(sched) {
    m_today = todayStr();
}

std::string CLI::todayStr() const {
    time_t now = time(nullptr);
    std::tm* t = localtime(&now);
    char buf[16];
    strftime(buf, sizeof(buf), "%Y-%m-%d", t);
    return buf;
}

void CLI::printLine(char c, int w) const {
    for (int i = 0; i < w; ++i) std::cout << c;
    std::cout << '\n';
}

void CLI::pause() const {
    std::cout << "\nPress Enter to continue...";
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
}

std::string CLI::prompt(const std::string& label, const std::string& def) {
    std::string val;
    if (def.empty())
        std::cout << "  " << label << ": ";
    else
        std::cout << "  " << label << " [" << def << "]: ";
    std::getline(std::cin, val);
    return val.empty() ? def : val;
}

int CLI::promptInt(const std::string& label, int def) {
    std::string s = prompt(label, std::to_string(def));
    try { return std::stoi(s); } catch (...) { return def; }
}

int CLI::menuChoice(int min, int max) {
    int choice = -1;
    while (choice < min || choice > max) {
        std::cout << "Choice: ";
        std::string line;
        std::getline(std::cin, line);
        try { choice = std::stoi(line); } catch (...) {}
        if (choice < min || choice > max)
            std::cout << "  Please enter a number between " << min << " and " << max << "\n";
    }
    return choice;
}

std::string CLI::priorityLabel(int p) const {
    if (p == 1) return "HIGH";
    if (p == 3) return "LOW";
    return "MED";
}

std::string CLI::itemName(const std::string& type, int id) const {
    if (type == "Appliance") {
        for (auto& a : m_sched.getAppliances())
            if (a.id == id) return a.name + " (" + a.brand + ")";
    } else {
        for (auto& f : m_sched.getFeatures())
            if (f.id == id) return f.name + " [" + f.category + "]";
    }
    return "Unknown";
}

// ----------------------------------------------------------------
// Main loop
// ----------------------------------------------------------------

void CLI::run() {
    std::cout << "\n";
    printLine('=');
    std::cout << "  HOUSE MAINTENANCE SCHEDULER & PLANNER\n";
    printLine('=');
    std::cout << "  Today: " << m_today << "\n\n";

    // Show overdue count on startup
    auto overdue = m_sched.getOverdueTasks(m_today);
    if (!overdue.empty())
        std::cout << "  ** " << overdue.size() << " OVERDUE task(s) need attention! **\n\n";

    mainMenu();
}

void CLI::mainMenu() {
    bool running = true;
    while (running) {
        std::cout << "\n";
        printLine('-');
        std::cout << "  MAIN MENU\n";
        printLine('-');
        std::cout << "  1. Dashboard (upcoming & overdue)\n";
        std::cout << "  2. Appliance Inventory\n";
        std::cout << "  3. Home Features & Systems\n";
        std::cout << "  4. Maintenance Tasks\n";
        std::cout << "  0. Exit\n";
        printLine('-');
        int c = menuChoice(0, 4);
        switch (c) {
            case 1: showDashboard(); break;
            case 2: applianceMenu(); break;
            case 3: featureMenu();   break;
            case 4: taskMenu();      break;
            case 0: running = false; break;
        }
    }
    m_sched.save();
    std::cout << "\n  Data saved. Goodbye!\n\n";
}

// ----------------------------------------------------------------
// Dashboard
// ----------------------------------------------------------------

void CLI::showDashboard() {
    printLine('=');
    std::cout << "  DASHBOARD  --  " << m_today << "\n";
    printLine('=');

    auto overdue  = m_sched.getOverdueTasks(m_today);
    auto upcoming = m_sched.getUpcomingTasks(m_today, 30);

    std::cout << "\n  OVERDUE (" << overdue.size() << ")\n";
    printLine('-', 60);
    if (overdue.empty()) {
        std::cout << "  No overdue tasks.\n";
    } else {
        std::cout << std::left
                  << std::setw(4)  << "ID"
                  << std::setw(28) << "Task"
                  << std::setw(12) << "Due"
                  << std::setw(6)  << "Pri"
                  << "Item\n";
        printLine('-', 60);
        for (auto& t : overdue) {
            std::cout << std::left
                      << std::setw(4)  << t.id
                      << std::setw(28) << t.title.substr(0, 27)
                      << std::setw(12) << t.next_due
                      << std::setw(6)  << priorityLabel(t.priority)
                      << itemName(t.item_type, t.item_id) << "\n";
        }
    }

    std::cout << "\n  UPCOMING (next 30 days) (" << upcoming.size() << ")\n";
    printLine('-', 60);
    if (upcoming.empty()) {
        std::cout << "  No upcoming tasks.\n";
    } else {
        std::cout << std::left
                  << std::setw(4)  << "ID"
                  << std::setw(28) << "Task"
                  << std::setw(12) << "Due"
                  << std::setw(6)  << "Pri"
                  << "Item\n";
        printLine('-', 60);
        for (auto& t : upcoming) {
            std::cout << std::left
                      << std::setw(4)  << t.id
                      << std::setw(28) << t.title.substr(0, 27)
                      << std::setw(12) << t.next_due
                      << std::setw(6)  << priorityLabel(t.priority)
                      << itemName(t.item_type, t.item_id) << "\n";
        }
    }

    // Stats
    auto appliances = m_sched.getAppliances();
    auto features   = m_sched.getFeatures();
    auto tasks      = m_sched.getTasks();
    std::cout << "\n  INVENTORY SUMMARY\n";
    printLine('-', 40);
    std::cout << "  Appliances tracked : " << appliances.size() << "\n";
    std::cout << "  Home features      : " << features.size()   << "\n";
    std::cout << "  Total tasks        : " << tasks.size()      << "\n";

    pause();
}

// ----------------------------------------------------------------
// Appliances
// ----------------------------------------------------------------

void CLI::applianceMenu() {
    bool back = false;
    while (!back) {
        std::cout << "\n";
        printLine('-');
        std::cout << "  APPLIANCE INVENTORY\n";
        printLine('-');
        std::cout << "  1. List all appliances\n";
        std::cout << "  2. Add appliance\n";
        std::cout << "  3. Edit appliance\n";
        std::cout << "  4. Delete appliance\n";
        std::cout << "  0. Back\n";
        printLine('-');
        int c = menuChoice(0, 4);
        switch (c) {
            case 1: listAppliances(); break;
            case 2: addAppliance();   break;
            case 3: editAppliance();  break;
            case 4: deleteAppliance();break;
            case 0: back = true;      break;
        }
    }
}

void CLI::listAppliances() {
    auto items = m_sched.getAppliances();
    printLine('=');
    std::cout << "  APPLIANCES (" << items.size() << ")\n";
    printLine('=');
    if (items.empty()) { std::cout << "  No appliances recorded.\n"; pause(); return; }

    std::cout << std::left
              << std::setw(4)  << "ID"
              << std::setw(20) << "Name"
              << std::setw(14) << "Brand"
              << std::setw(16) << "Location"
              << std::setw(12) << "Installed"
              << "Warranty Exp.\n";
    printLine('-');
    for (auto& a : items) {
        std::cout << std::left
                  << std::setw(4)  << a.id
                  << std::setw(20) << a.name.substr(0, 19)
                  << std::setw(14) << a.brand.substr(0, 13)
                  << std::setw(16) << a.location.substr(0, 15)
                  << std::setw(12) << a.install_date
                  << a.warranty_expiry << "\n";
    }

    // Detailed view option
    std::cout << "\n  Enter ID for details (0 to skip): ";
    std::string s; std::getline(std::cin, s);
    int id = 0; try { id = std::stoi(s); } catch (...) {}
    if (id > 0) {
        auto* a = m_sched.findAppliance(id);
        if (a) {
            printLine('-');
            std::cout << "  Name    : " << a->name           << "\n"
                      << "  Brand   : " << a->brand          << "\n"
                      << "  Model   : " << a->model          << "\n"
                      << "  Serial  : " << a->serial_number  << "\n"
                      << "  Location: " << a->location       << "\n"
                      << "  Installed: " << a->install_date  << "\n"
                      << "  Warranty: " << a->warranty_expiry<< "\n"
                      << "  Notes   : " << a->notes          << "\n";
        } else {
            std::cout << "  Not found.\n";
        }
    }
    pause();
}

void CLI::addAppliance() {
    std::cout << "\n  ADD APPLIANCE\n";
    printLine('-');
    Appliance a;
    a.name           = prompt("Name (e.g. Refrigerator)");
    a.brand          = prompt("Brand (e.g. Samsung)");
    a.model          = prompt("Model number");
    a.serial_number  = prompt("Serial number");
    a.location       = prompt("Location (e.g. Kitchen)");
    a.install_date   = prompt("Install date (YYYY-MM-DD)");
    a.warranty_expiry= prompt("Warranty expiry (YYYY-MM-DD)");
    a.notes          = prompt("Notes");
    if (a.name.empty()) { std::cout << "  Cancelled.\n"; return; }
    m_sched.addAppliance(a);
    m_sched.save();
    std::cout << "  Appliance added.\n";
    pause();
}

void CLI::editAppliance() {
    listAppliances();
    int id = promptInt("Enter appliance ID to edit");
    auto* a = m_sched.findAppliance(id);
    if (!a) { std::cout << "  Not found.\n"; pause(); return; }
    std::cout << "\n  EDIT APPLIANCE (press Enter to keep current value)\n";
    printLine('-');
    Appliance updated = *a;
    updated.name           = prompt("Name", a->name);
    updated.brand          = prompt("Brand", a->brand);
    updated.model          = prompt("Model", a->model);
    updated.serial_number  = prompt("Serial", a->serial_number);
    updated.location       = prompt("Location", a->location);
    updated.install_date   = prompt("Install date", a->install_date);
    updated.warranty_expiry= prompt("Warranty expiry", a->warranty_expiry);
    updated.notes          = prompt("Notes", a->notes);
    m_sched.updateAppliance(id, updated);
    m_sched.save();
    std::cout << "  Updated.\n";
    pause();
}

void CLI::deleteAppliance() {
    listAppliances();
    int id = promptInt("Enter appliance ID to delete (0 to cancel)");
    if (id == 0) return;
    std::cout << "  Confirm delete? (y/N): ";
    std::string yn; std::getline(std::cin, yn);
    if (yn == "y" || yn == "Y") {
        m_sched.deleteAppliance(id);
        m_sched.save();
        std::cout << "  Deleted.\n";
    }
    pause();
}

// ----------------------------------------------------------------
// Home Features
// ----------------------------------------------------------------

void CLI::featureMenu() {
    bool back = false;
    while (!back) {
        std::cout << "\n";
        printLine('-');
        std::cout << "  HOME FEATURES & SYSTEMS\n";
        printLine('-');
        std::cout << "  Categories: HVAC, Plumbing, Electrical, Roof,\n"
                  << "              Foundation, Landscaping, Pool, Other\n";
        printLine('-');
        std::cout << "  1. List all features\n";
        std::cout << "  2. Add feature/system\n";
        std::cout << "  3. Edit feature\n";
        std::cout << "  4. Delete feature\n";
        std::cout << "  0. Back\n";
        printLine('-');
        int c = menuChoice(0, 4);
        switch (c) {
            case 1: listFeatures(); break;
            case 2: addFeature();   break;
            case 3: editFeature();  break;
            case 4: deleteFeature();break;
            case 0: back = true;    break;
        }
    }
}

void CLI::listFeatures() {
    auto items = m_sched.getFeatures();
    printLine('=');
    std::cout << "  HOME FEATURES (" << items.size() << ")\n";
    printLine('=');
    if (items.empty()) { std::cout << "  No features recorded.\n"; pause(); return; }
    std::cout << std::left
              << std::setw(4)  << "ID"
              << std::setw(14) << "Category"
              << std::setw(22) << "Name"
              << std::setw(14) << "Location"
              << std::setw(12) << "Installed"
              << "Last Serviced\n";
    printLine('-');
    for (auto& f : items) {
        std::cout << std::left
                  << std::setw(4)  << f.id
                  << std::setw(14) << f.category.substr(0, 13)
                  << std::setw(22) << f.name.substr(0, 21)
                  << std::setw(14) << f.location.substr(0, 13)
                  << std::setw(12) << f.install_date
                  << f.last_serviced << "\n";
    }
    pause();
}

void CLI::addFeature() {
    std::cout << "\n  ADD HOME FEATURE / SYSTEM\n";
    printLine('-');
    HomeFeature f;
    f.category     = prompt("Category (HVAC/Plumbing/Electrical/Roof/Foundation/etc.)");
    f.name         = prompt("Name (e.g. Central AC, Water Heater)");
    f.location     = prompt("Location (e.g. Basement, Attic)");
    f.install_date = prompt("Install date (YYYY-MM-DD)");
    f.last_serviced= prompt("Last serviced (YYYY-MM-DD)");
    f.notes        = prompt("Notes");
    if (f.name.empty()) { std::cout << "  Cancelled.\n"; return; }
    m_sched.addFeature(f);
    m_sched.save();
    std::cout << "  Feature added.\n";
    pause();
}

void CLI::editFeature() {
    listFeatures();
    int id = promptInt("Enter feature ID to edit");
    auto* f = m_sched.findFeature(id);
    if (!f) { std::cout << "  Not found.\n"; pause(); return; }
    std::cout << "\n  EDIT FEATURE (Enter to keep)\n";
    HomeFeature updated = *f;
    updated.category     = prompt("Category", f->category);
    updated.name         = prompt("Name", f->name);
    updated.location     = prompt("Location", f->location);
    updated.install_date = prompt("Install date", f->install_date);
    updated.last_serviced= prompt("Last serviced", f->last_serviced);
    updated.notes        = prompt("Notes", f->notes);
    m_sched.updateFeature(id, updated);
    m_sched.save();
    std::cout << "  Updated.\n";
    pause();
}

void CLI::deleteFeature() {
    listFeatures();
    int id = promptInt("Enter feature ID to delete (0 to cancel)");
    if (id == 0) return;
    std::cout << "  Confirm delete? (y/N): ";
    std::string yn; std::getline(std::cin, yn);
    if (yn == "y" || yn == "Y") {
        m_sched.deleteFeature(id);
        m_sched.save();
        std::cout << "  Deleted.\n";
    }
    pause();
}

// ----------------------------------------------------------------
// Tasks
// ----------------------------------------------------------------

void CLI::taskMenu() {
    bool back = false;
    while (!back) {
        std::cout << "\n";
        printLine('-');
        std::cout << "  MAINTENANCE TASKS\n";
        printLine('-');
        std::cout << "  1. Show all tasks\n";
        std::cout << "  2. Add task\n";
        std::cout << "  3. Mark task complete\n";
        std::cout << "  4. Show overdue tasks\n";
        std::cout << "  5. Show upcoming (30 days)\n";
        std::cout << "  6. Delete task\n";
        std::cout << "  0. Back\n";
        printLine('-');
        int c = menuChoice(0, 6);
        switch (c) {
            case 1: listTasks();   break;
            case 2: addTask();     break;
            case 3: completeTask();break;
            case 4: showOverdue(); break;
            case 5: showUpcoming();break;
            case 6: deleteTask();  break;
            case 0: back = true;   break;
        }
    }
}

void CLI::listTasks() {
    auto tasks = m_sched.getTasks();
    printLine('=');
    std::cout << "  ALL MAINTENANCE TASKS (" << tasks.size() << ")\n";
    printLine('=');
    if (tasks.empty()) { std::cout << "  No tasks.\n"; pause(); return; }
    std::cout << std::left
              << std::setw(4)  << "ID"
              << std::setw(26) << "Title"
              << std::setw(12) << "Next Due"
              << std::setw(6)  << "Pri"
              << std::setw(6)  << "Freq"
              << "Item\n";
    printLine('-');
    for (auto& t : tasks) {
        std::string freq = t.frequency_days > 0
            ? std::to_string(t.frequency_days) + "d"
            : "once";
        std::cout << std::left
                  << std::setw(4)  << t.id
                  << std::setw(26) << t.title.substr(0, 25)
                  << std::setw(12) << (t.completed ? "DONE" : t.next_due)
                  << std::setw(6)  << priorityLabel(t.priority)
                  << std::setw(6)  << freq
                  << itemName(t.item_type, t.item_id) << "\n";
    }
    pause();
}

void CLI::addTask() {
    std::cout << "\n  ADD MAINTENANCE TASK\n";
    printLine('-');

    // Pick item type
    std::cout << "  Link to:\n  1. Appliance\n  2. Home Feature\n";
    int type_choice = menuChoice(1, 2);
    std::string item_type = (type_choice == 1) ? "Appliance" : "Feature";

    if (type_choice == 1) listAppliances();
    else                  listFeatures();

    int item_id = promptInt("Enter item ID");
    bool valid = (type_choice == 1)
        ? (m_sched.findAppliance(item_id) != nullptr)
        : (m_sched.findFeature(item_id)   != nullptr);
    if (!valid) { std::cout << "  Item not found.\n"; pause(); return; }

    MaintenanceTask t;
    t.item_type      = item_type;
    t.item_id        = item_id;
    t.title          = prompt("Task title");
    t.frequency_days = promptInt("Repeat every N days (0 = one-time)");
    t.next_due       = prompt("Next due date (YYYY-MM-DD)", m_today);

    std::cout << "  Priority: 1=High  2=Medium  3=Low\n";
    t.priority = menuChoice(1, 3);
    t.notes    = prompt("Notes");

    if (t.title.empty()) { std::cout << "  Cancelled.\n"; return; }
    m_sched.addTask(t);
    m_sched.save();
    std::cout << "  Task added.\n";
    pause();
}

void CLI::completeTask() {
    showUpcoming();
    int id = promptInt("Enter task ID to mark complete (0 to cancel)");
    if (id == 0) return;
    std::string done = prompt("Date completed (YYYY-MM-DD)", m_today);
    m_sched.completeTask(id, done);
    m_sched.save();
    std::cout << "  Task marked complete.\n";
    pause();
}

void CLI::deleteTask() {
    listTasks();
    int id = promptInt("Enter task ID to delete (0 to cancel)");
    if (id == 0) return;
    std::cout << "  Confirm delete? (y/N): ";
    std::string yn; std::getline(std::cin, yn);
    if (yn == "y" || yn == "Y") {
        m_sched.deleteTask(id);
        m_sched.save();
        std::cout << "  Deleted.\n";
    }
    pause();
}

void CLI::showOverdue() {
    auto tasks = m_sched.getOverdueTasks(m_today);
    printLine('=');
    std::cout << "  OVERDUE TASKS (" << tasks.size() << ")\n";
    printLine('=');
    if (tasks.empty()) { std::cout << "  No overdue tasks!\n"; pause(); return; }
    std::cout << std::left
              << std::setw(4)  << "ID"
              << std::setw(26) << "Title"
              << std::setw(12) << "Was Due"
              << std::setw(6)  << "Pri"
              << "Item\n";
    printLine('-');
    for (auto& t : tasks) {
        std::cout << std::left
                  << std::setw(4)  << t.id
                  << std::setw(26) << t.title.substr(0, 25)
                  << std::setw(12) << t.next_due
                  << std::setw(6)  << priorityLabel(t.priority)
                  << itemName(t.item_type, t.item_id) << "\n";
    }
    pause();
}

void CLI::showUpcoming() {
    auto tasks = m_sched.getUpcomingTasks(m_today, 30);
    printLine('=');
    std::cout << "  UPCOMING TASKS - Next 30 Days (" << tasks.size() << ")\n";
    printLine('=');
    if (tasks.empty()) { std::cout << "  Nothing scheduled in the next 30 days.\n"; pause(); return; }
    std::cout << std::left
              << std::setw(4)  << "ID"
              << std::setw(26) << "Title"
              << std::setw(12) << "Due"
              << std::setw(6)  << "Pri"
              << "Item\n";
    printLine('-');
    for (auto& t : tasks) {
        std::cout << std::left
                  << std::setw(4)  << t.id
                  << std::setw(26) << t.title.substr(0, 25)
                  << std::setw(12) << t.next_due
                  << std::setw(6)  << priorityLabel(t.priority)
                  << itemName(t.item_type, t.item_id) << "\n";
    }
    pause();
}

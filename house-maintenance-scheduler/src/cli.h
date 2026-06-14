#pragma once
#include "scheduler.h"
#include <string>

class CLI {
public:
    explicit CLI(Scheduler& sched);
    void run();

private:
    Scheduler& m_sched;
    std::string m_today;

    void mainMenu();

    // Dashboard
    void showDashboard();

    // Appliance menu
    void applianceMenu();
    void listAppliances();
    void addAppliance();
    void editAppliance();
    void deleteAppliance();

    // Feature menu
    void featureMenu();
    void listFeatures();
    void addFeature();
    void editFeature();
    void deleteFeature();

    // Task menu
    void taskMenu();
    void listTasks();
    void addTask();
    void completeTask();
    void deleteTask();
    void showOverdue();
    void showUpcoming();

    // Helpers
    std::string prompt(const std::string& label, const std::string& def = "");
    int promptInt(const std::string& label, int def = 0);
    int menuChoice(int min, int max);
    std::string todayStr() const;
    std::string priorityLabel(int p) const;
    std::string itemName(const std::string& type, int id) const;
    void printLine(char c = '-', int w = 60) const;
    void pause() const;
};

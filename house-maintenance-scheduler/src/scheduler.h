#pragma once
#include "models.h"
#include "storage.h"
#include <string>
#include <vector>

class Scheduler {
public:
    explicit Scheduler(const std::string& data_dir);

    // Appliances
    void addAppliance(Appliance a);
    void updateAppliance(int id, Appliance a);
    void deleteAppliance(int id);
    std::vector<Appliance> getAppliances() const;
    Appliance* findAppliance(int id);

    // Home features
    void addFeature(HomeFeature f);
    void updateFeature(int id, HomeFeature f);
    void deleteFeature(int id);
    std::vector<HomeFeature> getFeatures() const;
    HomeFeature* findFeature(int id);

    // Maintenance tasks
    void addTask(MaintenanceTask t);
    void completeTask(int id, const std::string& done_date);
    void deleteTask(int id);
    std::vector<MaintenanceTask> getTasks() const;
    std::vector<MaintenanceTask> getOverdueTasks(const std::string& today) const;
    std::vector<MaintenanceTask> getUpcomingTasks(const std::string& today, int days_ahead) const;

    void save();

private:
    Storage m_store;
    std::vector<Appliance>      m_appliances;
    std::vector<HomeFeature>    m_features;
    std::vector<MaintenanceTask> m_tasks;

    int nextApplianceId() const;
    int nextFeatureId() const;
    int nextTaskId() const;

    // Returns days between two YYYY-MM-DD date strings; negative if b < a
    static int daysBetween(const std::string& a, const std::string& b);
    static std::string addDays(const std::string& date, int days);
};

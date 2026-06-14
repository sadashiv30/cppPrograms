#pragma once
#include "models.h"
#include <string>
#include <vector>

class Storage {
public:
    explicit Storage(const std::string& data_dir);

    std::vector<Appliance>      loadAppliances();
    void                        saveAppliances(const std::vector<Appliance>& items);

    std::vector<HomeFeature>    loadFeatures();
    void                        saveFeatures(const std::vector<HomeFeature>& items);

    std::vector<MaintenanceTask> loadTasks();
    void                         saveTasks(const std::vector<MaintenanceTask>& items);

private:
    std::string m_dir;
    std::string escape(const std::string& s) const;
    std::string unescape(const std::string& s) const;
    std::vector<std::string> splitLine(const std::string& line, char delim = '|') const;
};

#include "scheduler.h"
#include <algorithm>
#include <stdexcept>
#include <ctime>
#include <sstream>
#include <iomanip>

Scheduler::Scheduler(const std::string& data_dir)
    : m_store(data_dir)
{
    m_appliances = m_store.loadAppliances();
    m_features   = m_store.loadFeatures();
    m_tasks      = m_store.loadTasks();
}

void Scheduler::save() {
    m_store.saveAppliances(m_appliances);
    m_store.saveFeatures(m_features);
    m_store.saveTasks(m_tasks);
}

// --- ID helpers ---

int Scheduler::nextApplianceId() const {
    int mx = 0;
    for (auto& a : m_appliances) mx = std::max(mx, a.id);
    return mx + 1;
}
int Scheduler::nextFeatureId() const {
    int mx = 0;
    for (auto& f : m_features) mx = std::max(mx, f.id);
    return mx + 1;
}
int Scheduler::nextTaskId() const {
    int mx = 0;
    for (auto& t : m_tasks) mx = std::max(mx, t.id);
    return mx + 1;
}

// --- Date helpers ---

// Parse YYYY-MM-DD into struct tm
static bool parseDate(const std::string& s, std::tm& tm_out) {
    if (s.size() < 10) return false;
    std::istringstream ss(s);
    ss >> std::get_time(&tm_out, "%Y-%m-%d");
    return !ss.fail();
}

int Scheduler::daysBetween(const std::string& a, const std::string& b) {
    std::tm ta = {}, tb = {};
    if (!parseDate(a, ta) || !parseDate(b, tb)) return 0;
    ta.tm_isdst = -1; tb.tm_isdst = -1;
    time_t ta_t = mktime(&ta);
    time_t tb_t = mktime(&tb);
    return static_cast<int>((tb_t - ta_t) / 86400);
}

std::string Scheduler::addDays(const std::string& date, int days) {
    std::tm tm = {};
    if (!parseDate(date, tm)) return date;
    tm.tm_isdst = -1;
    time_t t = mktime(&tm);
    t += static_cast<time_t>(days) * 86400;
    std::tm* nt = localtime(&t);
    char buf[16];
    strftime(buf, sizeof(buf), "%Y-%m-%d", nt);
    return buf;
}

// --- Appliances ---

void Scheduler::addAppliance(Appliance a) {
    a.id = nextApplianceId();
    m_appliances.push_back(a);
}

void Scheduler::updateAppliance(int id, Appliance a) {
    for (auto& x : m_appliances) {
        if (x.id == id) { a.id = id; x = a; return; }
    }
}

void Scheduler::deleteAppliance(int id) {
    m_appliances.erase(
        std::remove_if(m_appliances.begin(), m_appliances.end(),
                       [id](const Appliance& a){ return a.id == id; }),
        m_appliances.end());
}

std::vector<Appliance> Scheduler::getAppliances() const { return m_appliances; }

Appliance* Scheduler::findAppliance(int id) {
    for (auto& a : m_appliances) if (a.id == id) return &a;
    return nullptr;
}

// --- Features ---

void Scheduler::addFeature(HomeFeature f) {
    f.id = nextFeatureId();
    m_features.push_back(f);
}

void Scheduler::updateFeature(int id, HomeFeature f) {
    for (auto& x : m_features) {
        if (x.id == id) { f.id = id; x = f; return; }
    }
}

void Scheduler::deleteFeature(int id) {
    m_features.erase(
        std::remove_if(m_features.begin(), m_features.end(),
                       [id](const HomeFeature& f){ return f.id == id; }),
        m_features.end());
}

std::vector<HomeFeature> Scheduler::getFeatures() const { return m_features; }

HomeFeature* Scheduler::findFeature(int id) {
    for (auto& f : m_features) if (f.id == id) return &f;
    return nullptr;
}

// --- Tasks ---

void Scheduler::addTask(MaintenanceTask t) {
    t.id = nextTaskId();
    m_tasks.push_back(t);
}

void Scheduler::completeTask(int id, const std::string& done_date) {
    for (auto& t : m_tasks) {
        if (t.id != id) continue;
        t.last_done = done_date;
        t.completed = true;
        if (t.frequency_days > 0) {
            t.next_due = addDays(done_date, t.frequency_days);
            t.completed = false; // recurring: reset for next cycle
        }
        return;
    }
}

void Scheduler::deleteTask(int id) {
    m_tasks.erase(
        std::remove_if(m_tasks.begin(), m_tasks.end(),
                       [id](const MaintenanceTask& t){ return t.id == id; }),
        m_tasks.end());
}

std::vector<MaintenanceTask> Scheduler::getTasks() const { return m_tasks; }

std::vector<MaintenanceTask> Scheduler::getOverdueTasks(const std::string& today) const {
    std::vector<MaintenanceTask> out;
    for (auto& t : m_tasks) {
        if (t.completed) continue;
        if (!t.next_due.empty() && daysBetween(t.next_due, today) > 0)
            out.push_back(t);
    }
    std::sort(out.begin(), out.end(), [&](const MaintenanceTask& a, const MaintenanceTask& b){
        return a.priority < b.priority;
    });
    return out;
}

std::vector<MaintenanceTask> Scheduler::getUpcomingTasks(const std::string& today, int days_ahead) const {
    std::vector<MaintenanceTask> out;
    for (auto& t : m_tasks) {
        if (t.completed) continue;
        if (t.next_due.empty()) continue;
        int diff = daysBetween(today, t.next_due);
        if (diff >= 0 && diff <= days_ahead)
            out.push_back(t);
    }
    std::sort(out.begin(), out.end(), [](const MaintenanceTask& a, const MaintenanceTask& b){
        return a.next_due < b.next_due;
    });
    return out;
}

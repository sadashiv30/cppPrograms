#include "storage.h"
#include <fstream>
#include <sstream>
#include <stdexcept>

Storage::Storage(const std::string& data_dir) : m_dir(data_dir) {}

std::string Storage::escape(const std::string& s) const {
    std::string out;
    for (char c : s) {
        if (c == '|')  out += "\\p";
        else if (c == '\\') out += "\\\\";
        else if (c == '\n') out += "\\n";
        else out += c;
    }
    return out;
}

std::string Storage::unescape(const std::string& s) const {
    std::string out;
    for (size_t i = 0; i < s.size(); ++i) {
        if (s[i] == '\\' && i + 1 < s.size()) {
            char n = s[i + 1];
            if (n == 'p')       { out += '|';  ++i; }
            else if (n == '\\') { out += '\\'; ++i; }
            else if (n == 'n')  { out += '\n'; ++i; }
            else out += s[i];
        } else {
            out += s[i];
        }
    }
    return out;
}

std::vector<std::string> Storage::splitLine(const std::string& line, char delim) const {
    std::vector<std::string> parts;
    std::string cur;
    for (size_t i = 0; i < line.size(); ++i) {
        if (line[i] == '\\' && i + 1 < line.size() && (line[i+1] == 'p' || line[i+1] == '\\' || line[i+1] == 'n')) {
            cur += line[i];
            cur += line[++i];
        } else if (line[i] == delim) {
            parts.push_back(cur);
            cur.clear();
        } else {
            cur += line[i];
        }
    }
    parts.push_back(cur);
    return parts;
}

// --- Appliances ---

std::vector<Appliance> Storage::loadAppliances() {
    std::vector<Appliance> items;
    std::ifstream f(m_dir + "/appliances.dat");
    if (!f) return items;
    std::string line;
    while (std::getline(f, line)) {
        if (line.empty() || line[0] == '#') continue;
        auto p = splitLine(line);
        if (p.size() < 9) continue;
        Appliance a;
        a.id             = std::stoi(p[0]);
        a.name           = unescape(p[1]);
        a.brand          = unescape(p[2]);
        a.model          = unescape(p[3]);
        a.serial_number  = unescape(p[4]);
        a.location       = unescape(p[5]);
        a.install_date   = unescape(p[6]);
        a.warranty_expiry= unescape(p[7]);
        a.notes          = unescape(p[8]);
        items.push_back(a);
    }
    return items;
}

void Storage::saveAppliances(const std::vector<Appliance>& items) {
    std::ofstream f(m_dir + "/appliances.dat");
    f << "# id|name|brand|model|serial|location|install_date|warranty|notes\n";
    for (auto& a : items) {
        f << a.id << '|'
          << escape(a.name) << '|' << escape(a.brand) << '|'
          << escape(a.model) << '|' << escape(a.serial_number) << '|'
          << escape(a.location) << '|' << escape(a.install_date) << '|'
          << escape(a.warranty_expiry) << '|' << escape(a.notes) << '\n';
    }
}

// --- HomeFeatures ---

std::vector<HomeFeature> Storage::loadFeatures() {
    std::vector<HomeFeature> items;
    std::ifstream f(m_dir + "/features.dat");
    if (!f) return items;
    std::string line;
    while (std::getline(f, line)) {
        if (line.empty() || line[0] == '#') continue;
        auto p = splitLine(line);
        if (p.size() < 7) continue;
        HomeFeature h;
        h.id           = std::stoi(p[0]);
        h.category     = unescape(p[1]);
        h.name         = unescape(p[2]);
        h.location     = unescape(p[3]);
        h.install_date = unescape(p[4]);
        h.last_serviced= unescape(p[5]);
        h.notes        = unescape(p[6]);
        items.push_back(h);
    }
    return items;
}

void Storage::saveFeatures(const std::vector<HomeFeature>& items) {
    std::ofstream f(m_dir + "/features.dat");
    f << "# id|category|name|location|install_date|last_serviced|notes\n";
    for (auto& h : items) {
        f << h.id << '|'
          << escape(h.category) << '|' << escape(h.name) << '|'
          << escape(h.location) << '|' << escape(h.install_date) << '|'
          << escape(h.last_serviced) << '|' << escape(h.notes) << '\n';
    }
}

// --- MaintenanceTasks ---

std::vector<MaintenanceTask> Storage::loadTasks() {
    std::vector<MaintenanceTask> items;
    std::ifstream f(m_dir + "/tasks.dat");
    if (!f) return items;
    std::string line;
    while (std::getline(f, line)) {
        if (line.empty() || line[0] == '#') continue;
        auto p = splitLine(line);
        if (p.size() < 10) continue;
        MaintenanceTask t;
        t.id            = std::stoi(p[0]);
        t.title         = unescape(p[1]);
        t.item_type     = unescape(p[2]);
        t.item_id       = std::stoi(p[3]);
        t.frequency_days= std::stoi(p[4]);
        t.last_done     = unescape(p[5]);
        t.next_due      = unescape(p[6]);
        t.priority      = std::stoi(p[7]);
        t.completed     = (p[8] == "1");
        t.notes         = unescape(p[9]);
        items.push_back(t);
    }
    return items;
}

void Storage::saveTasks(const std::vector<MaintenanceTask>& items) {
    std::ofstream f(m_dir + "/tasks.dat");
    f << "# id|title|item_type|item_id|freq_days|last_done|next_due|priority|completed|notes\n";
    for (auto& t : items) {
        f << t.id << '|'
          << escape(t.title) << '|' << escape(t.item_type) << '|'
          << t.item_id << '|' << t.frequency_days << '|'
          << escape(t.last_done) << '|' << escape(t.next_due) << '|'
          << t.priority << '|' << (t.completed ? 1 : 0) << '|'
          << escape(t.notes) << '\n';
    }
}

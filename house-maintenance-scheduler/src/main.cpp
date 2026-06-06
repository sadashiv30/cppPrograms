#include "scheduler.h"
#include "cli.h"
#include <iostream>
#include <filesystem>
#include <string>

int main(int argc, char* argv[]) {
    std::string data_dir = "data";
    if (argc > 1) data_dir = argv[1];

    // Ensure data directory exists
    try {
        std::filesystem::create_directories(data_dir);
    } catch (const std::exception& e) {
        std::cerr << "Error creating data directory: " << e.what() << "\n";
        return 1;
    }

    Scheduler sched(data_dir);
    CLI cli(sched);
    cli.run();
    return 0;
}

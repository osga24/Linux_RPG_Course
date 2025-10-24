#include <iostream>
#include <fstream>
#include <string>

int main() {
    const char target = '#';
    const std::string path = "dirtyBook.txt";

    std::ifstream in(path);
    if (!in.is_open()) {
        std::cerr << "[ERROR] Failed to open file: " << path << "\n";
        return 2;
    }

    std::string line;
    while (std::getline(in, line)) {
        if (line.find(target) != std::string::npos) {
            std::cout << "Not fully cleaned\n";
            return 0;
        }
    }

    std::cout << "FLAG{br3@k_th3_$y$T3m}\n";
    return 0;
}

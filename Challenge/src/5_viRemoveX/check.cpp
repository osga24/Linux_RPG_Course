#include <iostream>
#include <fstream>
#include <string>

int main() {
    const char target = 'x';
    const std::string path = "dirtyBook.txt";

    std::ifstream in(path);
    if (!in.is_open()) {
        std::cerr << "[ERROR] 無法開啟檔案：" << path << "\n";
        return 2;
    }

    std::string line;
    while (std::getline(in, line)) {
        if (line.find(target) != std::string::npos) {
            std::cout << "未清潔乾淨\n";
            return 0;
        }
    }

    std::cout << "FLAG{{br3@k_th3_$y$T3m}}\n";
    return 0;
}

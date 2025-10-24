#include <fstream>
#include <iostream>
#include <string>

int main() {
    const std::string filePath = "./box/key.txt";
    const std::string flag = "FLAG{n0_w4y_y0u_r34d_4ll_0f_th3m}";
    const std::string keyword = "早餐吃到飽";

    std::ifstream in(filePath);
    if (!in) {
        std::cerr << "❌ 驗證失敗"  << "\n";
        return 1;
    }

    std::string content((std::istreambuf_iterator<char>(in)), {});
    in.close();

    bool hasFlag = content.find(flag) != std::string::npos;
    bool hasKeyword = content.find(keyword) != std::string::npos;

    if (hasFlag && hasKeyword) {
        std::cout << "✅ 驗證成功！\n";
        std::cout << "FLAG: " << flag << "\n";
    } else {
        std::cerr << "❌ 驗證失敗"  << "\n";
    }

    return 0;
}

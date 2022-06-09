#include "symbolTable.h"

int main() {
    freopen("symbolTableInput.txt", "r", stdin);
    int n;
    char c;
    std::string name;
    std::string type;

    std::cin >> n;
    SymbolTable symbolTable(n);

    while (!feof(stdin)) {
        std::cin >> c;

        switch (c) {
            case 'I':
                std::cin >> name >> type;
                symbolTable.insert(name, type);
                break;
            case 'L':
                std::cin >> name;
                if (!symbolTable.lookUp(name))
                    std::cout << name << " not found\n";
                break;
            case 'D':
                std::cin >> name;
                if (!symbolTable.remove(name)) {
                    std::cout << name << " not found\n";
                }
                break;
            case 'P':
                char token;
                std::cin >> token;
                switch (token) {
                    case 'A':
                        symbolTable.printAllScopeTable();
                        break;
                    case 'C':
                        symbolTable.printCurrentScopeTable();
                        break;
                    default:
                        std::cout << "Invalid input\n";
                }
                break;
            case 'S':
                symbolTable.enterScope();
                std::cout << "New ScopeTable with id " << symbolTable.getCurrentScopeID() << " created\n";
                break;
            case 'E':
                symbolTable.exitScope();
                break;
            default:
                std::cout << "Invalid input\n";
        }

        std::cout << '\n';
    }

    fclose(stdin);
    return 0;
}
#include "scopeTable.cpp"
#include <utility>
#include<vector>

class SymbolTable {
private:
    int sizeOfScopeTables;
    ScopeTable* rootScopeTable;
    ScopeTable* currentScopeTable;

public:
    SymbolTable(int sizeOfScopeTables) {
        this->sizeOfScopeTables = sizeOfScopeTables;
        rootScopeTable = new ScopeTable(sizeOfScopeTables);
        
        currentScopeTable = rootScopeTable;
    }

    void enterScope() {
        currentScopeTable = new ScopeTable(sizeOfScopeTables, currentScopeTable);
        std::cout << "New ScopeTable with id " << currentScopeTable->getId() << " created\n";
    }

    void exitScope() {
        std::string currentScopeId = currentScopeTable->getId();
        if(currentScopeTable != rootScopeTable) {
            ScopeTable* previousScopeTable = currentScopeTable;
            currentScopeTable = currentScopeTable->getParentScope();
            std::cout << "Current Scope: " << currentScopeTable->getId() << std::endl;
            delete previousScopeTable;
            std::cout << "ScopeTable with id " << currentScopeId << " removed\n";
        }
    }

    bool insert(std::string name, std::string type) {
        return currentScopeTable->insert(name, type);
    }

    bool remove(std::string symbolName) {
        return currentScopeTable->remove(symbolName);
    }

    SymbolInfo* lookUp(std::string symbolName) {
        ScopeTable* scope = currentScopeTable;
        SymbolInfo* symbolInfo = NULL;

        while (scope != NULL) {

            symbolInfo = scope->lookUp(symbolName);
            if(symbolInfo != NULL)
                return symbolInfo;
            scope = scope->getParentScope();
        }

        return NULL;
    }

    void printCurrentScopeTable() {
        currentScopeTable->print();
    }

    void printAllScopeTable() {
        ScopeTable* scopeTable = currentScopeTable;
        while (scopeTable != NULL) {
            scopeTable->print();
            scopeTable = scopeTable->getParentScope();
        }
    }

    ~SymbolTable() {
        ScopeTable* scopeTable = currentScopeTable;
        while (currentScopeTable != NULL) {
            currentScopeTable = scopeTable->getParentScope();
            delete scopeTable;
        }
    }
};

int main() {
    freopen("input.txt", "r", stdin);
    int n;
    char c;
    std::string name;
    std::string type;

    std::cin >> n;
//    std::cout << "Size " << n << std::endl;
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
                if(!symbolTable.lookUp(name))
                    std::cout << name << " not found\n";
                break;
            case 'D':
                std::cin >> name;
                if(!symbolTable.remove(name)) {
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
                break;
            case 'E':
                symbolTable.exitScope();
                break;
            default:
                std::cout << "Invalid input\n";
        }
    }

    return 0;
}
#include "symbolInfo.cpp"
#include<iostream>

class ScopeTable {
private:
    int size;
    int totalChildren;
    SymbolInfo **hashTable;
    ScopeTable *parentScope;
    std::string id;

    unsigned long sdbmhash(std::string name) {
        unsigned long hash = 0;

        for (int i = 0; i < name.length(); i++) {
            int c = name[i];
            hash = c + (hash << 6) + (hash << 16) - hash;
        }

        return hash;
    }

public:
// TODO: set id for root scopes
    ScopeTable(int size) {
        this->size = size;
        this->totalChildren = 0;
        hashTable = new SymbolInfo*[size];
        // memset(hashTable, NULL, size);
        for(int i = 0; i < size; i++) hashTable[i] = NULL;
        parentScope = NULL;
        std::cout << "Okay in constructor" << std::endl;
    }

    ScopeTable(int size, ScopeTable *parentScope) : ScopeTable(size) {
        this->parentScope = parentScope;
        parentScope->totalChildren++;
        char c = '0' + parentScope->totalChildren;
        id = parentScope->id + '.' + c;
    }

    bool insert(SymbolInfo &symbolInfo) {
        int idx = sdbmhash(symbolInfo.getName()) % size;

        if(hashTable[idx] == NULL) {
            hashTable[idx] = &symbolInfo;
        } else {
            SymbolInfo *current = hashTable[idx];
            SymbolInfo *next = current->getNext();

            while (current->getName() != symbolInfo.getName() && next != NULL) {
                current = next;
                next = current->getNext();
            }

            if (current->getName() == symbolInfo.getName())
                return false;

            current->setNext(&symbolInfo);    
        }
        
        return true;
    }

    SymbolInfo* lookUp(std::string symbolName) {
        int idx = sdbmhash(symbolName) % size;

        if (hashTable[idx] != NULL) {
            SymbolInfo *current = hashTable[idx];
            SymbolInfo *next = current->getNext();

            while (current->getName() != symbolName && next != NULL) {
                current = next;
                next = current->getNext();
            }

            if (current->getName() == symbolName)
                return current;
        }

        return NULL;
    }

    bool remove(std::string symbolName) {
        int idx = sdbmhash(symbolName) % size;

        if (hashTable[idx] != NULL) {
            SymbolInfo *current = hashTable[idx];
            SymbolInfo *next = current->getNext();

            // Checks the first element of the table at idx
            if (current->getName() == symbolName) {
                hashTable[idx] = next;
                current->setNext(NULL);
                return true;
            }

            while (next != NULL && next->getName() != symbolName) {
                current = next;
                next = current->getNext();
            }

            if (next->getName() == symbolName) {
                current->setNext(next->getNext());
                next->setNext(NULL);
                return true;
            }    
        }

        return false;
    }

    void print() {
        std::cout << "ScopeTable # " << id << '\n';
        for(int i = 0; i < size; i++) {
            std::cout << i << " --> ";

            SymbolInfo *next = hashTable[i];
            while(next != NULL) {
                std::cout << "< " << next->getName() << ": " << next->getType() << "> ";
                next = next->getNext();
            }

            std::cout << '\n';
        }
    }

    ~ScopeTable()
    {
        delete[] hashTable;
        delete parentScope;
    }
};

int main() {
    SymbolInfo a("t", "t");
    std::cout<< a.getName() << ' ' << a.getType() << std::endl;
    SymbolInfo num("5", "NUMBER");
    std::cout<< num.getName() << ' ' << num.getType() << std::endl;


    ScopeTable st(7);
    st.insert(a);
    st.insert(num);
    st.print();
}
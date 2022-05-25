#include "symbolInfo.cpp"
#include<iostream>
#include<string>

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
    ScopeTable(int size) {
        this->size = size;
        this->totalChildren = 0;
        this->id = "1";
        hashTable = new SymbolInfo*[size];

        for(int i = 0; i < size; i++)
            hashTable[i] = NULL;

        parentScope = NULL;
    }

    ScopeTable(int size, ScopeTable *parentScope) : ScopeTable(size) {
        this->parentScope = parentScope;
        int subId = ++this->parentScope->totalChildren;

        id = parentScope->id + '.' + std::to_string(subId);
    }

    bool insert(std::string name, std::string type) {
        SymbolInfo* symbolInfo = new SymbolInfo(name, type);
        int hashtableIndex = sdbmhash(symbolInfo->getName()) % size;
        int linkedListIndex = 0;
        SymbolInfo* current = hashTable[hashtableIndex];

        if(current == NULL) {
            hashTable[hashtableIndex] = symbolInfo;
        } else if(symbolInfo->getName() == current->getName()) {
            std::cout << '<' << name << ',' << type << "> already exists in current ScopeTable\n";
            return false;
        } else {
            SymbolInfo *next = current->getNext();

            while (next != NULL) {
                if(symbolInfo->getName() == current->getName()) {
                    std::cout << '<' << name << ',' << type << "> already exists in current ScopeTable\n";
                    return false;
                }
                current = next;
                next = current->getNext();
                linkedListIndex++;
            }

            current->setNext(symbolInfo);
            linkedListIndex++;
        }

        std::cout << "Inserted in ScopeTable # " << id
                  << " at position " << hashtableIndex << ", " << linkedListIndex << '\n';
        return true;
    }

    SymbolInfo* lookUp(std::string symbolName) {
        int hashTableIndex = sdbmhash(symbolName) % size;
        int linkedListIndex = 0;

        if (hashTable[hashTableIndex] != NULL) {
            SymbolInfo *current = hashTable[hashTableIndex];

            while (current != NULL) {
                if(symbolName == current->getName()) {
                    std::cout << "Found in ScopeTable # " << id
                              << " at position " << hashTableIndex << ", " << linkedListIndex << '\n';
                    return current;
                }
                    
                current = current->getNext();
                linkedListIndex++;
            }
        }

//        std::cout << "Not found\n";
        return NULL;
    }

    bool remove(std::string symbolName) {
        int hashTableIndex = sdbmhash(symbolName) % size;
        int linkedListIndex = 0;

        if (hashTable[hashTableIndex] != NULL) {
            SymbolInfo *current = hashTable[hashTableIndex];
            SymbolInfo *next = current->getNext();

            // Checks the first element of the table at hashTableIndex
            if (current->getName() == symbolName) {
                hashTable[hashTableIndex] = next;
                current->setNext(NULL);
                std::cout << "Found in ScopeTable # " << id << " at position "
                          << hashTableIndex << ", " << linkedListIndex << '\n';
                std::cout << "Deleted Entry" << hashTableIndex << ", " << linkedListIndex
                          << " from current ScopeTable\n";
                return true;
            }

            while (next != NULL && next->getName() != symbolName) {
                current = next;
                next = current->getNext();
                linkedListIndex++;
            }

            if (next->getName() == symbolName) {
                current->setNext(next->getNext());
                next->setNext(NULL);
                std::cout << "Found in ScopeTable # " << id << " at position "
                          << hashTableIndex << ", " << linkedListIndex << '\n';
                std::cout << "Deleted Entry " << hashTableIndex << ", " << linkedListIndex
                          << " from current ScopeTable\n";
                return true;
            }    
        }

//        std::cout << "Not found\n";
        return false;
    }

    void print() {
        std::cout << "ScopeTable # " << id << '\n';
        for(int i = 0; i < size; i++) {
            std::cout << i << " --> ";

            SymbolInfo *next = hashTable[i];
            while(next != NULL) {
                std::cout << "< " << next->getName() << " : " << next->getType() << "> ";
                next = next->getNext();
            }

            std::cout << '\n';
        }
    }

    // void setId(const std::string id) {
    //     this->id = id;
    // }

    ScopeTable *getParentScope() const {
        return parentScope;
    }

    const std::string &getId() const {
        return id;
    }

    ~ScopeTable()
    {
        for(int i = 0; i<size; i++) 
            delete hashTable[i];
            
        delete[] hashTable;
    }
};
#include "symbolInfo.h"

/**
 * Contains array of pointers to SymbolInfo objects as a
 * hash table. parentScope pointer points to the scope that
 * this ScopeTable object is a child of.
 */
class ScopeTable {
private:
    int size;
    int totalChildren;
    SymbolInfo **hashTable;
    ScopeTable *parentScope;
    std::string id;

    /**
     * Hash function associated with the hashTable.
     * @param name of the symbol
     * @return hashed value corresponding to the name string.
     */
    static unsigned long sdbmhash(std::string name) {
        unsigned long hash = 0;

        for (int i = 0; i < name.length(); i++) {
            int c = name[i];
            hash = c + (hash << 6) + (hash << 16) - hash;
        }

        return hash;
    }

public:
    /**
     * Initializes the ScopeTable object with no ID.
     * Allocates NULL to the parentScope.
     * @param size of the hashTable
     */
    ScopeTable(int size) {
        this->size = size;
        this->totalChildren = 0;
        hashTable = new SymbolInfo*[size];

        for(int i = 0; i < size; i++)
            hashTable[i] = NULL;

        parentScope = NULL;
    }

    /**
     * Allocates NULL to the parentScope.
     * @param size of the hashTable
     * @param id of the ScopeTable object
     */
    ScopeTable(int size, std::string id) : ScopeTable(size) {
        this->id = id;
    }

    /**
     * Allocates ID based on the parent ID.
     * example: If the ID of the parent is 1.1 and has 2 existing children then
     * the ID of this object will be 1.1.3
     * This also increases the number of children of the parent scope.
     * @param size of the hashTable
     * @param parentScope of this ScopeTable
     */
    ScopeTable(int size, ScopeTable *parentScope) : ScopeTable(size) {
        this->parentScope = parentScope;
        int subId = ++this->parentScope->totalChildren;

        id = parentScope->id + '.' + std::to_string(subId);
    }

    /**
     * Creates a new SymbolInfo object and inserts it into the hashTable
     * if no symbol corresponding to the name already exists in the table.
     * @param name of the symbol
     * @param type of the symbol
     * @return true if insertion is successful or false if unsuccessful.
     */
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

    /**
     * Searches for the symbol with the name that matches symbolName parameter.
     * @param symbolName name of the symbol
     * @return true if the hashTable contains a symbol with symbolName or false, if not found.
     */
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

        return NULL;
    }

    /**
     * Removes the symbol with the name that matches symbolName parameter.
     * @param symbolName name of the symbol.
     * @return true if removal is successful or false if unsuccessful.
     */
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
                std::cout << "Deleted Entry " << hashTableIndex << ", " << linkedListIndex
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

        return false;
    }

    /**
     * Prints the < symbolName : symbolType > of every symbol in this scope.
     */
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
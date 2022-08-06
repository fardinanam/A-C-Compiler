#ifndef COMPILER_SCOPE_TABLE_H
#define COMPILER_SCOPE_TABLE_H

#include "idInfo.h"
#include "functionInfo.h"

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
    static uint32_t sdbmhash(std::string name) {
        uint32_t hash = 0;

        for (int i = 0; i < name.length(); i++) {
            int c = name[i];
            hash = c + (hash << 6) + (hash << 16) - hash;
        }

        return hash;
    }

public:
    /**
     * Initializes the ScopeTable object with ID = 1.
     * Allocates NULL to the parentScope.
     * @param size of the hashTable
     */
    ScopeTable(int size) {
        this->size = size;
        this->totalChildren = 0;
        this->id = "1";
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
     * @param isFunction if the symbol is of type function, set true.
     * @return newly inserted SymbolInfo* if insertion is successful or NULL if unsuccessful.
     */
    SymbolInfo* insert(std::string name, std::string type, bool isFunction = false) {
        int hashtableIndex = sdbmhash(name) % size;
        int linkedListIndex = 0;
        SymbolInfo* current = hashTable[hashtableIndex];
        SymbolInfo* newSymbolInfo = NULL;

        if(current == NULL) {
            if(isFunction) {
                hashTable[hashtableIndex] = new FunctionInfo(name, type);
            } else {
                hashTable[hashtableIndex] = new SymbolInfo(name, type);
            }

            return hashTable[hashtableIndex];
        } else if(name == current->getName()) {
            // std::cout << '<' << name << ',' << type << "> already exists in current ScopeTable\n";
            return NULL;
        } else {
            SymbolInfo* next = current->getNext();

            while (next != NULL) {
                if(name == current->getName()) {
                    // std::cout << '<' << name << ',' << type << "> already exists in current ScopeTable\n";
                    return NULL;
                }
                
                current = next;
                next = current->getNext();
                linkedListIndex++;
            }

            // Check the last element
            if(name == current->getName()) {
                // std::cout << '<' << name << ',' << type << "> already exists in current ScopeTable\n";
                return NULL;
            }
            
            if(isFunction) {
                newSymbolInfo = new FunctionInfo(name, type);
                current->setNext(newSymbolInfo);
            } else {
                newSymbolInfo = new SymbolInfo(name, type);
                current->setNext(newSymbolInfo);
            }
            
            linkedListIndex++;
        }

        // std::cout << "Inserted in ScopeTable # " << id
        //           << " at position " << hashtableIndex << ", " << linkedListIndex << '\n';
        return newSymbolInfo;
    }

    /**
     * Creates a new SymbolInfo object and inserts it into the hashTable
     * if no symbol corresponding to the name already exists in the table.
     * @param name of the symbol
     * @param type of the symbol
     * @param idType type of the ID
     * @return newly inserted SymbolInfo* if insertion is successful or NULL if unsuccessful.
     */
    SymbolInfo* insert(std::string name, std::string type, std::string idType) {
        int hashtableIndex = sdbmhash(name) % size;
        int linkedListIndex = 0;
        SymbolInfo* current = hashTable[hashtableIndex];
        SymbolInfo* newSymbolInfo = NULL;

        if (current == NULL) {
            return hashTable[hashtableIndex] = new IdInfo(name, idType);
        } else if (name == current->getName()) {
            // std::cout << '<' << name << ',' << type << "> already exists in current ScopeTable\n";
            return NULL;
        } else {
            SymbolInfo* next = current->getNext();

            while (next != NULL) {
                if (name == current->getName()) {
                    // std::cout << '<' << name << ',' << type << "> already exists in current ScopeTable\n";
                    return NULL;
                }

                current = next;
                next = current->getNext();
                linkedListIndex++;
            }

            // Check the last element
            if (name == current->getName()) {
                // std::cout << '<' << name << ',' << type << "> already exists in current ScopeTable\n";
                return NULL;
            }

            newSymbolInfo = new IdInfo(name, idType);
            current->setNext(newSymbolInfo);

            linkedListIndex++;
        }

        // std::cout << "Inserted in ScopeTable # " << id
        //           << " at position " << hashtableIndex << ", " << linkedListIndex << '\n';
        return newSymbolInfo;
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
                    // std::cout << "Found in ScopeTable # " << id
                    //           << " at position " << hashTableIndex << ", " << linkedListIndex << '\n';
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
                
                // std::cout << "Found in ScopeTable # " << id << " at position "
                //           << hashTableIndex << ", " << linkedListIndex << '\n';
                // std::cout << "Deleted Entry " << hashTableIndex << ", " << linkedListIndex
                //           << " from current ScopeTable\n";
                
                delete current;
                return true;
            }

            while (next != NULL && next->getName() != symbolName) {
                current = next;
                next = current->getNext();
                linkedListIndex++;
            }

            if (next->getName() == symbolName) {
                current->setNext(next->getNext());
                
                // std::cout << "Found in ScopeTable # " << id << " at position "
                //           << hashTableIndex << ", " << linkedListIndex << '\n';
                // std::cout << "Deleted Entry " << hashTableIndex << ", " << linkedListIndex
                //           << " from current ScopeTable\n";
    
                delete next;
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

    /**
     * @returns the non empty buckets of symbols < symbolName : symbolType > in
     * the form of string.
     */
    std::string getNonEmptyBuckets() {
        std::string temp = "ScopeTable # " + id + "\n";
        for(int i = 0; i < size; i++) {
            bool found = false;
            if(hashTable[i] != NULL) {
                temp += " " + std::to_string(i) + " --> ";

                SymbolInfo *next = hashTable[i];
                while(next != NULL) {
                    found = true;
                    temp += "< " + next->getName() + " : " + next->getType() + "> ";
                    next = next->getNext();
                }
                if(found)
                    temp += '\n';
            }
        }

        return temp;
    }

    ScopeTable *getParentScope() const {
        return parentScope;
    }

    const std::string &getId() const {
        return id;
    }

    ~ScopeTable()
    {
        for(int i = 0; i<size; i++) {
            if(hashTable[i] != NULL) {
                while(hashTable[i] != NULL) {
                    SymbolInfo* tempSymbolInfo = hashTable[i]->getNext();
                    if (hashTable[i]->getIsFunction())
                        delete (FunctionInfo *)hashTable[i];
                    else if (hashTable[i]->getType() == "ID")
                        delete (IdInfo*)hashTable[i];
                    else 
                        delete hashTable[i];

                    hashTable[i] = tempSymbolInfo;
                }
            }
        }
            
        delete[] hashTable;
    }
};

#endif
#ifndef COMPILER_SYMBOL_TABLE_H
#define COMPILER_SYMBOL_TABLE_H

#include "scopeTable.h"

/**
 * Contains the size of every scope table's hashTable.
 * Has root scope pointer and current scope pointers
 * that can't be manipulated by the caller scopes.
 */
class SymbolTable {
private:
    int sizeOfScopeTables;
    ScopeTable* rootScopeTable;
    ScopeTable* currentScopeTable;

public:
    /**
     * Creates the root scope and points the current
     * pointer to root scope.
     * @param sizeOfScopeTables size of the hashTables of
     * the scopes.
     */
    SymbolTable(int sizeOfScopeTables) {
        this->sizeOfScopeTables = sizeOfScopeTables;
        rootScopeTable = new ScopeTable(sizeOfScopeTables);
        currentScopeTable = rootScopeTable;
    }

    /**
     * Creates a new scope inside the current scope and points
     * the currentScope pointer to the newly created scope.
     */
    void enterScope() {
        if(rootScopeTable == NULL) {
            rootScopeTable = new ScopeTable(sizeOfScopeTables);
            currentScopeTable = rootScopeTable;
        } else {
            currentScopeTable = new ScopeTable(sizeOfScopeTables, currentScopeTable);
        }
    }

    /**
     * Gets out of the current scope and deletes it.
     * Points the currentScope pointer to the parent of
     * the deleted scope.
     */
    void exitScope() {
        if(currentScopeTable != NULL) {
            std::string currentScopeId = currentScopeTable->getId();
            ScopeTable* previousScopeTable = currentScopeTable;
            currentScopeTable = currentScopeTable->getParentScope();

            std::cout << "ScopeTable with id " << currentScopeId << " removed\n";
            if(previousScopeTable == rootScopeTable) {
                // std::cout << "Destroying the first ScopeTable\n";
                rootScopeTable = NULL;
            }

            delete previousScopeTable;
        } else {
            std::cout << "NO CURRENT SCOPE\n";
        }
    }

    /**
     * Inserts a new symbol in the current scope if no symbol
     * corresponding to the name already exists in the scope.
     * @param name of the symbol
     * @param type of the symbol
     * @return true if insertion is successful or false if unsuccessful.
     */
    bool insert(std::string name, std::string type) {
        if(currentScopeTable == NULL) {
            enterScope();
        }

        return currentScopeTable->insert(name, type);
    }

    /**
     * Removes the symbol with the name that matches symbolName parameter
     * in the current scope.
     * @param symbolName name of the symbol.
     * @return true if removal is successful or false if unsuccessful.
     */
    bool remove(std::string symbolName) {
        if (currentScopeTable == NULL) {
            std::cout << "NO CURRENT SCOPE\n";
            return false;
        }
        
        return currentScopeTable->remove(symbolName);
    }

    /**
     * Searches for the symbol with the name that matches symbolName parameter
     * in the current scope. If not found, searches it in all the ancestors.
     * @param symbolName name of the symbol
     * @return true if any of the current or ancestor contains a symbol with
     * symbolName or false, if not found.
     */
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

    /**
     * Prints all the < symbolName : symbolType >
     * of the current scope.
     */
    void printCurrentScopeTable() {
        if (currentScopeTable == NULL) {
            std::cout << "NO CURRENT SCOPE\n";
        } else {
            currentScopeTable->print();
        }
    }

    /**
     * Prints all the < symbolName : symbolType >
     * of all the existing scopes.
     */
    void printAllScopeTable() {
        ScopeTable* scopeTable = currentScopeTable;
        if(scopeTable == NULL) {
            std::cout << "NO CURRENT SCOPE\n";
        }

        while (scopeTable != NULL) {
            scopeTable->print();
            scopeTable = scopeTable->getParentScope();
        }
    }

    std::string getCurrentScopeID() {
        if(currentScopeTable != NULL)
            return currentScopeTable->getId();
        
        return "NO CURRENT SCOPE";
    }

    ~SymbolTable() {
        ScopeTable* scopeTable = currentScopeTable;
        while (scopeTable != NULL) {
            currentScopeTable = scopeTable->getParentScope();
            delete scopeTable;
            scopeTable = currentScopeTable;
        }
    }
};

#endif
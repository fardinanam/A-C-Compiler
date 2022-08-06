#ifndef COMPILER_SYMBOL_INFO_H
#define COMPILER_SYMBOL_INFO_H

#include<iostream>
#include<string>

/**
 * Contains the name and type of a symbol. Also contains
 * an optional next pointer that can be pointed to another
 * SymbolInfo object.
 */
class SymbolInfo {
private:
    std::string name;
    std::string type;
    SymbolInfo *next;
public:
    /**
     * Initializes the object.
     * @param name of the symbol.
     * @param type of the symbol.
     */
    SymbolInfo(std::string name, std::string type) {
        this->name = name;
        this->type = type;
        this->next = NULL;
    }

    void setName(std::string name) { this->name = name; }

    void setType(std::string type) { this->type = type; }

    void setNext(SymbolInfo *next) { this->next = next; }

    std::string getName() const { return name; }

    std::string getType() const { return type; }

    SymbolInfo* getNext() const { return next; }

    ~SymbolInfo() {
        // Nothing to free
    }
};

#endif
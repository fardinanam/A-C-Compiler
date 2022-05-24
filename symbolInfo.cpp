#include<iostream>
#include<string>

class SymbolInfo {
private:
    std::string name;
    std::string type;
    SymbolInfo *next;
public:
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

    SymbolInfo *getNext() const { return next; }

    ~SymbolInfo() {
//        std::cout << name << " symbol's destructor called" << std::endl;
        delete next;
    }
};
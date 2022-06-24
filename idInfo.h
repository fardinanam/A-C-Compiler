#ifndef COMPILER_ID_INFO_H
#define COMPILER_ID_INFO_H

#include <string>
#include "symbolInfo.h"

class IdInfo : public SymbolInfo
{
private:
    std::string idType;

public:
    IdInfo(std::string name, std::string type) : SymbolInfo(name, type) {}
    
    IdInfo(std::string name, std::string type, std::string idType) : SymbolInfo(name, type) {
        this->idType = idType;
    }

    void setIdType(std::string idType) {this->idType = idType;}

    std::string getIdType() {return this->idType;}

    ~IdInfo() {}
};

#endif

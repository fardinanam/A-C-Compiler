#ifndef COMPILER_ID_INFO_H
#define COMPILER_ID_INFO_H

#include <string>
#include "symbolInfo.h"

class IdInfo : public SymbolInfo
{
private:
    std::string idType;

public:
    IdInfo(std::string name) : SymbolInfo(name, "ID") {
        this->idType = idType;
    }

    IdInfo(std::string name, std::string idType) : IdInfo(name) {
        this->idType = idType;
    }

    void setIdType(std::string idType) {this->idType = idType;}

    std::string getIdType() const {return this->idType;}

    ~IdInfo() {}
};

#endif

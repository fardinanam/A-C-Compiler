#ifndef COMPILER_ID_INFO_H
#define COMPILER_ID_INFO_H

#include <string>
#include "symbolInfo.h"

class IdInfo : public SymbolInfo
{
private:
    std::string idType;
    int stackOffset;
    int arraySize;

public:
    IdInfo(std::string name, int stackOffset) : SymbolInfo(name, "ID") {
        this->idType = idType;
        this->stackOffset = stackOffset;
        this->arraySize = 0;
    }

    IdInfo(std::string name, std::string idType, int stackOffset, int arraySize) : IdInfo(name, stackOffset) {
        this->idType = idType;
        this->arraySize = arraySize;
    }

    void setIdType(std::string idType) { this->idType = idType; }

    std::string getIdType() const { return this->idType; }

    void setStackOffset(int stackOffset) { this->stackOffset = stackOffset; }

    int getStackOffset() const { return this->stackOffset; }

    void setArraySize(int arraySize) { this->arraySize = arraySize; }

    int getArraySize() const { return this->arraySize; }

    ~IdInfo() {}
};

#endif

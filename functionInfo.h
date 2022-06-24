#ifndef COMPILER_FUNCTION_INFO_H
#define COMPILER_FUNCTION_INFO_H

#include <string>
#include "symbolInfo.h"

class FunctionInfo : public SymbolInfo {
private:
    std::string returnType;
    bool hasDefined;
public:
    FunctionInfo(std::string name, std::string type) : SymbolInfo(name, type) {
        hasDefined = false;
    }

    void setReturnType(std::string returnType) {this->returnType = returnType;}
    
    void isDefined(bool hasDefined) {this->hasDefined = hasDefined;}

    std::string getReturnType() {return this->returnType;}

    ~FunctionInfo() {}
};

#endif

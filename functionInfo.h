#ifndef COMPILER_FUNCTION_INFO_H
#define COMPILER_FUNCTION_INFO_H

#include <string>
#include <list>
#include <utility>
#include "symbolInfo.h"

class FunctionInfo : public SymbolInfo {
private:
    std::list<std::pair<int, std::string> > parameterList; // contains the <paramNo, type> of the parameters
    std::string returnType;
    bool isDefined;
public:
    FunctionInfo(std::string name, std::string type) : SymbolInfo(name, type) {
        setIsFunction();
        isDefined = false;
    }

    void addParameter(int paramNo, std::string type) {
        parameterList.push_back(std::make_pair(paramNo, type));
    }

    void setReturnType(std::string returnType) { this->returnType = returnType; }

    void setIsDefined() { this->isDefined = true; }

    int getNumberOfParams() const { return parameterList.size(); }

    std::string getReturnType() const { return this->returnType; }

    ~FunctionInfo() {}
};

#endif

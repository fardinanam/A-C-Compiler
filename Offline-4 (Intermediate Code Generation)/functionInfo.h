#ifndef COMPILER_FUNCTION_INFO_H
#define COMPILER_FUNCTION_INFO_H

#include <string>
#include <vector>
#include <utility>
#include "symbolInfo.h"

class FunctionInfo : public SymbolInfo {
private:
    std::vector<std::string> parameterList; // contains the types of the parameters
    std::string returnType;
    bool isDefined;
public:
    FunctionInfo(std::string name, std::string type) : SymbolInfo(name, type) {
        setIsFunction();
        isDefined = false;
    }

    void addParameter(std::string type) {
        parameterList.push_back(type);
    }

    void setReturnType(std::string returnType) { this->returnType = returnType; }

    void setIsDefined() { this->isDefined = true; }

    bool getIsDefined() { return this->isDefined; }

    int getNumberOfParameters() const { return parameterList.size(); }

    std::string getParameterTypeAtIdx(int i) {
        if(i >= parameterList.size())
            return "NONE";

        return parameterList[i];
    }

    std::string getReturnType() const { return this->returnType; }

    ~FunctionInfo() {}
};

#endif

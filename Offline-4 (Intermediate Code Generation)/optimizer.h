#ifndef COMPILER_OPTIMIZER_H
#define COMPILER_OPTIMIZER_H
#include <iostream>
#include <vector>
#include <fstream>
using namespace std;

bool isJump(string s)
{
    if (s == "JMP" || s == "JE" || s == "JL" || s == "JLE" || s == "JG" || s == "JGE" ||
        s == "JNE" || s == "JNL" || s == "JNLE" || s == "JNG" || s == "JNGE")
    {
        return true;
    }

    return false;
}
/**
 * Takes an string and a delimiter and returns a vector of strings
 * that are split by the delimiter.
 * @param s the string to split
 * @param delim the delimiter to split by
 * @return a vector of strings
 */
vector<string> split(const string &s, char delim)
{
    vector<string> elements;
    string item = "";
    for (int i = 0; i < s.length(); i++) {
        if (s[i] == delim || s[i] == '\t') {
            if (item != "") {
                elements.push_back(item);
                item = "";
            }
        }
        else {
            item += s[i];
        }
    }
    
    if (item != "") {
        elements.push_back(item);
    }

    return elements;
}

bool optimizeAsmCode(string sourceFileName, string destinationFileName)
{
    bool isOptimized = false;
    ifstream asmCodeFile(sourceFileName);
    if (!asmCodeFile.is_open())
    {
        cout << "Error: Could not open file " << sourceFileName << "\n";
        return false;
    }

    ofstream optimizedCodeFile(destinationFileName);
    if (!optimizedCodeFile.is_open())
    {
        cout << "Error: Could not open file " << destinationFileName << "\n";
        return false;
    }

    string previousLine = "";
    vector<string> previousInstruction;
    string currentLine;
    while (getline(asmCodeFile, currentLine))
    {
        vector<string> currentInstruction = split(currentLine, ' ');
        // if the current line is a comment then skip it
        if (currentInstruction.size() == 0)
            continue;
        else if(currentInstruction[0][0] == ';') {
            optimizedCodeFile << currentLine << '\n';
            continue;
        }   
        if (previousInstruction.size() == 0)
        {
            previousInstruction = currentInstruction;
            previousLine = currentLine;
            continue;
        }
        // if current line is a POP and the previous line is a PUSH
        if (currentInstruction[0] == "POP" && previousInstruction[0] == "PUSH")
        {
            optimizedCodeFile << ";" + previousLine << "\n";
            optimizedCodeFile << ";" + currentLine << "\n";
            // if push and pop are not on the same address or register
            // then convert it to MOV CURRENT, PREVIOUS
            if (currentInstruction[1] != previousInstruction[1])
            {
                // atleast one of push or pop is associated with a register
                // so the line below should not be an error
                optimizedCodeFile << "\t\tMOV " << currentInstruction[1] << ", " << previousInstruction[1] << "\n";
            }
            // else push and pop are on the same register. So just comment out both the lines
            // and reset the previous instruction to empty
            previousInstruction.clear();
            previousLine = "";
            isOptimized = true;
        }
        // else if the current instruction is MOV and both the registers or address are the same then just ignore the instruction
        else if (currentInstruction[0] == "MOV" && currentInstruction[1].substr(0, currentInstruction[1].length() - 1) == currentInstruction[2])
        {
            // ignore the current instruction
            isOptimized = true;
        }
        // else if both the instructions are MOV
        else if (currentInstruction[0] == "MOV" && previousInstruction[0] == "MOV")
        {
            currentInstruction[1] = split(currentInstruction[1], ',')[0];
            previousInstruction[1] = split(previousInstruction[1], ',')[0];
            // if the first register or address of both the instructions are the same
            // comment out the previous instruction and save the current instruction in previous instruction
            if (currentInstruction[1] == previousInstruction[1])
            {
                optimizedCodeFile << ";" + previousLine << "\n";
                // optimizedCodeFile << currentLine << "\n";
                previousInstruction = currentInstruction;
                previousLine = currentLine;
                isOptimized = true;
            }
            // else if the addresses or registers are the same
            // but in alternate order then comment out the current line and write the previous line
            else if (currentInstruction[1] == previousInstruction[2] &&
                     previousInstruction[1] == currentInstruction[2])
            {
                optimizedCodeFile << previousLine << "\n";
                optimizedCodeFile << ";" + currentLine << "\n";
                previousInstruction.clear();
                previousLine = "";
                isOptimized = true;
            }
            // else write the previous instruction and save the current instruction in the previous instruction
            else
            {
                optimizedCodeFile << previousLine << "\n";
                previousInstruction = currentInstruction;
                previousLine = currentLine;
            }
        }
        // else if the current instruction is a label and
        // the previous instruction is a jump containing the same label
        // then we can remove the jump
        else if (isJump(previousInstruction[0]) && currentInstruction[0][currentInstruction[0].length() - 1] == ':' && currentInstruction[0].substr(0, currentInstruction[0].length() - 1) == previousInstruction[1])
        {
            optimizedCodeFile << ";" + previousLine << "\n";
            optimizedCodeFile << currentLine << "\n";
            previousInstruction.clear();
            previousLine = "";
            isOptimized = true;
        }
        // else if the previous instruction is a CMP but the current instruction is not a jump
        // then remove the previous instruction
        else if (previousInstruction[0] == "CMP" && !isJump(currentInstruction[0]))
        {
            optimizedCodeFile << ";" + previousLine << "\n";
            previousInstruction.clear();
            previousLine = "";
            isOptimized = true;
        }
        // else write the previous instruction and save the current instruction in the previous instruction
        else
        {
            optimizedCodeFile << previousLine << "\n";
            previousInstruction = currentInstruction;
            previousLine = currentLine;
        }
    }
    if (previousInstruction.size() != 0 && previousInstruction[0] == "CMP") {
        optimizedCodeFile << ";" + previousLine << "\n";
    } else {
        optimizedCodeFile << previousLine << "\n";
    }

    asmCodeFile.close();
    optimizedCodeFile.close();
    return isOptimized;
}

#endif
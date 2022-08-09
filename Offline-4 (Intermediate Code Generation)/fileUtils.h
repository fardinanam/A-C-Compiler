#ifndef COMPILER_FILE_UTIL_H
#define COMPILER_FILE_UTIL_H

#include <string>
#include <fstream>
#include <iostream>

/**
 * Writes a string at the end of a file if append = false
 * Else overwrites the whole file and writes the string at the beginning
 * @param fileName - name of the file
 * @param str - string to write
 * @param append - true if you want to append the string at the end of the file
 */
void write(std::string fileName, std::string str, bool append = false) {
    std::ofstream file;
    if(append)
        file.open(fileName, std::ios_base::app);
    else
        file.open(fileName);

    if(!file.is_open()) {
        std::cout << "Error opening " << fileName << std::endl;
        return;
    }
    
    file << str << std::endl;
    file.close();
}

/**
 * Appends a string at a given position in a file
 * @param fileName - name of the file
 * @param lineNo - position in the file to append the string
 * @param str - string to append
 */
void writeAt(std::string fileName, std::string str, int lineNo)
{
    // Make a new file with the name tempCode.asm.
    // Copy the codes from code.asm upto lineNo to tempCode.asm
    // Append the str in the tempCode.asm file.
    // Append the rest of the codes from code.asm to tempCode.asm
    // Copy the tempCode.asm to code.asm

    std::ofstream tempCode;
    tempCode.open("tempCode.asm");
    std::ifstream codeFile;
    codeFile.open(fileName, std::ios_base::in);
    std::string line;
    int lineCount = 0;
    bool hasWritten = false;

    while (std::getline(codeFile, line))
    {
        if (lineCount == lineNo)
        {
            tempCode << str << '\n';
            hasWritten = true;
        }
        tempCode << line << '\n';
        lineCount++;
    }

    if (!hasWritten)
    {
        tempCode << str << '\n';
        hasWritten = true;
    }

    codeFile.close();
    tempCode.close();

    int status = remove(fileName.c_str());
    if (status)
        std::cout << "Error deleting file" << std::endl;

    status = rename("tempCode.asm", fileName.c_str());
    if (status)
        std::cout << "Error renaming file" << std::endl;
}

#endif //COMPILER_FILE_UTIL_H
module dminjs.main;

import std.stdio;
import std.file;
import core.sys.posix.unistd;
import dminjs.minify;

int main(string[] args){
    File inputFile;
    
    //check if input is being piped
    if(!isatty(stdin.fileno)){
        inputFile = stdin;
    }
    else{
        if(!areArgumentsValid(args)){
            return printUsage(args[0]);
        }
        inputFile.open(args[1]);
    }
    
    minifyFile(inputFile);
    
    return 0;
}

bool areArgumentsValid(string[] args){
    if(args.length != 2){
        return false;
    }
    
    return isValidFileName(args[1]);
}

bool isValidFileName(string fileName){
    return exists(fileName) && isFile(fileName);
}

int printUsage(string programName){
    stderr.writef("usage: %s <input_filename>\n", programName);
    return 1;
}

void minifyFile(File file){
    ParserState parserState = createParserState();
    
    char[] buf;
    while(file.readln(buf)){
        parserState = minifyLine(buf, parserState);
        write(buf);
    }
}
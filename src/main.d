module dminjs.main;

import std.stdio;
import std.file;
import dminjs.minify;

int main(string[] args){
    File inputFile;
    
    if(isInputFromPipe()){
        inputFile = stdin;
    }
    else{
        if(!areArgumentsValid(args)){
            return printUsage(args[0]);
        }
        string inputFileName = args[1];
        
        if(!exists(inputFileName)){
            writef("%s does not exist\n", inputFileName);
            return 1;
        }
        if(!isFile(inputFileName)){
            writef("%s is not a file\n", inputFileName);
            return 1;
        }
        inputFile.open(inputFileName);
    }
    
    minifyFile(inputFile);
    
    return 0;
}

//cross platform compatible version of isatty,
//just returns false on Windows
bool isInputFromPipe(){
    version(Windows){
        return false;
    }
    else{
        import core.sys.posix.unistd;
        return isatty(stdin.fileno) == 0;
    }
}

bool areArgumentsValid(string[] args){
    return args.length == 2;
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
module dminjs.test;

import std.stdio;
import dminjs.minify;


struct TestCase{
    string name;
    string input;
    string expected;
}

//colors based on: https://stackoverflow.com/questions/3219393/stdlib-and-colored-output-in-c
immutable string TEXT_RED = "\033[31m";
immutable string TEXT_YELLOW = "\033[33m";
immutable string TEXT_RESET = "\033[0m";


TestCase[] getTestCases(){
    TestCase[] ret;
    
    ret ~= TestCase("use strict", `  "use strict";  `, `"use strict";`);
    ret ~= TestCase("whitespace", "  \n\n   \t \r  ", ``);
    ret ~= TestCase("single line comment", "  //testing a comment \n var a = 'hello there'; ", `var a='hello there';`);
    ret ~= TestCase("regex literal", `  var regexLiteral = /oeu.[a-z \W"]\//; //comment `, `var regexLiteral=/oeu.[a-z \W"]\//;`);
    ret ~= TestCase("regex literal2", `  var regexLiteral = /oeu.[a-z g"]\//; //comment `, `var regexLiteral=/oeu.[a-z g"]\//;`);
    ret ~= TestCase("regex literal3", `  let regex=/ a b /; `, `let regex=/ a b /;`);
    ret ~= TestCase("regex literal4", `  func(/ a /, 'hello there') ; `, `func(/ a /,'hello there');`);
    ret ~= TestCase("division", `  var pi = (3.0 / 5) / (1/2); //comment `, `var pi=(3.0/5)/(1/2);`);
    ret ~= TestCase("division2", `  ( a  / 10. ) / _ / ($ ) / x3 ; //comment `, `(a/10.)/_/($)/x3;`);
    ret ~= TestCase("dividing nonsense", ` let d =   [] / 3. / " hello " / '  anyway ' ; `, `let d=[]/3./" hello "/'  anyway ';`);
    ret ~= TestCase("double quotes with escapes", `var s = "hello \" "; //comment  `, `var s="hello \" ";`);
    ret ~= TestCase("ending quote with backslash", ` " hello \" there \\"; //comment`, `" hello \" there \\";`);
    
    return ret;
}

bool runTestCase(TestCase testCase, bool shouldPrintError){
    bool didTestCasePass;
    
    ParserState parserState = createParserState();
    char[] output = testCase.input.dup;
    parserState = minifyLine(output, parserState);
    
    didTestCasePass = output == testCase.expected;
    
    if(!didTestCasePass && shouldPrintError){
        stderr.writef("%s%s test failed!\n%s", TEXT_RED, testCase.name, TEXT_RESET);
        stderr.writef("%sexpected: %s%s\n%sactual  : %s%s\n\n", TEXT_YELLOW, TEXT_RESET, testCase.expected, TEXT_YELLOW, TEXT_RESET, output);
    }
    
    
    return didTestCasePass;
}

void main(){
    TestCase[] testCases = getTestCases();
    
    ulong totalTests = testCases.length;
    ulong numTestsPassed = 0;
    
    foreach(TestCase testCase; testCases){
        if(runTestCase(testCase, true)){
            numTestsPassed++;
        }
    }
    
    writef("%d tests run, %d tests passed\n", totalTests, numTestsPassed);
}
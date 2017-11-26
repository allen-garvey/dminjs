module dminjs.main;

import std.stdio;
import dminjs.minify;

void main(){

    ParserState parserState;
    parserState.commentState = CommentType.None;
    parserState.quoteState = QuoteType.None;
    
    char[] buf;
    while(stdin.readln(buf)){
        parserState = minifyLine(buf, parserState);
        write(buf);
    }
}
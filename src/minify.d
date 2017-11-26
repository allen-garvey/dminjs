module dminjs.minify;

import std.ascii;

struct ParserState{
    char previousChar;
    char previousPreviousChar;
    char lastCharAdded;
    QuoteType quoteState;
    CommentType commentState;
}

enum QuoteType { None, Single, Double, Backtick }
enum CommentType { None, DoubleForwardSlash, ForwardSlashStar }

ParserState minifyLine(ref char[] line, ParserState parserState){
    char[] minifiedLineBuffer;
    minifiedLineBuffer.length = line.length;
    
    int bufferIndex = 0;
    bool shouldAddChar;
    char nextChar;
    
    foreach(int i, char c; line){
        if(i < line.length - 1){
            nextChar = line[i+1];
        }
        else{
            nextChar = 0;
        }
        shouldAddChar = false;
        switch(c){
            case '\n':
                if(parserState.commentState == CommentType.DoubleForwardSlash){
                    parserState.commentState = CommentType.None;
                    break;
                }
                goto case '\r';
            case ' ':
                if(isJsVariableNameChar(parserState.lastCharAdded) && isJsVariableNameChar(nextChar)){
                    goto DEFAULT_CASE;
                }
                goto case '\r';
            case '\t':
            case '\r':
                if(parserState.quoteState != QuoteType.None){
                    goto DEFAULT_CASE;
                }
                break;
            case '"':
                parserState = processQuoteType(parserState, QuoteType.Double);
                goto DEFAULT_CASE;
            case '\'':
                parserState = processQuoteType(parserState, QuoteType.Single);
                goto DEFAULT_CASE;
            case '`':
                parserState = processQuoteType(parserState, QuoteType.Backtick);
                goto DEFAULT_CASE;
            case '/':
                if(parserState.quoteState != QuoteType.None){
                    goto DEFAULT_CASE;
                }
                else if(parserState.commentState == CommentType.ForwardSlashStar && parserState.previousChar == '*'){
                    parserState.commentState = CommentType.None;
                }
                else if(parserState.commentState != CommentType.None){
                    //don't do anything, since we are in a comment and we are not ending a comment
                }
                //because of previous else if check, commentState is CommentType.None for following checks
                else if(nextChar == '/'){
                    parserState.commentState = CommentType.DoubleForwardSlash;
                }
                else if(nextChar == '*'){
                    parserState.commentState = CommentType.ForwardSlashStar;
                }
                //division sign
                else{
                    goto DEFAULT_CASE;
                }
                break;
            DEFAULT_CASE:
            default:
                if(parserState.commentState == CommentType.None){
                    shouldAddChar = true;   
                }
                break;
            
        }
        if(shouldAddChar){
            minifiedLineBuffer[bufferIndex] = c;
            parserState.lastCharAdded = c;
            bufferIndex++;
        }
        parserState.previousPreviousChar = parserState.previousChar;
        parserState.previousChar = c;
    }
    
    minifiedLineBuffer.length = bufferIndex;
    line = minifiedLineBuffer;
    
    return parserState;
}


bool isJsVariableNameChar(char c){
    if(isAlpha(c) || isDigit(c)){
        return true;
    }
    
    switch(c){
        case '_':
        case '$':
            return true;
        default:
            return false;
    }
}

ParserState processQuoteType(ParserState parserState, QuoteType quoteType){
    if(parserState.commentState != CommentType.None){
        return parserState;
    }
    if(parserState.quoteState == quoteType && !(parserState.previousChar == '\\' && parserState.previousPreviousChar != '\\')){
        parserState.quoteState = QuoteType.None;
    }
    else if(parserState.quoteState == QuoteType.None){
        parserState.quoteState = quoteType;
    }
    return parserState;
}
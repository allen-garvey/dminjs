module dminjs.minify;

import std.ascii;

enum MetaState { None, RegexLiteral, QuoteSingle, QuoteDouble, QuoteBacktick, CommentDoubleForwardSlash, CommentForwardSlashStar }

struct ParserState{
    char previousChar;
    char previousPreviousChar;
    char lastCharAdded;
    MetaState metaState;
}

ParserState createParserState(){
    ParserState parserState;
    parserState.metaState = MetaState.None;
    
    return parserState;
}

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
                if(parserState.metaState == MetaState.CommentDoubleForwardSlash){
                    parserState.metaState = MetaState.None;
                    break;
                }
                //goto required for fallthrough because of compiler warning
                goto case '\r';
            case ' ':
            case '\t':
            case '\r':
                if(isInQuote(parserState.metaState)){
                    goto DEFAULT_CASE;
                }
                else if(isJsVariableNameChar(parserState.lastCharAdded) && (isJsVariableNameChar(nextChar) || nextChar == 0)){
                    goto DEFAULT_CASE;
                }
                break;
            case '"':
                parserState = processQuoteType(parserState, MetaState.QuoteDouble);
                goto DEFAULT_CASE;
            case '\'':
                parserState = processQuoteType(parserState, MetaState.QuoteSingle);
                goto DEFAULT_CASE;
            case '`':
                parserState = processQuoteType(parserState, MetaState.QuoteBacktick);
                goto DEFAULT_CASE;
            case '/':
                if(isInQuote(parserState.metaState)){
                    goto DEFAULT_CASE;
                }
                else if(parserState.metaState == MetaState.CommentForwardSlashStar && parserState.previousChar == '*'){
                    parserState.metaState = MetaState.None;
                }
                else if(isInComment(parserState.metaState)){
                    //don't do anything, since we are in a comment and we are not ending a comment
                }
                //because of previous else if check, commentState is CommentType.None for following checks
                //backslash check is so this works with regex literals, but might have some weird edge cases with single line comments
                else if(nextChar == '/' && parserState.previousChar != '\\'){
                    parserState.metaState = MetaState.CommentDoubleForwardSlash;
                }
                else if(nextChar == '*'){
                    parserState.metaState = MetaState.CommentForwardSlashStar;
                }
                //division sign
                else{
                    goto DEFAULT_CASE;
                }
                break;
            DEFAULT_CASE:
            default:
                if(!isInComment(parserState.metaState)){
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

bool isInQuote(MetaState metaState){
    switch(metaState){
        case MetaState.QuoteSingle:
        case MetaState.QuoteDouble:
        case MetaState.QuoteBacktick:
            return true;
        default:
            return false;
    }
}

bool isInComment(MetaState metaState){
    switch(metaState){
        case MetaState.CommentDoubleForwardSlash:
        case MetaState.CommentForwardSlashStar:
            return true;
        default:
            return false;
    }
}

ParserState processQuoteType(ParserState parserState, MetaState quoteType){
    if(isInComment(parserState.metaState)){
        return parserState;
    }
    if(parserState.metaState == quoteType && !(parserState.previousChar == '\\' && parserState.previousPreviousChar != '\\')){
        parserState.metaState = MetaState.None;
    }
    else if(parserState.metaState == MetaState.None){
        parserState.metaState = quoteType;
    }
    return parserState;
}
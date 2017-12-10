module dminjs.minify;

import std.ascii;

enum MetaState { None, RegexLiteral, QuoteSingle, QuoteDouble, QuoteBacktick, CommentDoubleForwardSlash, CommentForwardSlashStar }

struct ParserState{
    char previousChar;
    char lastCharAdded;
    long escapeCharacterSequenceCount;
    MetaState metaState;
}

ParserState createParserState(){
    ParserState parserState;
    parserState.metaState = MetaState.None;
    parserState.escapeCharacterSequenceCount = 0;
    
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
            case '\\':
                if(isInCharacterLiteral(parserState.metaState)){
                    parserState.escapeCharacterSequenceCount++;
                }
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
                //because of previous else if checks, we know we are not in a comment here
                else if(parserState.metaState == MetaState.None && nextChar == '/'){
                    parserState.metaState = MetaState.CommentDoubleForwardSlash;
                }
                else if(parserState.metaState == MetaState.None && nextChar == '*'){
                    parserState.metaState = MetaState.CommentForwardSlashStar;
                }
                else if(parserState.metaState == MetaState.RegexLiteral || parserState.metaState == MetaState.None ){
                    parserState = processQuoteType(parserState, MetaState.RegexLiteral);
                    goto DEFAULT_CASE;
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

bool isInCharacterLiteral(MetaState metaState){
    return isInQuote(metaState) || metaState == MetaState.RegexLiteral;
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
    if(parserState.metaState == quoteType && (parserState.previousChar != '\\' || parserState.escapeCharacterSequenceCount % 2 == 0)){
        parserState.metaState = MetaState.None;
        parserState.escapeCharacterSequenceCount = 0;
    }
    else if(parserState.metaState == MetaState.None){
        parserState.metaState = quoteType;
    }
    return parserState;
}
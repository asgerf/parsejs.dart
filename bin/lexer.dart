library lexer;

import 'charcode.dart' as char;
import 'package:unicode/unicode.dart' as unicode;

class Token {
  int offset;
  int type;
  String value;
  bool afterLinebreak; // first token after a linebreak?
  String raw; // for string literals
  
  /// For tokens that can be used as binary operators, this indicates their relative precedence.
  /// Set to -100 for other tokens.
  /// Token type can be BINARY, or UNARY (+,-) or NAME (instanceof,in).
  int binaryPrecedence = -100;
  
  Token(this.offset, this.type, this.afterLinebreak, [this.value]);
  
  String toString() => value != null ? value : typeToString(type);
  
  String get detailedString => "[$offset, $value, $type, $afterLinebreak]";
  
  static const int EOF = 0;
  static const int NAME = 1;
  static const int NUMBER = 2;
  static const int BINARY = 3; // does not contain unary operators +,- or names instanceof, in (but binaryPrecedence is set for these)
  static const int ASSIGN = 4; // also compound assignment operators
  static const int UPDATE = 5; // ++ and --
  static const int UNARY = 6; // all unary operators except the names void, delete
  static const int STRING = 7;
  static const int REGEXP = 8;
  
  // Tokens without a value have type equal to their corresponding char code
  // All these are >31
  static const int LPAREN = char.LPAREN;
  static const int RPAREN = char.RPAREN;
  static const int LBRACE = char.LBRACE;
  static const int RBRACE = char.RBRACE;
  static const int LBRACKET = char.LBRACKET;
  static const int RBRACKET = char.RBRACKET;
  static const int COMMA = char.COMMA;
  static const int COLON = char.COLON;
  static const int SEMICOLON = char.SEMICOLON;
  static const int DOT = char.DOT;
  static const int QUESTION = char.QUESTION;
  
  static String typeToString(int type) {
    if (type > 31)
      return new String.fromCharCode(type);
    switch (type) {
      case EOF: return 'EOF';
      case NAME: return 'name';
      case NUMBER: return 'number';
      case BINARY: return 'binary operator';
      case ASSIGN: return 'assignment operator';
      case UPDATE: return 'update operator';
      case UNARY: return 'unary operator';
      case STRING: return 'string literal';
      default: return '[type $type]';
    }
  }
}

class Precedence {
  static const int EXPRESSION = 0;
  static const int CONDITIONAL = 1;
  static const int LOGICAL_OR = 2;
  static const int LOGICAL_AND = 3;
  static const int BITWISE_OR = 4;
  static const int BITWISE_XOR = 5;
  static const int BITWISE_AND = 6;
  static const int EQUALITY = 7;
  static const int RELATIONAL = 8;
  static const int SHIFT = 9;
  static const int ADDITIVE = 10;
  static const int MULTIPLICATIVE = 11;
}

bool isLetter(x) => (char.$a <= x && x <= char.$z) || (char.$A <= x && x <= char.$Z) || x > 0x100 && isFancyLetter(x);

bool isFancyLetter(x) => unicode.isUppercaseLetter(x) || unicode.isLowercaseLetter(x) || unicode.isTitlecaseLetter(x) || 
                         unicode.isModifierLetter(x) || unicode.isOtherLetter(x) || unicode.isLetterNumber(x);

bool isDigit(x) => char.$0 <= x && x <= char.$9; // Does NOT and should not include unicode special digits

bool isNameStart(x) => isLetter(x) || x == char.DOLLAR || x == char.UNDERSCORE;

bool isNamePart(x) => char.$a <= x && x <= char.$z || char.$A <= x && x <= char.$Z || char.$0 <= x && x <= char.$9 ||
                      x == char.DOLLAR || x == char.UNDERSCORE ||
                      x >= 0x100 && (isFancyLetter(x) || unicode.isDecimalNumber(x) || isFancyNamePart(x));

bool isFancyNamePart(x) => x == char.ZWNJ || x == char.ZWJ || x == char.BOM || unicode.isNonspacingMark(x); // TODO: Combining Spacing Mark (Mc) is missing from unicode.

/// Includes ordinary whitespace (not line terminators)
bool isWhitespace(x) {
  switch (x) {
    case char.SPACE:
    case char.TAB:
    case char.VTAB:
    case char.FF:
    case char.NBSP:
    case char.BOM:
      return true;
      
    default:
      return x > 0x100 && unicode.isSpaceSeparator(x);
  }
}

bool isEOL(x) => x == char.LF || x == char.CR || x == char.LS || x == char.PS || x == char.NULL;

class Lexer {
  
  Lexer(String text) {
    // TODO: can we do with without cloning?
    input = new List<int>.from(text.codeUnits);
    input.add(char.NULL);
  }
  
  List<int> input;
  int index = 0;
  int tokenStart;
  bool seenLinebreak;
  
  Token emitToken(int type, [String value]) {
    return new Token(tokenStart, type, seenLinebreak, value);
  }
  Token emitValueToken(int type) {
    String value = new String.fromCharCodes(input.getRange(tokenStart, index));
    return new Token(tokenStart, type, seenLinebreak, value);
  }
  
  /// Annotates a NAME token with precedence information before returning it.
  /// This is so 'instanceof' and 'in' can be used as both names and binary operators.
  Token addNamePrecedence(Token token) {
    if (token.value == 'instanceof' || token.value == 'in') {
      token.binaryPrecedence = Precedence.RELATIONAL;
    }
    return token;
  }
  
  Token scanNumber(int x) {
    if (x == char.$0) {
      x = input[++index];
      if (x == char.$x || x == char.$X) {
        x = input[++index];
        return scanHexNumber(x);
      }
    }
    while (isDigit(x)) {
      x = input[++index];
    }
    if (x == char.DOT) {
      x = input[++index];
      return scanDecimalPart(x);
    }
    return scanExponentPart(x);
  }
  
  Token scanDecimalPart(int x) {
    assert(input[index-1] == char.DOT); // Index should point to the character AFTER the dot
    while (isDigit(x)) {
      x = input[++index];
    }
    return scanExponentPart(x);
  }
  
  Token scanExponentPart(int x) {
    if (x == char.$e || x == char.$E) {
      x = input[++index];
      if (x == char.PLUS || x == char.MINUS) {
        x = input[++index];        
      }
      while (isDigit(x)) {
        x = input[++index];
      }
    }
    return emitValueToken(Token.NUMBER);
  }
  
  Token scanHexNumber(int x) {
    assert(input[index-1] == char.$x || input[index-1] == char.$X); // Index should point to the character AFTER the X
    while (isDigit(x) || char.$a <= x && x <= char.$f || char.$A <= x && x <= char.$F) {
      x = input[++index];
    }
    return emitValueToken(Token.NUMBER);
  }
  
  Token scanName(int x) {
    while (true) {
      if (x == char.BACKSLASH)
        return scanComplexName(x);
      if (!isNamePart(x))
        return addNamePrecedence(emitValueToken(Token.NAME));
      x = input[++index];
    }
  }
  
  Token scanComplexName(int x) { // name with unicode escape sequences
    List<int> buffer = new List<int>.from(input.getRange(tokenStart, index));
    while (true) {
      if (x == char.BACKSLASH) {
        x = input[++index];
        if (x != char.$u) {
          throw "Invalid escape sequence in name";
        }
        ++index;
        buffer.add(scanHexSequence(4));
        x = input[index];
      } else if (isNamePart(x)) {
        buffer.add(x);
        x = input[++index];
      } else {
        break;
      }
    }
    return addNamePrecedence(emitToken(Token.NAME, new String.fromCharCodes(buffer)));
  }
  
  /// [index] must point to the first hex digit.
  /// It will be advanced to point AFTER the hex sequence (i.e. index += count).
  int scanHexSequence(int count) {
    int x = input[index];
    int value = 0;
    for (int i=0; i<count; i++) {
      if (char.$0 <= x && x <= char.$9) {
        value = (value << 4) + (x - char.$0);
      }
      else if (char.$a <= x && x <= char.$f) {
        value = (value << 4) + (x - char.$a + 10);
      }
      else if (char.$A <= x && x <= char.$F) {
        value = (value << 4) + (x - char.$A + 10);
      }
      else {
        throw "Invalid hex sequence"; // TODO: error management
      }
      x = input[++index];
    }
    return value;
  }
  
  Token scan() {
    seenLinebreak = false;
    scanLoop:
    while (true) { 
      int x = input[index];
      tokenStart = index;
      switch (x) {
        case char.NULL:
          return emitToken(Token.EOF); // (will produce infinite EOF tokens if pressed for more tokens)
        
        case char.$0:
        case char.$1:
        case char.$2:
        case char.$3:
        case char.$4:
        case char.$5:
        case char.$6:
        case char.$7:
        case char.$8:
        case char.$9:
          return scanNumber(x);
          
        case char.SPACE: // Note: Exotic whitespace symbols are handled in the default clause.
        case char.TAB:
          ++index;
          while (isWhitespace(input[index])) ++index; // optimization
          continue;

        case char.CR:
        case char.LF:
        case char.LS:
        case char.PS:
          ++index;
          seenLinebreak = true;
          while (isWhitespace(input[index])) ++index; // optimization
          continue;
          
        case char.SLASH:
          x = input[++index]; // consume "/"
          if (x == char.SLASH) { // "//" comment
            x = input[++index];
            while (!isEOL(x)) {
              x = input[++index];
            }
            seenLinebreak = true;
            continue;
          }
          if (x == char.STAR) { // "/*" comment
            ++index;
            int len = input.length;
            while (true) {
              while (index < len && input[index] != char.STAR) ++index;
              if (index == len) throw "Unterminated block comment"; // TODO: error management
              ++index; // consume star
              if (input[index] == char.SLASH) {
                ++index;
                continue scanLoop; // Finished. Ignore token scan again.
              }
            }
          }
          // parser will recognize these as potential regexp heads
          if (x == char.EQ) { // "/="
            ++index;
            return emitToken(Token.ASSIGN, '/='); 
          }
          return emitToken(Token.BINARY, '/')..binaryPrecedence = Precedence.MULTIPLICATIVE;
          
        case char.PLUS:
          x = input[++index];
          if (x == char.PLUS) {
            ++index;
            return emitToken(Token.UPDATE, '++');
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '+=');
          }
          return emitToken(Token.UNARY, '+')..binaryPrecedence = Precedence.ADDITIVE;
        
        case char.MINUS:
          x = input[++index];
          if (x == char.MINUS) {
            ++index;
            return emitToken(Token.UPDATE, '--');
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '-=');
          }
          return emitToken(Token.UNARY, '-')..binaryPrecedence = Precedence.ADDITIVE;
          
        case char.STAR:
          x = input[++index];
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '*=');
          }
          return emitToken(Token.BINARY, '*')..binaryPrecedence = Precedence.MULTIPLICATIVE;
          
        case char.PERCENT:
          x = input[++index];
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '%=');
          }
          return emitToken(Token.BINARY, '%')..binaryPrecedence = Precedence.MULTIPLICATIVE;
          
        case char.LT:
          x = input[++index];
          if (x == char.LT) {
            x = input[++index];
            if (x == char.EQ) {
              ++index;
              return emitToken(Token.ASSIGN, '<<=');
            }
            return emitToken(Token.BINARY, '<<')..binaryPrecedence = Precedence.SHIFT;
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.BINARY, '<=')..binaryPrecedence = Precedence.RELATIONAL;
          }
          return emitToken(Token.BINARY, '<')..binaryPrecedence = Precedence.RELATIONAL;
          
        case char.GT:
          x = input[++index];
          if (x == char.GT) {
            x = input[++index];
            if (x == char.GT) {
              x = input[++index];
              if (x == char.EQ) {
                ++index;
                return emitToken(Token.ASSIGN, '>>>=');
              }
              return emitToken(Token.BINARY, '>>>')..binaryPrecedence = Precedence.SHIFT;
            }
            if (x == char.EQ) {
              ++index;
              return emitToken(Token.ASSIGN, '>>=');
            }
            return emitToken(Token.BINARY, '>>')..binaryPrecedence = Precedence.SHIFT;
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.BINARY, '>=')..binaryPrecedence = Precedence.RELATIONAL;
          }
          return emitToken(Token.BINARY, '>')..binaryPrecedence = Precedence.RELATIONAL;
          
        case char.HAT:
          x = input[++index];
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '^=');
          }
          return emitToken(Token.BINARY, '^')..binaryPrecedence = Precedence.BITWISE_XOR;
          
        case char.TILDE:
          ++index;
          return emitToken(Token.UNARY, '~');
          
        case char.BAR:
          x = input[++index];
          if (x == char.BAR) {
            ++index;
            return emitToken(Token.BINARY, '||')..binaryPrecedence = Precedence.LOGICAL_OR;
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '|=');
          }
          return emitToken(Token.BINARY, '|')..binaryPrecedence = Precedence.BITWISE_OR;
          
        case char.AMPERSAND:
          x = input[++index];
          if (x == char.AMPERSAND) {
            ++index;
            return emitToken(Token.BINARY, '&&')..binaryPrecedence = Precedence.LOGICAL_AND;
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '&=');
          }
          return emitToken(Token.BINARY, '&')..binaryPrecedence = Precedence.BITWISE_AND;
          
        case char.EQ:
          x = input[++index];
          if (x == char.EQ) {
            x = input[++index];
            if (x == char.EQ) {
              ++index;
              return emitToken(Token.BINARY, '===')..binaryPrecedence = Precedence.EQUALITY;
            }
            return emitToken(Token.BINARY, '==')..binaryPrecedence = Precedence.EQUALITY;
          }
          return emitToken(Token.ASSIGN, '=');
        
        case char.BANG:
          x = input[++index];
          if (x == char.EQ) {
            x = input[++index];
            if (x == char.EQ) {
              ++index;
              return emitToken(Token.BINARY, '!==')..binaryPrecedence = Precedence.EQUALITY;
            }
            return emitToken(Token.BINARY, '!=')..binaryPrecedence = Precedence.EQUALITY;
          }
          return emitToken(Token.UNARY, '!');
          
        case char.DOT:
          x = input[++index];
          if (isDigit(x)) {
            return scanDecimalPart(x);
          }
          return emitToken(Token.DOT);
          
        case char.SQUOTE:
        case char.DQUOTE:
          return scanStringLiteral(x);

        case char.LPAREN:
        case char.RPAREN:
        case char.LBRACKET:
        case char.RBRACKET:
        case char.LBRACE:
        case char.RBRACE:
        case char.COMMA:
        case char.COLON:
        case char.SEMICOLON:
        case char.QUESTION:
          ++index;
          return emitToken(x);
          
        case char.BACKSLASH:
          return scanComplexName(x);
          
        default:
          if (isNameStart(x))
            return scanName(x);
          if (isWhitespace(x)) {
            ++index;
            while (isWhitespace(input[index])) ++index;
            continue;
          }
          throw "Unrecognized character: $x";
      }
    }
  }
  
  /// For debugging, returns the string value of the current token range (trimmed to 100 to avoid mega outputs)
  String get currentTokenString => new String.fromCharCodes(input.getRange(tokenStart, index)).substring(0, 100);
  
  /// Scan a regular expression literal, where the opening token has already been scanned
  /// This is called directly from the parser.
  /// The opening token [slash] can be a "/" or a "/=" token
  Token scanRegexpBody(Token slash) {
    bool inCharClass = false; // If true, we are inside a bracket. A slash in here does not terminate the literal. They are not nestable.
    int x = input[index];
    while (inCharClass || x != char.SLASH) {
      switch (x) {
        case char.NULL:
          throw "Unterminated regexp: $currentTokenString"; // TODO: error management
        case char.LBRACKET:
          inCharClass = true;
          break;
        case char.RBRACKET:
          inCharClass = false;
          break;
        case char.BACKSLASH:
          x = input[++index];
          if (isEOL(x)) throw "Unterminated regexp: $currentTokenString"; // TODO: error management
          break;
      }
      x = input[++index];
    }
    x = input[++index]; // Move past the terminating "/"
    while (isNamePart(x)) { // Parse flags
      x = input[++index];
    }
    return emitToken(Token.REGEXP, new String.fromCharCodes(input.getRange(slash.offset, index)));
  }
  
  Token scanStringLiteral(int x) {
    List<int> buffer = <int>[]; // String value without quotes, after resolving escapes. 
    int quote = x;
    x = input[++index];
    while (x != quote) {
      if (x == char.BACKSLASH) {
        x = input[++index];
        switch (x) {
          case char.$b:
            buffer.add(char.BS);
            x = input[++index];
            break;
          case char.$f:
            buffer.add(char.FF);
            x = input[++index];
            break;
          case char.$n:
            buffer.add(char.LF);
            x = input[++index];
            break;
          case char.$r:
            buffer.add(char.CR);
            x = input[++index];
            break;
          case char.$t:
            buffer.add(char.TAB);
            x = input[++index];
            break;
          case char.$v:
            buffer.add(char.VTAB);
            x = input[++index];
            break;
            
          case char.$x:
            ++index;
            buffer.add(scanHexSequence(2));
            x = input[index];
            break;
            
          case char.$u:
            ++index;
            buffer.add(scanHexSequence(4));
            x = input[index];
            break;
            
          case char.$0:
          case char.$1:
          case char.$2:
          case char.$3:
          case char.$4:
          case char.$5:
          case char.$6:
          case char.$7: // Octal escape
            int value = (x - char.$0);
            x = input[++index];
            while (isDigit(x)) {
              int nextValue = (value << 3) + (x - char.$0);
              if (nextValue > 127)
                break;
              value = nextValue;
              x = input[++index];
            }
            buffer.add(value);
            break; // OK
            
          case char.LF:
          case char.LS:
          case char.PS:
            x = input[++index]; // just continue on next line
            break; 
            
          case char.CR:
            x = input[++index];
            if (x == char.LF) {
              x = input[++index]; // Escape entire CR-LF sequence
            }
            break;

          case char.SQUOTE:
          case char.DQUOTE:
          case char.BACKSLASH:
          default:
            buffer.add(x);
            x = input[++index];
            break;
        }
      } else if (isEOL(x)) { // Note: EOF counts as an EOL
        throw "Unterminated string literal";
      } else {
        buffer.add(x); // ordinary char
        x = input[++index]; 
      }
    }
    ++index; // skip ending quote
    // XXX: don't build two separate strings if there were no escape sequences
    String value = new String.fromCharCodes(buffer);
    String raw = new String.fromCharCodes(input.getRange(tokenStart, index));
    return emitToken(Token.STRING, value)..raw = raw;
  }
  
  
}




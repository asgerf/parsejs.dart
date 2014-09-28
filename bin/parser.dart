library parser;

import 'lexer.dart';
import 'ast.dart';

class Parser {
  
  Lexer lexer;
  Token token;
  
  /// Returns the current token, and scans the next one. 
  Token next() {
    Token t = token;
    token = lexer.scan();
    return t;
  }
  
  /// Consume a semicolon, or if a line-break was here, just pretend there was one here.
  void magicSemicolon() {
    if (token.type == Token.SEMICOLON) {
      next();
      return;
    }
    if (token.afterLinebreak) {
      return;
    }
    if (token.type == Token.EOF) {
      return;
    }
    throw "Expected semicolon";
  }
  
  void consume(int type) {
    if (token.type != type) {
      throw "Unexpected token: $token ${token.detailedString}";
    }
    next();
  }
  Token requireNext(int type) {
    if (token.type != type) {
      throw "Unexpected token: $token ${token.detailedString}";
    }
    return next();
  }
  
  Name parseName() {
    Token token = requireNext(Token.NAME);
    return new Name(token.value);
  }

  ///// FUNCTIONS //////
  
  List<Name> parseParameters() {
    consume(Token.LPAREN);
    List<Name> list = <Name>[];
    while (token.type != Token.RPAREN) {
      if (list.length > 0) {
        consume(Token.COMMA);
      }
      list.add(parseName());
    }
    consume(Token.RPAREN);
    return list;
  }
  
  BlockStatement parseFunctionBody() {
    return null;
  }
  
  FunctionExpression parseFunctionExpression() {
    assert(token.value == 'function');
    next();
    Name name = null;
    if (token.type == Token.NAME) {
      name = parseName();
    }
    List<Name> params = parseParameters();
    BlockStatement body = parseFunctionBody();
    return new FunctionExpression(name, params, body);
  }
  
  ///// EXPRESSIONS //////
  
  Expression parsePrimary() {
    switch (token.type) {
      case Token.NAME:
        Token name = next();
        switch (name.value) {
          case 'this': return new ThisExpression();
          case 'true': return new LiteralExpression(true);
          case 'false': return new LiteralExpression(false);
          case 'null': return new LiteralExpression(null);
          case 'function': return parseFunctionExpression();
        }
        return new NameExpression(new Name(name.value));
        
      case Token.NUMBER:
        Token tok = next();
        return new LiteralExpression(double.parse(tok.value));
        
      case Token.STRING:
        Token tok = next();
        return new LiteralExpression(tok.value);
        
      case Token.LBRACKET:
        return parseArrayLiteral();
        
      case Token.LBRACE:
        return parseObjectLiteral();
        
      case Token.LPAREN:
        next();
        Expression exp = parseExpression();
        consume(Token.RPAREN);
        return exp;
        
      case Token.BINARY:
      case Token.ASSIGN:
        if (token.value == '/' || token.value == '/=') {
          Token regexTok = lexer.scanRegexpBody(token);
          next();
          return new RegexpExpression(regexTok.value);
        }
        throw "Unexpected token: $token";
        
      default:
        throw "Unexpected token: $token";
    }
  }
  
  Expression parseArrayLiteral() {
    consume(Token.LBRACKET);
    List<Expression> expressions = <Expression>[];
    while (token.type != Token.RBRACKET) {
      if (token.type == Token.COMMA) {
        next();
        expressions.add(null);
      } else {
        expressions.add(parseAssignment());
        if (token.type != Token.RBRACKET) {
          consume(Token.COMMA);
        }
      }
    }
    consume(Token.RBRACKET);
    return new ArrayExpression(expressions);
  }
  
  Name makePropertyName(Token tok) => new Name(tok.value.toString()); // TODO: check token type to detect errors
  
  Property parseProperty() {
    Token nameTok = next();
    if (token.type == Token.COLON) {
      next(); // skip colon
      Name name = makePropertyName(nameTok);
      Expression value = parseAssignment();
      return new Property(name, value);
    }
    if (nameTok.type == Token.NAME && (nameTok.value == 'get' || nameTok.value == 'set')) {
      nameTok = next();
      Name name = makePropertyName(nameTok);
      List<Name> params = parseParameters();
      BlockStatement body = parseFunctionBody();
      Expression value = new FunctionExpression(null, params, body);
      return new Property(name, value, nameTok.value == 'get' ? 'get' : 'set'); // (internalize the get/set strings)
    }
    throw "Invalid property: $nameTok $token";
  }
  
  Expression parseObjectLiteral() {
    consume(Token.LBRACE);
    List<Property> properties = <Property>[];
    while (token.type != Token.RBRACE) {
      if (properties.length > 0) {
        consume(Token.COMMA);
      }
      properties.add(parseProperty());
    }
    consume(Token.RBRACE);
    return new ObjectExpression(properties);
  }
  
  List<Expression> parseArguments() {
    consume(Token.LPAREN);
    List<Expression> list = <Expression>[];
    while (token.type != Token.RPAREN) {
      if (list.length > 0) {
        consume(Token.COMMA);
      }
      list.add(parseAssignment());
    }
    consume(Token.RPAREN);
    return list;
  }
  
  Expression parseMemberExpression(Token newTok) {
    Expression exp = parsePrimary();
    loop:
    while (true) {
      switch (token.type) {
        case Token.DOT:
          next();
          Name name = parseName();
          exp = new MemberExpression(exp, name);
          break;
          
        case Token.LBRACKET:
          next();
          Expression index = parseExpression();
          consume(Token.RBRACKET);
          exp = new IndexExpression(exp, index);
          break;
          
        case Token.LPAREN:
          List<Expression> args = parseArguments();
          if (newTok != null) {
            exp = new NewExpression(exp, args);
            newTok = null;
          } else {
            exp = new CallExpression(exp, args);
          }
          break;
          
        default:
          break loop;
      }
    }
    return exp;
  }
  
  Expression parseNewExpression() {
    assert(token.value == 'new');
    Token newTok = next();
    if (token.value == 'new')  {
      return new NewExpression(parseNewExpression(), <Expression>[]);
    }
    return parseMemberExpression(newTok);
  }
  
  Expression parseLeftHandSide() {
    if (token.value == 'new') {
      return parseNewExpression();
    } else {
      return parseMemberExpression(null);
    }
  }
  
  Expression parsePostfix() {
    Expression exp = parseLeftHandSide();
    if (token.type == Token.UPDATE && !token.afterLinebreak) {
      Token operator = next();
      exp = new UpdateExpression.postfix(operator.value, exp);
    }
    return exp;
  }
  
  Expression parseUnary() {
    switch (token.type) {
      case Token.UNARY:
        Token operator = next();
        return new UnaryExpression(operator.value, parsePostfix());
        
      case Token.UPDATE:
        Token operator = next();
        return new UpdateExpression.prefix(operator.value, parsePostfix());
        
      case Token.NAME:
        if (token.value == 'delete' || token.value == 'void' || token.value == 'typeof') {
          Token operator = next();
          return new UnaryExpression(operator.value, parsePostfix());
        }
        break;
    }
    return parsePostfix();
  }
  
  Expression parseBinary(int minPrecedence) {
    Expression exp = parseUnary();
    while (token.binaryPrecedence >= minPrecedence) {
      Token operator = next();
      Expression right = parseBinary(operator.binaryPrecedence + 1);
      exp = new BinaryExpression(exp, operator.value, right);
    }
    return exp;
  }
  
  Expression parseConditional() {
    Expression exp = parseBinary(Precedence.EXPRESSION);
    if (token.type == Token.QUESTION) {
      Expression thenExp = parseAssignment();
      consume(Token.COLON);
      Expression elseExp = parseAssignment();
      exp = new ConditionalExpression(exp, thenExp, elseExp);
    }
    return exp;
  }
  
  Expression parseAssignment() {
    Expression exp = parseConditional();
    if (token.type == Token.ASSIGN) {
      Token operator = next();
      Expression right = parseAssignment();
      exp = new AssignmentExpression(exp, operator.value, right);
    }
    return exp;
  }
  
  Expression parseExpression() {
    Expression exp = parseAssignment();
    if (token.type == Token.COMMA) {
      List<Expression> expressions = <Expression>[exp];
      while (token.type == Token.COMMA) {
        next();
        expressions.add(parseAssignment());
      }
      exp = new SequenceExpression(expressions);
    }
    return exp;
  }
  
  ////// STATEMENTS /////
  
  
}


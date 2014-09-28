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
  void consumeSemicolon() {
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
  
  Expression parseBinary(int minPrecedence, bool allowIn) {
    Expression exp = parseUnary();
    while (token.binaryPrecedence >= minPrecedence) {
      if (!allowIn && token.value == 'in') break;
      Token operator = next();
      Expression right = parseBinary(operator.binaryPrecedence + 1, allowIn);
      exp = new BinaryExpression(exp, operator.value, right);
    }
    return exp;
  }
  
  Expression parseConditional(bool allowIn) {
    Expression exp = parseBinary(Precedence.EXPRESSION, allowIn);
    if (token.type == Token.QUESTION) {
      Expression thenExp = parseAssignment();
      consume(Token.COLON);
      Expression elseExp = parseAssignment(allowIn: allowIn);
      exp = new ConditionalExpression(exp, thenExp, elseExp);
    }
    return exp;
  }
  
  Expression parseAssignment({bool allowIn: true}) {
    Expression exp = parseConditional(allowIn);
    if (token.type == Token.ASSIGN) {
      Token operator = next();
      Expression right = parseAssignment(allowIn: allowIn);
      exp = new AssignmentExpression(exp, operator.value, right);
    }
    return exp;
  }
  
  Expression parseExpression({bool allowIn: true}) {
    Expression exp = parseAssignment(allowIn: allowIn);
    if (token.type == Token.COMMA) {
      List<Expression> expressions = <Expression>[exp];
      while (token.type == Token.COMMA) {
        next();
        expressions.add(parseAssignment(allowIn: allowIn));
      }
      exp = new SequenceExpression(expressions);
    }
    return exp;
  }
  
  ////// STATEMENTS /////
  
  void consumeName(String name) {
    if (token.type != Token.NAME || token.value != name) {
      throw "Unexpected token $token, expected $name";
    }
    next();
  }
  
  bool tryName(String name) {
    if (token.type == Token.NAME && token.value == name) {
      next();
      return true;
    } else {
      return false;
    }
  }
  
  BlockStatement parseBlock() {
    consume(Token.LBRACE);
    List<Statement> list = <Statement>[];
    while (token.type != Token.RBRACE) {
      list.add(parseStatement());
    }
    consume(Token.RBRACE);
    return new BlockStatement(list);
  }
  
  VariableDeclaration parseVariableDeclaration() {
    assert(token.value == 'var');
    consume(Token.NAME);
    List<VariableDeclarator> list = <VariableDeclarator>[];
    while (true) {
      Name name = parseName();
      Expression init = null;
      if (token.type == Token.ASSIGN) {
        if (token.value != '=') {
          throw "Compound assignment in initializer"; // TODO: error management
        }
        next();
        init = parseAssignment();
      }
      list.add(new VariableDeclarator(name, init));
      if (token.type != Token.COMMA) break;
      next();
    }
    consumeSemicolon();
    return new VariableDeclaration(list);
  }
  
  Statement parseEmptyStatement() {
    consume(Token.SEMICOLON); 
    return new EmptyStatement();
  }
  
  Statement parseExpressionStatement() {
    return new ExpressionStatement(parseExpression());
  }
  
  Statement parseIf() {
    assert(token.value == 'if');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression condition = parseExpression();
    consume(Token.RPAREN);
    Statement thenBody = parseStatement();
    Statement elseBody;
    if (tryName('else')) {
      elseBody = parseStatement();
    }
    return new IfStatement(condition, thenBody, elseBody);
  }
  
  Statement parseDoWhile() {
    assert(token.value == 'do');
    consume(Token.NAME);
    Statement body = parseStatement();
    consumeName('while');
    consume(Token.LPAREN);
    Expression condition = parseExpression();
    consume(Token.RPAREN);
    return new DoWhileStatement(body, condition);
  }
  
  Statement parseWhile() {
    assert(token.value == 'while');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression condition = parseExpression();
    consume(Token.RPAREN);
    Statement body = parseStatement();
    return new WhileStatement(condition, body);
  }
  
  Statement parseFor() {
    assert(token.value == 'for');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression exp1;
    if (token.type != Token.SEMICOLON) {
      exp1 = parseExpression(allowIn: false);
    }
    if (exp1 != null && tryName('in')) {
      Expression exp2 = parseExpression();
      consume(Token.RPAREN);
      Statement body = parseStatement();
      return new ForInStatement(exp1, exp2, body);
    } else {
      consume(Token.SEMICOLON);
      Expression exp2, exp3;
      if (token.type != Token.SEMICOLON) {
        exp2 = parseExpression();
      }
      consume(Token.SEMICOLON);
      if (token.type != Token.RPAREN) {
        exp3 = parseExpression();
      }
      consume(Token.RPAREN);
      Statement body = parseStatement();
      return new ForStatement(exp1, exp2, exp3, body);
    }
  }
  
  Statement parseContinue() {
    assert(token.value == 'continue');
    consume(Token.NAME);
    Name name;
    if (token.type == Token.NAME && !token.afterLinebreak) {
      name = parseName();
    }
    consumeSemicolon();
    return new ContinueStatement(name);
  }
  
  Statement parseBreak() {
    assert(token.value == 'break');
    consume(Token.NAME);
    Name name;
    if (token.type == Token.NAME && !token.afterLinebreak) {
      name = parseName();
    }
    consumeSemicolon();
    return new BreakStatement(name);
  }
  
  Statement parseReturn() {
    assert(token.value == 'return');
    consume(Token.NAME);
    Expression exp;
    if (token.type != Token.SEMICOLON && !token.afterLinebreak) {
      exp = parseExpression();
    }
    consumeSemicolon();
    return new ReturnStatement(exp);
  }
  
  Statement parseWith() {
    assert(token.value == 'with');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression exp = parseExpression();
    consume(Token.RPAREN);
    Statement body = parseStatement();
    return new WithStatement(exp, body);
  }
  
  Statement parseSwitch() {
    assert(token.value == 'switch');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression argument = parseExpression();
    consume(Token.RPAREN);
    consume(Token.LBRACE);
    List<SwitchCase> cases = <SwitchCase>[];
    cases.add(parseSwitchCaseHead());
    while (token.type != Token.RBRACE) {
      if (tryName('case') || tryName('default')) {
        cases.add(parseSwitchCaseHead());
      } else {
        cases.last.body.add(parseStatement());
      }
    }
    consume(Token.RBRACE);
    return new SwitchStatement(argument, cases);
  }
  
  /// Parses a single 'case E:' or 'default:' without the following statements
  SwitchCase parseSwitchCaseHead() {
    Token tok = requireNext(Token.NAME);
    if (tok.value == 'case') {
      consume(Token.COLON);
      return new SwitchCase(parseExpression(), <Statement>[]);
    } else if (tok.value == 'default') {
      consume(Token.COLON);
      return new SwitchCase(null, <Statement>[]);
    } else {
      throw "Unexpected token $tok"; // TODO: error management
    }
  }
  
  Statement parseLabeledStatement() {
    Name name = parseName();
    consume(Token.COLON);
    Statement body = parseStatement();
    return new LabeledStatement(name, body);
  }
  
  Statement parseThrow() {
    assert(token.value == 'throw');
    consume(Token.NAME);
    Expression exp = parseExpression();
    consumeSemicolon();
    return new ThrowStatement(exp);
  }

  Statement parseTry() {
    assert(token.value == 'try');
    consume(Token.NAME);
    BlockStatement body = parseBlock();
    CatchClause handler;
    BlockStatement finalizer;
    if (tryName('catch')) {
      consume(Token.LPAREN);
      Name name = parseName();
      consume(Token.RPAREN);
      BlockStatement catchBody = parseBlock();
      handler = new CatchClause(name, catchBody);
    }
    if (tryName('finally')) {
      finalizer = parseBlock();
    }
    return new TryStatement(body, handler, finalizer);
  }
  
  Statement parseDebuggerStatement() {
    assert(token.value == 'debugger');
    consume(Token.NAME);
    consumeSemicolon();
    return new DebuggerStatement();
  }
  
  Statement parseStatement() {
    if (token.type == Token.LBRACE)
      return parseBlock();
    if (token.type == Token.SEMICOLON)
      return parseEmptyStatement();
    if (token.type != Token.NAME)
      return parseExpressionStatement();
    switch (token.value) {
      case 'var': return parseVariableDeclaration();
      case 'if': return parseIf();
      case 'do': return parseDoWhile();
      case 'while': return parseWhile();
      case 'for': return parseFor();
      case 'continue': return parseContinue();
      case 'break': return parseBreak();
      case 'return': return parseReturn();
      case 'with': return parseWith();
      case 'switch': return parseSwitch();
      case 'throw': return parseThrow();
      case 'try': return parseTry();
      case 'debugger': return parseDebuggerStatement();
      // TODO: function declaration
      default:
        Token maybeLabel = next();
        
    }
  }
  
  
}


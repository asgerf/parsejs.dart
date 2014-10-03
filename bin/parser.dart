library parser;

import 'lexer.dart';
import 'ast.dart';

class ParseError {
  String msg;
  int position;
  
  ParseError(this.msg, this.position);
  
  String toString() => msg;
}

class Parser {
  
  Parser(this.lexer) {
    token = lexer.scan();
  }
  
  Lexer lexer;
  Token token;
  
  Token pushbackBuffer;
  
  void pushback(Token tok) {
    pushbackBuffer = token;
    token = tok;
  }
  
  dynamic fail({Token tok, String expected, String message}) {
    if (tok == null)
      tok = token;
    if (message == null) {
      if (expected != null)
        message = "Expected $expected but found $tok";
      else
        message = "Unexpected token $tok";
    }
    throw new ParseError(message, tok.offset);
  }
  
  /// Returns the current token, and scans the next one. 
  Token next() {
    Token t = token;
    if (pushbackBuffer != null) {
      token = pushbackBuffer;
      pushbackBuffer = null;
    } else {
      token = lexer.scan();
    }
    return t;
  }
  
  /// Consume a semicolon, or if a line-break was here, just pretend there was one here.
  void consumeSemicolon() {
    if (token.type == Token.SEMICOLON) {
      next();
      return;
    }
    if (token.afterLinebreak || token.type == Token.RBRACE || token.type == Token.EOF) {
      return;
    }
    fail(expected: 'semicolon');
  }
  
  void consume(int type) {
    if (token.type != type) {
      fail(expected: Token.typeToString(type));
    }
    next();
  }
  Token requireNext(int type) {
    if (token.type != type) {
      fail(expected: Token.typeToString(type));
    }
    return next();
  }
  
  void consumeName(String name) {
    if (token.type != Token.NAME || token.value != name) {
      fail(expected: name);
    }
    next();
  }
  
  bool peekName(String name) {
    return token.type == Token.NAME && token.value == name;
  }
  
  bool tryName(String name) {
    if (token.type == Token.NAME && token.value == name) {
      next();
      return true;
    } else {
      return false;
    }
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
    return parseBlock();
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
        switch (token.value) {
          case 'this': 
            next();
            return new ThisExpression();
          case 'true': 
            next();
            return new LiteralExpression(true, 'true');
          case 'false': 
            next();
            return new LiteralExpression(false, 'false');
          case 'null': 
            next();
            return new LiteralExpression(null, 'null');
          case 'function': 
            return parseFunctionExpression();
        }
        Token name = next();
        return new NameExpression(new Name(name.value));
        
      case Token.NUMBER:
        Token tok = next();
        return new LiteralExpression(num.parse(tok.value), tok.value);
        
      case Token.STRING:
        Token tok = next();
        return new LiteralExpression(tok.value, tok.raw);
        
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
        return fail();
        
      default:
        return fail();
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
  
  Node makePropertyName(Token tok) {
    switch (tok.type) {
      case Token.NAME: return new Name(tok.value);
      case Token.STRING: return new LiteralExpression(tok.value)..raw = tok.raw;
      case Token.NUMBER: return new LiteralExpression(double.parse(tok.value))..raw = tok.value;
      default: return fail(tok: tok, expected: 'property name');
    }
  }
  
  Property parseProperty() {
    Token nameTok = next();
    if (token.type == Token.COLON) {
      next(); // skip colon
      Node name = makePropertyName(nameTok);
      Expression value = parseAssignment();
      return new Property(name, value);
    }
    if (nameTok.type == Token.NAME && (nameTok.value == 'get' || nameTok.value == 'set')) {
      String kind = nameTok.value == 'get' ? 'get' : 'set'; // internalize the string
      nameTok = next();
      Node name = makePropertyName(nameTok);
      List<Name> params = parseParameters();
      BlockStatement body = parseFunctionBody();
      Expression value = new FunctionExpression(null, params, body);
      return new Property(name, value, kind); // (internalize the get/set strings)
    }
    return fail(expected: 'property', tok : nameTok);
  }
  
  Expression parseObjectLiteral() {
    consume(Token.LBRACE);
    List<Property> properties = <Property>[];
    while (token.type != Token.RBRACE) {
      if (properties.length > 0) {
        consume(Token.COMMA);
      }
      if (token.type == Token.RBRACE) break; // may end with extra comma
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
    if (newTok != null) {
      exp = new NewExpression(exp, <Expression>[]);
    }
    return exp;
  }
  
  Expression parseNewExpression() {
    assert(token.value == 'new');
    Token newTok = next();
    if (peekName('new'))  {
      return new NewExpression(parseNewExpression(), <Expression>[]);
    }
    return parseMemberExpression(newTok);
  }
  
  Expression parseLeftHandSide() {
    if (peekName('new')) {
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
        return new UnaryExpression(operator.value, parseUnary());
        
      case Token.UPDATE:
        Token operator = next();
        return new UpdateExpression.prefix(operator.value, parseUnary());
        
      case Token.NAME:
        if (token.value == 'delete' || token.value == 'void' || token.value == 'typeof') {
          Token operator = next();
          return new UnaryExpression(operator.value, parseUnary());
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
      next();
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
  
  BlockStatement parseBlock() {
    consume(Token.LBRACE);
    List<Statement> list = <Statement>[];
    while (token.type != Token.RBRACE) {
      list.add(parseStatement());
    }
    consume(Token.RBRACE);
    return new BlockStatement(list);
  }
  
  VariableDeclaration parseVariableDeclarationList({bool allowIn: true}) {
    assert(token.value == 'var');
    consume(Token.NAME);
    List<VariableDeclarator> list = <VariableDeclarator>[];
    while (true) {
      Name name = parseName();
      Expression init = null;
      if (token.type == Token.ASSIGN) {
        if (token.value != '=') {
          fail(message: 'Compound assignment in initializer');
        }
        next();
        init = parseAssignment(allowIn: allowIn);
      }
      list.add(new VariableDeclarator(name, init));
      if (token.type != Token.COMMA) break;
      next();
    }
    return new VariableDeclaration(list);
  }
  
  VariableDeclaration parseVariableDeclarationStatement() {
    VariableDeclaration decl = parseVariableDeclarationList();
    consumeSemicolon();
    return decl;
  }
  
  Statement parseEmptyStatement() {
    consume(Token.SEMICOLON); 
    return new EmptyStatement();
  }
  
  Statement parseExpressionStatement() {
    Expression exp = parseExpression();
    consumeSemicolon();
    return new ExpressionStatement(exp);
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
    consumeSemicolon();
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
    Node exp1;
    if (peekName('var')) {
      exp1 = parseVariableDeclarationList(allowIn: false);
    } else if (token.type != Token.SEMICOLON) {
      exp1 = parseExpression(allowIn: false);
    }
    if (exp1 != null && tryName('in')) {
      if (exp1 is VariableDeclaration && (exp1 as VariableDeclaration).declarations.length > 1) {
        fail(message: 'Multiple vars declared in for-in loop');
      }
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
    if (token.type != Token.SEMICOLON && token.type != Token.RBRACE && token.type != Token.EOF && !token.afterLinebreak) {
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
      if (peekName('case') || peekName('default')) {
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
      Expression value = parseExpression();
      consume(Token.COLON);
      return new SwitchCase(value, <Statement>[]);
    } else if (tok.value == 'default') {
      consume(Token.COLON);
      return new SwitchCase(null, <Statement>[]);
    } else {
      return fail();
    }
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
  
  Statement parseFunctionDeclaration() {
    assert(token.value == 'function');
    FunctionExpression func = parseFunctionExpression();
    if (func.name == null) {
      fail(message: 'Function declaration must have a name');
    }
    return new FunctionDeclaration(func);
  }
  
  Statement parseStatement() {
    if (token.type == Token.LBRACE)
      return parseBlock();
    if (token.type == Token.SEMICOLON)
      return parseEmptyStatement();
    if (token.type != Token.NAME)
      return parseExpressionStatement();
    switch (token.value) {
      case 'var': return parseVariableDeclarationStatement();
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
      case 'function': return parseFunctionDeclaration();
      default:
        Token nameTok = next();
        if (token.type == Token.COLON) {
          next();
          Statement body = parseStatement();
          return new LabeledStatement(new Name(nameTok.value), body);
        } else {
          // revert lookahead and parse as expression statement
          pushback(nameTok);
          return parseExpressionStatement();
        }
    }
  }
  
  Program parseProgram() {
    List<Statement> statements = <Statement>[];
    while (token.type != Token.EOF) {
      statements.add(parseStatement());
    }
    return new Program(statements);
  }
  
}


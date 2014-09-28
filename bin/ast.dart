

// AST structure mostly designed after the Mozilla Parser API:
//  https://developer.mozilla.org/en-US/docs/Mozilla/Projects/SpiderMonkey/Parser_API

abstract class Node {
  Node parent;
  
  /// Source-code offsets.
  int start, end;

  /// Line number corresponding to [start] offset.
  /// Technically redundant information given that [start] is here, but [line] is
  /// useful for debugging and quick printouts, so it is included in Node.
  int line;

  /// Retrieves the filename from the enclosing [Program]. Returns null if the node is orphaned.
  String get filename {
    Program program = enclosingProgram;
    if (program != null) return program.filename;
    return null;
  }
  
  /// A string with filename and line number.
  String get location => "$filename:$line";
  
  /// Returns the [Program] node enclosing this node, possibly the node itself, or null if not enclosed in any program.
  Program get enclosingProgram {
    Node node = this;
    while (node != null) {
      if (node is Program) return node;
      node = node.parent;
    }
    return null;
  }
  
  /// Returns the [FunctionExpression] enclosing this node, possibly the node itself, or null if not enclosed in any function.
  /// NOTE: calling this on [FunctionDeclaration] and [FunctionExpression] yields different results.
  FunctionExpression get enclosingFunction {
    Node node = this;
    while (node != null) {
      if (node is FunctionExpression) return node;
      node = node.parent;
    }
    return null;
  }
  
  /// Visits the immediate children of this node.
  void forEach(callback(Node node));
}

class Program extends Node {
  /// Indicates where the program was parsed from.
  /// In principle, this can be anything, it is just a string passed to the parser for convenience.
  String filename;

  List<Statement> body;

  Program(this.body);
  
  void forEach(callback) => body.forEach(callback);
}

/// An identifier. The class is called [Name] simply because it is shorter than "Identifier".
class Name extends Node {
  String value;

  Name(this.value);
  
  void forEach(callback) {}
}


///// STATEMENTS /////

abstract class Statement extends Node {}

class EmptyStatement extends Statement {
  void forEach(callback) {}
}

class BlockStatement extends Statement {
  List<Statement> body;

  BlockStatement(this.body);
  
  void forEach(callback) => body.forEach(callback);
}

class ExpressionStatement extends Statement {
  Expression expression;

  ExpressionStatement(this.expression);
  
  forEach(callback) => callback(expression);
}

class IfStatement extends Statement {
  Expression condition;
  Statement then;
  Statement otherwise; // May be null.

  IfStatement(this.condition, this.then, this.otherwise);
  
  forEach(callback) {
    callback(condition);
    callback(then);
    if (otherwise != null) callback(otherwise);
  }
}

class LabeledStatement extends Statement {
  Name label;
  Statement body;

  LabeledStatement(this.label, this.body);
  
  forEach(callback) {
    callback(label);
    callback(body);
  }
}

class BreakStatement extends Statement {
  Name label; // May be null.

  BreakStatement(this.label);
  
  forEach(callback) {
    if (label != null) callback(label);
  }
}

class ContinueStatement extends Statement {
  Name label; // May be null.

  ContinueStatement(this.label);
  
  forEach(callback) {
    if (label != null) callback(label);
  }
}

class WithStatement extends Statement {
  Expression object;
  Statement body;

  WithStatement(this.object, this.body);
  
  forEach(callback) {
    callback(object);
    callback(body);
  }
}

class SwitchStatement extends Statement {
  Expression argument;
  List<SwitchCase> cases;

  SwitchStatement(this.argument, this.cases);
  
  forEach(callback) {
    callback(argument);
    cases.forEach(callback);
  }
}

class SwitchCase extends Node {
  Expression expression; // May be null (for default clause)
  List<Statement> body;

  SwitchCase(this.expression, this.body);
  SwitchCase.defaultCase(this.body);

  bool get isDefault => expression == null;
  
  forEach(callback) {
    if (expression != null) callback(expression);
    body.forEach(callback);
  }
}

class ReturnStatement extends Statement {
  Expression argument;

  ReturnStatement(this.argument);
  
  forEach(callback) => callback(argument);
}

class ThrowStatement extends Statement {
  Expression argument;

  ThrowStatement(this.argument);

  forEach(callback) => callback(argument);
}

class TryStatement extends Statement {
  BlockStatement block;
  CatchClause handler; // May be null
  BlockStatement finalizers; // May be null (but not if handler is null)

  TryStatement(this.block, this.handler, this.finalizers);
  
  forEach(callback) {
    callback(block);
    if (handler != null) callback(handler);
    if (finalizers != null) callback(finalizers);
  }
}

class CatchClause extends Node {
  Name param;
  BlockStatement body;
  
  forEach(callback) {
    callback(param);
    callback(body);
  }
}

class WhileStatement extends Statement {
  Expression condition;
  Statement body;

  WhileStatement(this.condition, this.body);
  
  forEach(callback) {
    callback(condition);
    callback(body);
  }
}

class DoWhileStatement extends Statement {
  Statement body;
  Expression condition;

  DoWhileStatement(this.body, this.condition);
  
  forEach(callback) {
    callback(body);
    callback(condition);
  }
}

class ForStatement extends Statement {
  Node init; // May be VariableDeclaration, Expression, or null.
  Expression condition; // May be null.
  Expression update; // May be null.
  Statement body;

  ForStatement(this.init, this.condition, this.update, this.body);
  
  forEach(callback) {
    if (init != null) callback(init);
    if (condition != null) callback(condition);
    if (update != null) callback(update);
    callback(body);
  }
}

class ForInStatement extends Statement {
  Node left; // May be VariableDeclaration or Expression.
  Expression right;
  Statement body;

  ForInStatement(this.left, this.right, this.body);
  
  forEach(callback) {
    callback(left);
    callback(right);
    callback(body);
  }
}

class FunctionDeclaration extends Statement {
  FunctionExpression function;

  FunctionDeclaration(this.function);
  
  forEach(callback) => callback(function);
}

class VariableDeclaration extends Statement {
  List<VariableDeclarator> declarations;

  VariableDeclaration(this.declarations);
  
  forEach(callback) => declarations.forEach(callback);
}

class VariableDeclarator extends Node {
  Name name;
  Expression init; // May be null.

  VariableDeclarator(this.name, this.init);
  
  forEach(callback) {
    callback(name);
    callback(init);
  }
}

class DebuggerStatement extends Statement {
  forEach(callback) {}
}

///////

abstract class Expression extends Node {}

class ThisExpression extends Expression {
  forEach(callback) {}
}

class ArrayExpression extends Expression {
  List<Expression> expressions; // May CONTAIN nulls for omitted elements: e.g. [1,2,,,]

  ArrayExpression(this.expressions);

  forEach(callback) => expressions.forEach(callback);
}

class ObjectExpression extends Expression {
  List<Property> properties;

  ObjectExpression(this.properties);
  
  forEach(callback) => properties.forEach(callback);
}

class Property extends Node {
  Name key;           // Literals will be converted to their equivalent name string
  Expression value;   // Will be FunctionExpression with no name for getters and setters
  String kind;        // May be: init, get, set

  Property(this.key, this.value, [this.kind = 'init']);
  Property.getter(this.key, FunctionExpression this.value) : kind = 'get';
  Property.setter(this.key, FunctionExpression this.value) : kind = 'set';
  
  bool get isInit => kind == 'init';
  bool get isGetter => kind == 'get';
  bool get isSetter => kind == 'set';
  
  /// Returns the value as a FunctionExpression. Useful for getters/setters.
  FunctionExpression get function => value as FunctionExpression;

  forEach(callback) {
    callback(key);
    callback(value);
  }
}

class FunctionExpression extends Expression {
  Name name;
  List<Name> params;
  Statement body;

  FunctionExpression(this.name, this.params, this.body);
  
  bool get isExpression => parent is! FunctionDeclaration;

  forEach(callback) {
    if (name != null) callback(name);
    params.forEach(callback);
    callback(body);
  }
}

class SequenceExpression extends Expression {
  List<Expression> expressions;

  SequenceExpression(this.expressions);
  
  forEach(callback) => expressions.forEach(callback);
}

class UnaryExpression extends Expression {
  String operator; // May be: +, -, !, ~, typeof, void, delete
  Expression argument;

  UnaryExpression(this.operator, this.argument);
  
  forEach(callback) => callback(argument);
}

class BinaryExpression extends Expression {
  Expression left;
  String operator; // May be: ==, !=, ===, !==, <, <=, >, >=, <<, >>, >>>, +, -, *, /, %, |, ^, &, in, instanceof
  Expression right;

  BinaryExpression(this.left, this.operator, this.right);
  
  forEach(callback) {
    callback(left);
    callback(right);
  }
}

class AssignmentExpression extends Expression {
  Expression left;
  String operator; // May be: =, +=, -=, *=, /=, %=, <<=, >>=, >>>=, |=, ^=, &=
  Expression right;

  AssignmentExpression(this.left, this.operator, this.right);

  bool get isCompound => operator.length > 1;
  
  forEach(callback) {
    callback(left);
    callback(right);
  }
}

class UpdateExpression extends Expression {
  String operator; // May be: ++, --
  Expression argument;
  bool isPrefix;

  UpdateExpression(this.operator, this.argument, this.isPrefix);
  UpdateExpression.prefix(this.operator, this.argument) : isPrefix = true;
  UpdateExpression.postfix(this.operator, this.argument) : isPrefix = false;
  
  forEach(callback) => callback(argument);
}

class LogicalExpression extends Expression {
  Expression left;
  String operator; // May be: &&, ||
  Expression right;

  LogicalExpression(this.left, this.operator, this.right);
  
  forEach(callback) {
    callback(left);
    callback(right);
  }
}

class ConditionalExpression extends Expression {
  Expression condition;
  Expression then;
  Expression otherwise;

  ConditionalExpression(this.condition, this.then, this.otherwise);
  
  forEach(callback) {
    callback(condition);
    callback(then);
    callback(otherwise);
  }
}

class NewExpression extends Expression {
  Expression callee;
  List<Expression> arguments;

  NewExpression(this.callee, this.arguments);
  
  forEach(callback) {
    callback(callee);
    arguments.forEach(callback);
  }
}

class CallExpression extends Expression {
  Expression callee;
  List<Expression> arguments;

  CallExpression(this.callee, this.arguments);
  
  forEach(callback) {
    callback(callee);
    arguments.forEach(callback);
  }
}

class MemberExpression extends Expression {
  Expression object;
  Name property;

  MemberExpression(this.object, this.property);
  
  forEach(callback) {
    callback(object);
    callback(property);
  }
}

class IndexExpression extends Expression {
  Expression object;
  Expression property;

  IndexExpression(this.object, this.property);
  
  forEach(callback) {
    callback(object);
    callback(property);
  }
}

class NameExpression extends Expression {
  Name name;

  NameExpression(this.name);
  
  forEach(callback) => callback(name);
}

class LiteralExpression extends Expression {
  dynamic value;
  
  LiteralExpression(this.value);
  
  bool get isString => value is String;
  bool get isNumber => value is num;
  bool get isBool => value is bool;
  bool get isNull => value == null;
  
  String get stringValue => value as String;
  num get numberValue => value as num;
  bool get boolValue => value as bool;
  
  /// Converts the value to a string
  String get toName => value.toString();
  
  forEach(callback) {}
}

class RegexpExpression extends Expression {
  String regexp; // Includes slashes and everything (TODO: separate into regexp and flags)
  
  RegexpExpression(this.regexp);
  
  forEach(callback) {}
}



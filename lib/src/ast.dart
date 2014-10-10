library ast;

part 'ast_visitor.dart';

// AST structure mostly designed after the Mozilla Parser API:
//  https://developer.mozilla.org/en-US/docs/Mozilla/Projects/SpiderMonkey/Parser_API

abstract class Node {
  Node parent;
  
  /// Source-code offsets.
  int start, end;

  /// 1-based line number. 
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
  
  /// Calls the relevant `visit` method on the visitor.
  dynamic visitBy(Visitor visitor);
}

class Program extends Node {
  /// Indicates where the program was parsed from.
  /// In principle, this can be anything, it is just a string passed to the parser for convenience.
  String filename;

  List<Statement> body;

  Program(this.body);
  
  void forEach(callback) => body.forEach(callback);
  
  String toString() => 'Program';
  
  visitBy(Visitor v) => v.visitProgram(this);
}

/// An identifier. The class is called [Name] simply because it is shorter than "Identifier".
class Name extends Node {
  String value;

  Name(this.value);
  
  void forEach(callback) {}
  
  String toString() => '$value';
  
  visitBy(Visitor v) => v.visitName(this);
}


///// STATEMENTS /////

abstract class Statement extends Node {}

class EmptyStatement extends Statement {
  void forEach(callback) {}
  
  String toString() => 'EmptyStatement';
  
  visitBy(Visitor v) => v.visitEmptyStatement(this);
}

class BlockStatement extends Statement {
  List<Statement> body;

  BlockStatement(this.body);
  
  void forEach(callback) => body.forEach(callback);
  
  String toString() => 'BlockStatement';
  
  visitBy(Visitor v) => v.visitBlock(this);
}

class ExpressionStatement extends Statement {
  Expression expression;

  ExpressionStatement(this.expression);
  
  forEach(callback) => callback(expression);
  
  String toString() => 'ExpressionStatement';
  
  visitBy(Visitor v) => v.visitExpressionStatement(this);
}

class IfStatement extends Statement {
  Expression condition;
  Statement then;
  Statement otherwise; // May be null.

  IfStatement(this.condition, this.then, [this.otherwise]);
  
  forEach(callback) {
    callback(condition);
    callback(then);
    if (otherwise != null) callback(otherwise);
  }
  
  String toString() => 'IfStatement';
  
  visitBy(Visitor v) => v.visitIf(this);
}

class LabeledStatement extends Statement {
  Name label;
  Statement body;

  LabeledStatement(this.label, this.body);
  
  forEach(callback) {
    callback(label);
    callback(body);
  }
  
  String toString() => 'LabeledStatement';
  
  visitBy(Visitor v) => v.visitLabeledStatement(this);
}

class BreakStatement extends Statement {
  Name label; // May be null.

  BreakStatement(this.label);
  
  forEach(callback) {
    if (label != null) callback(label);
  }
  
  String toString() => 'BreakStatement';
  
  visitBy(Visitor v) => v.visitBreak(this);
}

class ContinueStatement extends Statement {
  Name label; // May be null.

  ContinueStatement(this.label);
  
  forEach(callback) {
    if (label != null) callback(label);
  }
  
  String toString() => 'ContinueStatement';
  
  visitBy(Visitor v) => v.visitContinue(this);
}

class WithStatement extends Statement {
  Expression object;
  Statement body;

  WithStatement(this.object, this.body);
  
  forEach(callback) {
    callback(object);
    callback(body);
  }
  
  String toString() => 'WithStatement';
  
  visitBy(Visitor v) => v.visitWith(this);
}

class SwitchStatement extends Statement {
  Expression argument;
  List<SwitchCase> cases;

  SwitchStatement(this.argument, this.cases);
  
  forEach(callback) {
    callback(argument);
    cases.forEach(callback);
  }
  
  String toString() => 'SwitchStatement';
  
  visitBy(Visitor v) => v.visitSwitch(this);
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
  
  String toString() => 'SwitchCase';
  
  visitBy(Visitor v) => v.visitSwitchCase(this);
}

class ReturnStatement extends Statement {
  Expression argument;

  ReturnStatement(this.argument);
  
  forEach(callback) => argument != null ? callback(argument) : null;
  
  String toString() => 'ReturnStatement';
  
  visitBy(Visitor v) => v.visitReturn(this);
}

class ThrowStatement extends Statement {
  Expression argument;

  ThrowStatement(this.argument);

  forEach(callback) => callback(argument);
  
  String toString() => 'ThrowStatement';
  
  visitBy(Visitor v) => v.visitThrow(this);
}

class TryStatement extends Statement {
  BlockStatement block;
  CatchClause handler; // May be null
  BlockStatement finalizer; // May be null (but not if handler is null)

  TryStatement(this.block, this.handler, this.finalizer);
  
  forEach(callback) {
    callback(block);
    if (handler != null) callback(handler);
    if (finalizer != null) callback(finalizer);
  }
  
  String toString() => 'TryStatement';
  
  visitBy(Visitor v) => v.visitTry(this);
}

class CatchClause extends Node {
  Name param;
  BlockStatement body;
  
  CatchClause(this.param, this.body);
  
  forEach(callback) {
    callback(param);
    callback(body);
  }
  
  String toString() => 'CatchClause';
  
  visitBy(Visitor v) => v.visitCatch(this);
}

class WhileStatement extends Statement {
  Expression condition;
  Statement body;

  WhileStatement(this.condition, this.body);
  
  forEach(callback) {
    callback(condition);
    callback(body);
  }
  
  String toString() => 'WhileStatement';
  
  visitBy(Visitor v) => v.visitWhile(this);
}

class DoWhileStatement extends Statement {
  Statement body;
  Expression condition;

  DoWhileStatement(this.body, this.condition);
  
  forEach(callback) {
    callback(body);
    callback(condition);
  }
  
  String toString() => 'DoWhileStatement';
  
  visitBy(Visitor v) => v.visitDoWhile(this);
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
  
  String toString() => 'ForStatement';
  
  visitBy(Visitor v) => v.visitFor(this);
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
  
  String toString() => 'ForInStatement';
  
  visitBy(Visitor v) => v.visitForIn(this);
}

class FunctionDeclaration extends Statement {
  FunctionExpression function;

  FunctionDeclaration(this.function);
  
  forEach(callback) => callback(function);
  
  String toString() => 'FunctionDeclaration';
  
  visitBy(Visitor v) => v.visitFunctionDeclaration(this);
}

class VariableDeclaration extends Statement {
  List<VariableDeclarator> declarations;

  VariableDeclaration(this.declarations);
  
  forEach(callback) => declarations.forEach(callback);
  
  String toString() => 'VariableDeclaration';
  
  visitBy(Visitor v) => v.visitVariableDeclaration(this);
}

class VariableDeclarator extends Node {
  Name name;
  Expression init; // May be null.

  VariableDeclarator(this.name, this.init);
  
  forEach(callback) {
    callback(name);
    if (init != null) callback(init);
  }
  
  String toString() => 'VariableDeclarator';
  
  visitBy(Visitor v) => v.visitVariableDeclarator(this);
}

class DebuggerStatement extends Statement {
  forEach(callback) {}
  
  String toString() => 'DebuggerStatement';
  
  visitBy(Visitor v) => v.visitDebugger(this);
}

///////

abstract class Expression extends Node {}

class ThisExpression extends Expression {
  forEach(callback) {}
  
  String toString() => 'ThisExpression';
  
  visitBy(Visitor v) => v.visitThis(this);
}

class ArrayExpression extends Expression {
  List<Expression> expressions; // May CONTAIN nulls for omitted elements: e.g. [1,2,,,]

  ArrayExpression(this.expressions);

  forEach(callback) {
    for (Expression exp in expressions) {
      if (exp != null) {
        callback(exp);
      }
    }
  }
  
  String toString() => 'ArrayExpression';
  
  visitBy(Visitor v) => v.visitArray(this);
}

class ObjectExpression extends Expression {
  List<Property> properties;

  ObjectExpression(this.properties);
  
  forEach(callback) => properties.forEach(callback);
  
  String toString() => 'ObjectExpression';
  
  visitBy(Visitor v) => v.visitObject(this);
}

class Property extends Node {
  Node key;           // Literal or Name
  Expression value;   // Will be FunctionExpression with no name for getters and setters
  String kind;        // May be: init, get, set

  Property(this.key, this.value, [this.kind = 'init']);
  Property.getter(this.key, FunctionExpression this.value) : kind = 'get';
  Property.setter(this.key, FunctionExpression this.value) : kind = 'set';
  
  bool get isInit => kind == 'init';
  bool get isGetter => kind == 'get';
  bool get isSetter => kind == 'set';
  
  String get nameString => key is Name ? (key as Name).value : (key as LiteralExpression).value.toString();
  
  /// Returns the value as a FunctionExpression. Useful for getters/setters.
  FunctionExpression get function => value as FunctionExpression;

  forEach(callback) {
    callback(key);
    callback(value);
  }
  
  String toString() => 'Property';
  
  visitBy(Visitor v) => v.visitProperty(this);
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
  
  String toString() => 'FunctionExpression';
  
  visitBy(Visitor v) => v.visitFunctionExpression(this);
}

class SequenceExpression extends Expression {
  List<Expression> expressions;

  SequenceExpression(this.expressions);
  
  forEach(callback) => expressions.forEach(callback);
  
  String toString() => 'SequenceExpression';
  
  visitBy(Visitor v) => v.visitSequence(this);
}

class UnaryExpression extends Expression {
  String operator; // May be: +, -, !, ~, typeof, void, delete
  Expression argument;

  UnaryExpression(this.operator, this.argument);
  
  forEach(callback) => callback(argument);
  
  String toString() => 'UnaryExpression';
  
  visitBy(Visitor v) => v.visitUnary(this);
}

class BinaryExpression extends Expression {
  Expression left;
  String operator; // May be: ==, !=, ===, !==, <, <=, >, >=, <<, >>, >>>, +, -, *, /, %, |, ^, &, &&, ||, in, instanceof
  Expression right;

  BinaryExpression(this.left, this.operator, this.right);
  
  forEach(callback) {
    callback(left);
    callback(right);
  }
  
  String toString() => 'BinaryExpression';
  
  visitBy(Visitor v) => v.visitBinary(this);
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
  
  String toString() => 'AssignmentExpression';
  
  visitBy(Visitor v) => v.visitAssignment(this);
}

class UpdateExpression extends Expression {
  String operator; // May be: ++, --
  Expression argument;
  bool isPrefix;

  UpdateExpression(this.operator, this.argument, this.isPrefix);
  UpdateExpression.prefix(this.operator, this.argument) : isPrefix = true;
  UpdateExpression.postfix(this.operator, this.argument) : isPrefix = false;
  
  forEach(callback) => callback(argument);
  
  String toString() => 'UpdateExpression';
  
  visitBy(Visitor v) => v.visitUpdateExpression(this);
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
  
  String toString() => 'ConditionalExpression';
  
  visitBy(Visitor v) => v.visitConditional(this);
}

class NewExpression extends Expression {
  Expression callee;
  List<Expression> arguments;

  NewExpression(this.callee, this.arguments);
  
  forEach(callback) {
    callback(callee);
    arguments.forEach(callback);
  }
  
  String toString() => 'NewExpression';
  
  visitBy(Visitor v) => v.visitNew(this);
}

class CallExpression extends Expression {
  Expression callee;
  List<Expression> arguments;

  CallExpression(this.callee, this.arguments);
  
  forEach(callback) {
    callback(callee);
    arguments.forEach(callback);
  }
  
  String toString() => 'CallExpression';
  
  visitBy(Visitor v) => v.visitCall(this);
}

class MemberExpression extends Expression {
  Expression object;
  Name property;

  MemberExpression(this.object, this.property);
  
  forEach(callback) {
    callback(object);
    callback(property);
  }
  
  String toString() => 'MemberExpression';
  
  visitBy(Visitor v) => v.visitMember(this);
}

class IndexExpression extends Expression {
  Expression object;
  Expression property;

  IndexExpression(this.object, this.property);
  
  forEach(callback) {
    callback(object);
    callback(property);
  }
  
  String toString() => 'IndexExpression';
  
  visitBy(Visitor v) => v.visitIndex(this);
}

/// A [Name] that is used as an expression. 
/// Note that "undefined", "NaN", and "Infinity" are name expressions, and not literals and one might expect.
class NameExpression extends Expression {
  Name name;

  NameExpression(this.name);
  
  forEach(callback) => callback(name);
  
  String toString() => 'NameExpression';
  
  visitBy(Visitor v) => v.visitNameExpression(this);
}

class LiteralExpression extends Expression {
  dynamic value;
  String raw;
  
  LiteralExpression(this.value, [this.raw]);
  
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
  
  String toString() => 'LiteralExpression';
  
  visitBy(Visitor v) => v.visitLiteral(this);
}

class RegexpExpression extends Expression {
  String regexp; // Includes slashes and flags and everything (TODO: separate into regexp and flags)
  
  RegexpExpression(this.regexp);
  
  forEach(callback) {}
  
  String toString() => 'RegexpExpression';
  
  visitBy(Visitor v) => v.visitRegexp(this);
}


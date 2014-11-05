part of ast;

/// Visitor interface for AST nodes. See [BaseVisitor] and [RecursiveVisitor].
abstract class Visitor<T> {
  T visit(Node node) => node.visitBy(this);
  
  T visitPrograms(Programs node);
  T visitProgram(Program node);
  T visitFunctionNode(FunctionNode node);
  T visitName(Name node);
  
  T visitEmptyStatement(EmptyStatement node);
  T visitBlock(BlockStatement node);
  T visitExpressionStatement(ExpressionStatement node);
  T visitIf(IfStatement node);
  T visitLabeledStatement(LabeledStatement node);
  T visitBreak(BreakStatement node);
  T visitContinue(ContinueStatement node);
  T visitWith(WithStatement node);
  T visitSwitch(SwitchStatement node);
  T visitSwitchCase(SwitchCase node);
  T visitReturn(ReturnStatement node);
  T visitThrow(ThrowStatement node);
  T visitTry(TryStatement node);
  T visitCatchClause(CatchClause node);
  T visitWhile(WhileStatement node);
  T visitDoWhile(DoWhileStatement node);
  T visitFor(ForStatement node);
  T visitForIn(ForInStatement node);
  T visitFunctionDeclaration(FunctionDeclaration node);
  T visitVariableDeclaration(VariableDeclaration node);
  T visitVariableDeclarator(VariableDeclarator node);
  T visitDebugger(DebuggerStatement node);
  
  T visitThis(ThisExpression node);
  T visitArray(ArrayExpression node);
  T visitObject(ObjectExpression node);
  T visitProperty(Property node);
  T visitFunctionExpression(FunctionExpression node);
  T visitSequence(SequenceExpression node);
  T visitUnary(UnaryExpression node);
  T visitBinary(BinaryExpression node);
  T visitAssignment(AssignmentExpression node);
  T visitUpdateExpression(UpdateExpression node);
  T visitConditional(ConditionalExpression node);
  T visitCall(CallExpression node);
  T visitMember(MemberExpression node);
  T visitIndex(IndexExpression node);
  T visitNameExpression(NameExpression node);
  T visitLiteral(LiteralExpression node);
  T visitRegexp(RegexpExpression node);
}

/// Implementation of [Visitor] which redirects each `visit` method to a method [defaultNode].
/// 
/// This is convenient when only a couple of `visit` methods are needed 
/// and a default action can be taken for all other nodes.
class BaseVisitor<T> implements Visitor<T> {
  T defaultNode(Node node) => null;
  
  T visit(Node node) => node.visitBy(this);

  T visitPrograms(Programs node) => defaultNode(node);
  T visitProgram(Program node) => defaultNode(node);
  T visitFunctionNode(FunctionNode node) => defaultNode(node);
  T visitName(Name node) => defaultNode(node);
  
  T visitEmptyStatement(EmptyStatement node) => defaultNode(node);
  T visitBlock(BlockStatement node) => defaultNode(node);
  T visitExpressionStatement(ExpressionStatement node) => defaultNode(node);
  T visitIf(IfStatement node) => defaultNode(node);
  T visitLabeledStatement(LabeledStatement node) => defaultNode(node);
  T visitBreak(BreakStatement node) => defaultNode(node);
  T visitContinue(ContinueStatement node) => defaultNode(node);
  T visitWith(WithStatement node) => defaultNode(node);
  T visitSwitch(SwitchStatement node) => defaultNode(node);
  T visitSwitchCase(SwitchCase node) => defaultNode(node);
  T visitReturn(ReturnStatement node) => defaultNode(node);
  T visitThrow(ThrowStatement node) => defaultNode(node);
  T visitTry(TryStatement node) => defaultNode(node);
  T visitCatchClause(CatchClause node) => defaultNode(node);
  T visitWhile(WhileStatement node) => defaultNode(node);
  T visitDoWhile(DoWhileStatement node) => defaultNode(node);
  T visitFor(ForStatement node) => defaultNode(node);
  T visitForIn(ForInStatement node) => defaultNode(node);
  T visitFunctionDeclaration(FunctionDeclaration node) => defaultNode(node);
  T visitVariableDeclaration(VariableDeclaration node) => defaultNode(node);
  T visitVariableDeclarator(VariableDeclarator node) => defaultNode(node);
  T visitDebugger(DebuggerStatement node) => defaultNode(node);
  
  T visitThis(ThisExpression node) => defaultNode(node);
  T visitArray(ArrayExpression node) => defaultNode(node);
  T visitObject(ObjectExpression node) => defaultNode(node);
  T visitProperty(Property node) => defaultNode(node);
  T visitFunctionExpression(FunctionExpression node) => defaultNode(node);
  T visitSequence(SequenceExpression node) => defaultNode(node);
  T visitUnary(UnaryExpression node) => defaultNode(node);
  T visitBinary(BinaryExpression node) => defaultNode(node);
  T visitAssignment(AssignmentExpression node) => defaultNode(node);
  T visitUpdateExpression(UpdateExpression node) => defaultNode(node);
  T visitConditional(ConditionalExpression node) => defaultNode(node);
  T visitCall(CallExpression node) => defaultNode(node);
  T visitMember(MemberExpression node) => defaultNode(node);
  T visitIndex(IndexExpression node) => defaultNode(node);
  T visitNameExpression(NameExpression node) => defaultNode(node);
  T visitLiteral(LiteralExpression node) => defaultNode(node);
  T visitRegexp(RegexpExpression node) => defaultNode(node);
}

/// Traverses the entire subtree when visiting a node.
/// 
/// When overriding a `visitXXX` method, it is your responsibility to visit
/// the children of the given node, otherwise that subtree will not be traversed.
///  
/// For example:
///     visitWhile(While node) {
///         print('Found while loop on line ${node.line}');
///         node.forEach(visit); // visit children
///     }
/// Without the call to `forEach`, a while loop nested in another while loop would 
/// not be found.
class RecursiveVisitor<T> extends BaseVisitor<T> {
  defaultNode(Node node) {
    node.forEach(visit);
  }
}



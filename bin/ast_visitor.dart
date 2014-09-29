part of ast;


abstract class Visitor<T> {
  
  T visit(Node node) => node.visitBy(this);
  
  T visitProgram(Program node);
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
  T visitCatch(CatchClause node);
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
  T visitNew(NewExpression node);
  T visitCall(CallExpression node);
  T visitMember(MemberExpression node);
  T visitIndex(IndexExpression node);
  T visitNameExpression(NameExpression node);
  T visitLiteral(LiteralExpression node);
  T visitRegexp(RegexpExpression node);
  
}

class BaseVisitor<T> implements Visitor<T> {
  
  T defaultNode(Node node) => null;
  T defaultStatement(Statement node) => null;
  T defaultExpression(Expression node) => null;
  
  T visit(Node node) => node.visitBy(this);
  
  T visitProgram(Program node) => defaultNode(node);
  T visitName(Name node) => defaultNode(node);
  
  T visitEmptyStatement(EmptyStatement node) => defaultStatement(node);
  T visitBlock(BlockStatement node) => defaultStatement(node);
  T visitExpressionStatement(ExpressionStatement node) => defaultStatement(node);
  T visitIf(IfStatement node) => defaultStatement(node);
  T visitLabeledStatement(LabeledStatement node) => defaultStatement(node);
  T visitBreak(BreakStatement node) => defaultStatement(node);
  T visitContinue(ContinueStatement node) => defaultStatement(node);
  T visitWith(WithStatement node) => defaultStatement(node);
  T visitSwitch(SwitchStatement node) => defaultStatement(node);
  T visitSwitchCase(SwitchCase node) => defaultNode(node);
  T visitReturn(ReturnStatement node) => defaultStatement(node);
  T visitThrow(ThrowStatement node) => defaultStatement(node);
  T visitTry(TryStatement node) => defaultStatement(node);
  T visitCatch(CatchClause node) => defaultNode(node);
  T visitWhile(WhileStatement node) => defaultStatement(node);
  T visitDoWhile(DoWhileStatement node) => defaultStatement(node);
  T visitFor(ForStatement node) => defaultStatement(node);
  T visitForIn(ForInStatement node) => defaultStatement(node);
  T visitFunctionDeclaration(FunctionDeclaration node) => defaultStatement(node);
  T visitVariableDeclaration(VariableDeclaration node) => defaultStatement(node);
  T visitVariableDeclarator(VariableDeclarator node) => defaultNode(node);
  T visitDebugger(DebuggerStatement node) => defaultStatement(node);
  
  T visitThis(ThisExpression node) => defaultExpression(node);
  T visitArray(ArrayExpression node) => defaultExpression(node);
  T visitObject(ObjectExpression node) => defaultExpression(node);
  T visitProperty(Property node) => defaultNode(node);
  T visitFunctionExpression(FunctionExpression node) => defaultExpression(node);
  T visitSequence(SequenceExpression node) => defaultExpression(node);
  T visitUnary(UnaryExpression node) => defaultExpression(node);
  T visitBinary(BinaryExpression node) => defaultExpression(node);
  T visitAssignment(AssignmentExpression node) => defaultExpression(node);
  T visitUpdateExpression(UpdateExpression node) => defaultExpression(node);
  T visitConditional(ConditionalExpression node) => defaultExpression(node);
  T visitNew(NewExpression node) => defaultExpression(node);
  T visitCall(CallExpression node) => defaultExpression(node);
  T visitMember(MemberExpression node) => defaultExpression(node);
  T visitIndex(IndexExpression node) => defaultExpression(node);
  T visitNameExpression(NameExpression node) => defaultExpression(node);
  T visitLiteral(LiteralExpression node) => defaultExpression(node);
  T visitRegexp(RegexpExpression node) => defaultExpression(node);
  
}

class RecursiveVisitor extends BaseVisitor {
  // TODO: implement this properly
  visit(Node node) {
    node.visitBy(this);
    node.forEach(visit);
  }
  
}

import 'dart:io';
import '../bin/lexer.dart';
import '../bin/parser.dart';
import '../bin/ast.dart';
import '../bin/line_numbers.dart';


void printAST(Node node) {
  int level = 0;
  void visit(Node node) {
    String indent = ''.padLeft(level * 2);
    print('$indent$node');
    level++;
    node.forEach(visit);
    level--;
  }
  visit(node);
}

void main() {

  String filename = '../benchmarks/deltablue.js';
  
  new File(filename).readAsString().then((String text) {
    Lexer lexer = new Lexer(text);
    Parser parser = new Parser(lexer);
    
    LineNumbers lines = new LineNumbers(text);
    
    try {
      Program program = parser.parseProgram();
      printAST(program);
      print('OK');
    } on ParseError catch (e) {
      int line = 1 + lines.getLineAt(e.position);
      print("$filename:$line ${e.msg}");
      rethrow;
    }
    
  });
  
}
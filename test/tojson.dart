import '../bin/ast.dart';
import '../bin/parser.dart';
import '../bin/lexer.dart';
import '../bin/ast_json.dart';


import 'dart:io';
import 'dart:convert' show JSON;

void main(List<String> args) {
  File file = new File(args[0]);
  file.readAsString().then((String text) {
    Program ast = new Parser(new Lexer(text)).parseProgram();
    
    var json = new Ast2Json().visit(ast);
  
    print(JSON.encode(json));
  });
}

// Parses the given FILE and prints it as JSON so it can be compared against Esprima's output. 

import '../bin/ast.dart';
import '../bin/parser.dart';
import '../bin/lexer.dart';
import '../bin/ast_json.dart';
import '../bin/line_numbers.dart';

import 'dart:io';
import 'dart:convert' show JSON;

void main(List<String> args) {
  File file = new File(args[0]);
  file.readAsString().then((String text) {
    try {
      Program ast = new Parser(new Lexer(text)).parseProgram();
      var json = new Ast2Json().visit(ast);
      print(JSON.encode(json));
    } on ParseError catch (e) {
      LineNumbers lines = new LineNumbers(text);
      int line = 1 + lines.getLineAt(e.position);
      stderr.writeln('${file.path}:$line ${e.msg}');
      exit(1);
    }
  });
}

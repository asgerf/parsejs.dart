library javascript_parser;

import 'dart:io';
import 'dart:async';
import 'ast.dart';
import 'lexer.dart';
import 'parser.dart';

export 'ast.dart';
export 'lexer.dart' show ParseError;

Program parse(String text, {String filename, int firstLine : 1}) {
  Lexer lexer = new Lexer(text, filename: filename, currentLine: firstLine);
  return new Parser(lexer).parseProgram();
}

Future<Program> parseFile(File file) => file.readAsString().then((String text) => parse(text, filename: file.path));


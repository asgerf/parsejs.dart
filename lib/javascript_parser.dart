library javascript_parser;

import 'dart:io';
import 'dart:async';

import 'src/ast.dart';
import 'src/lexer.dart';
import 'src/parser.dart';

export 'src/ast.dart';
export 'src/lexer.dart' show ParseError;

Program parse(String text, {String filename, int firstLine : 1}) {
  return new Parser(new Lexer(text, filename: filename, currentLine: firstLine)).parseProgram();
}

Future<Program> parseFile(File file) => file.readAsString().then((String text) => parse(text, filename: file.path));


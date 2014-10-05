library javascript_parser;

import 'dart:io';
import 'dart:async';
import 'ast.dart';
import 'lexer.dart';
import 'parser.dart';

export 'ast.dart';
export 'parser.dart' show ParseError;

Program parse(String text) => new Parser(new Lexer(text)).parseProgram();

Future<Program> parseFile(File file) => file.readAsString().then(parse);

import 'dart:io';
import '../lib/src/lexer.dart';

void main() {
  
  String filename = 'testcases/own/keywords.js';
  
  new File(filename).readAsString().then((String text) {
    Lexer lexer = new Lexer(text);
    for (Token token = lexer.scan(); token.type != Token.EOF; token = lexer.scan()) {
      print(token);
    }
  });
  
}
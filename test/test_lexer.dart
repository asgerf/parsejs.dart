import 'dart:io';
import '../bin/lexer.dart';

void main() {
  
  String filename = 'test.js';
  
  new File(filename).readAsString().then((String text) {
    Lexer lexer = new Lexer(text);
    for (Token token = lexer.scan(); token.type != Token.EOF; token = lexer.scan()) {
      print(token);
    }
  });
  
}
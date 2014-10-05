// Parses the given FILE and prints it as JSON so it can be compared against Esprima's output. 

import '../bin/ast.dart';
import '../bin/parser.dart';
import '../bin/lexer.dart';
import 'ast_json.dart';
import '../../scrap/bin/line_numbers.dart';

import 'dart:io';
import 'dart:convert' show JSON;

class Args {
  List<String> args = <String>[];
  Set<String> flags = new Set<String>();
  
  bool operator[](String flag) => flags.contains(flag);
}

Args parseArgs(List<String> args) {
  Args result = new Args();
  for (String arg in args) {
    if (arg.startsWith('--')) {
      result.flags.add(arg.substring(2));
    } else {
      result.args.add(arg);
    }
  }
  return result;
}

void main(List<String> cmdargs) {
  Args cmd = parseArgs(cmdargs);
  
  if (cmd.args.length != 1) {
    print("Usage: test_parser.dart [--json] [--time] FILE.js");
    exit(1);
  }
  
  File file = new File(cmd.args[0]);
  file.readAsString().then((String text) {
    try {
      Stopwatch watch = new Stopwatch()..start();
      Program ast = new Parser(new Lexer(text)).parseProgram();
      int time = watch.elapsedMilliseconds;
      
      if (cmd['time']) {
        print(time);
      }
      
      if (cmd['json']) {
        var json = new Ast2Json().visit(ast);
        print(JSON.encode(json));
      }
      
    } on ParseError catch (e) {
      stderr.writeln('${file.path}:${e.lineNumber} ${e.message}');
      exit(1);
    }
  });
}

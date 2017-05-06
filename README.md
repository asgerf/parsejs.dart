# ParseJS

**ParseJS** is a JavaScript parser for Dart. It is well-tested and is reasonably efficient.

## Example Usage
```dart
import 'package:parsejs/parsejs.dart';

void main() {
    new File('test.js').readAsString().then((String code) {
        Program ast = parsejs(code, filename: 'test.js')
        // Use the AST for something
    })
}
```

## Options

The `parsejs` function takes the following optional arguments:

- `filename`: An arbitrary string indicating where the source came from. For your convenience this will be available on `Node.filename` and on `ParseError.filename`.
- `firstLine`: The line number to associate with the first line of code. Default is 1. Useful if code was extracted from an HTML file, and you prefer absolute line numbers.
- `handleNoise`: If true, parser will try to ignore hash bangs and HTML comment tags surrounding the source code. Default is true.
- `annotate`: If true, parser will initialize `Node.parent`, `Scope.environment`, and `Name.scope`, to simplify subsequent AST analysis. Default is true.
- `parseAsExpression`: If true, the input will be parsed as an expression statement.

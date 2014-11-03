# JSParser

**JSParser** is a JavaScript parser for Dart. It is well-tested and is reasonably efficient.

## Usage
```dart
import 'package:jsparser/jsparser.dart';

void main() {
    new File('test.js').readAsString().then((String code) {
        Program ast = parse(code, filename: 'test.js')
        // Use the AST for something
    })
}
```

## Testing

We parse [test-262](http://test262.ecmascript.org/) and the [Octane benchmark suite](https://developers.google.com/octane), and compare the resulting AST against the one produced by [Esprima](http://esprima.org/). To run the tests, you must first install [node.js](http://nodejs.org/), then run the following:
```
cd test
npm install
./runtest
```



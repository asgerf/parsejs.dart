library line_numbers;

int clamp(int x, int min, int max) => x < min ? min : (x > max ? max : x);

class LineNumbers {
  
  List<int> line2offset = <int>[]; // N -> index of first character on line N. First line is 0 so 0 always maps to 0.
  
  static const int LF = 10;
  static const int CR = 13;
  
  LineNumbers(String text) {
    line2offset.add(0);
    for (int i=0; i<text.length; i++) {
      int code = text.codeUnitAt(i);
      if (code == LF) {
        line2offset.add(i+1);
      }
      else if (code == CR) {
        if (i+1 < text.length && text.codeUnitAt(i+1) == LF) {
          i++;
        }
        line2offset.add(i+1);
      }
    }
    if (line2offset.last != text.length) {
      line2offset.add(text.length);
    }
  }
  
  int getStartOfLine(int line) => line2offset[clamp(line, 0, line2offset.length-1)];
  int getEndOfLine(int line) => getStartOfLine(line+1);
  
  String extractLine(String text, int line) => text.substring(getStartOfLine(line), getEndOfLine(line));
  
  int getLineAt(int offset) {
    if (offset >= line2offset.last) return line2offset.length - 1;
    if (offset < 0) return 0;
    int min = 0;
    int max = line2offset.length - 1;
    while (min < max) {
      int line = (min + max) >> 1;
      if (offset < line2offset[line]) {
        max = line - 1;
        continue;
      }
      int next_line = line + 1;
      if (line2offset[next_line] < offset) {
        min = next_line;
        continue;
      }
      return line;
    }
    return min;
  }
  
  
}
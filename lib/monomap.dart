class Monomap {
  final int width;
  final int height;

  int _cursor_x = 0;
  int _cursor_y = 0;

  late final List<bool> _bitmap = List.filled(width * height, false);

  List<bool> get data => _bitmap;

  Monomap(this.width, this.height);

  /// draw single pixel
  void drawPixel(int x, int y, bool color) {
    _bitmap[x + (width * y)] = color;
  }

  /// draw a line
  /// using Bresenham's line algorithm
  void drawLine(int x0, int y0, int x1, int y1, bool color) {
    final dx = (x1 - x0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final dy = (y1 - y0).abs();
    final sy = y0 < y1 ? 1 : -1;

    var err = (dx > dy ? dx : -dy) / 2;

    while (true) {
      drawPixel(x0, y0, color);

      if (x0 == x1 && y0 == y1) break;

      final e2 = err;

      if (e2 > -dx) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dy) {
        err += dx;
        y0 += sy;
      }
    }
  }

  /// Draw an outlined  rectangle
  void drawRect(int x, int y, int w, int h, bool color) {
    // top
    this.drawLine(x, y, x + w, y, color);

    // left
    this.drawLine(x, y + 1, x, y + h - 1, color);

    // right
    this.drawLine(x + w, y + 1, x + w, y + h - 1, color);

    // bottom
    this.drawLine(x, y + h - 1, x + w, y + h - 1, color);
  }

  /// draw a filled rectangle on the oled
  void fillRect(int x, int y, int w, int h, bool color) {
    // one iteration for each column of the rectangle
    for (int i = x; i < x + w; i += 1) {
      // draws a vert line
      this.drawLine(i, y, i, y + h - 1, color);
    }
  }

  /// Draw a circle outline
  ///
  /// This method is ad verbatim translation from the corresponding
  /// method on the Adafruit GFX library
  /// https://github.com/adafruit/Adafruit-GFX-Library
  void drawCircle(
    int x0,
    int y0,
    int r,
    bool color,
  ) {
    int f = 1 - r;
    int ddF_x = 1;
    int ddF_y = -2 * r;
    int x = 0;
    int y = r;

    [
      [x0, y0 + r, color],
      [x0, y0 - r, color],
      [x0 + r, y0, color],
      [x0 - r, y0, color],
    ].forEach(
      (e) {
        drawPixel(e[0] as int, e[1] as int, e[2] as bool);
      },
    );

    while (x < y) {
      if (f >= 0) {
        y--;
        ddF_y += 2;
        f += ddF_y;
      }
      x++;
      ddF_x += 2;
      f += ddF_x;

      [
        [x0 + x, y0 + y, color],
        [x0 - x, y0 + y, color],
        [x0 + x, y0 - y, color],
        [x0 - x, y0 - y, color],
        [x0 + y, y0 + x, color],
        [x0 - y, y0 + x, color],
        [x0 + y, y0 - x, color],
        [x0 - y, y0 - x, color],
      ].forEach(
        (e) {
          drawPixel(e[0] as int, e[1] as int, e[2] as bool);
        },
      );
    }
  }

  /// set starting position of a text string on the oled
  setCursor(int x, int y) {
    _cursor_x = x;
    _cursor_y = y;
  }

  /// write text to the oled
  void writeString(Font font, int size, String string, bool color, bool wrap,
      int linespacing) {
    final wordArr = string.split(' ');

    final len = wordArr.length;

    // start x offset at cursor pos
    int offset = _cursor_x;
    int padding = 0;

    const letspace = 1;
    final int leading = linespacing | 2;

    // loop through words
    for (var i = 0; i < len; i += 1) {
      // put the word space back in
      if (i < len - 1) wordArr[i] += ' ';

      final stringArr = wordArr[i].split('');
      final slen = stringArr.length;
      final compare = (font.width * size * slen) + (size * (len - 1));

      // wrap words if necessary
      if (wrap && len > 1 && (offset >= (width - compare))) {
        offset = 1;
        _cursor_y += (font.height * size) + size + leading;
        setCursor(offset, _cursor_y);
      }

      // loop through the array of each char to draw
      for (var i = 0; i < slen; i += 1) {
        // look up the position of the char, pull out the buffer slice
        final charBuf = _findCharBuf(font, stringArr[i]);
        // read the bits in the bytes that make up the char
        final charBytes = _readCharBytes(charBuf);
        // draw the entire charactei
        _drawChar(font, charBytes, size, color);

        // fills in background behind the text pixels so that it's easier to read the text
        this.fillRect(
            offset - padding, _cursor_y, padding, (font.height * size), !color);

        // calc new x position for the next char, add a touch of padding too if it's a non space char
        padding = (stringArr[i] == ' ') ? 0 : size + letspace;
        offset += (font.width * size) + padding;

        // wrap letters if necessary
        if (wrap && (offset >= (width - font.width - letspace))) {
          offset = 1;
          _cursor_y += (font.height * size) + size + leading;
        }
        // set the 'cursor' for the next char to be drawn, then loop again for next char
        setCursor(offset, _cursor_y);
      }
    }
  }

  /// get character bytes from the supplied font object in order to send to framebuffer
  List<List<int>> _readCharBytes(List<int> byteArray) {
    var bitArr = <int>[];
    final bitCharArr = <List<int>>[];
    // loop through each byte supplied for a char
    for (var i = 0; i < byteArray.length; i += 1) {
      // set current byte
      final byte = byteArray[i];
      // read each byte
      for (var j = 0; j < 8; j += 1) {
        // shift bits right until all are read
        final bit = byte >> j & 1;
        bitArr.add(bit);
      }
      // push to array containing flattened bit sequence
      bitCharArr.add(bitArr);
      // clear bits for next byte
      bitArr = [];
    }
    return bitCharArr;
  }
  

  void clear() {
    _bitmap.map((e) => false);
  }

  /// draw an individual character to the screen
  void _drawChar(Font font, List<List<int>> byteArray, int size, bool color) {
    // take your positions...
    var x = _cursor_x;
    var y = _cursor_y;

    var c = 0;
    var pagePos = 0;
    // loop through the byte array containing the hexes for the char
    for (var i = 0; i < byteArray.length; i += 1) {
      pagePos = (i / font.width).floor() * 8;
      for (var j = 0; j < 8; j += 1) {
        // pull color out (invert the color if user chose black)
        final pixelState = (byteArray[i][j] == 1) ? color : !color;
        var xpos;
        var ypos;
        // standard font size
        if (size == 1) {
          xpos = x + c;
          ypos = y + j + pagePos;
          this.drawPixel(xpos, ypos, pixelState);
        } else {
          // MATH! Calculating pixel size multiplier to primitively scale the font
          xpos = x + (i * size);
          ypos = y + (j * size);
          this.fillRect(xpos, ypos, size, size, pixelState);
        }
      }
      c = (c < font.width - 1) ? c += 1 : 0;
    }
  }

  /// find where the character exists within the font object
  List<int> _findCharBuf(Font font, String c) {
    final charLength = ((font.width * font.height) / 8).ceil();
    // use the lookup array as a ref to find where the current char bytes start
    final cBufPos = font.lookup.indexOf(c) * charLength;
    // slice just the current char's bytes out of the fontData array and return
    return font.fontData.sublist(cBufPos, cBufPos + charLength);
  }
}

class Font {
  final bool monospace;
  int width;
  int height;
  List<int> fontData;
  List<String> lookup;

  Font({
    required this.monospace,
    required this.width,
    required this.height,
    required this.fontData,
    required this.lookup,
  });
}

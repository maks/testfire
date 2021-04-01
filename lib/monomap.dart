class Monomap {
  final int width;
  final int height;

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

  void clear() {
    _bitmap.map((e) => false);
  }
}

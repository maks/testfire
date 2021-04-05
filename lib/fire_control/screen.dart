import 'dart:math';

import 'package:monochrome_draw/monochrome_draw.dart';
import 'package:oled_font_57/oled_font_57.dart' as font57;

import 'menu.dart';
import 'selectable_list.dart';

class Screen {
  final Function(List<bool>) onPaint;
  final MainMenu menu;

  static const maxVisibleItems = 4;
  static const lineHeight = 8;

  final font = Font(
    monospace: font57.monospace,
    width: font57.width,
    height: font57.height,
    fontData: font57.fontData,
    lookup: font57.lookup,
  );
  final MonoCanvas oledBitmap = MonoCanvas(128, 64);

  Screen(this.onPaint, this.menu) {
    redraw();
  }

  void drawHeading(String heading) {
    oledBitmap.setCursor(0, 0);
    oledBitmap.writeString(font, 1, heading, true, true, 1);
    oledBitmap.setCursor(0, lineHeight);
    oledBitmap.writeString(font, 1, '=' * heading.length, true, true, 1);
    onPaint(oledBitmap.data);
  }

  void drawContent(List<String> content) {
    final offset = lineHeight * 2;
    for (int line = 0; line < min(content.length, maxVisibleItems); line++) {
      oledBitmap.setCursor(0, (8 * line) + offset);
      oledBitmap.writeString(font, 1, content[line], true, true, 1);
    }
    onPaint(oledBitmap.data);
  }

  void redraw() {
    menu.draw(this);
  }

  void clear() {
    oledBitmap.clear();
  }
}

class Page extends SelectableItem {
  final String title;
  final SelectableList<MenuParam> params;

  Page(this.title, this.params, Function() onUpdate);

  void next() => params.next();

  void prev() => params.prev();

  void select() => params.select();

  void draw(Screen s) {
    s.clear();
    s.drawHeading(title);
    s.drawContent(params.items
        .map((p) => (p == params.selectedItem ? '>' : '') + p.title)
        .toList());
  }
}

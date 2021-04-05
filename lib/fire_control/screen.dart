import 'package:monochrome_draw/monochrome_draw.dart';
import 'package:oled_font_57/oled_font_57.dart' as font57;

import '../fire_midi.dart';

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
    for (int line = 0; line < maxVisibleItems; line++) {
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

abstract class SelectableItem {
  void next();
  void prev();
  void select();
}

class SelectableList<T extends SelectableItem> {
  bool _showingItem = false;
  int _selectedIndex = 0;
  List<T> items;
  T get selectedItem => items[_selectedIndex];
  final Function() onUpdate;

  SelectableList(this.onUpdate, this.items);

  void prev() {
    print('prev');
    if (_showingItem) {
      selectedItem.prev();
    } else {
      _selectedIndex =
          _selectedIndex == 0 ? _selectedIndex : _selectedIndex - 1;
    }
    onUpdate();
  }

  void next() {
    print('next');
    if (_showingItem) {
      selectedItem.next();
    } else {
      _selectedIndex = _selectedIndex == (items.length - 1)
          ? _selectedIndex
          : _selectedIndex + 1;
    }
    onUpdate();
  }

  void select() {
    print('select');
    if (_showingItem) {
      selectedItem.select();
    } else {
      _showingItem = true;
    }
    onUpdate();
  }

  void back() {
    print('back');
    _showingItem = false;
    onUpdate();
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

abstract class MenuParam extends SelectableItem {
  final String title;

  MenuParam(this.title);
}

class IntMenuParam extends MenuParam {
  int _value;

  int get value => _value;

  IntMenuParam(String name, int defaultValue)
      : _value = defaultValue,
        super(name);

  @override
  void next() => _value++;

  @override
  void prev() => _value--;

  @override
  void select() {/* NA */}
}

abstract class Menu {
  Menu(this.onUpdate);

  String get title;
  SelectableList<Page> get pages;
  void draw(Screen s);
  final Function() onUpdate;
}

/// simple 2-level menu system
class MainMenu implements Menu {
  static const _title = 'FireTribe';

  @override
  String get title => _title;

  late final SelectableList<Page> pages;

  Page get selectedPage => pages.selectedItem;

  bool _showingPage = false;

  @override
  Function() onUpdate;

  MainMenu(this.onUpdate) {
    pages = SelectableList(
      onUpdate,
      [
        Page(
          'Sequencer',
          SelectableList<MenuParam>(
            onUpdate,
            [
              IntMenuParam('BPM', 120),
            ],
          ),
          onUpdate,
        ),
        Page(
          'Sampler',
          SelectableList<MenuParam>(onUpdate, []),
          onUpdate,
        ),
        Page(
          'Synth',
          SelectableList<MenuParam>(onUpdate, []),
          onUpdate,
        ),
        Page(
          'Settings',
          SelectableList<MenuParam>(onUpdate, []),
          onUpdate,
        ),
      ],
    );
  }

  void onMidiEvent(FireDevice device, int type, int id, int value) {
    if (type == CCInputs.dialRotate && id == CCInputs.select) {
      if (value == CCInputs.rotateLeft) {
        prev();
      }
      if (value == CCInputs.rotateRight) {
        next();
      }
    }
    if (type == CCInputs.buttonDown && id == CCInputs.selectDown) {
      select();
    }
    if (type == CCInputs.buttonDown && id == CCInputs.browser) {
      back();
    }
  }

  void prev() {
    print('prev');
    if (_showingPage) {
      selectedPage.prev();
    } else {
      pages.prev();
    }
    onUpdate();
  }

  void next() {
    print('next');
    if (_showingPage) {
      selectedPage.next();
    } else {
      pages.next();
    }
    onUpdate();
  }

  void select() {
    print('select');
    if (_showingPage) {
      selectedPage.select();
    } else {
      _showingPage = true;
    }
    onUpdate();
  }

  void back() {
    print('back');
    _showingPage = false;
    onUpdate();
  }

  @override
  void draw(Screen s) {
    if (_showingPage) {
      selectedPage.draw(s);
    } else {
      s.clear();
      s.drawHeading(_title);
      s.drawContent(pages.items
          .map((p) => (p == selectedPage ? '>' : '') + p.title)
          .toList());
    }
  }
}

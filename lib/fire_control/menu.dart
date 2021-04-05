import '../fire_midi.dart';
import 'screen.dart';
import 'selectable_list.dart';

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

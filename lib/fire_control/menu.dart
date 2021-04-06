import 'package:testfire/session/sessionProvider.dart';

import '../fire_midi.dart';
import 'page.dart';
import 'screen.dart';
import 'selectable_list.dart';

abstract class MenuParam extends SelectableItem {
  final String title;
  final Function() onUpdate;

  MenuParam(this.title, this.onUpdate);

  void draw(Screen s);
}

class IntMenuParam extends MenuParam {
  int get value => container.read(sessionProvider).bpm;

  final container;

  IntMenuParam(
      String name, int defaultValue, Function() onUpdate, this.container)
      : super(name, onUpdate);

  @override
  void next() {
    container.read(sessionProvider.notifier).incrementBpm();
    onUpdate();
  }

  @override
  void prev() {
    container.read(sessionProvider.notifier).decrementBpm();
    onUpdate();
  }

  @override
  void select() {/* NA */}

  @override
  void draw(Screen s) {
    s.clear();
    s.drawHeading(title);
    s.drawContent([value.toString()], large: true);
  }
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

  MainMenu(this.onUpdate, container) {
    pages = SelectableList(
      onUpdate,
      [
        Page(
          'Sequencer',
          SelectableList<MenuParam>(
            onUpdate,
            [
              IntMenuParam('BPM', 120, onUpdate, container),
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

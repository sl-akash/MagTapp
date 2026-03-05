import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class StateModifierBool extends StateNotifier<bool> {
  StateModifierBool() : super(false);

  void change() => !state;
  void falsify() => state = false;
  void trutify() => state = true;
}
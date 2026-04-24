import 'dart:async';
import 'package:flutter/foundation.dart';

class ActionDebouncer {
  ActionDebouncer({this.duration = const Duration(milliseconds: 500)});
  final Duration duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

import 'dart:async';

/// Delays execution of [action] until [duration] has elapsed since the last call.
/// Use one instance per search field.
///
/// Example:
///   final _debounce = Debounce();
///   _debounce.run(() => _fetchData());
class Debounce {
  final Duration duration;
  Timer? _timer;

  Debounce({this.duration = const Duration(milliseconds: 400)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

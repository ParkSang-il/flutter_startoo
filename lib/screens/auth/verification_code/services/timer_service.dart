import 'dart:async';

// 타이머 서비스
class TimerService {
  Timer? _timer;
  int _remainingSeconds = 180;

  void startTimer({
    required void Function(int seconds) onTick,
  }) {
    _timer?.cancel();
    _remainingSeconds = 180;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        onTick(_remainingSeconds);
      } else {
        timer.cancel();
        onTick(0);
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}


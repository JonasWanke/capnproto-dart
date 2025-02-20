import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'error.dart';

class AsyncBufferedReader {
  AsyncBufferedReader(Stream<List<int>> stream) {
    _subscription = stream.listen(
      (event) {
        _pendingData.add(event);
        _notifyNewEvent();
      },
      onDone: _notifyNewEvent,
    );
  }

  late final StreamSubscription<List<int>> _subscription;
  final _pendingData = Queue<List<int>>();
  var _offsetInFirstBuffer = 0;

  var _nextEvent = Completer<void>();
  void _notifyNewEvent() {
    final nextEvent = _nextEvent;
    _nextEvent = Completer();
    nextEvent.complete();
  }

  @useResult
  Future<int> read(Uint8List buffer) async {
    if (buffer.isEmpty) return 0;

    var didResumeSubscription = false;
    var offset = 0;
    while (offset < buffer.length) {
      if (_pendingData.isEmpty) {
        if (!didResumeSubscription) {
          didResumeSubscription = true;
          _subscription.resume();
        }

        await _nextEvent.future;
        if (_pendingData.isEmpty) break;
      }

      final newData = _pendingData.first;
      final length = math.min(
        buffer.length - offset,
        newData.length - _offsetInFirstBuffer,
      );
      buffer.setRange(
        offset,
        offset + length,
        newData.skip(_offsetInFirstBuffer),
      );
      offset += length;
      if (_offsetInFirstBuffer + length == newData.length) {
        _pendingData.removeFirst();
        _offsetInFirstBuffer = 0;
      }
    }
    _subscription.pause();
    return offset;
  }

  @useResult
  Future<Result<void, PrematureEndOfInputCapnpError>> readExact(
    Uint8List buffer,
  ) async {
    final length = await read(buffer);
    if (length < buffer.length) {
      return const Err(PrematureEndOfInputCapnpError());
    }
    return const Ok(null);
  }

  Future<void> cancel() => _subscription.cancel();
}

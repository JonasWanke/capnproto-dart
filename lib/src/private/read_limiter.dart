import 'package:oxidized/oxidized.dart';

import '../error.dart';

class ReadLimiter {
  ReadLimiter(int? limit) : _limit = limit;

  int? _limit;
  int? get limit => _limit;

  CapnpResult<void> canRead(int amount) {
    if (_limit case final limit?) {
      if (amount > limit) return const Err(ReadLimitExceededCapnpError());
      _limit = limit - amount;
    }

    return const Ok(null);
  }
}

import 'package:flutter/foundation.dart';

final ValueNotifier<int> financeBalanceRefreshRevision = ValueNotifier<int>(0);

void notifyFinanceBalanceRefreshed() {
  financeBalanceRefreshRevision.value++;
}

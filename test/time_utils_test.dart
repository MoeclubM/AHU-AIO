import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/jwapp/utils/time_utils.dart';

void main() {
  group('TimeUtils standard unit tests (AHU 13 periods)', () {
    test('standardUnitStartTimes contains all 13 periods', () {
      expect(TimeUtils.standardUnitStartTimes.length, 13);
      expect(TimeUtils.standardUnitStartTimes[1], '08:00');
      expect(TimeUtils.standardUnitStartTimes[2], '08:50');
      expect(TimeUtils.standardUnitStartTimes[3], '09:50');
      expect(TimeUtils.standardUnitStartTimes[4], '10:40');
      expect(TimeUtils.standardUnitStartTimes[5], '11:30');
      expect(TimeUtils.standardUnitStartTimes[6], '14:00');
      expect(TimeUtils.standardUnitStartTimes[7], '14:50');
      expect(TimeUtils.standardUnitStartTimes[8], '15:50');
      expect(TimeUtils.standardUnitStartTimes[9], '16:40');
      expect(TimeUtils.standardUnitStartTimes[10], '17:30');
      expect(TimeUtils.standardUnitStartTimes[11], '19:00');
      expect(TimeUtils.standardUnitStartTimes[12], '19:50');
      expect(TimeUtils.standardUnitStartTimes[13], '20:40');
    });

    test('resolveStartUnit resolves correctly for all 13 periods', () {
      // 上午 1-5 节
      expect(TimeUtils.resolveStartUnit('08:00'), 1);
      expect(TimeUtils.resolveStartUnit('08:50'), 2);
      expect(TimeUtils.resolveStartUnit('09:50'), 3);
      expect(TimeUtils.resolveStartUnit('10:40'), 4);
      expect(TimeUtils.resolveStartUnit('11:30'), 5);

      // 下午 6-10 节
      expect(TimeUtils.resolveStartUnit('14:00'), 6);
      expect(TimeUtils.resolveStartUnit('14:50'), 7);
      expect(TimeUtils.resolveStartUnit('15:50'), 8);
      expect(TimeUtils.resolveStartUnit('16:40'), 9);
      expect(TimeUtils.resolveStartUnit('17:30'), 10);

      // 晚上 11-13 节
      expect(TimeUtils.resolveStartUnit('19:00'), 11);
      expect(TimeUtils.resolveStartUnit('19:50'), 12);
      expect(TimeUtils.resolveStartUnit('20:40'), 13);
    });

    test('resolveEndUnit resolves correctly for typical class durations', () {
      // 上午 1-2 节大课: 08:00 ~ 09:35 -> 2 节
      expect(TimeUtils.resolveEndUnit('09:35', 1), 2);
      // 上午 3-4 节大课: 09:50 ~ 11:25 -> 4 节
      expect(TimeUtils.resolveEndUnit('11:25', 3), 4);
      // 上午 4-5 节或 5 节课: ~ 12:15 -> 5 节
      expect(TimeUtils.resolveEndUnit('12:15', 4), 5);
      expect(TimeUtils.resolveEndUnit('12:15', 5), 5);

      // 下午 6-7 节大课: 14:00 ~ 15:35 -> 7 节
      expect(TimeUtils.resolveEndUnit('15:35', 6), 7);
      // 下午 8-9 节大课: 15:50 ~ 17:25 -> 9 节
      expect(TimeUtils.resolveEndUnit('17:25', 8), 9);
      // 下午第 10 节: ~ 18:15 -> 10 节
      expect(TimeUtils.resolveEndUnit('18:15', 10), 10);

      // 晚上 11-12 节大课: 19:00 ~ 20:35 -> 12 节
      expect(TimeUtils.resolveEndUnit('20:35', 11), 12);
      // 晚上 11-13 节大课: 19:00 ~ 21:25 -> 13 节
      expect(TimeUtils.resolveEndUnit('21:25', 11), 13);
    });
  });
}

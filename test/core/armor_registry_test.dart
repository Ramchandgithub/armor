import 'package:flutter_test/flutter_test.dart';
import 'package:armor/armor.dart';

void main() {
  group('ArmorRegistry Tests', () {
    setUp(() {
      ArmorRegistry.clear();
    });

    test('initially has no healed bugs', () {
      expect(ArmorRegistry.healedBugs.isEmpty, isTrue);
      expect(ArmorRegistry.totalHealed, equals(0));
      expect(ArmorRegistry.mostCommonHealedError, isNull);
    });

    test('registerNullCheckHealing increments count', () {
      ArmorRegistry.registerNullCheckHealing();
      expect(ArmorRegistry.healedBugs['null_check'], equals(1));
      expect(ArmorRegistry.totalHealed, equals(1));

      ArmorRegistry.registerNullCheckHealing();
      expect(ArmorRegistry.healedBugs['null_check'], equals(2));
      expect(ArmorRegistry.totalHealed, equals(2));
    });

    test('registerSetStateHealing increments count', () {
      ArmorRegistry.registerSetStateHealing();
      expect(ArmorRegistry.healedBugs['setState_after_dispose'], equals(1));
      expect(ArmorRegistry.totalHealed, equals(1));
    });

    test('registerDeactivatedWidgetHealing increments count', () {
      ArmorRegistry.registerDeactivatedWidgetHealing();
      expect(ArmorRegistry.healedBugs['deactivated_widget'], equals(1));
      expect(ArmorRegistry.totalHealed, equals(1));
    });

    test('registerRenderOverflowHealing increments count', () {
      ArmorRegistry.registerRenderOverflowHealing();
      expect(ArmorRegistry.healedBugs['render_overflow'], equals(1));
      expect(ArmorRegistry.totalHealed, equals(1));
    });

    test('registerImageLoadingHealing increments count', () {
      ArmorRegistry.registerImageLoadingHealing();
      expect(ArmorRegistry.healedBugs['image_loading'], equals(1));
      expect(ArmorRegistry.totalHealed, equals(1));
    });

    test('registerNetworkHealing increments count', () {
      ArmorRegistry.registerNetworkHealing();
      expect(ArmorRegistry.healedBugs['network_error'], equals(1));
      expect(ArmorRegistry.totalHealed, equals(1));
    });

    test('registerPlatformChannelHealing increments count', () {
      ArmorRegistry.registerPlatformChannelHealing();
      expect(ArmorRegistry.healedBugs['platform_channel'], equals(1));
      expect(ArmorRegistry.totalHealed, equals(1));
    });

    test('registerFileOperationHealing increments count', () {
      ArmorRegistry.registerFileOperationHealing();
      expect(ArmorRegistry.healedBugs['file_operation'], equals(1));
      expect(ArmorRegistry.totalHealed, equals(1));
    });

    test('totalHealed calculates correctly with multiple types', () {
      ArmorRegistry.registerNullCheckHealing();
      ArmorRegistry.registerNullCheckHealing();
      ArmorRegistry.registerSetStateHealing();
      ArmorRegistry.registerRenderOverflowHealing();

      expect(ArmorRegistry.totalHealed, equals(4));
    });

    test('mostCommonHealedError returns correct type', () {
      ArmorRegistry.registerNullCheckHealing();
      ArmorRegistry.registerNullCheckHealing();
      ArmorRegistry.registerNullCheckHealing();
      ArmorRegistry.registerSetStateHealing();

      expect(ArmorRegistry.mostCommonHealedError, equals('null_check'));
    });

    test('healedBugs returns unmodifiable map', () {
      ArmorRegistry.registerNullCheckHealing();
      final bugs = ArmorRegistry.healedBugs;

      expect(bugs, isA<Map<String, int>>());
      expect(() => bugs['test'] = 1, throwsUnsupportedError);
    });

    test('clear resets all data', () {
      ArmorRegistry.registerNullCheckHealing();
      ArmorRegistry.registerSetStateHealing();
      expect(ArmorRegistry.totalHealed, equals(2));

      ArmorRegistry.clear();
      expect(ArmorRegistry.healedBugs.isEmpty, isTrue);
      expect(ArmorRegistry.totalHealed, equals(0));
      expect(ArmorRegistry.mostCommonHealedError, isNull);
    });

    test('getStatsString returns formatted output', () {
      expect(ArmorRegistry.getStatsString(), equals('No errors healed yet'));

      ArmorRegistry.registerNullCheckHealing();
      ArmorRegistry.registerSetStateHealing();

      final stats = ArmorRegistry.getStatsString();
      expect(stats, contains('Armor Healing Statistics:'));
      expect(stats, contains('Total healed: 2'));
      expect(stats, contains('Null Check: 1'));
      expect(stats, contains('SetState After Dispose: 1'));
    });
  });
}

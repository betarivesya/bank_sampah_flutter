import 'package:flutter_test/flutter_test.dart';
import 'package:bank_sampah_flutter/app_styles.dart';

void main() {
  group('currency and date format helpers', () {
    test('rupiah formats Indonesian currency correctly', () {
      expect(rupiah(125000), 'Rp125.000');
    });

    test('tanggalIndonesia formats date in Indonesian locale', () {
      final date = DateTime(2026, 9, 18);
      expect(tanggalIndonesia(date), '18 September 2026');
    });
  });
}

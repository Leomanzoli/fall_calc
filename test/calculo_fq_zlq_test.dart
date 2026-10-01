import 'package:fall_calc_final/utils/calculo_fq_zlq.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Talabarte com absorvedor (Manual NR-35, Fig. 50 / 51 / 52)', () {
    test('Fig. 50-A: ancoragem 1 m acima do anel-D -> FQ ~0,33', () {
      final r = calcularTalabarte(l: 1.5, ea: 1.2, aa: 2.5, c: 1.5);
      expect(r.fq, closeTo(1 / 3, 0.01));
      expect(r.alerta, isEmpty);
    });

    test('Fig. 50-B: ancoragem na altura do anel-D -> FQ 1', () {
      final r = calcularTalabarte(l: 1.5, ea: 1.2, aa: 1.5, c: 1.5);
      expect(r.fq, closeTo(1.0, 1e-9));
    });

    test('Fig. 50-C: ancoragem nos pés -> FQ 2 (limite NBR 14629)', () {
      final r = calcularTalabarte(l: 1.5, ea: 1.2, aa: 0.0, c: 1.5);
      expect(r.fq, closeTo(2.0, 1e-9));
      expect(r.alerta, contains('NBR 14629'));
    });

    test('Ancoragem abaixo dos pés -> FQ > 2 com alerta', () {
      final r = calcularTalabarte(l: 1.5, ea: 1.2, aa: -0.5, c: 1.5);
      expect(r.fq, greaterThan(2.0));
      expect(r.alerta, contains('excede'));
    });

    test('Fig. 51/52: ZLQ = f3 + a + b + c + d (sem deformação)', () {
      final r = calcularTalabarte(
        l: 1.5,
        ea: 1.2,
        aa: 2.0,
        c: 1.5,
        incluirDeformacaoCinto: false,
        flecha: 0.5,
      );
      expect(r.zlqAncoragem, closeTo(0.5 + 1.5 + 1.2 + 1.5 + 1.0, 1e-9));
      expect(r.zlqPes, closeTo(r.zlqAncoragem - 2.0, 1e-9));
    });

    test('F nunca menor que 1 m', () {
      final r = calcularTalabarte(l: 1.0, ea: 0.5, aa: 6.0, c: 1.5);
      expect(r.zlqPes, 1.0);
    });

    test('Talabarte sem comprimento -> inválido', () {
      expect(calcularTalabarte(l: 0, ea: 1, aa: 1, c: 1.5).valido, isFalse);
    });
  });

  group('Trava-quedas retrátil', () {
    test('Ancoragem acima da cabeça: ZLQ = AA + DOF + extras + MS', () {
      final r = calcularTravaQuedas(dof: 1.4, aa: 2.0, c: 1.5);
      expect(r.fq, 0.0); // sem queda livre
      expect(r.zlqPes, closeTo(1.4 + 0.3 + 1.0, 1e-9)); // 2,70 m
      expect(r.zlqAncoragem, closeTo(2.0 + 2.7, 1e-9)); // 4,70 m
      expect(r.alerta, isEmpty);
    });

    test('Ancoragem nos pés: PQL = C, pés param C + DOF abaixo da ancoragem', () {
      final r = calcularTravaQuedas(
        dof: 1.4,
        aa: 0.0,
        c: 1.5,
        incluirDeformacaoCinto: false,
      );
      expect(r.fq, closeTo(1.5, 1e-9));
      expect(r.zlqPes, closeTo(1.5 + 1.4 + 1.0, 1e-9));
      expect(r.zlqAncoragem, closeTo(r.zlqPes, 1e-9));
      expect(r.alerta, contains('ALERTA SEVERO'));
    });

    test('ZLQ desde a ancoragem é sempre F + AA', () {
      for (final aa in [-1.0, 0.0, 1.0, 1.5, 2.5]) {
        final r = calcularTravaQuedas(dof: 1.0, aa: aa, c: 1.5);
        expect(r.zlqAncoragem, closeTo(r.zlqPes + aa, 1e-9));
      }
    });
  });
}

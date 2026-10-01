// lib/utils/calculo_fq_zlq.dart
//
// Fórmulas de Fator de Queda (FQ) e Zona Livre de Queda (ZLQ).
// Referências: Manual Consolidado da NR-35 (glossário; Fig. 50, 51 e 52),
// NBR 16489, NBR 14629 (absorvedor certificado para FQ 2 / 100 kg).

/// Margem de segurança "d" do Manual da NR-35 (1 m).
const double margemSeguranca = 1.0;

/// Adicional conservador para deformação/ajuste do cinturão (não consta no
/// exemplo do Manual; adotado por boa prática).
const double deformacaoCinto = 0.3;

class ResultadoFqZlq {
  /// Talabarte: Fator de Queda. Trava-quedas: Potencial de Queda Livre (m).
  /// -1 quando não há cálculo válido.
  final double fq;

  /// ZLQ medida do ponto de ancoragem para baixo (m).
  final double zlqAncoragem;

  /// Distância livre necessária abaixo dos pés do trabalhador (m), mínimo 1 m.
  final double zlqPes;

  final String alerta;
  final bool valido;

  const ResultadoFqZlq({
    required this.fq,
    required this.zlqAncoragem,
    required this.zlqPes,
    required this.alerta,
    required this.valido,
  });

  static const invalido = ResultadoFqZlq(
    fq: -1,
    zlqAncoragem: 0,
    zlqPes: 0,
    alerta: '',
    valido: false,
  );
}

/// Talabarte com absorvedor de energia em ponto fixo.
///
/// [l] comprimento do talabarte, [ea] estiramento do absorvedor,
/// [aa] altura da ancoragem em relação aos pés, [c] distância anel-D → pés.
ResultadoFqZlq calcularTalabarte({
  required double l,
  required double ea,
  required double aa,
  required double c,
  bool incluirDeformacaoCinto = true,
  double flecha = 0.0,
}) {
  if (l <= 0) return ResultadoFqZlq.invalido;

  // Fig. 50 (NBR 16489): Hq = L - (AA - C); FQ = Hq / L.
  double hq = l - (aa - c);
  if (hq < 0) hq = 0;
  final fq = hq / l;

  String alerta = '';
  if (fq > 1.9 && fq <= 2.0) {
    alerta =
        'Atenção: FQ 2 é o limite de certificação do absorvedor de energia (NBR 14629 - ensaio com FQ 2 e 100 kg). Prefira ancoragem acima do anel-D (NR-35, 35.5.11.1).';
  } else if (fq > 2) {
    alerta =
        'ATENÇÃO!\nFQ acima de 2 excede o limite de certificação do absorvedor de energia (NBR 14629 - ensaio com FQ 2 e 100 kg). A força de retenção pode ultrapassar 6 kN (NR-35, 35.5.11-d). Reposicione a ancoragem.';
  }

  // Fig. 51/52: ZLQ = f3 + a + b + c + d
  final deform = incluirDeformacaoCinto ? deformacaoCinto : 0.0;
  final zlqAnc = l + ea + c + deform + flecha + margemSeguranca;
  var f = zlqAnc - aa;
  if (f < margemSeguranca) f = margemSeguranca;

  return ResultadoFqZlq(
    fq: fq,
    zlqAncoragem: zlqAnc,
    zlqPes: f,
    alerta: alerta,
    valido: true,
  );
}

/// Trava-quedas retrátil.
///
/// [dof] distância de operação de freio (do manual do equipamento).
/// O anel-D desce PQL + DOF (+ deformação); os pés param C abaixo dele.
/// Logo F = PQL + DOF + extras + MS e ZLQ (desde a ancoragem) = F + AA.
ResultadoFqZlq calcularTravaQuedas({
  required double dof,
  required double aa,
  required double c,
  bool incluirDeformacaoCinto = true,
  double flecha = 0.0,
}) {
  final pql = aa < c ? c - aa : 0.0;

  String alerta = '';
  if (pql > 0.01) {
    alerta =
        'ALERTA SEVERO:\nAncoragem abaixo do Anel D. Risco elevado!\nConsulte o manual do trava-quedas. Fabricantes geralmente proíbem o uso com queda livre, exigindo equipamentos Classe B (ou SRD-LE) para trabalho em borda (leading edge).';
  }

  final deform = incluirDeformacaoCinto ? deformacaoCinto : 0.0;
  var f = pql + dof + deform + flecha + margemSeguranca;
  if (f < margemSeguranca) f = margemSeguranca;
  final zlqAnc = f + aa;

  return ResultadoFqZlq(
    fq: pql,
    zlqAncoragem: zlqAnc,
    zlqPes: f,
    alerta: alerta,
    valido: true,
  );
}

/// Formatea pesos chilenos: 1234567 -> $1.234.567 ; -45000 -> -$45.000
String clp(int n) {
  final texto = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) b.write('.');
    b.write(texto[i]);
  }
  return '${n < 0 ? '-' : ''}\$$b';
}

/// AAAA-MM-DD -> DD-MM-AAAA
String fechaCorta(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}-${p[1]}-${p[0]}' : iso;
}

String fechaHora(DateTime d) {
  String dos(int v) => v.toString().padLeft(2, '0');
  return '${dos(d.day)}-${dos(d.month)}-${d.year} ${dos(d.hour)}:${dos(d.minute)}';
}

/// Lee un monto escrito por la persona ("1.500.000", "1500000") como entero.
/// Devuelve null si no hay dígitos.
int? parseMonto(String texto) =>
    int.tryParse(texto.replaceAll(RegExp(r'[^0-9]'), ''));

List<Map<String, String>> parseCsvRows(String csv) {
  final lines = csv
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .toList();

  if (lines.isEmpty) {
    return [];
  }

  final headers = _parseCsvLine(lines.first.replaceFirst('\uFEFF', ''));
  return [
    for (final line in lines.skip(1))
      if (line.trim().isNotEmpty)
        Map<String, String>.fromIterables(headers, _parseCsvLine(line)),
  ];
}

List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  final field = StringBuffer();
  var insideQuotes = false;

  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (character == '"') {
      if (insideQuotes && index + 1 < line.length && line[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        insideQuotes = !insideQuotes;
      }
    } else if (character == ',' && !insideQuotes) {
      fields.add(field.toString().trim());
      field.clear();
    } else {
      field.write(character);
    }
  }

  fields.add(field.toString().trim());
  return fields;
}

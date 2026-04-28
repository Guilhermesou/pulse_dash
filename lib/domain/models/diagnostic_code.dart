enum ErrorSeverity { low, medium, high }

class DiagnosticCode {
  final String code;
  final String description;
  final ErrorSeverity severity;
  final List<String> causes;
  final List<String> suggestions;
  final int confidencePercent;

  DiagnosticCode({
    required this.code,
    required this.description,
    required this.severity,
    required this.causes,
    required this.suggestions,
    required this.confidencePercent,
  });
}

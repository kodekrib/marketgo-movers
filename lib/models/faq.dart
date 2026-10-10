/// A single FAQ entry served by `GET /api/v1/faqs/:target`.
class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
  });

  final int id;
  final String question;
  final String answer;

  factory FaqEntry.fromJson(Map<String, dynamic> json) {
    return FaqEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}
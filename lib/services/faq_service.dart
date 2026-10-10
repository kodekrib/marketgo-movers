import '../models/faq.dart';
import 'api_client.dart';

/// Loads the public FAQ list for the movers app (`/api/v1/faqs/movers`).
class FaqService {
  FaqService({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  /// Fetches FAQs from the backend. Returns an empty list when none are
  /// configured; network/auth errors bubble up to the caller.
  Future<List<FaqEntry>> byTarget(String target) async {
    final data = await api.get('/api/v1/faqs/$target');
    final items = data['faqs'];
    if (items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(FaqEntry.fromJson)
          .toList();
    }
    return const [];
  }
}
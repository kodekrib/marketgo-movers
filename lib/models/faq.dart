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

/// Built-in help content shown when the backend isn't reachable (demo mode).
List<FaqEntry> demoFaqs() {
  return const [
    FaqEntry(
      id: 1,
      question: 'How do I book a move?',
      answer:
          'Tap "Book a move" on the Home tab, choose the vehicle type you need, '
          'then enter your pickup and delivery addresses. Add any packing extras '
          'and submit — a licensed mover will be assigned to your booking.',
    ),
    FaqEntry(
      id: 2,
      question: 'Which vehicle should I pick?',
      answer:
          'Pickup trucks suit a few boxes and small furniture, vans fit a '
          'bedroom, mini trucks cover a one-to-two bedroom apartment, and '
          'lorries handle a full household. Your exact quote is confirmed '
          'when the job is accepted.',
    ),
    FaqEntry(
      id: 3,
      question: 'Can I add packers to my move?',
      answer:
          'Yes. In the booking form you can add optional extra packers. They '
          'help carry, wrap and arrange your items alongside the driver.',
    ),
    FaqEntry(
      id: 4,
      question: 'How do I pay for my move?',
      answer:
          'Once your job is accepted you can tap "Pay now" on the job page and '
          'complete payment securely with Paystack or Flutterwave. The payment '
          'status updates as soon as the transaction is confirmed.',
    ),
    FaqEntry(
      id: 5,
      question: 'Can I track my move?',
      answer:
          'Open the job from "My Moves" or the active move card on the Home tab '
          'to see the current status — from Accepted all the way to Delivered.',
    ),
    FaqEntry(
      id: 6,
      question: 'What if I need to cancel?',
      answer:
          'From the job detail page you can cancel a booking while it is still '
          'pending. Once a mover has been assigned, contact support for help '
          'with your cancellation.',
    ),
  ];
}
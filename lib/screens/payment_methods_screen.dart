import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../services/account_store.dart';
import '../widgets/movers_app_bar.dart';

/// Saved payment methods (stored locally on the device).
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: const MoversAppBar(title: 'Payment methods'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        backgroundColor: MoversApp.brandOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add card'),
      ),
      body: ListenableBuilder(
        listenable: AccountStore.instance,
        builder: (context, _) {
          final cards = AccountStore.instance.cards;
          if (cards.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No saved payment methods yet.\nAdd one to save it on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = cards[index];
              final isDefault = c.isDefault ||
                  (AccountStore.instance.defaultCard?.id == c.id);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAF0EE)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MoversApp.brandOrangeLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.credit_card_rounded,
                          color: MoversApp.brandOrangeDark),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${c.brand} •••• ${c.last4}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              if (isDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: MoversApp.brandOrangeLight,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text('Default',
                                      style: TextStyle(
                                          color: MoversApp.brandOrangeDark,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Expires ${c.expiry}',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (choice) {
                        switch (choice) {
                          case 'default':
                            AccountStore.instance.setDefaultCard(c.id);
                          case 'delete':
                            AccountStore.instance.removeCard(c.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'default', child: Text('Set as default')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CardEditorSheet(),
    );
  }
}

/// Card brands offered when adding a payment method.
const List<String> _cardTypes = [
  'Visa',
  'Mastercard',
  'Verve',
  'American Express',
  'Discover',
];

/// Bottom sheet that collects a new card, with a brand dropdown, a card number
/// grouped as `xxxx xxxx xxxx xxxx`, and an `MM/YY` expiry.
class _CardEditorSheet extends StatefulWidget {
  const _CardEditorSheet();

  @override
  State<_CardEditorSheet> createState() => _CardEditorSheetState();
}

class _CardEditorSheetState extends State<_CardEditorSheet> {
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  String _cardType = _cardTypes.first;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  String get _numberDigits => _numberCtrl.text.replaceAll(RegExp(r'\D'), '');
  String get _expiryDigits => _expiryCtrl.text.replaceAll(RegExp(r'\D'), '');

  void _save() {
    final digits = _numberDigits;
    if (digits.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid 16-digit card number.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final expiryDigits = _expiryDigits;
    final month =
        expiryDigits.length == 4 ? int.parse(expiryDigits.substring(0, 2)) : 0;
    if (expiryDigits.length != 4 || month < 1 || month > 12) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid expiry date in MM/YY format.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    AccountStore.instance.addCard(_cardType, digits, _expiryCtrl.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add payment method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _cardType,
            decoration: const InputDecoration(labelText: 'Card type'),
            items: [
              for (final type in _cardTypes)
                DropdownMenuItem(value: type, child: Text(type)),
            ],
            onChanged: (value) =>
                setState(() => _cardType = value ?? _cardType),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _numberCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            decoration: const InputDecoration(
                labelText: 'Card number', hintText: '•••• •••• •••• ••••'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _expiryCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
              _ExpiryDateFormatter(),
            ],
            decoration:
                const InputDecoration(labelText: 'Expiry', hintText: 'MM/YY'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save card')),
        ],
      ),
    );
  }
}

/// Groups a card number into blocks of four digits (`xxxx xxxx xxxx xxxx`).
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formats a card expiry as `MM/YY` while the user types.
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Pay securely through the payment gateway at checkout. MarketGO does not collect or save your card details.')));
}

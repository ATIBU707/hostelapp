import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading && authProvider.payments == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = authProvider.payments;

        if (payments == null || payments.isEmpty) {
          return const Center(
            child: Text(
              'No payment history found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final paymentDate = DateTime.parse(payment['payment_date']);
            final formattedDate = DateFormat.yMMMd().format(paymentDate);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined, color: Colors.blue),
                title: Text(
                  '₹${payment['amount']} - ${payment['payment_type']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Paid on $formattedDate'),
                trailing: Chip(
                  label: Text(
                    payment['status'] ?? 'Completed',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

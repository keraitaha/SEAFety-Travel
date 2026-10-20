import 'package:flutter/material.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/booking_model.dart';
import '../services/booking_service.dart';

class BookingsScreen extends StatelessWidget {
  final AppUser currentUser;
  const BookingsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final service = BookingService();
    return StreamBuilder<List<BookingModel>>(
      stream: service.agencyBookings(currentUser.userid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load bookings.'));
        }
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const Center(child: Text('No bookings yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (context, i) {
            final b = bookings[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.touristdisplayname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${b.currency} ${b.totalprice.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(label: b.status),
                        const SizedBox(width: 8),
                        _StatusChip(label: b.paymentstatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _changeStatus(context, service, b),
                          child: const Text('Status'),
                        ),
                        TextButton(
                          onPressed: () =>
                              _changePayment(context, service, b),
                          child: const Text('Payment'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _changeStatus(
    BuildContext context,
    BookingService service,
    BookingModel b,
  ) {
    _pickOption(
      context,
      title: 'Update booking status',
      options: const ['pending', 'confirmed', 'cancelled'],
      current: b.status,
      onSelected: (value) async {
        await service.updateStatus(
          bookingid: b.bookingid,
          status: value,
          summary: 'Status changed to $value',
        );
      },
    );
  }

  void _changePayment(
    BuildContext context,
    BookingService service,
    BookingModel b,
  ) {
    _pickOption(
      context,
      title: 'Update payment status',
      options: const ['unpaid', 'partial', 'paid'],
      current: b.paymentstatus,
      onSelected: (value) async {
        await service.updatePaymentStatus(
          bookingid: b.bookingid,
          paymentstatus: value,
          summary: 'Payment changed to $value',
        );
      },
    );
  }

  void _pickOption(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
    required Future<void> Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...options.map(
                (o) => ListTile(
                  title: Text(o),
                  trailing: o == current ? const Icon(Icons.check) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await onSelected(o);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

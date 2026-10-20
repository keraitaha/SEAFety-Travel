import 'package:flutter/material.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/package_model.dart';
import '../../shared/theme/app_theme.dart';
import '../services/package_service.dart';
import 'package_form_screen.dart';

class PackagesScreen extends StatelessWidget {
  final AppUser currentUser;
  const PackagesScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final service = PackageService();
    return Scaffold(
      body: StreamBuilder<List<PackageModel>>(
        stream: service.myPackages(currentUser.userid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load packages.'));
          }
          final packages = snapshot.data ?? [];
          if (packages.isEmpty) {
            return const Center(
              child: Text('No packages yet. Tap + to add one.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: packages.length,
            itemBuilder: (context, i) {
              final p = packages[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: p.imageurl.isEmpty
                      ? const CircleAvatar(child: Icon(Icons.card_travel))
                      : CircleAvatar(
                          backgroundImage: NetworkImage(p.imageurl),
                        ),
                  title: Text(p.title),
                  subtitle: Text(
                    '${p.currency} ${p.price.toStringAsFixed(2)} · '
                    '${p.durationdays} days · ${p.availability}'
                    '${p.published ? "" : " · (draft)"}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PackageFormScreen(
                              currentUser: currentUser,
                              existing: p,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(context, service, p);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PackageFormScreen(currentUser: currentUser),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PackageService service,
    PackageModel p,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete package?'),
        content: Text('This will permanently remove "${p.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await service.deletePackage(p.packageid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'admin_service.dart';

class AdminSubscriptionPage extends StatefulWidget {
  const AdminSubscriptionPage({super.key});

  @override
  State<AdminSubscriptionPage> createState() => _AdminSubscriptionPageState();
}

class _AdminSubscriptionPageState extends State<AdminSubscriptionPage> {
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await AdminService.getSubscriptions();
      setState(() {
        _subscriptions = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscriptions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Subscription')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : ListView.builder(
              itemCount: _subscriptions.length,
              itemBuilder: (context, index) {
                final sub = _subscriptions[index];
                return ListTile(
                  title: Text(sub['user_id']?.toString() ?? 'Unknown User'),
                  subtitle: Text('Status: ${sub['status'] ?? 'N/A'}'),
                  trailing: Text(sub['expiry_date']?.toString() ?? ''),
                );
              },
            ),
    );
  }
}

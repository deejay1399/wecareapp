import 'package:flutter/material.dart';
import 'admin_service.dart';

class AdminSubscriptionPage extends StatefulWidget {
  const AdminSubscriptionPage({super.key});

  @override
  State<AdminSubscriptionPage> createState() => _AdminSubscriptionPageState();
}

class _AdminSubscriptionPageState extends State<AdminSubscriptionPage> {
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _filteredSubscriptions = [];
  bool _isLoading = true;
  String? _error;

  String _selectedCategory = 'All'; // <-- Filter by status
  final Color mainRed = const Color(0xFFD32F2F); // Main red color

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
        _applyFilter(); // Apply filter automatically
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscriptions: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedCategory == 'All') {
      _filteredSubscriptions = _subscriptions;
    } else {
      _filteredSubscriptions = _subscriptions.where((sub) {
        final status = (sub['status'] ?? '').toString().toLowerCase();
        return status == _selectedCategory.toLowerCase();
      }).toList();
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '—';
    try {
      final parsed = DateTime.parse(date);
      return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return date;
    }
  }

  Widget _buildFilterButtons() {
    final categories = ['All', 'Paid', 'Pending', 'Failed'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? mainRed : Colors.white,
              foregroundColor: isSelected ? Colors.white : mainRed,
              side: BorderSide(color: mainRed, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              setState(() {
                _selectedCategory = cat;
                _applyFilter();
              });
            },
            child: Text(
              cat,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No ${_selectedCategory == 'All' ? 'subscriptions' : _selectedCategory.toLowerCase()} items found.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try refreshing or checking another category.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: mainRed,
        title: const Text(
          'Admin Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchSubscriptions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          : _subscriptions.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildFilterButtons(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchSubscriptions,
                    color: mainRed,
                    child: _filteredSubscriptions.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: _buildEmptyState(),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredSubscriptions.length,
                            itemBuilder: (context, index) {
                              final sub = _filteredSubscriptions[index];
                              final status =
                                  sub['status']?.toString() ?? 'Unknown';
                              final planName = sub['plan_name'] ?? 'N/A';
                              final expiryDate = _formatDate(
                                sub['expiry_date'],
                              );
                              final userId = sub['user_id'] ?? 'Unknown';
                              final amount =
                                  sub['amount']?.toString() ?? '0.00';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(
                                      status,
                                    ).withOpacity(0.2),
                                    child: Icon(
                                      Icons.person,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                  title: Text(
                                    planName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Text(
                                        'User: $userId',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Amount: ₱$amount',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Expiry: $expiryDate',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getStatusColor(status),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBlockUsersPage extends StatefulWidget {
  const AdminBlockUsersPage({super.key});

  @override
  State<AdminBlockUsersPage> createState() => _AdminBlockUsersPageState();
}

class _AdminBlockUsersPageState extends State<AdminBlockUsersPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  String _selectedCategory = 'All';
  final Color mainRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch helpers
      final helpersResponse = await supabase
          .from('helpers')
          .select('id, first_name, last_name, email, barangay, is_allowed')
          .order('created_at', ascending: false);

      // Fetch employers
      final employersResponse = await supabase
          .from('employers')
          .select('id, first_name, last_name, email, barangay, is_allowed')
          .order('created_at', ascending: false);

      // Combine both lists with a type indicator
      final allUsers = <Map<String, dynamic>>[];

      for (var helper in helpersResponse) {
        helper['user_type'] = 'Helper';
        allUsers.add(helper);
      }

      for (var employer in employersResponse) {
        employer['user_type'] = 'Employer';
        allUsers.add(employer);
      }

      setState(() {
        _users = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBlockUser(
    String userId,
    String userType,
    bool currentlyAllowed,
  ) async {
    try {
      final table = userType == 'Helper' ? 'helpers' : 'employers';
      final newAllowedStatus = !currentlyAllowed;

      await supabase
          .from(table)
          .update({'is_allowed': newAllowedStatus})
          .eq('id', userId);

      // Refresh the list
      _fetchUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newAllowedStatus
                  ? 'User unblocked successfully'
                  : 'User blocked successfully',
            ),
            backgroundColor: newAllowedStatus ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    if (_selectedCategory == 'All') {
      return _users;
    } else {
      return _users
          .where((user) => user['user_type'] == _selectedCategory)
          .toList();
    }
  }

  Widget _buildFilterButtons() {
    final categories = ['All', 'Helper', 'Employer'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (isSelected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: _getColorForCategory(category),
                  backgroundColor: _getColorForCategory(
                    category,
                  ).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _selectedCategory == category
                        ? Colors.white
                        : _getColorForCategory(category),
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _getColorForCategory(category),
                    width: _selectedCategory == category ? 0 : 1,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    if (category == 'Helper') {
      return Colors.orange;
    } else if (category == 'Employer') {
      return Colors.blue;
    }
    return mainRed;
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? 'N/A';
    final lastName = user['last_name'] ?? 'N/A';
    final email = user['email'] ?? 'N/A';
    final barangay = user['barangay'] ?? 'N/A';
    final userType = user['user_type'] ?? 'N/A';
    final isAllowed = user['is_allowed'] ?? true;

    final cardColor = userType == 'Helper' ? Colors.orange : Colors.blue;
    final borderColor = !isAllowed
        ? cardColor.withOpacity(0.5)
        : Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: !isAllowed ? cardColor.withOpacity(0.1) : Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userType,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cardColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAllowed
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAllowed ? 'ALLOWED' : 'BLOCKED',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // User details
            _buildDetailRow('Email', email),
            const SizedBox(height: 8),
            _buildDetailRow('Barangay', barangay),
            const SizedBox(height: 16),
            // Action button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isAllowed ? Colors.red : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _toggleBlockUser(user['id'], userType, isAllowed);
                },
                child: Text(
                  isAllowed ? 'Block User' : 'Unblock User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Users'),
        backgroundColor: mainRed,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _fetchUsers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filter buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildFilterButtons(),
                ),
                // User count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Found ${filteredUsers.length} user${filteredUsers.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // User list
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No users found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(filteredUsers[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDocumentsPage extends StatefulWidget {
  const AdminDocumentsPage({super.key});

  @override
  State<AdminDocumentsPage> createState() => _AdminDocumentsPageState();
}

class _AdminDocumentsPageState extends State<AdminDocumentsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _helpers = [];
  List<Map<String, dynamic>> _employers = [];
  bool _isLoading = true;
  String? _error;

  String _selectedCategory = 'All';
  final Color mainRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final helpersResponse = await supabase
          .from('helpers')
          .select('id, first_name, last_name, barangay_clearance_base64')
          .order('created_at', ascending: false);

      final employersResponse = await supabase
          .from('employers')
          .select('id, first_name, last_name, barangay_clearance_base64')
          .order('created_at', ascending: false);

      setState(() {
        _helpers = List<Map<String, dynamic>>.from(helpersResponse);
        _employers = List<Map<String, dynamic>>.from(employersResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load barangay clearances: $e';
        _isLoading = false;
      });
    }
  }

  void _showFullImage(Uint8List imageBytes, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarangayClearancePreview(
          imageBytes: imageBytes,
          name: name,
          mainRed: mainRed,
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    final categories = ['All', 'Employer', 'Helper'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? mainRed : Colors.white,
                  foregroundColor: isSelected ? Colors.white : mainRed,
                  side: BorderSide(color: mainRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Text(
                  cat,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> person, String role) {
    final firstName = person['first_name'] ?? '';
    final lastName = person['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final base64File = person['barangay_clearance_base64'];

    Uint8List? imageBytes;
    String? imageUrl;
    if (base64File != null && base64File.toString().isNotEmpty) {
      final val = base64File.toString();
      if (val.startsWith('http://') || val.startsWith('https://')) {
        imageUrl = val;
      } else {
        try {
          imageBytes = base64Decode(val);
        } catch (_) {}
      }
    }

    return GestureDetector(
      onTap: () {
        if (imageBytes != null) {
          _showFullImage(imageBytes, fullName);
        } else if (imageUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarangayClearancePreviewNetwork(
                imageUrl: imageUrl!,
                name: fullName,
                mainRed: mainRed,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No clearance file available for this person.'),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image Preview
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : (imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          )),
            ),

            // 📄 Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : 'Unknown $role',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$role Barangay Clearance',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: mainRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.visibility, color: mainRed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_rounded, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No barangay clearances found.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter data based on selection
    List<Map<String, dynamic>> displayedList = [];
    if (_selectedCategory == 'Helper') {
      displayedList = _helpers;
    } else if (_selectedCategory == 'Employer') {
      displayedList = _employers;
    } else {
      displayedList = [..._helpers, ..._employers];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: mainRed,
        title: const Text(
          'Barangay Clearances',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDocuments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : Column(
              children: [
                _buildFilterButtons(),
                Expanded(
                  child: RefreshIndicator(
                    color: mainRed,
                    onRefresh: _fetchDocuments,
                    child: displayedList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayedList.length,
                            itemBuilder: (context, index) {
                              final item = displayedList[index];
                              final role = _helpers.contains(item)
                                  ? 'Helper'
                                  : 'Employer';
                              return _buildCard(item, role);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

// 🔍 Preview Page
class BarangayClearancePreview extends StatelessWidget {
  final Uint8List imageBytes;
  final String name;
  final Color mainRed;

  const BarangayClearancePreview({
    super.key,
    required this.imageBytes,
    required this.name,
    required this.mainRed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: mainRed,
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 5,
          child: Image.memory(imageBytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// Network variant for previewing images by URL
class BarangayClearancePreviewNetwork extends StatelessWidget {
  final String imageUrl;
  final String name;
  final Color mainRed;

  const BarangayClearancePreviewNetwork({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.mainRed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: mainRed,
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

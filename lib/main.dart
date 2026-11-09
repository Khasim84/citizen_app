import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CivicConnectApp());
}

// --------------------------------------------------
// APP THEME
// --------------------------------------------------

const Color primaryBlue = Color(0xFF245BDB);
const Color darkBlue = Color(0xFF173B82);
const Color backgroundColor = Color(0xFFF5F7FC);
const Color textColor = Color(0xFF202B3C);
const Color greenColor = Color(0xFF159B70);

class CivicConnectApp extends StatelessWidget {
  const CivicConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CivicConnect',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E5EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E5EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primaryBlue,
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const MainNavigation(),
      onGenerateRoute: (settings) {
        if (settings.name == '/register') {
          return MaterialPageRoute(
            builder: (_) => const RegisterComplaintScreen(),
          );
        }

        if (settings.name == '/details') {
          final complaint = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (_) => ComplaintDetailsScreen(
              complaint: complaint,
            ),
          );
        }

        return null;
      },
    );
  }
}

// --------------------------------------------------
// MAIN NAVIGATION
// --------------------------------------------------

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final List<Map<String, dynamic>> complaints = [];
  static const String _complaintsKey = 'civicconnect_complaints';
  bool _isLoadingComplaints = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_complaintsKey);
      if (savedData != null) {
        final decoded = jsonDecode(savedData) as List<dynamic>;
        complaints
          ..clear()
          ..addAll(
            decoded.map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          );
      }
    } catch (e) {
      debugPrint('Could not load saved complaints: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingComplaints = false;
        });
      }
    }
  }

  Future<void> _saveComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_complaintsKey, jsonEncode(complaints));
    } catch (e) {
      debugPrint('Could not save complaints: $e');
    }
  }

  Future<void> openRegistration() async {
    final result = await Navigator.pushNamed(
      context,
      '/register',
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        complaints.insert(0, result);
        selectedIndex = 1;
      });
      await _saveComplaints();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint registered successfully!'),
          backgroundColor: greenColor,
        ),
      );
    }
  }

  Future<void> openDetails(
    Map<String, dynamic> complaint,
  ) async {
    // Passing complaint information through route arguments.
    final result = await Navigator.pushNamed(
      context,
      '/details',
      arguments: Map<String, dynamic>.from(complaint),
    );

    if (result is Map<String, dynamic>) {
      setState(() {
        if (result['deleted'] == true) {
          complaints.removeWhere(
            (item) => item['id'] == result['id'],
          );
        } else {
          final index = complaints.indexWhere(
            (item) => item['id'] == result['id'],
          );

          if (index != -1) {
            complaints[index] = result;
          }
        }
      });
      await _saveComplaints();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        complaints: complaints,
        onRegister: openRegistration,
        onViewComplaints: () {
          setState(() => selectedIndex = 1);
        },
      ),
      MyComplaintsScreen(
        complaints: complaints,
        onComplaintTap: openDetails,
        isLoading: _isLoadingComplaints,
      ),
      const SizedBox.shrink(),
      const HelpScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex == 2
            ? 0
            : selectedIndex == 3
                ? 2
                : selectedIndex,
        children: [
          pages[0],
          pages[1],
          pages[3],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            openRegistration();
          } else {
            setState(() {
              selectedIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Help',
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// HOME SCREEN
// --------------------------------------------------

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> complaints;
  final VoidCallback onRegister;
  final VoidCallback onViewComplaints;

  const HomeScreen({
    super.key,
    required this.complaints,
    required this.onRegister,
    required this.onViewComplaints,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = complaints.where((c) => c['status'] == 'Resolved').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.location_city,
              color: primaryBlue,
              size: 28,
            ),
            const SizedBox(width: 9),
            const Text(
              'CivicConnect',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Your Voice, Your City.',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Report civic issues and help build a better community.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 25),

              // Welcome banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_city,
                      color: Colors.white,
                      size: 42,
                    ),
                    SizedBox(height: 17),
                    Text(
                      'Make a Difference Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Report roads, water, electricity and sanitation issues.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'Report Issue',
                      color: primaryBlue,
                      onTap: onRegister,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.assignment_outlined,
                      title: 'My Complaints',
                      color: greenColor,
                      onTap: onViewComplaints,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                'Complaint Overview',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _OverviewCard(
                      title: 'Total',
                      value: complaints.length.toString(),
                      icon: Icons.description_outlined,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewCard(
                      title: 'Resolved',
                      value: resolved.toString(),
                      icon: Icons.check_circle_outline,
                      color: greenColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.public,
                      color: primaryBlue,
                      size: 32,
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SDG 16',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Peace, Justice and Strong Institutions',
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// HOME REUSABLE WIDGETS
// --------------------------------------------------

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 21,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EAF2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 31, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// REGISTER COMPLAINT SCREEN
// --------------------------------------------------

class RegisterComplaintScreen extends StatefulWidget {
  const RegisterComplaintScreen({super.key});

  @override
  State<RegisterComplaintScreen> createState() =>
      _RegisterComplaintScreenState();
}

class _RegisterComplaintScreenState extends State<RegisterComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = 'Roads';

  final List<String> categories = [
    'Roads',
    'Water Supply',
    'Sanitation',
    'Electricity',
    'Public Safety',
    'Other',
  ];

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void submitComplaint() {
    if (!_formKey.currentState!.validate()) return;

    final complaint = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': nameController.text.trim(),
      'title': titleController.text.trim(),
      'category': category,
      'location': locationController.text.trim(),
      'description': descriptionController.text.trim(),
      'status': 'Pending',
      'date': DateTime.now().toString().substring(0, 16),
    };

    Navigator.pop(context, complaint);
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: label,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register a Complaint',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report a Civic Issue',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Provide the details below to register your complaint.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Citizen Name',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _field(
                  label: 'Enter your name',
                  controller: nameController,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Complaint Title',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _field(
                  label: 'Enter complaint title',
                  controller: titleController,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(),
                  items: categories.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _field(
                  label: 'Enter complaint location',
                  controller: locationController,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _field(
                  label: 'Describe the issue',
                  controller: descriptionController,
                  maxLines: 5,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: submitComplaint,
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Submit Complaint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// MY COMPLAINTS SCREEN
// --------------------------------------------------

class MyComplaintsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> complaints;
  final Function(Map<String, dynamic>) onComplaintTap;
  final bool isLoading;

  const MyComplaintsScreen({
    super.key,
    required this.complaints,
    required this.onComplaintTap,
    required this.isLoading,
  });

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  final searchController = TextEditingController();

  String selectedCategory = 'All Categories';
  String? selectedStatus;

  final List<String> categories = [
    'All Categories',
    'Roads',
    'Water Supply',
    'Sanitation',
    'Electricity',
    'Public Safety',
    'Other',
  ];

  final List<String> statusOptions = [
    'Pending',
    'In Progress',
    'Resolved',
  ];

  List<Map<String, dynamic>> get filteredComplaints {
    return widget.complaints.where((complaint) {
      final search = searchController.text.toLowerCase();

      final matchesSearch =
          complaint['title'].toString().toLowerCase().contains(search) ||
              complaint['name'].toString().toLowerCase().contains(search) ||
              complaint['location'].toString().toLowerCase().contains(search);

      final matchesCategory = selectedCategory == 'All Categories' ||
          complaint['category'] == selectedCategory;

      final matchesStatus =
          selectedStatus == null || complaint['status'] == selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return greenColor;
      case 'In Progress':
        return Colors.orange.shade700;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredComplaints;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Complaints',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search title, name or location',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                          ),
                          items: categories.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedStatus,
                          hint: const Text('Select status'),
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                          ),
                          items: statusOptions.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 75,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No complaints found',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Your registered complaints will appear here.',
                                style: TextStyle(color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final complaint = filtered[index];
                            final status = complaint['status'].toString();

                            return Card(
                              elevation: 0,
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0xFFE6EAF2),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 9,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE9EFFF),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    color: primaryBlue,
                                  ),
                                ),
                                title: Text(
                                  complaint['title'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        complaint['category'].toString(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor(status),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  widget.onComplaintTap(complaint);
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// COMPLAINT DETAILS SCREEN
// --------------------------------------------------

class ComplaintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaint,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late String status;

  @override
  void initState() {
    super.initState();
    status = widget.complaint['status'] ?? 'Pending';
  }

  Widget detailCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: primaryBlue),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void saveStatus() {
    final updated = Map<String, dynamic>.from(widget.complaint);
    updated['status'] = status;

    Navigator.pop(context, updated);
  }

  void deleteComplaint() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Complaint?'),
          content: const Text(
            'Are you sure you want to delete this complaint?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pop(context, {
                  'deleted': true,
                  'id': widget.complaint['id'],
                });
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complaint Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complaint Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              detailCard(
                'Citizen Name',
                c['name'].toString(),
                Icons.person_outline,
              ),
              detailCard(
                'Complaint Title',
                c['title'].toString(),
                Icons.title,
              ),
              detailCard(
                'Category',
                c['category'].toString(),
                Icons.category_outlined,
              ),
              detailCard(
                'Location',
                c['location'].toString(),
                Icons.location_on_outlined,
              ),
              detailCard(
                'Description',
                c['description'].toString(),
                Icons.description_outlined,
              ),
              detailCard(
                'Date Registered',
                c['date'].toString(),
                Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6EAF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Complaint Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 13),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'In Progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'Resolved',
                          child: Text('Resolved'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Status'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: deleteComplaint,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Delete Complaint',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// HELP AND ABOUT SCREEN
// --------------------------------------------------

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Widget helpItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE9EFFF),
            child: Icon(icon, color: primaryBlue),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & About',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, darkBlue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.location_city,
                      size: 52,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'CivicConnect',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your Voice, Your City.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'How to Use the App',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              helpItem(
                Icons.add_circle_outline,
                'Register a Complaint',
                'Open the Report section and enter the complaint details. Submit the form to register your issue.',
              ),
              helpItem(
                Icons.assignment_outlined,
                'View My Complaints',
                'Visit My Complaints to view, search and filter your registered complaints.',
              ),
              helpItem(
                Icons.track_changes,
                'Track Complaint Status',
                'Select a complaint to view its details and check or update its current status.',
              ),
              const SizedBox(height: 15),
              const Text(
                'About the Project',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'CivicConnect is a citizen grievance application developed using Flutter. It allows citizens to register and manage civic complaints through a simple mobile interface.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SDG 16',
                      style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Peace, Justice and Strong Institutions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The application supports citizen participation and accountability by providing a platform to report and manage civic grievances.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Center(
                child: Text(
                  'CivicConnect • Made for Better Communities',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tution_management_app/constants/colors.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTeachersWithIncome();
    _searchController.addListener(_filterTeachers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachersWithIncome() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final teachersQuery =
          await _firestore
              .collection('teachers')
              .where('role', isEqualTo: 'teacher')
              .get();

      if (teachersQuery.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _teachers = [];
          _filteredTeachers = [];
        });
        return;
      }

      final Map<String, String> subjectToTeacherMap = {};
      final List<Map<String, dynamic>> teachers = [];

      for (var doc in teachersQuery.docs) {
        final data = doc.data();
        final subjects = List<String>.from(data['subjects'] ?? []);
        final teacher = {
          'uid': doc.id,
          'firstName': data['firstName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'subjects': subjects,
          'classes': List<String>.from(data['classes'] ?? []),
          'monthlyIncome': 0.0,
          'subjectEarnings': <String, double>{},
        };
        teachers.add(teacher);

        for (var subject in subjects) {
          subjectToTeacherMap[subject] = doc.id;
        }
      }

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final paymentsQuery =
          await _firestore
              .collection('payments')
              .where('paymentDate', isGreaterThanOrEqualTo: firstDayOfMonth)
              .get();

      for (var paymentDoc in paymentsQuery.docs) {
        final paymentData = paymentDoc.data();
        final subjectFees = paymentData['subjectFees'] as List<dynamic>? ?? [];

        for (var sf in subjectFees) {
          final subject = sf['subject'] as String;
          final fee = (sf['fee'] as num).toDouble();
          final teacherId = subjectToTeacherMap[subject];

          if (teacherId != null) {
            final teacher = teachers.firstWhere((t) => t['uid'] == teacherId);
            teacher['monthlyIncome'] += fee;
            teacher['subjectEarnings'][subject] =
                (teacher['subjectEarnings'][subject] ?? 0.0) + fee;
          }
        }
      }

      setState(() {
        _teachers = teachers;
        _filteredTeachers = List.from(teachers);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  void _filterTeachers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTeachers =
          _teachers.where((teacher) {
            final fullName =
                '${teacher['firstName']} ${teacher['lastName']}'.toLowerCase();
            final email = teacher['email'].toString().toLowerCase();
            return fullName.contains(query) || email.contains(query);
          }).toList();
    });
  }

  Future<void> _refreshData() async {
    await _fetchTeachersWithIncome();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'LKR ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: sbtnColor,
        title: const Text('Teachers', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredTeachers.isEmpty
                          ? Center(
                            child:
                                _teachers.isEmpty
                                    ? const Text('No teachers available')
                                    : const Text('No matching teachers found'),
                          )
                          : ListView.builder(
                            itemCount: _filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _filteredTeachers[index];
                              return _TeacherCard(
                                teacher: teacher,
                                currencyFormat: currencyFormat,
                              );
                            },
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(height: 10, color: sbtnColor),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final NumberFormat currencyFormat;

  const _TeacherCard({required this.teacher, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text('${teacher['firstName']} ${teacher['lastName']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacher['email'] ?? ''),
            const SizedBox(height: 4),
            Text(
              'Total Income: ${currencyFormat.format(teacher['monthlyIncome'] ?? 0.0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.remove_red_eye_outlined),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDetailsPage(teacher: teacher),
            ),
          );
        },
      ),
    );
  }
}

class TeacherDetailsPage extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TeacherDetailsPage({super.key, required this.teacher});

  Future<Map<String, double>> _getSubjectEarnings() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final paymentsQuery =
          await _firestore
              .collection('payments')
              .where('paymentDate', isGreaterThanOrEqualTo: firstDayOfMonth)
              .get();

      final Map<String, double> subjectEarnings = {};
      final subjects = List<String>.from(teacher['subjects'] ?? []);

      for (var paymentDoc in paymentsQuery.docs) {
        final paymentData = paymentDoc.data();
        final subjectFees = paymentData['subjectFees'] as List<dynamic>? ?? [];

        for (var sf in subjectFees) {
          final subject = sf['subject'] as String;
          if (subjects.contains(subject)) {
            final fee = (sf['fee'] as num).toDouble();
            subjectEarnings[subject] = (subjectEarnings[subject] ?? 0.0) + fee;
          }
        }
      }

      return subjectEarnings;
    } catch (e) {
      debugPrint('Error getting subject earnings: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'LKR ');

    return Scaffold(
      appBar: AppBar(
        title: Text('${teacher['firstName']} ${teacher['lastName']}'),
        backgroundColor: sbtnColor,
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _getSubjectEarnings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final subjectEarnings = snapshot.data ?? {};
          final totalIncome = subjectEarnings.values.fold(0.0, (a, b) => a + b);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailItem('Email', teacher['email'] ?? 'Not provided'),
                _DetailItem('Phone', teacher['phone'] ?? 'Not provided'),
                const SizedBox(height: 20),
                const Text(
                  'Subject Earnings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: subjectEarnings.length,
                    itemBuilder: (context, index) {
                      final subject = subjectEarnings.keys.elementAt(index);
                      final earnings = subjectEarnings[subject] ?? 0.0;
                      return ListTile(
                        title: Text(subject),
                        trailing: Text(currencyFormat.format(earnings)),
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Monthly Income:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currencyFormat.format(totalIncome),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
          const Divider(),
        ],
      ),
    );
  }
}

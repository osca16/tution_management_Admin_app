import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _studentNumberController =
      TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<String> _selectedClasses = [];
  Map<String, dynamic>? _studentData;
  double _totalPayable = 0.0;
  bool _isLoading = false;
  String _searchError = '';
  Map<String, double> _subjectFees = {};
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSubjectFees();
  }

  @override
  void dispose() {
    _studentNumberController.dispose();
    _parentEmailController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjectFees() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('teachers').get();
      final fees = <String, double>{};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['subject'] != null && data['feePerSubject'] != null) {
          final feeValue = data['feePerSubject'];
          final fee =
              feeValue is String
                  ? double.tryParse(feeValue) ?? 0.0
                  : (feeValue as num).toDouble();

          if (data['subject'] is String && fee > 0) {
            fees[data['subject']] = fee;
          }
        }
      }

      setState(() {
        _subjectFees = fees;
      });
    } catch (e) {
      debugPrint('Error loading subject fees: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load subject fees.')),
      );
    }
  }

  Future<void> _loadPaymentHistory(String studentNumber) async {
    try {
      setState(() => _isLoading = true);

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('payments')
              .where('studentNumber', isEqualTo: studentNumber)
              .orderBy('createdAt', descending: true)
              .limit(20)
              .get();

      List<Map<String, dynamic>> history =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'studentNumber': data['studentNumber'],
              'studentName': data['studentName'],
              'month': data['month'],
              'amount': data['amount'],
              'paymentDate': data['createdAt'],
              'subjects': data['classes'],
              'subjectFees': data['subjectFees'],
            };
          }).toList();

      setState(() => _paymentHistory = history);
    } catch (e) {
      debugPrint('Error loading payment history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load payment history.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchStudent() async {
    if (!_validateStudentNumber()) return;

    setState(() {
      _isLoading = true;
      _searchError = '';
      _studentData = null;
      _selectedClasses = [];
      _totalPayable = 0.0;
      _paymentHistory = [];
    });

    try {
      final studentQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where(
                'studentNumber',
                isEqualTo: _studentNumberController.text.trim(),
              )
              .where('role', isEqualTo: 'student')
              .limit(1)
              .get();

      if (studentQuery.docs.isEmpty) {
        setState(() => _searchError = 'Student not found.');
        return;
      }

      final studentDoc = studentQuery.docs.first;
      final studentData = studentDoc.data();

      setState(() {
        _studentData = {
          ...studentData,
          'docId': studentDoc.id,
          'subjects': studentData['subjects'] ?? [],
        };
        _selectedClasses = List<String>.from(_studentData!['subjects']);
        _calculateTotal();
      });

      await _loadPaymentHistory(_studentNumberController.text.trim());
    } catch (e) {
      setState(() => _searchError = 'Error: ${e.toString()}');
      debugPrint('Error searching student: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateStudentNumber() {
    if (_studentNumberController.text.isEmpty) {
      setState(() => _searchError = 'Please enter a student number.');
      return false;
    }
    return true;
  }

  void _calculateTotal() {
    if (_studentData == null || _selectedClasses.isEmpty) {
      setState(() => _totalPayable = 0.0);
      return;
    }

    double total = 0.0;
    for (var classItem in _selectedClasses) {
      total += _subjectFees[classItem] ?? 0.0;
    }

    setState(() => _totalPayable = total);
  }

  void _toggleClass(String classItem) {
    setState(() {
      if (_selectedClasses.contains(classItem)) {
        _selectedClasses.remove(classItem);
      } else {
        _selectedClasses.add(classItem);
      }
      _calculateTotal();
    });
  }

  Future<void> _addNewClassToStudent() async {
    if (_studentData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No student data found.')));
      return;
    }

    final studentId = _studentData!['docId'];
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student document missing ID.')),
      );
      return;
    }

    final studentDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(studentId);

    try {
      final doc = await studentDocRef.get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student document not found.')),
        );
        return;
      }

      final availableSubjects = _subjectFees.keys.toList();
      final currentSubjects = List<String>.from(
        _studentData!['subjects'] ?? [],
      );
      final newSubjects =
          availableSubjects.where((s) => !currentSubjects.contains(s)).toList();

      if (newSubjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new classes available to add.')),
        );
        return;
      }

      final newClass = await showDialog<String>(
        context: context,
        builder: (context) {
          String? selectedSubject;
          return AlertDialog(
            title: const Text('Add New Class'),
            content: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(),
              ),
              items:
                  newSubjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
              onChanged: (value) => selectedSubject = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selectedSubject),
                child: const Text('Add'),
              ),
            ],
          );
        },
      );

      if (newClass != null && newClass.isNotEmpty) {
        setState(() => _isLoading = true);

        await studentDocRef.update({
          'subjects': FieldValue.arrayUnion([newClass]),
        });

        setState(() {
          _studentData!['subjects'] = [...currentSubjects, newClass];
          _selectedClasses.add(newClass);
          _calculateTotal();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class added successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding class: ${e.toString()}')),
      );
      debugPrint('Error adding class: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndGenerateReceipt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClasses.isEmpty) {
      setState(() => _searchError = 'Please select at least one class.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Payment'),
            content: Text(
              'Confirm payment of LKR ${_totalPayable.toStringAsFixed(2)} '
              'for ${_getStudentName()} for ${_monthController.text}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _generateReceipt();
    }
  }

  Future<void> _generateReceipt() async {
    setState(() => _isLoading = true);

    try {
      final paymentData = {
        'studentId': _studentData!['docId'],
        'studentNumber': _studentNumberController.text.trim(),
        'studentName': _getStudentName(),
        'studentEmail': _studentData!['email'] ?? '',
        'parentEmail': _parentEmailController.text.trim(),
        'classes': _selectedClasses,
        'month': _monthController.text.trim(),
        'amount': _totalPayable,
        'subjectFees':
            _selectedClasses
                .map((c) => {'subject': c, 'fee': _subjectFees[c] ?? 0})
                .toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      };

      await FirebaseFirestore.instance.collection('payments').add(paymentData);

      await _loadPaymentHistory(_studentNumberController.text.trim());

      final phoneNumber = _studentData!['contact']?.toString() ?? '';
      if (phoneNumber.isNotEmpty) {
        await _sendPaymentSMS(phoneNumber, _monthController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully!')),
      );

      _parentEmailController.clear();
      _monthController.clear();
      setState(() {
        _selectedClasses = [];
        _totalPayable = 0.0;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPaymentSMS(String phoneNumber, String month) async {
    // Format phone number (Sri Lanka example)
    if (!phoneNumber.startsWith('+94')) {
      phoneNumber = '+94${phoneNumber.replaceAll(RegExp(r'^0'), '')}';
    }

    final message =
        'Payment completed for $month. Student Number: ${_studentNumberController.text}. '
        'Amount: LKR ${_totalPayable.toStringAsFixed(2)}. Thank you!';

    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No SMS app found. Please install one.'),
          ),
        );
      }
    } catch (e) {
      if (e is PlatformException) {
        switch (e.code) {
          case 'ACTIVITY_NOT_FOUND':
            debugPrint('No SMS app installed');
            break;
          case 'INVALID_URL':
            debugPrint('Malformed phone number');
            break;
          default:
            debugPrint('Unknown error: ${e.message}');
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch SMS: ${e.toString()}')),
      );
    }
  }

  void _sendSMS() async {
    // Validate phone number
    if (_studentData?['contact']?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available')),
      );
      return;
    }

    // Validate message content
    if (_totalPayable <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid payment amount')));
      return;
    }

    await _sendPaymentSMS(
      _studentData!['contact'].toString(),
      _monthController.text,
    );
  }

  String _getStudentName() {
    if (_studentData == null) return 'No student data';
    final data = _studentData!;
    if (data['name'] != null) return data['name'];
    if (data['fullName'] != null) return data['fullName'];
    if (data['studentName'] != null) return data['studentName'];
    if (data['firstName'] != null) {
      return '${data['firstName']} ${data['lastName'] ?? ''}'.trim();
    }
    return 'Student ${_studentNumberController.text}';
  }

  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment) {
    final paymentDate = (payment['paymentDate'] as Timestamp).toDate();
    final formattedDate = DateFormat(
      'yyyy-MM-dd – hh:mm a',
    ).format(paymentDate);
    final amount = (payment['amount'] as num).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paid on: $formattedDate',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                'LKR $amount',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              backgroundColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _studentNumberController,
                decoration: InputDecoration(
                  hintText: 'e.g. 0001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _searchStudent,
              child: const Text('Search'),
            ),
          ],
        ),
        if (_searchError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_searchError, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _buildStudentDetailsSection() {
    if (_studentData == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Student Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    _getStudentName(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Grade', _studentData!['grade'] ?? 'N/A'),
              _buildDetailRow('Email', _studentData!['email'] ?? 'N/A'),
              _buildDetailRow('Contact', _studentData!['contact'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Total Payable',
                'LKR ${_totalPayable.toStringAsFixed(2)}',
                isAmount: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentFormSection() {
    if (_studentData == null) return const SizedBox();

    final studentSubjects =
        _studentData?['subjects'] is List
            ? List<String>.from(_studentData!['subjects'] ?? [])
            : [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Parent Email (for receipt)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _parentEmailController,
            decoration: InputDecoration(
              hintText: 'parent@example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter parent email.';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Month',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _monthController,
            decoration: InputDecoration(
              hintText: 'MM/YYYY',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: const Icon(Icons.calendar_month),
            ),
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a month.';
              }
              return null;
            },
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                _monthController.text =
                    "${picked.month.toString().padLeft(2, '0')}/${picked.year}";
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Classes (${studentSubjects.length} enrolled)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_subjectFees.length} available',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (studentSubjects.isEmpty)
            const Text('No enrolled classes found for this student.')
          else
            Column(
              children: [
                ...studentSubjects.map((subject) {
                  final fee = _subjectFees[subject] ?? 0;
                  return CheckboxListTile(
                    title: Text('$subject (LKR ${fee.toStringAsFixed(2)})'),
                    value: _selectedClasses.contains(subject),
                    onChanged: (value) => _toggleClass(subject),
                    secondary: const Icon(Icons.school),
                  );
                }),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Class'),
                  onPressed: _isLoading ? null : _addNewClassToStudent,
                ),
              ],
            ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B03AC),
                minimumSize: const Size(200, 50),
              ),
              onPressed: _isLoading ? null : _confirmAndGenerateReceipt,
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'GENERATE RECEIPT',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    if (_studentData == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Payment History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_paymentHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('No payment history found for this student.'),
            ),
          )
        else
          Column(
            children: _paymentHistory.map(_buildPaymentHistoryItem).toList(),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                color: isAmount ? Colors.green : null,
              ),
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
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3B03AC),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentSearchSection(),
                _buildStudentDetailsSection(),
                _buildPaymentHistorySection(),
                _buildPaymentFormSection(),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

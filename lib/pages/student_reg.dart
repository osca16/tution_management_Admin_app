import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard.dart';

void main() {
  runApp(StudentRegistrationApp());
}

class StudentRegistrationApp extends StatelessWidget {
  const StudentRegistrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StudentRegistrationForm(),
    );
  }
}

class StudentRegistrationForm extends StatefulWidget {
  const StudentRegistrationForm({super.key});

  @override
  _StudentRegistrationFormState createState() =>
      _StudentRegistrationFormState();
}

class _StudentRegistrationFormState extends State<StudentRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _studentNumberController =
      TextEditingController();

  String? selectedGender;
  String? selectedGrade;
  List<Map<String, String>> subjectsWithTeachers =
      []; // Stores subject-teacher pairs
  String? selectedSubject;
  String? selectedTeacher;
  List<String> availableTeachers = [];
  bool _isLoading = false;
  bool _loadingTeachers = false;

  final List<String> availableSubjects = [
    "Maths",
    "Science",
    "English",
    "History",
    "Sinhala",
    "ICT",
    "English Literature",
    "Tamil",
    "Commerce",
    "Dancing",
    "Music",
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _schoolController.dispose();
    _guardianController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachersForSubject(String subject) async {
    setState(() => _loadingTeachers = true);
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('teachers')
              .where('role', isEqualTo: 'teacher')
              .where('subject', isEqualTo: subject)
              .get();

      setState(() {
        availableTeachers =
            querySnapshot.docs
                .map((doc) => "${doc['firstName']} ${doc['lastName']}")
                .toList();
        if (availableTeachers.isNotEmpty) {
          selectedTeacher = availableTeachers.first;
        } else {
          selectedTeacher = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading teachers: $e')));
    } finally {
      setState(() => _loadingTeachers = false);
    }
  }

  Future<void> _registerStudent() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    if (subjectsWithTeachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one subject')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'school': _schoolController.text.trim(),
            'guardian': _guardianController.text.trim(),
            'contact': _contactController.text.trim(),
            'email': _emailController.text.trim(),
            'studentNumber': _studentNumberController.text.trim(),
            'role': 'student',
            'gender': selectedGender,
            'grade': selectedGrade,
            'subjects':
                subjectsWithTeachers.map((st) => st['subject']).toList(),
            'subjectTeachers':
                subjectsWithTeachers, // Store subject-teacher pairs
            'createdAt': FieldValue.serverTimestamp(),
          });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ConfirmationPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error occurred: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.purple,
                        ),
                        onPressed:
                            () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminDashboard(),
                              ),
                              (route) => false,
                            ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 4, width: 500, color: Colors.purple),
                  const SizedBox(height: 10),
                  const Text(
                    "Student Registration",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _firstNameController,
                                "First Name",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                _lastNameController,
                                "Last Name",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(_schoolController, "School"),
                        const SizedBox(height: 10),
                        _buildTextField(
                          _studentNumberController,
                          "Student Number",
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                "Gender",
                                ["Male", "Female", "Other"],
                                (value) =>
                                    setState(() => selectedGender = value),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdown(
                                "Grade",
                                [
                                  "Grade 6",
                                  "Grade 7",
                                  "Grade 8",
                                  "Grade 9",
                                  "Grade 10",
                                  "Grade 11",
                                ],
                                (value) =>
                                    setState(() => selectedGrade = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Subject Dropdown
                        _buildDropdown("Select Subject", availableSubjects, (
                          value,
                        ) async {
                          setState(() => selectedSubject = value);
                          if (value != null) {
                            await _loadTeachersForSubject(value);
                          }
                        }),
                        const SizedBox(height: 10),
                        // Teacher Dropdown (only visible when subject is selected)
                        if (selectedSubject != null &&
                            availableTeachers.isNotEmpty)
                          _buildDropdown(
                            "Select Teacher",
                            availableTeachers,
                            (value) => setState(() => selectedTeacher = value),
                          ),
                        if (selectedSubject != null &&
                            availableTeachers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "No teachers available for this subject",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 10),
                        // Add Subject button
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                              ),
                              onPressed: () {
                                if (selectedSubject == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please select a subject"),
                                    ),
                                  );
                                  return;
                                }

                                if (availableTeachers.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "No teachers available for this subject",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (selectedTeacher == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please select a teacher"),
                                    ),
                                  );
                                  return;
                                }

                                // Check if subject already added
                                if (subjectsWithTeachers.any(
                                  (st) => st['subject'] == selectedSubject,
                                )) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Subject already added"),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  subjectsWithTeachers.add({
                                    'subject': selectedSubject!,
                                    'teacher': selectedTeacher!,
                                  });
                                });

                                if (kDebugMode) {
                                  print(
                                    "Subjects with Teachers: $subjectsWithTeachers",
                                  );
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("Add Subject"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Display the added subjects with teachers
                        if (subjectsWithTeachers.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Added Subjects:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...subjectsWithTeachers.map((subjectTeacher) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subjectTeacher['subject']!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "Teacher: ${subjectTeacher['teacher']}",
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              subjectsWithTeachers.remove(
                                                subjectTeacher,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        const SizedBox(height: 10),
                        _buildTextField(_guardianController, "Guardian Name"),
                        const SizedBox(height: 10),
                        _buildTextField(_contactController, "Contact Number"),
                        const SizedBox(height: 10),
                        _buildTextField(
                          _emailController,
                          "Student Email Address",
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          _passwordController,
                          "Enter Password for Student Mail",
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _registerStudent,
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        if (label.contains('Email') &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Enter a valid email address';
        }
        if (isPassword && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (label == 'Student Number' && value.length < 3) {
          return 'Student number must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      hint: Text(hint),
      value:
          items.contains(
                hint == "Select Subject" ? selectedSubject : selectedTeacher,
              )
              ? (hint == "Select Subject" ? selectedSubject : selectedTeacher)
              : null,
      items:
          items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if ((hint != "Select Subject" && hint != "Select Teacher") &&
            (value == null || value.isEmpty)) {
          return '$hint is required';
        }
        return null;
      },
    );
  }
}

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Successful'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Student Registration Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AdminDashboard()),
                  (route) => false,
                );
              },
              child: const Text('Return to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard.dart';

void main() => runApp(TeacherRegistrationApp());

class TeacherRegistrationApp extends StatelessWidget {
  const TeacherRegistrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TeacherRegistrationForm(),
    );
  }
}

class TeacherRegistrationForm extends StatefulWidget {
  const TeacherRegistrationForm({super.key});

  @override
  _TeacherRegistrationFormState createState() => _TeacherRegistrationFormState();
}

class _TeacherRegistrationFormState extends State<TeacherRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _feeController = TextEditingController(); // Added fee controller
  
  String? selectedSubject;
  String? selectedGradeFrom;
  String? selectedGradeTo;
  bool _isLoading = false;
  bool _registrationSuccess = false;
  String _statusMessage = '';
  Color _statusColor = Colors.transparent;

  final List<String> subjects = [
    'Maths', 'Science', 'English', 'History', 
    'Sinhala', 'ICT', 'English Literature', 
    'Tamil', 'Commerce', 'Dancing', 'Music'
  ];
  
  final List<String> grades = ['6', '7', '8', '9', '10', '11'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    _feeController.dispose(); // Dispose fee controller
    super.dispose();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password': return '⚠️ Password must be at least 6 characters';
      case 'email-already-in-use': return '⛔ Email already in use';
      case 'invalid-email': return '✉️ Invalid email format';
      default: return '❌ Registration failed';
    }
  }

  Future<void> _registerTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _registrationSuccess = false;
      _statusMessage = '';
      _statusColor = Colors.transparent;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(userCredential.user?.uid)
          .set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'contact': _contactController.text.trim(),
        'subject': selectedSubject,
        'gradeFrom': selectedGradeFrom,
        'gradeTo': selectedGradeTo,
        'feePerSubject': double.tryParse(_feeController.text) ?? 0.0, // Added fee field
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _registrationSuccess = true;
        _statusMessage = '🎉 Registration Successful!';
        _statusColor = Colors.green.shade100;
      });

      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()),
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        _registrationSuccess = false;
        _statusMessage = _getErrorMessage(e.code);
        _statusColor = Colors.red.shade100;
      });
    } catch (e) {
      setState(() {
        _registrationSuccess = false;
        _statusMessage = '❌ Error: ${e.toString()}';
        _statusColor = Colors.red.shade100;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.purple, size: 30),
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => AdminDashboard()),
                    (route) => false,
                  ),
                ),
                
                // Status Indicator
                if (_statusMessage.isNotEmpty)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _registrationSuccess ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _registrationSuccess ? Icons.check_circle : Icons.error,
                          color: _registrationSuccess ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _registrationSuccess ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Purple Header Line
                Container(
                  height: 4,
                  width: double.infinity,
                  color: Colors.purple,
                ),
                const SizedBox(height: 10),
                
                // Title
                const Text(
                  'Teacher Registration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name Fields
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_firstNameController, 'First Name')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTextField(_lastNameController, 'Last Name')),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Subject Dropdown
                        _buildDropdownField('Subject', subjects, selectedSubject, (value) {
                          setState(() => selectedSubject = value);
                        }),
                        const SizedBox(height: 15),
                        
                        // Grade Range
                        Row(
                          children: [
                            Expanded(child: _buildDropdownField('Grade From', grades, selectedGradeFrom, (value) {
                              setState(() => selectedGradeFrom = value);
                            })),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('to', style: TextStyle(fontSize: 16)),
                            ),
                            Expanded(child: _buildDropdownField('Grade To', grades, selectedGradeTo, (value) {
                              setState(() => selectedGradeTo = value);
                            })),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Fee Field (Added this new field)
                        _buildFeeField(),
                        const SizedBox(height: 15),
                        
                        // Email Field
                        _buildEmailField(),
                        const SizedBox(height: 15),
                        
                        // Password Field
                        _buildPasswordField(),
                        const SizedBox(height: 15),
                        
                        // Contact Field
                        _buildTextField(_contactController, 'Contact Number'),
                        const SizedBox(height: 25),
                        
                        // Register Button
                        _isLoading
                            ? const CircularProgressIndicator(color: Colors.purple)
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                onPressed: _registerTeacher,
                                child: const Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Success/Failure Modal
          if (_statusMessage.isNotEmpty && !_isLoading)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_registrationSuccess) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => AdminDashboard()),
                      (route) => false,
                    );
                  } else {
                    setState(() => _statusMessage = '');
                  }
                },
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _registrationSuccess 
                                  ? Icons.check_circle_outline 
                                  : Icons.error_outline,
                              color: _registrationSuccess 
                                  ? Colors.green 
                                  : Colors.red,
                              size: 70,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _registrationSuccess ? 'SUCCESS!' : 'OOPS!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _registrationSuccess 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 25),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _registrationSuccess 
                                    ? Colors.green 
                                    : Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                if (_registrationSuccess) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => AdminDashboard()),
                                    (route) => false,
                                  );
                                } else {
                                  setState(() => _statusMessage = '');
                                }
                              },
                              child: Text(
                                _registrationSuccess ? 'GO TO DASHBOARD' : 'TRY AGAIN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Added this new method for fee field
  Widget _buildFeeField() {
    return TextFormField(
      controller: _feeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Fee per Subject (LKR)',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter fee amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) <= 0) {
          return 'Fee must be greater than 0';
        }
        return null;
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.email, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(
      String label, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
      ),
      value: value,
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 15)),
        );
      }).toList(),
      validator: (value) =>
          value == null ? 'Please select $label' : null,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
    );
  }
}
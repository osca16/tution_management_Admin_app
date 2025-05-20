import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tution_management_app/pages/hall_reservation_screen.dart';
import 'package:tution_management_app/pages/payement.dart';
import 'package:tution_management_app/pages/student_reg.dart';
import 'package:tution_management_app/pages/students.dart';
import 'package:tution_management_app/pages/teacher_list.dart';
import 'package:tution_management_app/pages/teacher_reg.dart';
import 'package:tution_management_app/pages/login_page.dart'; // Make sure this import exists

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navigate to LoginPage and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false, // This removes all existing routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B03AC),
        elevation: 5,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildButton(
                "Student Registration",
                Icons.person_add,
                const Color(0xFF3B03AC),
                onPressed:
                    () => _navigateToScreen(const StudentRegistrationApp()),
              ),
              _buildButton(
                "Teacher Registration",
                Icons.person_add,
                const Color(0xFF3B03AC),
                onPressed:
                    () => _navigateToScreen(const TeacherRegistrationApp()),
              ),
              _buildButton(
                "Payment",
                Icons.attach_money,
                const Color(0xFF3B03AC),
                onPressed: () => _navigateToScreen(const PaymentScreen()),
              ),
              _buildButton(
                "Hall Reservation",
                Icons.check_box,
                const Color(0xFF3B03AC),
                onPressed:
                    () => _navigateToScreen(const HallReservationScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF3B03AC),
      child: Column(
        children: [
          // Drawer Header
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF3B03AC)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 60, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // View Students Button
          _buildDrawerItem(
            icon: Icons.people,
            title: 'View All Students',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(StudentListScreen());
            },
          ),

          // View Teachers Button
          _buildDrawerItem(
            icon: Icons.school,
            title: 'View All Teachers',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(const TeachersPage());
            },
          ),

          const Spacer(),

          // Logout Button
          _buildDrawerItem(icon: Icons.logout, title: 'Logout', onTap: _logout),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildButton(
    String text,
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 40.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State <TeacherDashboard> createState() => TeacherDashboardState();
}

class TeacherDashboardState extends State<TeacherDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF3B03AC),
        child: Column(
          children: [
            // Custom Drawer Header with Menu Button
            Container(
              height: 80, // Adjust height as needed
              decoration: BoxDecoration(
                color: Color(0xFF3B03AC),
              ),
              child: Padding(
                // Match the padding of the AppBar's leading button
                padding:
                    const EdgeInsets.only(left: 20.0, top: 15.0, bottom: 15.0),
                child: Row(
                  children: [
                    // Drawer Menu Button
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.white),
                      iconSize: 24, // Match the AppBar button size
                      padding: EdgeInsets.zero, // Remove default padding
                      constraints: BoxConstraints(), // Remove constraints
                      onPressed: () {
                        // Close the drawer when the menu button is pressed
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem("Profile", icon: Icons.person),
            _buildDrawerItem("Student", icon: Icons.people),
            Spacer(),
            _buildDrawerItem("Log Out", icon: Icons.logout),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Color(0xFF3B03AC),
        elevation: 5,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          iconSize: 24, // Match the drawer button size
          padding: EdgeInsets.zero, // Remove default padding
          constraints: BoxConstraints(), // Remove constraints
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
                  "Mark Attendance", Icons.check_box, Color(0xFF3A3A3A)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, {IconData? icon}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Color(0xFF3B03AC),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: Colors.white) : null,
        title: Text(title,
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        onTap: () {
          // Close the drawer when an item is pressed
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(
              vertical: 24.0, horizontal: 40.0), // Increased padding
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        icon: Icon(icon, color: Colors.white, size: 28), // Increased icon size
        label: Text(text,
            style: TextStyle(
                color: Colors.white,
                fontSize: 18, // Increased font size
                fontWeight: FontWeight.bold)),
        onPressed: () {},
      ),
    );
  }
}

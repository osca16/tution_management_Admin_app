import 'package:flutter/material.dart';

class HallReservationScreen extends StatelessWidget {
  const HallReservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hall Reservation', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTeacherCard(
              teacherName: "Teacher 01",
              teacherId: "TEANO001",
              currency: "💶",
            ),
            const SizedBox(height: 16),
            _buildTeacherCard(
              teacherName: "Teacher 02",
              teacherId: "TEANO002",
              currency: "💷",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard({
    required String teacherName,
    required String teacherId,
    required String currency,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            CheckboxListTile(
              title: Text(teacherName),
              value: false,
              onChanged: null,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(height: 1),
            CheckboxListTile(
              title: Text(teacherId),
              value: true,
              onChanged: null,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: Text(currency),
              value: true,
              onChanged: null,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }
}
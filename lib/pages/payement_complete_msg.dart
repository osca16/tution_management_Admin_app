import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SuccessScreen(),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          Container(
            height: 4,
            color: Colors.purple,
          ),
          const Spacer(),
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Color.fromRGBO(55, 239, 61, 1),
          ),
          const SizedBox(height: 20),
          const Text(
            "SUCCESS",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(55, 239, 61, 1),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Thank you for your request\nWe are working hard to find the best\nservices and deals for you",
              textAlign: TextAlign.center,
              
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Saving Receipt & Send SMS Alert",
            style: TextStyle(fontSize: 14, color: Colors.black45),
          ),
          const SizedBox(height: 30),
          // Complete Button
          ElevatedButton(
            onPressed: () {
              // Add navigation or action here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(55, 239, 61, 1),
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Complete",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const Spacer(),
          // Purple Border at the Bottom
          Container(
            height: 50, // Adjust thickness
            width: double.infinity,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}
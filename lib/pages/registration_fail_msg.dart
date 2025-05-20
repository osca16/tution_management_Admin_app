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
      home: ErrorScreen(),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
              SizedBox(height: 100),
              Container(
                height: 4,
                color: Colors.purple,
              ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  "ERROR!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Thank you for your request\nWe are unable to continue process",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Please try again to complete the process",
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Handle retry logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                  "Try Again",
                  style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Change text color to white
                   ),
                    ),

                ),
              ],
            ),
          ),
          // Purple line at the bottom (optional)
          Container(
            height: 50,
            color: Colors.purple,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
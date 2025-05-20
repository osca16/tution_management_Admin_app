import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: SuccessScreen(),
  ));
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
         children: [
              SizedBox(height:100),
              Container(
                height: 4,
                color: Colors.purple,
              ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Color.fromRGBO(55, 239, 61, 1),
                      child: Icon(
                        Icons.check,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "SUCCESS",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(55, 239, 61, 1),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Thank you for your request\nWe are working hard to find best\nservices and deals for you",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Shortly you will find a confirmation in your email",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(55, 239, 61, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () {
                        // Add your action here
                      },
                      child: Text(
                        "Complete",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 50, // Bottom purple section
            width: double.infinity,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}
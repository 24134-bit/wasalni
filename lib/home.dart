import 'package:flutter/material.dart';
import 'rides.dart';

class HomePage extends StatelessWidget {
  final Map captain;
  const HomePage(this.captain, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(captain['name']),
                subtitle: Text("📞 ${captain['phone']}"),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.directions_car),
              label: const Text("View Available Rides"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RidesPage(captain['id']),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

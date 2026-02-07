import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rides.dart';
import 'services/notification_service.dart';

class HomePage extends StatefulWidget {
  final Map captain;
  const HomePage(this.captain, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    int userId = int.tryParse(widget.captain['id'].toString()) ?? 0;
    NotificationService.startPolling(context, userId, 'driver');
  }

  @override
  void dispose() {
    NotificationService.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.get('dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
               final prefs = await SharedPreferences.getInstance();
               await prefs.clear();
               if(!context.mounted) return;
               Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          )
        ],
      ),
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
                title: Text(widget.captain['name']),
                subtitle: Text("📞 ${widget.captain['phone']}"),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.directions_car),
              label: Text(Lang.get('view_available_rides')),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RidesPage(widget.captain['id']),
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

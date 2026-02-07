import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../lang.dart';

class NotificationsPage extends StatefulWidget {
  final int userId;
  final String role;
  const NotificationsPage({super.key, required this.userId, required this.role});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  void _fetchNotifications() async {
    try {
      final res = await http.get(
        Uri.parse("${Config.baseUrl}/get_notifications.php?user_id=${widget.userId}&role=${widget.role}&all=1"),
        headers: Config.headers
      );
      if(mounted && res.statusCode == 200) {
        setState(() {
          notifications = json.decode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Lang.get('notifications'))),
      body: RefreshIndicator(
        onRefresh: () async => _fetchNotifications(),
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty 
            ? Center(child: Text(Lang.get('no_notifications')))
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (ctx, i) {
                  var n = notifications[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: const Icon(Icons.notifications, color: Colors.blue),
                      title: Text(n['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['body'] ?? 'No Body'),
                          const SizedBox(height: 5),
                          Text(n['created_at'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

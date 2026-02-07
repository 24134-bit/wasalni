import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class NotificationService {
  static Timer? _timer;
  static int _lastId = 0;
  static bool _isPolling = false;

  static void startPolling(BuildContext context, int userId, String role) {
    if (_isPolling) return;
    _isPolling = true;
    
    // Initial poll after 2 seconds, then every 10 seconds
    Future.delayed(const Duration(seconds: 2), () => _poll(context, userId, role));
    
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _poll(context, userId, role);
    });
  }

  static void stopPolling() {
    _timer?.cancel();
    _isPolling = false;
  }

  static Future<void> _poll(BuildContext context, int userId, String role) async {
    try {
      final url = "${Config.baseUrl}/get_notifications.php?user_id=$userId&role=$role&last_id=$_lastId";
      final res = await http.get(Uri.parse(url), headers: Config.headers);
      
      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        if (data.isNotEmpty) {
          // Update lastId to the max ID received
          int maxId = _lastId;
          for (var item in data) {
            int currentId = int.tryParse(item['id'].toString()) ?? 0;
            if (currentId > maxId) maxId = currentId;
            
            // Show Notification
            if (context.mounted) {
              ScaffoldMessenger.of(context).showMaterialBanner(
                MaterialBanner(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item['body']),
                    ],
                  ),
                  backgroundColor: Colors.blueAccent.shade100,
                  leading: const Icon(Icons.notifications_active, color: Colors.blue),
                  actions: [
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                      child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              // Auto hide after 5 seconds
              Future.delayed(const Duration(seconds: 5), () {
                if(context.mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              });
            }
          }
          _lastId = maxId;
        }
      }
    } catch (e) {
      print("Notification polling error: $e");
    }
  }
}

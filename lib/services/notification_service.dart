import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
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
            
            // Show Notification (Non-intrusive SnackBar instead of Banner)
            if (context.mounted) {
              // Vibrate
              HapticFeedback.heavyImpact();
              
              ScaffoldMessenger.of(context).showMaterialBanner(
                MaterialBanner(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(item['body'], style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  backgroundColor: const Color(0xFF0D47A1),
                  actions: [
                    TextButton(
                      child: const Text('OK', style: TextStyle(color: Colors.white)),
                      onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                    ),
                  ],
                ),
              );
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

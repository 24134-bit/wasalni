// No changes needed if grep didn't find "Wasalni" here, but checking for completeness.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/admin_dashboard.dart';
import 'config.dart';
import 'screens/home_page.dart';
import 'lang.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool isLoading = false;

  void _login() async {
    setState(() => isLoading = true);
    var url = "${Config.baseUrl}/captain_login.php";
    try {
      var res = await http.post(
        Uri.parse(url),
        headers: Config.headers,
        body: {"phone": phone.text, "password": password.text},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200) {
        try {
          // Try to find the JSON part of the response (handles InfinityFree security scripts)
          final jsonFinder = RegExp(r'\{"success":.*\}', dotAll: true);
          final match = jsonFinder.firstMatch(res.body);
          
          if (match == null) {
            String errorMsg = "Server error or connectivity issue.";
            if (res.body.contains("aes.js") || res.body.contains("__test")) {
               errorMsg = "InfinityFree Security blocking. Please rebuild the APK with the new headers I added.";
            }
            throw Exception(errorMsg);
          }
          
          String cleanBody = match.group(0)!;
          debugPrint("Clean JSON captured: '$cleanBody'");

          var data = json.decode(cleanBody);
          if (data["success"] == true) { // Check explicit true
            var user = data["user"];

            // Save Session
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', user['id'].toString());
            await prefs.setString('role', user['role']);
            await prefs.setString('name', user['name'] ?? 'Driver'); // Handle null name
            await prefs.setString('phone', user['phone']);

            if (!mounted) return;

            if (user['role'] == 'admin') {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                  (route) => false);
            } else {
              int userId = int.tryParse(user["id"].toString()) ?? 0;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage(driverId: userId)),
                  (route) => false);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: ${data["error"] ?? 'Invalid credentials'}")));
          }
        } catch (e) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                  title: const Text("Server Insight Required"),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("The server returned something unexpected. This often happens on free hosting (InfinityFree) due to security tests or 404 errors.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800])),
                        const Divider(),
                        const Text("Diagnostic Trace:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(e.toString()),
                        const SizedBox(height: 10),
                        const Text("Server Response (First 500 chars):", style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey[200],
                          child: Text(res.body.length > 500 ? res.body.substring(0, 500) + "..." : res.body, 
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                  ),
                  actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("OK"))],
              ));
        }
      } else {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                title: const Text("HTTP Error"),
                content: Text("Status Code: ${res.statusCode}")));
      }
    } catch (e) {
      if (mounted) {
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text("Connection Failed"),
                  content: Text(
                      "Could not connect to:\n$url\n\nError: $e\n\nCheck if XAMPP is running and your IP/URL is correct in config.dart."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"))
                  ],
                ));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: "btn1",
            onPressed: () async {
              await Lang.set('fr');
              setState((){});
            },
            backgroundColor: Colors.blue,
            child: const Text("FR"),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.small(
            heroTag: "btn2",
            onPressed: () async {
              await Lang.set('ar');
              setState((){});
            },
            backgroundColor: Colors.green,
            child: const Text("عربي"),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/logo.jpeg', width: 120, height: 120, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 10),
                      Text(Lang.get('login_title'),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1))),
                      const SizedBox(height: 5),
                      Text(Lang.get('app_name'),
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 30),
                      TextField(
                          controller: phone,
                          textAlign: Lang.curr == 'ar' ? TextAlign.right : TextAlign.left,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              alignLabelWithHint: true,
                              labelText: Lang.get('phone'),
                              prefixIcon: const Icon(Icons.phone))),
                      const SizedBox(height: 15),
                      TextField(
                          controller: password,
                          obscureText: true,
                          textAlign: Lang.curr == 'ar' ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(
                              alignLabelWithHint: true,
                              labelText: Lang.get('password'),
                              prefixIcon: const Icon(Icons.lock))),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(Lang.get('login_btn'),
                                  style: const TextStyle(letterSpacing: 1.2)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

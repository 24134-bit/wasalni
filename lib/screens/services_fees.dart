import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../lang.dart';

class ServicesFeesPage extends StatefulWidget {
  const ServicesFeesPage({super.key});

  @override
  State<ServicesFeesPage> createState() => _ServicesFeesPageState();
}

class _ServicesFeesPageState extends State<ServicesFeesPage> {
  Map<String, dynamic>? settings;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  void _fetchSettings() async {
    try {
      final res = await http.get(Uri.parse("${Config.baseUrl}/get_settings.php"), headers: Config.headers);
      if(mounted && res.statusCode == 200) {
        setState(() {
          settings = json.decode(res.body);
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
      appBar: AppBar(
        title: Text(Lang.get('services_fees_title')),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildFeeItem("قيمة الكيلومتر", "${settings?['price_km'] ?? '0'} أوقية"),
                  _buildFeeItem("قيمة الدقيقة", "${settings?['price_min'] ?? '0'} أوقية"),
                  _buildFeeItem("القيمة الادنى (Base Fare)", "${settings?['base_fare'] ?? '0'} أوقية"),
                  const Divider(height: 40),
                  _buildFeeItem("رسوم وصلني (Commission)", "% ${settings?['commission_percent'] ?? '0'}"),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.red.shade50,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "يرجى العلم بأن وصلني عند احتساب القيمة الإجمالية للرحلة، فإنها تتضمن المسافة الإضافية للرحلة والوقت الإضافي؛ ومع ذلك، لا يتم احتساب رسوم مقابل جزء صغير من المسافة والوقت للركاب بعد تجاوز الحد الأساسي.",
                            style: TextStyle(height: 1.5, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFeeItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

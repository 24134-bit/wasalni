import 'package:flutter/material.dart';
import '../lang.dart';

class ServicesFeesPage extends StatelessWidget {
  const ServicesFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.get('services_fees_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildFeeItem("قيمة الكيلومتر", "22.5 أوقية"),
              _buildFeeItem("قيمة الدقيقة", "1.0 أوقية"),
              _buildFeeItem("المسار المفتوح - الكيلومتر", "10.0 أوقية"),
              _buildFeeItem("المسار المفتوح - الدقيقة", "5.0 أوقية"),
              _buildFeeItem("القيمة الادنى لبداية الرحلة", "100.0 أوقية"),
              const Divider(height: 40),
              _buildFeeItem("رسوم وصلني", "% 15"),
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

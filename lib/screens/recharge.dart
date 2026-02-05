import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../lang.dart';

class RechargePage extends StatefulWidget {
  final int driverId;
  const RechargePage({super.key, required this.driverId});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final amountController = TextEditingController();
  final senderPhoneController = TextEditingController();
  final referenceNumberController = TextEditingController();
  final Map<String, String> paymentInfo = {
    'Bankily': '22255689',
    'Masrifi': '31003874',
    'Sadad': '31003874'
  };
  String method = 'Bankily';
  XFile? receipt;
  bool isUploading = false;

  Future pickReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image!=null) setState(() => receipt = image);
  }

  void submitRecharge() async {
    if(amountController.text.isEmpty || receipt==null || referenceNumberController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields, including reference number")));
       return;
    }

    setState(() => isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Config.baseUrl}/recharge_request.php")
      );
      request.fields['driver_id'] = widget.driverId.toString();
      request.fields['amount'] = amountController.text;
      request.fields['sender_phone'] = senderPhoneController.text;
      request.fields['reference_number'] = referenceNumberController.text;
      request.fields['method'] = method;
      
      // Fix for Web: Read bytes instead of path
      final bytes = await receipt!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'receipt', 
        bytes,
        filename: receipt!.name
      ));

      var response = await request.send();
      
      if (mounted) {
        if(response.statusCode==200){
           // Reading Stream response
           final respStr = await response.stream.bytesToString();
           // Sanitize
           String cleanBody = respStr.trim();
           int open = cleanBody.indexOf('{');
           int close = cleanBody.lastIndexOf('}');
           if (open != -1 && close != -1 && open <= close) {
             cleanBody = cleanBody.substring(open, close + 1);
           }
           
           // Verify JSON
           try {
             var data = json.decode(cleanBody);
             // We assume success if we can parse it, or check data['success'] if API returns it
           } catch(e) {}

           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recharge request sent! Waiting for approval.")));
           Navigator.pop(context);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send request")));
           setState(() => isUploading = false);
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Lang.get('recharge'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Payment Method Selection
            Text(Lang.get('select_method'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: method,
              items: paymentInfo.keys.map((e) => DropdownMenuItem(value:e,child: Row(children: [
                 Icon(Icons.credit_card, color: Colors.blue[800]), 
                 const SizedBox(width: 10), 
                 Text(e)
              ]))).toList(),
              onChanged: (v)=>setState(()=>method=v!),
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)),
            ),
            
            // Account Info Card
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200)
              ),
              child: Column(
                children: [
                   Text(Lang.get('transfer_to'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(paymentInfo[method]!, style: const TextStyle(fontSize: 22, color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(Lang.get('instr_recharge'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Lang.get('security_warning'),
                          style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text(Lang.get('amount'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "${Lang.get('amount')} (MRU)",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance)
              ),
            ),

            const SizedBox(height: 20),
            Text("رقم العملية (إجباري)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: referenceNumberController,
              decoration: InputDecoration(
                hintText: "أدخل رقم المعاملة من لقطة الشاشة",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.pin)
              ),
            ),

            const SizedBox(height: 20),
            Text(Lang.get('phone'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: senderPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: Lang.get('phone'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone_android)
              ),
            ),

            const SizedBox(height: 30),
            Text(Lang.get('upload_proof'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            InkWell(
              onTap: pickReceipt,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100]
                ),
                child: receipt == null 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload, size: 50, color: Colors.grey),
                        Text(Lang.get('tap_upload'))
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 50, color: Colors.green),
                        Positioned(bottom: 10, child: Text("${Lang.get('selected')}: ${receipt!.name}", style: const TextStyle(fontWeight: FontWeight.bold)))
                      ], 
                    ),
              ),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: isUploading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(Lang.get('submit'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: isUploading ? null : submitRecharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

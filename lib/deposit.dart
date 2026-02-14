import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'lang.dart';

class DepositPage extends StatefulWidget {
  final int captainId;
  const DepositPage(this.captainId, {super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final amountController = TextEditingController();
  String method = 'Bankily';
  XFile? receipt;

  Future pickReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image!=null) setState(() => receipt = image);
  }

  void submitDeposit() async {
    if(amountController.text.isEmpty || receipt==null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill amount and attach receipt")));
       return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Config.baseUrl}/deposit_request.php")
      );
      request.fields['driver_id'] = widget.captainId.toString();
      request.fields['amount'] = amountController.text;
      request.fields['method'] = method;
      request.files.add(await http.MultipartFile.fromPath('receipt', receipt!.path));

      var response = await request.send();
      
      if (mounted) {
        if(response.statusCode==200){
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deposit request sent!")));
           Navigator.pop(context);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send request")));
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Lang.get('recharge'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.bottom(20),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
              child: Text(Lang.get('security_warning'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: Lang.get('amount')),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: method,
              isExpanded: true,
              items: ['Bankily','Sadad'].map((e) => DropdownMenuItem(value:e,child: Text(e))).toList(),
              onChanged: (v)=>setState(()=>method=v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: pickReceipt, child: Text(Lang.get('upload_proof'))),
            if(receipt != null) ...[
              const SizedBox(height: 10),
              Text("${Lang.get('selected')}: ${receipt!.name}"),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
                onPressed: submitDeposit, 
                child: Text(Lang.get('confirm'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

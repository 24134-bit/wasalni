import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../lang.dart';
import 'recharge.dart';

class WalletPage extends StatefulWidget {
  final int driverId;
  const WalletPage({super.key, required this.driverId});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double balance = 0.0;
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  void _fetchWallet() async {
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/wallet.php?driver_id=${widget.driverId}"), headers: Config.headers);
      var data = json.decode(res.body);

      if(mounted) {
        if (data['success'] == true) {
          setState(() {
            balance = double.parse(data['balance'].toString());
            transactions = data['transactions'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${data['error']}"), backgroundColor: Colors.red)
          );
        }
      }
    } catch(e) {
      if(mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Lang.get('wallet'))),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchWallet();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF0D47A1),
              child: Column(
                children: [
                  Text(Lang.get('curr_balance'), style: const TextStyle(color: Colors.white70)),
                  Text("${balance.toStringAsFixed(2)} ${Lang.get('sar')}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => RechargePage(driverId: widget.driverId)));
                      _fetchWallet();
                    },
                    icon: const Icon(Icons.add),
                    label: Text(Lang.get('top_up')),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue),
                  )
                ],
              ),
            ),
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty 
                  ? ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No transactions yet.")))])
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (ctx, i) {
                        var t = transactions[i];
                        bool isCredit = t['type'] == 'deposit';
                        return ListTile(
                          leading: Icon(
                            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isCredit ? Colors.green : Colors.red,
                          ),
                          title: Text(t['description']),
                          subtitle: Text(t['date']),
                          trailing: Text(
                            "${t['amount']} ${Lang.get('sar')}",
                            style: TextStyle(
                              color: isCredit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

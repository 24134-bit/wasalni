import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'deposit.dart';
import 'config.dart';
import 'lang.dart';
import 'screens/ride_map.dart';

class RidesPage extends StatefulWidget {
  final int captainId;
  const RidesPage(this.captainId, {super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  List<dynamic> rides = [];
  double balance = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    setState(() => isLoading = true);
    try {
      // Fetch Rides
      var resRides = await http.get(Uri.parse("${Config.baseUrl}/rides.php?action=list&driver_id=${widget.captainId}"), headers: Config.headers);
      var resBalance = await http.get(Uri.parse("${Config.baseUrl}/rides.php?action=balance&driver_id=${widget.captainId}"), headers: Config.headers);
      
      setState(() {
        rides = json.decode(resRides.body);
        balance = double.parse(json.decode(resBalance.body)['balance'].toString());
        isLoading = false;
      });
    } catch (e) {
      if(mounted) setState(() => isLoading = false);

    }
  }

  void _takeRide(Map<String, dynamic> ride) async {
    try {
      var res = await http.post(
        Uri.parse("${Config.baseUrl}/take_ride.php"),
        headers: Config.headers,
        body: {"ride_id": ride['id'].toString(), "driver_id": widget.captainId.toString()}
      );
      var data = json.decode(res.body);

      if(!mounted) return;
      if(data["success"]){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.get('ride_accepted'))));
        _refreshData();
        
        // Navigate to Map
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => RideMapPage(rideId: int.parse(ride['id'].toString()), rideData: ride)
        ));
        
        _refreshData(); // Refresh on return
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data["error"])));
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // _completeRide is now handled in RideMapPage but we can keep it for manual "Delivered" if map fails or for non-map flow.
  // Converting it to use map:


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(Lang.get('available_rides'), style: const TextStyle(fontSize: 16)),
            Text("${Lang.get('curr_balance')}: $balance ${Lang.get('sar')}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => DepositPage(widget.captainId)));
              _refreshData(); // Refresh balance after coming back
            },
          ),
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
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
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
          itemCount: rides.length,
          itemBuilder: (_, i) {
            var r = rides[i];
            
            // Filter logic: Show if Pending OR (if Accepted/InProgress AND assigned to this driver)
            bool isAssignedToMe = r['driver_id'] == widget.captainId;
            bool isAvailable = r['status'] == 'pending';

            if (!isAvailable && !isAssignedToMe) return const SizedBox.shrink();

            return Card(
              color: isAssignedToMe ? Colors.blue.shade50 : Colors.white,
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(isAssignedToMe) 
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                         child: Text("${Lang.get('status')}: ${Lang.get('status_' + r['status'])}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                       ),
                    const SizedBox(height: 5),
                    Text("📍 ${Lang.get('pickup')}: ${r['pickup_address']}"),
                    Text("➡️ ${Lang.get('dropoff')}: ${r['dropoff_address']}"),
                    Text("💰 ${Lang.get('price')}: ${r['total_price']} ${Lang.get('sar')}"),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if(isAvailable)
                          ElevatedButton(
                            onPressed: () => _takeRide(r), 
                            child: Text(Lang.get('accept_ride'))
                          ),
                        if(isAssignedToMe && r['status'] == 'accepted')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: () async { 
                               await Navigator.push(context, MaterialPageRoute(
                                 builder: (_) => RideMapPage(rideId: int.parse(r['id'].toString()), rideData: r)
                               ));
                               _refreshData();
                            }, 
                            child: Text(Lang.get('on_trip_btn'))
                          ),
                        // If already delivered, maybe hide or show completed?
                        if(isAssignedToMe && r['status'] == 'delivered')
                           Text("✅ ${Lang.get('completed')}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}

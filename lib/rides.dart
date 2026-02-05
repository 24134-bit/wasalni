import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'deposit.dart';
import 'config.dart';
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
      var resRides = await http.get(Uri.parse("${Config.baseUrl}/rides.php?action=list&driver_id=${widget.captainId}"));
      var resBalance = await http.get(Uri.parse("${Config.baseUrl}/rides.php?action=balance&driver_id=${widget.captainId}"));
      
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
        body: {"ride_id": ride['id'].toString(), "driver_id": widget.captainId.toString()}
      );
      var data = json.decode(res.body);

      if(!mounted) return;
      if(data["success"]){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride Accepted! Prepare for pickup.")));
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
            const Text("Available Rides", style: TextStyle(fontSize: 16)),
            Text("Balance: $balance", style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh))
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
                         child: Text("Status: ${r['status'].toString().toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                       ),
                    const SizedBox(height: 5),
                    Text("📍 Pickup: ${r['pickup_address']}"),
                    Text("➡️ Dropoff: ${r['dropoff_address']}"),
                    Text("💰 Price: ${r['total_price']}"),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if(isAvailable)
                          ElevatedButton(
                            onPressed: () => _takeRide(r), 
                            child: const Text("Take Ride")
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
                            child: const Text("Track & Deliver")
                          ),
                        // If already delivered, maybe hide or show completed?
                        if(isAssignedToMe && r['status'] == 'delivered')
                           const Text("✅ Completed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
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

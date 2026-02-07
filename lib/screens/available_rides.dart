import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../lang.dart';
import 'ride_details.dart';

class AvailableRidesPage extends StatefulWidget {
  final int driverId;
  const AvailableRidesPage({super.key, required this.driverId});

  @override
  State<AvailableRidesPage> createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  List<dynamic> rides = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  void _fetchRides() async {
    try {
      // Using 'action=list' to get pending rides
      // Note: Backend alignment might be needed depending on available_rides.php implementation
      // Assuming available_rides.php returns a JSON list of pending rides directly or via some structure.
      var res = await http.get(Uri.parse("${Config.baseUrl}/available_rides.php?action=list&driver_id=${widget.driverId}"), headers: Config.headers);
      
      if(mounted) {
        setState(() {
          rides = json.decode(res.body);
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
      appBar: AppBar(title: Text(Lang.get('available_rides'))),
      body: RefreshIndicator(
        onRefresh: () async => _fetchRides(),
        child: isLoading 
           ? const Center(child: CircularProgressIndicator()) 
           : rides.isEmpty 
             ? Center(child: Text(Lang.get('no_rides')))
             : ListView.builder(
                 itemCount: rides.length,
                 itemBuilder: (ctx, i) {
                   var ride = rides[i];
                   return Card(
                     margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                     elevation: 3,
                     child: ListTile(
                       leading: const CircleAvatar(
                         backgroundColor: Color(0xFF2ECC71),
                         child: Icon(Icons.directions_car, color: Colors.white),
                       ),
                       title: Text(ride['pickup_address'] ?? 'Unknown Pickup'),
                       subtitle: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text("${Lang.get('to')}: ${ride['dropoff_address'] ?? 'Unknown Dropoff'}"),
                           if(ride['customer_phone'] != null) Text("الزبون: ${ride['customer_phone']}", style: const TextStyle(color: Colors.blueGrey)),
                           Text("${Lang.get('price')}: ${ride['total_price']} ${Lang.get('sar')}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                         ],
                       ),
                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                       onTap: () {
                         Navigator.push(context, MaterialPageRoute(
                           builder: (_) => RideDetailsPage(driverId: widget.driverId, rideData: ride)
                         ));
                       },
                     ),
                   );
                 },
               ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config.dart';
import '../lang.dart';
import 'on_ride_page.dart';
import 'dart:async';

class RideDetailsPage extends StatefulWidget {
  final int driverId;
  final Map<String, dynamic> rideData;

  const RideDetailsPage({super.key, required this.driverId, required this.rideData});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  bool isProcessing = false;
  final Completer<GoogleMapController> _controller = Completer();
  late LatLng pickup;
  late LatLng dropoff;
  final Set<Marker> _markers = {};

  final Set<Polyline> _polylines = {};
  double commissionRate = 10.0;
  bool isSettingsLoaded = false;
  double currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    pickup = LatLng(
      double.parse(widget.rideData['pickup_lat'].toString()), 
      double.parse(widget.rideData['pickup_lng'].toString())
    );
    dropoff = LatLng(
      double.parse(widget.rideData['dropoff_lat'].toString()), 
      double.parse(widget.rideData['dropoff_lng'].toString())
    );
    _markers.addAll({
      Marker(markerId: const MarkerId('p1'), position: pickup, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
      Marker(markerId: const MarkerId('p2'), position: dropoff, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
    });
    _polylines.add(Polyline(polylineId: const PolylineId('route'), points: [pickup, dropoff], color: Colors.blue, width: 5));
    _fetchSettings();
  }

  void _fetchSettings() async {
    try {
      // Fetch settings
      var res = await http.get(Uri.parse("${Config.baseUrl}/get_settings.php"), headers: Config.headers);
      var data = json.decode(res.body);
      
      // Fetch current balance for the driver
      var balRes = await http.get(Uri.parse("${Config.baseUrl}/wallet.php?driver_id=${widget.driverId}"), headers: Config.headers);
      var balData = json.decode(balRes.body);

      if(mounted) {
        setState(() {
          commissionRate = double.tryParse(data['commission_percent']?.toString() ?? "10") ?? 10.0;
          currentBalance = double.tryParse(balData['balance']?.toString() ?? "0.0") ?? 0.0;
          isSettingsLoaded = true;
        });
      }
    } catch(e) {
      if(mounted) setState(() => isSettingsLoaded = true);
    }
  }

  void _startRide() async {
    setState(() => isProcessing = true);
    try {
      var res = await http.post(
        Uri.parse("${Config.baseUrl}/take_ride.php"),
        headers: Config.headers,
        body: {
          "ride_id": widget.rideData['id'].toString(),
          "driver_id": widget.driverId.toString()
        }
      );
      var data = json.decode(res.body);

      if(!mounted) return;

      if(data['success']) {
        // Navigate to On Ride Page
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => OnRidePage(driverId: widget.driverId, rideData: widget.rideData)
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'])));
        setState(() => isProcessing = false);
      }
    } catch(e) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
         setState(() => isProcessing = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    var r = widget.rideData;
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.get('ride_details')),
        actions: [
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
      body: SafeArea(
        child: Column(
          children: [
            // Map Preview
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: pickup, zoom: 12),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) => _controller.complete(controller),
                ),
              ),
            ),
            // Info Card & Button section
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            _buildRow(Icons.location_on, Lang.get('pickup'), r['pickup_address']),
                            const Divider(),
                            _buildRow(Icons.flag, Lang.get('dropoff'), r['dropoff_address']),
                            const Divider(),
                            _buildRow(Icons.account_balance, Lang.get('price'), "${r['total_price']} MRU"),
                            const Divider(),
                            if(!isSettingsLoaded) 
                               const Center(child: LinearProgressIndicator())
                            else ...[
                               _buildRow(Icons.percent, "Commission (${commissionRate.toStringAsFixed(0)}%)", "-${(double.parse(r['total_price'].toString()) * (commissionRate/100)).toStringAsFixed(1)} MRU"),
                               const Divider(),
                               _buildRow(Icons.wallet, "Safe (Net)", "${(double.parse(r['total_price'].toString()) * (1 - (commissionRate/100))).toStringAsFixed(1)} MRU"),
                            ],
                            if(r['customer_phone'] != null) ...[
                              const Divider(),
                              _buildRow(Icons.phone, "رقم الزبون", r['customer_phone']),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (isSettingsLoaded && widget.rideData['type'] == 'open' && currentBalance < 50)
                       Container(
                         margin: const EdgeInsets.only(bottom: 10),
                         padding: const EdgeInsets.all(10),
                         decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red)),
                         child: Row(
                           children: [
                             const Icon(Icons.warning, color: Colors.red),
                             const SizedBox(width: 10),
                             Expanded(child: Text(Lang.get('min_balance_msg'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                           ],
                         ),
                       ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (widget.rideData['type'] == 'open' && currentBalance < 50) ? Colors.grey : const Color(0xFF2ECC71),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 8,
                          shadowColor: Colors.green.withOpacity(0.4)
                        ),
                        onPressed: (isProcessing || (widget.rideData['type'] == 'open' && currentBalance < 50)) ? null : _startRide,
                        child: isProcessing 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : Text(Lang.get('accept_ride'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        )
      ],
    );
  }
}

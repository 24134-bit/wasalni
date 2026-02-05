import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  }

  void _startRide() async {
    setState(() => isProcessing = true);
    try {
      var res = await http.post(
        Uri.parse("${Config.baseUrl}/take_ride.php"),
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
      appBar: AppBar(title: Text(Lang.get('ride_details'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Map Preview
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
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
            const SizedBox(height: 20),
            // Info Card
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
                    if(r['customer_phone'] != null) ...[
                      const Divider(),
                      _buildRow(Icons.phone, "رقم الزبون", r['customer_phone']),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
                onPressed: isProcessing ? null : _startRide,
                child: isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(Lang.get('accept_ride'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
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

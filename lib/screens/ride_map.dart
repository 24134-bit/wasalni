import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wasalni_app/config.dart';

class RideMapPage extends StatefulWidget {
  final int rideId;
  final Map<String, dynamic> rideData;

  const RideMapPage({super.key, required this.rideId, required this.rideData});

  @override
  State<RideMapPage> createState() => _RideMapPageState();
}

class _RideMapPageState extends State<RideMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  bool isLoading = false;
  
  // Coordinates
  late LatLng pickup;
  late LatLng dropoff;

  @override
  void initState() {
    super.initState();
    pickup = LatLng(
      double.tryParse(widget.rideData['pickup_lat'].toString()) ?? 24.7136, 
      double.tryParse(widget.rideData['pickup_lng'].toString()) ?? 46.6753
    );
    dropoff = LatLng(
      double.tryParse(widget.rideData['dropoff_lat'].toString()) ?? 24.7136, 
      double.tryParse(widget.rideData['dropoff_lng'].toString()) ?? 46.6753
    );
    _setMarkers();
  }

  void _setMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: InfoWindow(title: 'Pickup', snippet: widget.rideData['pickup_address']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          infoWindow: InfoWindow(title: 'Dropoff', snippet: widget.rideData['dropoff_address']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  void _completeRide() async {
    setState(() => isLoading = true);
    try {
      var res = await http.post(
        Uri.parse("${Config.baseUrl}/complete_ride.php"),
        body: {"ride_id": widget.rideId.toString()}
      );
      var data = json.decode(res.body);

      if(!mounted) return;
      if(data["success"]){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride Completed. Payment deducted.")));
        Navigator.pop(context, true); // Return success
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to complete ride")));
         setState(() => isLoading = false);
      }
    } catch (e) {
       if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
          setState(() => isLoading = false);
       } 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ride Navigation")),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: pickup,
              zoom: 12,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Card(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text("Going to: ${widget.rideData['dropoff_address']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 10),
                     if(isLoading)
                       const CircularProgressIndicator()
                     else
                       SizedBox(
                         width: double.infinity,
                         child: ElevatedButton(
                           onPressed: _completeRide,
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                           child: const Text("Delivered & Finish"),
                         ),
                       )
                   ],
                 ),
               ),
            ),
          )
        ],
      ),
    );
  }
}

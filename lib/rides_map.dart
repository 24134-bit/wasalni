import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideMapPage extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  const RideMapPage({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
  });

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      Marker(markerId: const MarkerId('pickup'), position: LatLng(pickupLat, pickupLng), infoWindow: const InfoWindow(title: "Pickup")),
      Marker(markerId: const MarkerId('dropoff'), position: LatLng(dropLat, dropLng), infoWindow: const InfoWindow(title: "Dropoff")),
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Ride Map")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(pickupLat, pickupLng),
          zoom: 12,
        ),
        markers: markers,
      ),
    );
  }
}

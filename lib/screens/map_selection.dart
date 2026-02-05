import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../lang.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapSelectionPage extends StatefulWidget {
  final String title;
  const MapSelectionPage({super.key, required this.title});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _searchLocation() async {
    if(_searchController.text.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final apiKey = "AIzaSyCZSKdO45onQVeq-ZAe1_2DJTzV-918qbo";
      final url = "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(_searchController.text)}&key=$apiKey";
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);
      
      if(data['status'] == 'OK' && data['results'].isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        final coord = LatLng(loc['lat'], loc['lng']);
        setState(() {
          _selectedLocation = coord;
          _isSearching = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(coord, 15));
      } else {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location not found")));
         setState(() => _isSearching = false);
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isSearching = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  void _setInitialLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLocation!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green, size: 30),
              onPressed: () => Navigator.pop(context, _selectedLocation),
            )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(18.0735, -15.9582), zoom: 12),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (loc) => setState(() => _selectedLocation = loc),
            markers: _selectedLocation == null ? <Marker>{} : <Marker>{
              Marker(markerId: const MarkerId('picked'), position: _selectedLocation!)
            },
          ),
          Positioned(
            top: 20, left: 20, right: 20,
            child: Column(
              children: [
                Card(
                  elevation: 5,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: Lang.get('search_loc'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      suffixIcon: _isSearching 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(icon: const Icon(Icons.search), onPressed: _searchLocation),
                      border: InputBorder.none
                    ),
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
                const SizedBox(height: 10),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("اضغط على الخريطة لتحديد الموقع، أو استخدم البحث أعلاه", textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

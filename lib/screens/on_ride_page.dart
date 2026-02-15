import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import '../config.dart';
import '../lang.dart';

class OnRidePage extends StatefulWidget {
  final int driverId;
  final Map<String, dynamic> rideData;

  const OnRidePage({super.key, required this.driverId, required this.rideData});

  @override
  State<OnRidePage> createState() => _OnRidePageState();
}

class _OnRidePageState extends State<OnRidePage> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _statusCheckTimer;
  Timer? _priceTimer;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;
  double _currentPrice = 0.0;
  double _pricePerMin = 0.0;
  bool isOpenRide = false;
  bool isLoading = false;
  late LatLng pickup;
  late LatLng dropoff;

  @override
  void initState() {
    super.initState();
    isOpenRide = widget.rideData['type'] == 'open';
    _currentPrice = double.tryParse(widget.rideData['total_price'].toString()) ?? 0.0;
    
    pickup = LatLng(
      double.parse(widget.rideData['pickup_lat'].toString()), 
      double.parse(widget.rideData['pickup_lng'].toString())
    );
    dropoff = LatLng(
      double.parse(widget.rideData['dropoff_lat'].toString()), 
      double.parse(widget.rideData['dropoff_lng'].toString())
    );
    _setMarkers();
    _setPolylines();

    if (isOpenRide) {
      _fetchSettingsAndStartTimer();
    }
    
    // Check if ride is still active (not cancelled by admin)
    _startStatusCheck();

    // Start live tracking
    _startLiveTracking();
  }

  void _startLiveTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _updatePolylines();
        });
      }
    });
  }

  void _updatePolylines() {
    Set<Polyline> newPolylines = {};
    List<LatLng> points = [];

    if (_currentPosition != null) {
      points.add(_currentPosition!);
    }
    points.add(pickup);
    points.add(dropoff);

    newPolylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 5,
      )
    );

    setState(() {
      _polylines = newPolylines;
    });
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
       try {
         final res = await http.get(
           Uri.parse("${Config.baseUrl}/available_rides.php?action=active_ride&driver_id=${widget.driverId}"), 
           headers: Config.headers
         );
         final data = json.decode(res.body);
         
         if (mounted) {
           if (!data['success'] || data['ride'] == null || data['ride']['id'].toString() != widget.rideData['id'].toString()) {
             // Ride is gone!
             _statusCheckTimer?.cancel();
             _showCancelledDialog();
           }
         }
       } catch (e) {}
    });
  }

  void _showCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("تنبيه", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("عذراً، هذه الرحلة تم إلغاؤها من قبل المسؤول."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Exit ride page
            }, 
            child: const Text("حسناً")
          )
        ],
      )
    );
  }

  void _fetchSettingsAndStartTimer() async {
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/get_settings.php"), headers: Config.headers);
      var settings = json.decode(res.body);
      _pricePerMin = double.tryParse(settings['price_min'].toString()) ?? 1.0;
      
      // If price is 0 (just started), set it to base_fare
      if (_currentPrice == 0) {
        _currentPrice = double.tryParse(settings['base_fare'].toString()) ?? 5.0;
      }

      _priceTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {
            _currentPrice += _pricePerMin;
          });
        }
      });
    } catch (e) {
      debugPrint("Error fetching settings: $e");
    }
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _statusCheckTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _setPolylines() {
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [pickup, dropoff],
          color: Colors.blue,
          width: 5,
        )
      );
    });
  }

  void _setMarkers() {
    final pickupTitle = Lang.get('pickup');
    final dropoffTitle = Lang.get('dropoff');
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: InfoWindow(title: pickupTitle, snippet: widget.rideData['pickup_address']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          infoWindow: InfoWindow(title: dropoffTitle, snippet: widget.rideData['dropoff_address']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  void _finishRide() async {
    setState(() => isLoading = true);
    try {
      var response;
      try {
         Position p = await Geolocator.getCurrentPosition();
         response = await http.post(
            Uri.parse("${Config.baseUrl}/finish_ride.php"),
            headers: Config.headers,
            body: {
              "ride_id": widget.rideData['id'].toString(),
              "d_lat": p.latitude.toString(),
              "d_lng": p.longitude.toString()
            }
         );
      } catch(e) {
         // Fallback if location fails
         response = await http.post(
            Uri.parse("${Config.baseUrl}/finish_ride.php"),
            headers: Config.headers,
            body: {
              "ride_id": widget.rideData['id'].toString(),
              "d_lat": "0", 
              "d_lng": "0" 
            }
          );
      }

      var data = json.decode(response.body);

      if(!mounted) return;

      if(data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.get('ride_finished'))));
        Navigator.pop(context); // Back to Home
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'])));
        setState(() => isLoading = false);
      }
    } catch(e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
         setState(() => isLoading = false);
      }
    }
  }

  void _cancelRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Lang.get('cancel')),
        content: const Text("هل أنت متأكد من إلغاء هذه الرحلة؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("لا")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("نعم", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("${Config.baseUrl}/cancel_ride.php"),
        headers: Config.headers,
        body: {
          "ride_id": widget.rideData['id'].toString(),
          "driver_id": widget.driverId.toString()
        }
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(res.body);
      if (mounted) {
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف الرحلة بنجاح")));
          
          // Clear timers before popping
          _priceTimer?.cancel();
          _statusCheckTimer?.cancel();
          _positionStream?.cancel();
          
          Navigator.pop(context); // Go back to Home
        } else {
          String errorMsg = data['error'] ?? "فشل الحذف";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الاتصال: $e"), backgroundColor: Colors.red));
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.get('on_trip')),
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
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(target: pickup, zoom: 13),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _controller.complete(controller),
          ),
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                   children: [
                     Text("${Lang.get('dropoff')}: ${widget.rideData['dropoff_address']}", style: const TextStyle(fontSize: 16)),
                     if(widget.rideData['customer_phone'] != null) ...[
                       const SizedBox(height: 5),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.phone, size: 16, color: Colors.green),
                           const SizedBox(width: 5),
                           Text("${Lang.get('customer_phone_label')}: ${widget.rideData['customer_phone']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                         ],
                       ),
                     ],
                     const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            "${Lang.get('price')}: ${_currentPrice.toStringAsFixed(2)} ${Lang.get('sar')}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (isOpenRide) 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text("(+ $_pricePerMin ${Lang.get('sar')} / min)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      const Divider(),
                      const SizedBox(height: 10),
                      // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _finishRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      Lang.get('finish_ride', context),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              ),
            ),
          ),
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

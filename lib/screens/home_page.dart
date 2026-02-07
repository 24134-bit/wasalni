import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../config.dart';
import '../lang.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import 'available_rides.dart';
import 'wallet.dart';
import 'services_fees.dart';
import 'on_ride_page.dart';
import '../services/notification_service.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget {
  final int driverId;
  const HomePage({super.key, required this.driverId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer();
  bool isOnline = true;
  double balance = 0.0;
  String captainName = "Captain";
  String? photoPath;
  LatLng? _currentLatLng;
  bool _isLocationEnabled = false;
  final Set<Marker> _markers = {};
  Timer? _locationTimer;
  Timer? _activeRideTimer;
  Map<String, dynamic>? activeRide;

  static const CameraPosition _riyadh = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _fetchWalletInfo();
    _fetchActiveRide();
    // Start notification polling for Captain
    NotificationService.startPolling(context, widget.driverId, 'driver');
    // Update location every 10 seconds if online
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if(isOnline) _updateLocation();
    });
    // Fetch active ride every 30 seconds
    _activeRideTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchActiveRide();
    });
  }

  @override
  void dispose() {
    NotificationService.stopPolling();
    _locationTimer?.cancel();
    _activeRideTimer?.cancel();
    super.dispose();
  }

  void _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      if(!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(Lang.get('loc_required')),
          content: Text(Lang.get('loc_required')),
          actions: [
            TextButton(onPressed: () => _checkLocationPermission(), child: Text(Lang.get('confirm')))
          ],
        )
      );
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
       // Request to enable service
       return;
    }

    setState(() => _isLocationEnabled = true);
  }

  void _fetchWalletInfo() async {
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/wallet.php?driver_id=${widget.driverId}"), headers: Config.headers);
      var data = json.decode(res.body);
      if(mounted && data['success']) {
        setState(() {
          balance = double.parse(data['balance'].toString());
          captainName = data['name'] ?? "Captain";
          photoPath = data['photo_path'];
        });
      }
    } catch(e) {}
  }

  void _fetchActiveRide() async {
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/available_rides.php?action=active_ride&driver_id=${widget.driverId}"), headers: Config.headers);
      var data = json.decode(res.body);
      if(mounted && data['success']) {
        setState(() => activeRide = data['ride']);
      } else if(mounted) {
        setState(() => activeRide = null);
      }
    } catch(e) {}
  }

  void _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentLatLng = LatLng(position.latitude, position.longitude));

      // Move camera
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_currentLatLng!));

      // Send to Backend
      await http.post(
        Uri.parse("${Config.baseUrl}/update_location.php"),
        headers: Config.headers,
        body: {
          "driver_id": widget.driverId.toString(),
          "lat": position.latitude.toString(),
          "lng": position.longitude.toString(),
          "is_online": isOnline ? "1" : "0"
        }
      );
    } catch (e) {

    }
  }

  void _toggleOnline() {
    setState(() => isOnline = !isOnline);
    _updateLocation(); 
  }

  // _fetchOtherCaptains removed as per user request (Admin only visibility)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.get('home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsPage(userId: widget.driverId, role: 'driver'))),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D47A1)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white, 
                    radius: 30, 
                    backgroundImage: (photoPath != null && photoPath!.isNotEmpty) 
                      ? NetworkImage(Config.getImageUrl(photoPath)) 
                      : null,
                    child: (photoPath == null || photoPath!.isEmpty) 
                      ? const Icon(Icons.person, color: Color(0xFF0D47A1), size: 40) 
                      : null
                  ),
                  const SizedBox(height: 10),
                  Text(captainName, style: const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text("Wallet"),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => WalletPage(driverId: widget.driverId)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(Lang.get('services_fees_title')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesFeesPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(Lang.get('logout'), style: const TextStyle(color: Colors.red)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if(!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _riyadh,
            myLocationEnabled: true,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          // Top Info Card
          Positioned(
            top: 50, 
            left: 20, 
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(3),
                         decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                         child: CircleAvatar(
                            backgroundColor: Colors.white, 
                            radius: 25, 
                            backgroundImage: (photoPath != null && photoPath!.isNotEmpty) 
                              ? NetworkImage(Config.getImageUrl(photoPath)) 
                              : null,
                            child: (photoPath == null || photoPath!.isEmpty) 
                              ? const Icon(Icons.person, color: Color(0xFF0D47A1), size: 30) 
                              : null
                          ),
                       ),
                       const SizedBox(width: 15),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(captainName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                           Text("${balance.toStringAsFixed(2)} ${Lang.get('sar')}", style: const TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold, fontSize: 16)),
                         ],
                       ),
                     ],
                   ),
                   // Online Status & Logout Toggle
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       GestureDetector(
                         onTap: _toggleOnline,
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           decoration: BoxDecoration(
                             color: isOnline ? const Color(0xFF2ECC71) : Colors.redAccent,
                             borderRadius: BorderRadius.circular(20),
                             boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                           ),
                           child: Row(
                             children: [
                               Icon(isOnline ? Icons.wifi : Icons.wifi_off, color: Colors.white, size: 20),
                               const SizedBox(width: 8),
                               Text(isOnline ? Lang.get('online') : Lang.get('offline'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                             ],
                           ),
                         ),
                       ),
                       const SizedBox(height: 8),
                       GestureDetector(
                         onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            if(!mounted) return;
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                         },
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.2),
                             borderRadius: BorderRadius.circular(10),
                           ),
                           child: Text(Lang.get('logout'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                         ),
                       )
                     ],
                   )
                ],
              ),
            ),
          ),
          
          // Wallet Quick Access (New)
          Positioned(
            top: 160,
            left: 20,
            right: 20,
            child: GestureDetector(
               onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (_) => WalletPage(driverId: widget.driverId)));
               },
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Color(0xFF0D47A1), size: 28),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(Lang.get('wallet'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                               Text(Lang.get('recharge'), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
                   ],
                 ),
               ),
            ),
          ),
          // Ongoing Ride Card (New)
          if(activeRide != null)
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.orange[50], 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.orange, width: 1)),
              child: ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.orange, size: 30),
                title: Text(Lang.get('ongoing_ride'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${activeRide!['pickup_address']} -> ${activeRide!['dropoff_address']}"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(
                       builder: (_) => OnRidePage(driverId: widget.driverId, rideData: activeRide!)
                     ));
                  },
                  child: Text(Lang.get('resume_ride')),
                ),
              ),
            ),
          ),
          // Bottom Action Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.list_alt, size: 28),
                label: Text(Lang.get('available_rides'), style: const TextStyle(fontSize: 18, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  elevation: 10,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                onPressed: () async {
                   await Navigator.push(context, MaterialPageRoute(builder: (_) => AvailableRidesPage(driverId: widget.driverId)));
                   _fetchActiveRide(); // Refresh on return
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

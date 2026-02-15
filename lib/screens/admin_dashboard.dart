
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../lang.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_selection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/notification_service.dart';
import 'notifications_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> pendingDeposits = [];
  bool isLoading = true;

  // New Ride Controllers
  bool isOpenRide = false;
  final pickupCtrl = TextEditingController();
  final dropoffCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final customerPhoneCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  LatLng? pickupCoord;
  LatLng? dropoffCoord;
  List<dynamic> activeRides = [];
  bool isLoadingRides = false;
  Timer? _refreshTimer;
  
  // New Captain Controllers
  final captNameCtrl = TextEditingController();
  final captPhoneCtrl = TextEditingController();
  final captPassCtrl = TextEditingController();
  final captCarCtrl = TextEditingController();
  Set<Marker> _captainMarkers = {};
  Timer? _liveMapTimer;
  XFile? captainPhoto;
  
  // Settings Controllers
  final priceKmCtrl = TextEditingController();
  final priceMinCtrl = TextEditingController();
  final baseFareCtrl = TextEditingController();
  final commissionCtrl = TextEditingController();
  double _currentPriceKm = 10;
  double _currentBaseFare = 5;

  Future _pickCaptainPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image!=null) setState(() => captainPhoto = image);
  }



  @override
  void initState() {
    super.initState();
    // Start notification polling for Admin (using ID 0 as generic admin id since role is what matters)
    NotificationService.startPolling(context, 0, 'admin');

    _tabController = TabController(length: 7, vsync: this);
    _loadDeposits();
    _loadActiveRides();
    _loadSettings();
    _fetchCaptainsForMap();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_tabController.index == 4) _loadActiveRides();
    });
    _liveMapTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_tabController.index == 5) _fetchCaptainsForMap();
    });
  }

  @override
  void dispose() {
    NotificationService.stopPolling();
    _refreshTimer?.cancel();
    _liveMapTimer?.cancel();
    super.dispose();
  }

  void _fetchCaptainsForMap() async {
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/get_captains_locations.php"), headers: Config.headers);
      var data = json.decode(res.body) as List;
      Set<Marker> markers = {};
      for(var c in data) {
         markers.add(Marker(
           markerId: MarkerId("c_${c['id']}"),
           position: LatLng(
             double.tryParse(c['last_lat']?.toString() ?? "0") ?? 0, 
             double.tryParse(c['last_lng']?.toString() ?? "0") ?? 0
           ),
           infoWindow: InfoWindow(title: c['name'], snippet: c['car_number']),
           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
         ));
      }
      if(mounted) setState(() => _captainMarkers = markers);
    } catch(e) {}
  }

  void _loadDeposits() async {
    setState(() => isLoading = true);
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/admin_deposits.php"), headers: Config.headers);
      if(mounted) {
        setState(() {
          pendingDeposits = json.decode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  void _loadActiveRides() async {
    setState(() => isLoadingRides = true);
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/available_rides.php?action=list_all"), headers: Config.headers);
      if(mounted) {
        var data = json.decode(res.body);
        if (data is List) {
          setState(() {
            activeRides = data;
            isLoadingRides = false;
          });
        } else {
           // Handle error or empty
           if(mounted) setState(() => isLoadingRides = false);
        }
      }
    } catch (e) {
      if(mounted) setState(() => isLoadingRides = false);
    }
  }

  void _adminCancelRide(int rideId) async {
    try {
      var res = await http.post(
        Uri.parse("${Config.baseUrl}/admin_cancel_ride.php"),
        headers: Config.headers,
        body: {"ride_id": rideId.toString()}
      );
      var data = json.decode(res.body);
      if(!mounted) return;
      if(data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride Cancelled & Refunded", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        _loadActiveRides();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${data['error']}")));
      }
    } catch(e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _pickLocation(bool isPickup) async {
    LatLng? loc = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => MapSelectionPage(title: isPickup ? Lang.get('pickup') : Lang.get('dropoff'))
    ));
    if(loc != null) {
      setState(() {
        if(isPickup) {
          pickupCoord = loc;
          pickupCtrl.text = "Coordinate: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}";
        } else {
          dropoffCoord = loc;
          dropoffCtrl.text = "Coordinate: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}";
        }
        _calculatePrice();
      });
    }
  }

  void _calculatePrice() {
    if(pickupCoord != null && dropoffCoord != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        pickupCoord!.latitude, pickupCoord!.longitude,
        dropoffCoord!.latitude, dropoffCoord!.longitude
      );
      double distanceInKm = distanceInMeters / 1000;
      // Dynamic Price
      double calculatedPrice = _currentBaseFare + (distanceInKm * _currentPriceKm);
      priceCtrl.text = calculatedPrice.toStringAsFixed(0);
    }
  }

  void _loadSettings() async {
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/get_settings.php"), headers: Config.headers);
      var data = json.decode(res.body);
      setState(() {
        priceKmCtrl.text = data['price_km'].toString();
        priceMinCtrl.text = data['price_min'].toString();
        baseFareCtrl.text = data['base_fare'].toString();
        commissionCtrl.text = data['commission_percent']?.toString() ?? "10";
        _currentPriceKm = double.parse(data['price_km'].toString());
        _currentBaseFare = double.parse(data['base_fare'].toString());
      });
    } catch(e) {}
  }

  void _saveSettings() async {
    try {
      await http.post(
        Uri.parse("${Config.baseUrl}/update_settings.php"),
        headers: Config.headers,
        body: {
          "price_km": priceKmCtrl.text,
          "price_min": priceMinCtrl.text,
          "base_fare": baseFareCtrl.text,
          "commission_percent": commissionCtrl.text
        }
      );
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Saved Successfully!")));
      _loadSettings(); // Reload to update current values for calculation
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _process(int id, bool approved) async {
    final action = approved ? 'approve' : 'reject';
    http.Response? res;
    try {
      res = await http.post(
        Uri.parse("${Config.baseUrl}/admin_approve_recharge.php"),
        headers: Config.headers,
        body: {"id": id.toString(), "action": action}
      );
      
      final respStr = res.body;
      final jsonFinder = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonFinder.firstMatch(respStr);
      String cleanBody = match != null ? match.group(0)! : respStr;
      
      var data = json.decode(cleanBody);
      
      if(!mounted) return;
      if (data['success'] == true) {
        String msg = approved ? "Approved Successfully" : "Rejected Successfully";
        if (data['new_balance'] != null) {
          msg += ". New Balance: ${data['new_balance']}";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green)
        );
        _loadDeposits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data['error']}"), backgroundColor: Colors.red)
        );
      }
    } catch(e) {
      if(mounted) {
        String errorMsg = "Format Error: $e";
        if (res != null) {
          errorMsg += "\nRaw Response: ${res.body}";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ));
      }
    }
  }

  void _createRide() async {
    if(pickupCtrl.text.isEmpty) return;
    if(!isOpenRide && (dropoffCtrl.text.isEmpty || priceCtrl.text.isEmpty)) return;
    
    final pLat = pickupCoord?.latitude.toString() ?? "18.0735";
    final pLng = pickupCoord?.longitude.toString() ?? "-15.9582";
    final dLat = dropoffCoord?.latitude.toString() ?? "18.0800";
    final dLng = dropoffCoord?.longitude.toString() ?? "-15.9500";

    try {
      var res = await http.post(
        Uri.parse("${Config.baseUrl}/create_ride.php"),
        headers: Config.headers,
        body: {
          "pickup": pickupCtrl.text,
          "dropoff": isOpenRide ? "" : dropoffCtrl.text,
          "price": isOpenRide ? "0" : priceCtrl.text,
          "p_lat": pLat, 
          "p_lng": pLng, 
          "d_lat": dLat, 
          "d_lng": dLng,
          "customer_phone": customerPhoneCtrl.text,
          "type": isOpenRide ? "open" : "closed"
        }
      );
      var data = json.decode(res.body);
      if(!mounted) return;

      if(data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.get('ride_created_success'))));
        pickupCtrl.clear(); dropoffCtrl.clear(); priceCtrl.clear(); customerPhoneCtrl.clear();
        pickupCoord = null; dropoffCoord = null;
        _loadActiveRides(); // Immediate refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${data['error']}"), backgroundColor: Colors.red));
      }
    } catch(e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _addCaptain() async {
    if(captNameCtrl.text.isEmpty || captPhoneCtrl.text.isEmpty || captPassCtrl.text.isEmpty || captCarCtrl.text.isEmpty) return;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Config.baseUrl}/create_captain.php")
      );
      request.headers.addAll(Config.headers);
      request.fields['name'] = captNameCtrl.text;
      request.fields['phone'] = captPhoneCtrl.text;
      request.fields['password'] = captPassCtrl.text;
      request.fields['car_number'] = captCarCtrl.text;

      if(captainPhoto != null) {
         final bytes = await captainPhoto!.readAsBytes();
         request.files.add(http.MultipartFile.fromBytes(
           'photo', 
           bytes,
           filename: captainPhoto!.name
         ));
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      // Sanitizer for safety
      final jsonFinder = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonFinder.firstMatch(respStr);
      String cleanBody = match != null ? match.group(0)! : respStr;

      var data = json.decode(cleanBody);
      if(!mounted) return;
      if(data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Captain Added Successfully")));
        captNameCtrl.clear(); captPhoneCtrl.clear(); captPassCtrl.clear(); captCarCtrl.clear();
        setState(() => captainPhoto = null);
        _tabController.animateTo(1); // Go to Captains list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${data['error']}")));
      }
    } catch(e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _viewImage(String path) {
    if (path.isEmpty) return;
    
    // Ensure path doesn't have double slashes if prepended
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    String imageUrl = Config.getImageUrl(cleanPath);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              imageUrl, 
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (c, e, s) => Column(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  const Text("Impossible de charger l'image", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("URL: $imageUrl", style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                ]
              )
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.get('admin_dash')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage(userId: 0, role: 'admin'))),
          ),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: Lang.get('admin_approvals')), 
            Tab(text: Lang.get('admin_captains')), 
             Tab(text: Lang.get('admin_create_ride')),
            Tab(text: Lang.get('admin_add_captain')),
            Tab(text: Lang.get('admin_active_rides')),
            Tab(text: Lang.get('admin_live_map')),
            Tab(text: Lang.get('settings')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Approvals Tab
          isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView.builder(
              itemCount: pendingDeposits.length,
              itemBuilder: (ctx, i) {
                var d = pendingDeposits[i];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ExpansionTile(
                    leading: const Icon(Icons.monetization_on, color: Colors.orange),
                    title: Text("${d['driver_name'] ?? 'Driver #${d['driver_id']}'} - ${Lang.get('amount')}: ${d['amount']} MRU"),
                    subtitle: Text("الرقم المحول منه: ${d['sender_phone']}\nرقم العملية: ${d['reference_number']}\n${Lang.get('select_method')}: ${d['method']}"),
                    children: [
                       Padding(
                         padding: const EdgeInsets.all(10),
                         child: Column(
                           children: [
                             if(d['image_path'] != null && d['image_path'] != "")
                               ElevatedButton.icon(
                                 onPressed: () => _viewImage(d['image_path']),
                                 icon: const Icon(Icons.image),
                                 label: Text(Lang.get('view_proof')),
                               ),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                               children: [
                                 ElevatedButton.icon(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                   icon: const Icon(Icons.check),
                                   label: Text(Lang.get('approve')),
                                   onPressed: () => _process(int.parse(d['id'].toString()), true),
                                 ),
                                 ElevatedButton.icon(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                   icon: const Icon(Icons.close),
                                   label: Text(Lang.get('reject')),
                                   onPressed: () => _process(int.parse(d['id'].toString()), false),
                                 ),
                               ],
                             )
                           ],
                         ),
                       )
                    ],
                  ),
                );
              },
            ),
          
          // Captains Tab
          RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: FutureBuilder(
              future: http.get(Uri.parse("${Config.baseUrl}/get_captains.php"), headers: Config.headers),
              builder: (ctx, AsyncSnapshot<http.Response> snapshot) {
                 if(snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                 if(snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                 
                 var captains = [];
                 try {
                   captains = json.decode(snapshot.data!.body);
                 } catch(e) {}
  
                 if(captains.isEmpty) return const Center(child: Text("No captains found."));
  
                 return ListView.builder(
                   itemCount: captains.length,
                   itemBuilder: (ctx, i) {
                     var c = captains[i];
                     bool isOnline = c['is_online'] == '1' || c['is_online'] == true;
                     return Card(
                       child: ListTile(
                         leading: CircleAvatar(
                           backgroundColor: isOnline ? Colors.green : Colors.grey,
                           backgroundImage: (c['photo_path'] != null && c['photo_path'] != "") 
                             ? NetworkImage("${Config.baseUrl}/${c['photo_path']}") 
                             : null,
                           child: (c['photo_path'] == null || c['photo_path'] == "") 
                             ? const Icon(Icons.person, color: Colors.white) 
                             : null,
                         ),
                         title: Text("${c['name'] ?? "Driver ${c['id']}"} (${c['phone']})"),
                         subtitle: Text("${Lang.get('car_number')}: ${c['car_number'] ?? 'N/A'}\n${Lang.get('wallet')}: ${c['balance']} MRU"),
                         isThreeLine: true,
                         trailing: Icon(Icons.circle, color: isOnline ? Colors.green : Colors.grey),
                       ),
                     );
                   },
                 );
              }
            ),
          ),

          // Create Ride Tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Ride Type Toggle
                  Row(
                    children: [
                      Text("${Lang.get('ride_type')}:", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      ChoiceChip(label: Text(Lang.get('ride_closed')), selected: !isOpenRide, onSelected: (v) => setState(() => isOpenRide = !v)),
                      const SizedBox(width: 5),
                      ChoiceChip(label: Text(Lang.get('ride_open')), selected: isOpenRide, onSelected: (v) => setState(() => isOpenRide = v)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: pickupCtrl, decoration: InputDecoration(labelText: Lang.get('pickup'), prefixIcon: const Icon(Icons.location_on)))),
                      IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => _pickLocation(true))
                    ],
                  ),
                  const SizedBox(height: 10),
                  if(!isOpenRide) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: dropoffCtrl, decoration: InputDecoration(labelText: Lang.get('dropoff'), prefixIcon: const Icon(Icons.flag)))),
                          IconButton(icon: const Icon(Icons.map, color: Colors.red), onPressed: () => _pickLocation(false))
                        ],
                      ),
                    ],
                  const SizedBox(height: 10),
                  TextField(controller: customerPhoneCtrl, decoration: InputDecoration(labelText: Lang.get('customer_phone_label'), prefixIcon: const Icon(Icons.phone)), keyboardType: TextInputType.phone),
                  if(!isOpenRide) ...[
                    const SizedBox(height: 10),
                    TextField(controller: priceCtrl, decoration: InputDecoration(labelText: Lang.get('price'), prefixIcon: const Icon(Icons.account_balance), suffixText: "MRU"), keyboardType: TextInputType.number),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(onPressed: _createRide, child: Text(Lang.get('admin_create_ride'))),
                  )
                ],
              ),
            ),
          ),

          // Add Captain Tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(Lang.get('admin_add_captain'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: captNameCtrl, decoration: InputDecoration(labelText: Lang.get('name'), prefixIcon: const Icon(Icons.person))),
                  const SizedBox(height: 10),
                  TextField(controller: captPhoneCtrl, decoration: InputDecoration(labelText: Lang.get('phone'), prefixIcon: const Icon(Icons.phone)), keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  TextField(controller: captPassCtrl, decoration: InputDecoration(labelText: Lang.get('password'), prefixIcon: const Icon(Icons.lock)), obscureText: true),
                  const SizedBox(height: 10),
                  TextField(controller: captCarCtrl, decoration: InputDecoration(labelText: Lang.get('car_number'), prefixIcon: const Icon(Icons.directions_car))),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _pickCaptainPhoto,
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                      child: captainPhoto == null 
                        ? const Center(child: Text("اضغط لرفع صورة الكابتن")) 
                        : Image.network(captainPhoto!.path, errorBuilder: (c,e,s) => Center(child: Text("تم اختيار الصورة: ${captainPhoto!.name}"))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
                      onPressed: _addCaptain, 
                      child: Text(Lang.get('submit'), style: const TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Active Rides Tab (New)
          isLoadingRides 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(hintText: Lang.get('search_customer'), prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder()),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _loadActiveRides(),
                    child: activeRides.where((r) => r['customer_phone']?.toString().contains(searchCtrl.text) ?? true).isEmpty 
                    ? Center(child: Text(Lang.get('no_matching_rides')))
                    : ListView.builder(
                        itemCount: activeRides.where((r) => r['customer_phone']?.toString().contains(searchCtrl.text) ?? true).length,
                        itemBuilder: (ctx, i) {
                          var r = activeRides.where((r) => r['customer_phone']?.toString().contains(searchCtrl.text) ?? true).toList()[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.local_taxi),
                              title: Text("${r['pickup_address']} -> ${r['dropoff_address']}"),
                              subtitle: Text("${Lang.get('customer_phone_label')}: ${r['customer_phone'] ?? 'N/A'}\n${Lang.get('status')}: ${Lang.get('status_' + r['status'])} | ${r['total_price']} ${Lang.get('sar')}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _adminCancelRide(int.parse(r['id'].toString())),
                              ),
                            ),
                          );
                        },
                      ),
                  ),
                ),
              ],
            ),
          // Live Map Tab
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(18.0735, -15.9582), zoom: 12),
            markers: _captainMarkers,
          ),
          
          // Settings Tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(Lang.get('price_configs'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: priceKmCtrl, decoration: InputDecoration(labelText: Lang.get('price_per_km'), prefixIcon: const Icon(Icons.directions_car)), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: priceMinCtrl, decoration: InputDecoration(labelText: Lang.get('price_per_min'), prefixIcon: const Icon(Icons.timer)), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: baseFareCtrl, decoration: InputDecoration(labelText: Lang.get('base_fare'), prefixIcon: const Icon(Icons.start)), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: commissionCtrl, decoration: InputDecoration(labelText: Lang.get('commission_label'), prefixIcon: const Icon(Icons.percent)), keyboardType: TextInputType.number),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: Text(Lang.get('save_changes')),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

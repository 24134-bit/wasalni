
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

  Future _pickCaptainPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image!=null) setState(() => captainPhoto = image);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDeposits();
    _loadActiveRides();
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
    _refreshTimer?.cancel();
    _liveMapTimer?.cancel();
    super.dispose();
  }

  void _fetchCaptainsForMap() async {
    try {
      var res = await http.get(Uri.parse("${Config.baseUrl}/get_captains_locations.php"));
      var data = json.decode(res.body) as List;
      Set<Marker> markers = {};
      for(var c in data) {
         markers.add(Marker(
           markerId: MarkerId("c_${c['id']}"),
           position: LatLng(double.parse(c['last_lat']), double.parse(c['last_lng'])),
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
      var res = await http.get(Uri.parse("${Config.baseUrl}/admin_deposits.php"));
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
      var res = await http.get(Uri.parse("${Config.baseUrl}/available_rides.php?action=list_all"));
      if(mounted) {
        setState(() {
          activeRides = json.decode(res.body);
          isLoadingRides = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => isLoadingRides = false);
    }
  }

  void _adminCancelRide(int rideId) async {
    try {
      var res = await http.post(
        Uri.parse("${Config.baseUrl}/admin_cancel_ride.php"),
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
      // Price = 10 MRU per km
      double calculatedPrice = distanceInKm * 10;
      priceCtrl.text = calculatedPrice.toStringAsFixed(0);
    }
  }

  void _process(int id, bool approved) async {
    final action = approved ? 'approve' : 'reject';
    try {
      await http.post(
        Uri.parse("${Config.baseUrl}/admin_approve_recharge.php"),
        body: {"id": id.toString(), "action": action}
      );
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? "Approved" : "Rejected"))
      );
      _loadDeposits();
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _createRide() async {
    if(pickupCtrl.text.isEmpty || dropoffCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
    
    final pLat = pickupCoord?.latitude.toString() ?? "18.0735";
    final pLng = pickupCoord?.longitude.toString() ?? "-15.9582";
    final dLat = dropoffCoord?.latitude.toString() ?? "18.0800";
    final dLng = dropoffCoord?.longitude.toString() ?? "-15.9500";

    try {
      await http.post(
        Uri.parse("${Config.baseUrl}/create_ride.php"),
        body: {
          "pickup": pickupCtrl.text,
          "dropoff": dropoffCtrl.text,
          "price": priceCtrl.text,
          "p_lat": pLat, 
          "p_lng": pLng, 
          "d_lat": dLat, 
          "d_lng": dLng,
          "customer_phone": customerPhoneCtrl.text
        }
      );
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride Created Successfully")));
      pickupCtrl.clear(); dropoffCtrl.clear(); priceCtrl.clear(); customerPhoneCtrl.clear();
      pickupCoord = null; dropoffCoord = null;
    } catch(e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _addCaptain() async {
    if(captNameCtrl.text.isEmpty || captPhoneCtrl.text.isEmpty || captPassCtrl.text.isEmpty || captCarCtrl.text.isEmpty) return;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Config.baseUrl}/create_captain.php")
      );
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
    String imageUrl = Config.getImageUrl(path);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imageUrl, errorBuilder: (c, e, s) => Column(children: [const Icon(Icons.error, color: Colors.red), Text("Error loading image\nURL: $imageUrl", style: const TextStyle(fontSize: 10))])),
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
               final prefs = await SharedPreferences.getInstance();
               await prefs.clear();
               if(!context.mounted) return;
               Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
            Tab(text: Lang.get('admin_live_map'))
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
                    title: Text("${Lang.get('amount')}: ${d['amount']} ${Lang.get('sar')}"),
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
                                   onPressed: () => _process(int.parse(d['id']), true),
                                 ),
                                 ElevatedButton.icon(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                   icon: const Icon(Icons.close),
                                   label: Text(Lang.get('reject')),
                                   onPressed: () => _process(int.parse(d['id']), false),
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
          FutureBuilder(
            future: http.get(Uri.parse("${Config.baseUrl}/get_captains.php")),
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
                   bool isOnline = c['is_online'] == '1';
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
                       subtitle: Text("${Lang.get('car_number')}: ${c['car_number'] ?? 'N/A'}\n${Lang.get('wallet')}: ${c['balance']} ${Lang.get('sar')}"),
                       isThreeLine: true,
                       trailing: Icon(Icons.circle, color: c['is_online'] == "1" ? Colors.green : Colors.grey),
                     ),
                   );
                 },
               );
            }
          ),

          // Create Ride Tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: pickupCtrl, decoration: InputDecoration(labelText: Lang.get('pickup'), prefixIcon: const Icon(Icons.location_on)))),
                      IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => _pickLocation(true))
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: dropoffCtrl, decoration: InputDecoration(labelText: Lang.get('dropoff'), prefixIcon: const Icon(Icons.flag)))),
                      IconButton(icon: const Icon(Icons.map, color: Colors.red), onPressed: () => _pickLocation(false))
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: customerPhoneCtrl, decoration: const InputDecoration(labelText: "رقم هاتف الزبون", prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  TextField(controller: priceCtrl, decoration: InputDecoration(labelText: Lang.get('price'), prefixIcon: const Icon(Icons.account_balance), suffixText: "MRU"), keyboardType: TextInputType.number),
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
                    decoration: const InputDecoration(hintText: "بحث برقم هاتف الزبون...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _loadActiveRides(),
                    child: activeRides.where((r) => r['customer_phone']?.toString().contains(searchCtrl.text) ?? true).isEmpty 
                    ? const Center(child: Text("No Matching Rides"))
                    : ListView.builder(
                        itemCount: activeRides.where((r) => r['customer_phone']?.toString().contains(searchCtrl.text) ?? true).length,
                        itemBuilder: (ctx, i) {
                          var r = activeRides.where((r) => r['customer_phone']?.toString().contains(searchCtrl.text) ?? true).toList()[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.local_taxi),
                              title: Text("${r['pickup_address']} -> ${r['dropoff_address']}"),
                              subtitle: Text("الزبون: ${r['customer_phone'] ?? 'N/A'}\n${Lang.get('status_' + r['status'])} | ${r['total_price']} MRU"),
                              trailing: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _adminCancelRide(int.parse(r['id'])),
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
          )
        ],
      ),
    );
  }
}

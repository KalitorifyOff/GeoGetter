import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geocoding Full Address',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Location & Address'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  Position? _currentPosition;
  String? _address;
  bool _locationServiceEnabled = true;
  bool _isLoading = false;
  bool _cameFromSettings = false;
  bool _useNetwork = false; // ⬅️ Switch control

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _cameFromSettings) {
      _cameFromSettings = false;
      initFlow();
    }
  }

  Future<void> initFlow() async {
    setState(() {
      _isLoading = true;
      _locationServiceEnabled = true;
      _address = null;
    });

    bool ready = await checkPermissionsAndServices();
    if (ready) {
      await getCurrentLocation();
      await getAddress(); // ⬅️ Chooses geocoding or network
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> checkPermissionsAndServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Location Service Disabled"),
              content: const Text("Please enable location services."),
              actions: [
                TextButton(
                  onPressed: () {
                    Geolocator.openLocationSettings();
                    _cameFromSettings = true;
                    Navigator.pop(context);
                  },
                  child: const Text("Open Settings"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            ),
      );
      setState(() {
        _locationServiceEnabled = false;
      });
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.deniedForever) {
        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Permission Denied Forever"),
                content: const Text(
                  "Please enable location permission in settings.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Geolocator.openAppSettings();
                      _cameFromSettings = true;
                      Navigator.pop(context);
                    },
                    child: const Text("Open App Settings"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ],
              ),
        );
        return false;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationServiceEnabled = false;
        });
        return false;
      }
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print("Location error: $e");
    }
  }

  Future<void> getAddress() async {
    if (_currentPosition == null) return;

    if (_useNetwork) {
      await getAddressFromNetwork(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } else {
      await getAddressFromGeocoding(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
  }

  Future<void> getAddressFromGeocoding(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _address = '''
name: ${place.name}
street: ${place.street}
thoroughfare: ${place.thoroughfare}
subThoroughfare: ${place.subThoroughfare}
locality: ${place.locality}
subLocality: ${place.subLocality}
administrativeArea: ${place.administrativeArea}
subAdministrativeArea: ${place.subAdministrativeArea}
postalCode: ${place.postalCode}
country: ${place.country}
isoCountryCode: ${place.isoCountryCode}
''';
        });
      }
    } catch (e) {
      print("Geocoding error: $e");
    }
  }

  Future<void> getAddressFromNetwork(double latitude, double longitude) async {
    const int maxRetries = 5;
    int attempt = 0;
    http.Response? response;

    while (attempt < maxRetries) {
      attempt++;
      try {
        final url =
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';

        response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'FlutterApp'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _address = data['display_name'] ?? "No address found";
          });
          return;
        } else {
          print("Error status: ${response.statusCode}");
        }
      } on TimeoutException {
        print("Attempt $attempt: Request timed out");
      } catch (e) {
        print("Attempt $attempt: $e");
      }
    }

    setState(() {
      _address = "Failed to get address from network.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_locationServiceEnabled
              ? const Center(child: Text("Location service is disabled."))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Use Network API"),
                        Switch(
                          value: _useNetwork,
                          onChanged: (val) {
                            setState(() => _useNetwork = val);
                            initFlow(); // re-fetch
                          },
                        ),
                      ],
                    ),
                    if (_currentPosition != null)
                      Text(
                        'Lat: ${_currentPosition!.latitude}, Long: ${_currentPosition!.longitude}',
                      ),
                    const SizedBox(height: 16),
                    const Text("Address:"),
                    Text(_address ?? "Fetching address..."),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: initFlow,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

## 📍 Get Place Details Using Geocoding in Flutter

This Flutter project demonstrates how to get the user's current location and convert the latitude and longitude coordinates into a readable address using the [`geocoding`](https://pub.dev/packages/geocoding) package.

---

### 🚀 Features

* Get current location using `geolocator`
* Convert coordinates to human-readable address using `geocoding`
* Display address in the UI

---

### 📦 Packages Used

| Package    | Description                              |
| ---------- | ---------------------------------------- |
| geolocator | To get the device’s current GPS location |
| geocoding  | To convert coordinates to addresses      |

---

### 📱 Screenshots

> *(Add a screenshot of the UI showing the address here if needed)*

---

### 🛠️ How It Works

1. Request location permissions
2. Get the current position (latitude & longitude)
3. Use `placemarkFromCoordinates()` from `geocoding` package to get address details
4. Display the address in the app

---

### 🔧 Setup Instructions

1. Add dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  geolocator: ^10.1.0
  geocoding: ^2.1.0
```

2. Add the required permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

3. Add the following to your `android/app/build.gradle` (if required):

```gradle
defaultConfig {
  minSdkVersion 21
}
```

---

### 📄 Sample Code

```dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

Future<void> getAddressFromLatLng() async {
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  
  List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude, position.longitude);
  
  Placemark place = placemarks[0];
  print('${place.street}, ${place.locality}, ${place.country}');
}
```

---

### ⚠️ Common Errors

* **DEADLINE\_EXCEEDED / IO\_ERROR**: Network issue or location/geocoding service unavailable.

  * ✅ Ensure device has active internet.
  * ✅ Wrap in timeout for safer use.
  * ✅ Try fallback services like OpenStreetMap if needed.

---

### 🙌 Contribution

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

### 📧 Contact

Feel free to connect on [LinkedIn](https://linkedin.com) or raise an issue here.
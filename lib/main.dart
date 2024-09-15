import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
//import 'dart:async';

List<double> myLocationLatLong = [0,0];
List<String> nearbyFriends = [];
List<String> allFriendsID = [
  "userID01",
  "userID18",
  "userID05",
  "userID10",
  "userID35",
  "userID75",
  "userID85",
  "userID88",
  "userID90",
];

Future<void> getFriendsLocationFromFirestore(Position position) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // await firestore.collection('users').doc("0").update({
  //   'location': GeoPoint(position.latitude, position.longitude),
  //   'lastUpdated': FieldValue.serverTimestamp(),
  // });

  await firestore.collection('users').doc("userID").update({
    'distance': 100,
    'location': GeoPoint(position.latitude, position.longitude),
    'lastUpdated': FieldValue.serverTimestamp(),
  });
}

Future<void> sendLocationToFirestore(Position position) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  await firestore.collection('users').doc("userID").update({
    'location': GeoPoint(position.latitude, position.longitude),
    'lastUpdated': FieldValue.serverTimestamp(),
  });
}

Future<Position> getCurrentLocation() async {
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

// in init
Future<void> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    // Handle permission denied
    // do nothing for now
    print("Can't get location permission!");
  } else {
    print("Got location permission! ");
  }
}

// Future<GeoPoint?> getUserLocation(String userID) async {
Future<GeoPoint> getUserLocation(String userID) async {
    // Get the document snapshot for userID (in this case "0")
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(userID).get();

    // Check if the document exists
    GeoPoint userLocation = GeoPoint(0,0);
    if (documentSnapshot.exists) {
      // Extract the 'location' field which is of type GeoPoint
      userLocation = documentSnapshot.data()?['location'];
    }
    return userLocation;
}

Future<String> getUserName(String userID) async {
  // Get the document snapshot for userID (in this case "0")
  DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
  await FirebaseFirestore.instance.collection('users').doc(userID).get();

  // Check if the document exists
  String username = "You Know Who";
  if (documentSnapshot.exists) {
    // Extract the 'location' field which is of type GeoPoint
    username = documentSnapshot.data()?['name'];
  }
  return username;
}

// unit meters
double calculateDistance(double lat2, double lon2) {
  // calculation for distance here:
  double lat1 = myLocationLatLong[0];
  double lon1 = myLocationLatLong[1];
  double distance = 0;
  print("calculate distance reached");
  // print(lat1.toString());
  // print(lon1.toString());
  // print(lat2.toString());
  // print(lon2.toString());
  // https://community.fabric.microsoft.com/t5/Desktop/How-to-calculate-lat-long-distance/td-p/1488227
  distance = acos(sin(lat1)*sin(lat2)+cos(lat1)*cos(lat2)*cos(lon2-lon1))*6371;
  // print(distance);
  // print("distance: ");
  return distance;
}

Future<bool> isFriendNearby(String friendID) async {
  bool isNearby = false;
  GeoPoint friendPosition = await getUserLocation(friendID);
  double distance = calculateDistance(friendPosition.latitude, friendPosition.longitude);
  if (distance <= 10) {
    isNearby = true;
  }
  return isNearby;

}

// sets the timer
// void startLocationUpdates() {
//   Timer.periodic(Duration(seconds: 10), (Timer timer) async {
//     Position position = await getCurrentLocation();
//     await sendLocationToFirestore(position);
//   });
// }

Future<void> updateNearbyList(Position position) async {
  // update my location - both locally and remotely
  myLocationLatLong[0] = position.latitude;
  myLocationLatLong[1] = position.longitude;
  sendLocationToFirestore(position);
  // who is nearby?
  nearbyFriends = [];

  bool isNearby = false;
  String fname = "";
  // calculation + update nearby list
  for (String friendID in allFriendsID) {
    isNearby = await isFriendNearby(friendID);
    if (isNearby) {
      fname = await getUserName(friendID);
      nearbyFriends.add(fname);
    }
  }
}

// IMPORTANT: this updates everything, includes
//  - my location
//  - my friends location -> nearby list
void startLocationUpdates() {
  Timer.periodic(Duration(seconds: 10), (Timer timer) async {
    Position position = await getCurrentLocation();
    await updateNearbyList(position);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  asyncRunApp();
}

void asyncRunApp() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

List<String> _nearbyFriends = ["FriendA", "FriendB", "FriendC"];
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    requestLocationPermission();

    startLocationUpdates();
  }

  void _updateAllInfo() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _nearbyFriends.add("Friend" + _counter.toString());
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //

    // This functions gets friends nearby as a list and convert them to string
    String getNearbyFriendsString() {
      return nearbyFriends.join('\n');
    }
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text(
              "Let's see who's online: "
            ),
            Text(
              getNearbyFriendsString(),
              style: TextStyle(fontSize: 12),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateAllInfo,
        tooltip: 'Update',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

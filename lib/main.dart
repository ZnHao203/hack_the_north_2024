import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
//import 'dart:async';

// void updateUserLocation(String userID) async {
//   // get and store
//   Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//   FirebaseFirestore.instance.collection('users').doc(userID).update({
//     'location': GeoPoint(position.latitude, position.longitude),
//     'lastUpdated': FieldValue.serverTimestamp(),
//   });
// }

// // // Set a timer to update every 5 minutes
// void handleTimeout(Timer timer) async{  // callback function
//   // Do some work.
//   updateUserLocation("0");
//   _nearbyFriends.add("From counter");
// }

Future<void> sendLocationToFirestore(Position position) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  await firestore.collection('users').doc("0").update({
    'location': GeoPoint(position.latitude, position.longitude),
    'lastUpdated': FieldValue.serverTimestamp(),
  });
}

Future<Position> getCurrentLocation() async {
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

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

void startLocationUpdates() {
  Timer.periodic(Duration(minutes: 1), (Timer timer) async {
    Position position = await getCurrentLocation();
    await sendLocationToFirestore(position);
  });
}

void main() {
  init_firebase();
  //getLocationPermission();
  // updateUserLocation("0");
  // Timer(const Duration(seconds: 60), handleTimeout);
  // Timer.periodic(const Duration(seconds: 60), (timer) {
  //   handleTimeout();
  // });
  // final timer = Timer.periodic(const Duration(seconds: 10), handleTimeout);
  // handleTimeout(timer);


  runApp(const MyApp());
}

Future<void> init_firebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      return _nearbyFriends.join('\n');
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

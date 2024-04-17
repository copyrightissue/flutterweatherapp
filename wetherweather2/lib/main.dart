import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'radar_map.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      // I think this ok to be here, firebase apikeys are public?
      apiKey: "AIzaSyA7Ifgh_kQmOZla1QC4kObdLkQqcQk7v44",
      authDomain: "test-12fa0.firebaseapp.com",
      databaseURL: "https://test-12fa0-default-rtdb.firebaseio.com",
      projectId: "test-12fa0",
      storageBucket: "test-12fa0.appspot.com",
      messagingSenderId: "344443641492",
      appId: "1:344443641492:web:651c3b30fbc469d3ed5e81",
      measurementId: "G-19XY9V4E8R",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wether Weather 2'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: "Home"),
            Tab(icon: Icon(Icons.map), text: "Radar"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WeatherCardsView(),
          RadarMap(), // RadarMap widget
        ],
      ),
    );
  }
}

class WeatherCardsView extends StatefulWidget {
  @override
  _WeatherCardsViewState createState() => _WeatherCardsViewState();
}

class _WeatherCardsViewState extends State<WeatherCardsView> {
  Map<String, dynamic>? todayWeather;
  List<Map<String, dynamic>> forecastDays = [];

  @override
  void initState() {
    super.initState();
    fetchWeatherFromFirestore();
  }
  // Fetch weather data from Firestore, if the error is a firebaseobject then it a little bit breaks
  Future<void> fetchWeatherFromFirestore() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('weather').doc('Missoula').get();

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> forecasts = data['list'];

        if (forecasts.isNotEmpty) {
          // Extract today's weather from the first forecast entry
          setState(() {
            todayWeather = {
              "temp": "${forecasts[0]['main']['temp'].toStringAsFixed(1)}°F",
              "condition": forecasts[0]['weather'][0]['main'],
              "humidity": "${forecasts[0]['main']['humidity']}%",
              "wind": "${forecasts[0]['wind']['speed'].toStringAsFixed(1)} mph",
              "icon": "https://openweathermap.org/img/w/${forecasts[0]['weather'][0]['icon']}.png"
            };
          });

          // Aggregate forecasts for the next 4 days
          forecastDays = [];
          for (int i = 0; i < forecasts.length; i += 8) {
            if (i == 0 || forecastDays.length >= 5) continue; // Skip today's weather and limit to 4 days
            var forecast = forecasts[i];
            forecastDays.add({
              "date": DateFormat('EEEE, MMM d').format(DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000)),
              "avgTemp": "${forecast['main']['temp'].toStringAsFixed(1)}",
              "condition": forecast['weather'][0]['description'],
              "humidity": "${forecast['main']['humidity']}%",
              "wind": "${forecast['wind']['speed'].toStringAsFixed(1)} mph",
              "icon": "https://openweathermap.org/img/w/${forecast['weather'][0]['icon']}.png"
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return todayWeather == null
        // Show a loading indicator while fetching weather data, neat
        ? Center(child: CircularProgressIndicator())
        : ListView(
      children: [
        buildTodayWeatherCard(),
        ...forecastDays.map((day) => buildForecastCard(day)).toList(),
      ],
    );
  }
  // Building the Main weather card, with the current weather
  Widget buildTodayWeatherCard() {
    return Card(
      color: Colors.blue[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TODO: Add current city after "Today"
            Text("Today", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(todayWeather!['icon'], width: 50),
                SizedBox(width: 10),
                Text(todayWeather!['temp'], style: TextStyle(fontSize: 20)),
              ],
            ), //row
            Text(todayWeather!['condition'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Humidity: ${todayWeather!['humidity']}", style: TextStyle(fontSize: 16)),
                Text("Wind: ${todayWeather!['wind']}", style: TextStyle(fontSize: 16)),
              ],
            ),  //Row
          ],
        ), //Column
      ), //Padding
    ); //card
  }

  Widget buildForecastCard(Map<String, dynamic> day) {
    return Card(
      child: ListTile(
        leading: Image.network(day['icon'], width: 50),
        title: Text("${day['date']} - Avg Temp: ${day['avgTemp']}°F"),
        subtitle: Text(day['condition']),
      ), //tile
    ); //card
  }
}
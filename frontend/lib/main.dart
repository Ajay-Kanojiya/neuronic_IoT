import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Node server host and port
const String nodeServer = "http://10.0.2.2";
const int port = 3001;

// API endpoints to fetch control emulator
const String stop = '$nodeServer:$port/stop';
const String start = '$nodeServer:$port/start';
const String fetchSensorData = '$nodeServer:$port/fetch_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Emulator Control',
      theme: ThemeData(
        primaryColor: Color(0xFF007ACC), // Primary color of the application
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: Color(0xFFD3D3D3)), // Secondary color scheme
        scaffoldBackgroundColor: Color(0xFFE0F7FA), // Light blue background
        textTheme: TextTheme(
          headlineMedium: TextStyle(
              color: Color(0xFF333333),
              fontSize: 24,
              fontWeight: FontWeight.bold), // Style for medium headlines
          bodyLarge: TextStyle(
              color: Color(0xFF333333),
              fontSize: 18), // Style for large body text
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18.0)), // Rounded button shape
          buttonColor: Color(0xFF007ACC), // Button color
        ),
      ),
      home: EmulatorControlScreen(), // Sets the initial screen of the app
    );
  }
}

class EmulatorControlScreen extends StatefulWidget {
  @override
  _EmulatorControlScreenState createState() => _EmulatorControlScreenState();
}

class _EmulatorControlScreenState extends State<EmulatorControlScreen> {
  String status = 'Unknown'; // Initial status
  String temperature = 'N/A'; // Initial temperature value
  String humidity = 'N/A'; // Initial humidity value

  Future<void> startEmulator() async {
    var response = await http.post(Uri.parse(start));
    setState(() {
      status = jsonDecode(response.body)['message'];
      print('Emulator started, status: $status');
    });
  }

  Future<void> stopEmulator() async {
    var response = await http.post(Uri.parse(stop));
    setState(() {
      status = jsonDecode(response.body)['message'];
      print('Emulator stopped, status: $status');
    });
  }

  Future<void> fetchData() async {
    var response = await http.get(Uri.parse(fetchSensorData));
    var data = jsonDecode(response.body);
    setState(() {
      temperature = data['temperature'].toStringAsFixed(2);
      humidity = data['humidity'].toStringAsFixed(2);
      print('Data fetched: Temperature = $temperature, Humidity = $humidity');
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the color based on the status
    Color statusColor;
    if (status.toLowerCase() == 'running') {
      statusColor = Colors.green;
    } else if (status.toLowerCase() == 'stopped') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.grey; // Default color for unknown status
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('IoT Emulator Control'),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Card displaying the current status of the emulator
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Status:',
                              style: Theme.of(context).textTheme.headlineMedium),
                          SizedBox(height: 8),
                          Text(status,
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                color: statusColor,
                              )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: startEmulator,
                    child: Text('Start Emulator'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: stopEmulator,
                    child: Text('Stop Emulator'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: fetchData,
                    child: Text('Fetch Data'),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Temperature:',
                              style: Theme.of(context).textTheme.headlineMedium),
                          SizedBox(height: 8),
                          Text('$temperature °C',
                              style: Theme.of(context).textTheme.bodyLarge),
                          SizedBox(height: 20),
                          Text('Humidity:',
                              style: Theme.of(context).textTheme.headlineMedium),
                          SizedBox(height: 8),
                          Text('$humidity %',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

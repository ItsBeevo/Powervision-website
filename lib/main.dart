// Local imports
import 'settings.dart';
import 'panelsData.dart';
import 'panelsWidgets.dart';

// Dart imports
import 'dart:core';
import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';

// Indicating the state of the new data
bool loadedData = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize firebase tools
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MyApp(),
  ));
} 

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {  

  // Contains the new data as soon as they are fetched
  late Future<List<Panel>> panels;

  @override
  void initState() {
    super.initState();

    // Assign new data into panels variable
    panels = fetchData();

    // Timer checking every second if one minute has passed by
    Timer.periodic(Duration(seconds: 1), (timer) {

      // If there is difference between the current minute and the one stored in lastMinute variable
      // This means that a minute has passed by
      if (DateTime.now().minute != lastMinute) {

        // Assign current minute into lastMinute variable
        lastMinute = DateTime.now().minute;

        setState(() {
          // New data will start loading again
          loadedData = false;

          // Assign new data into panels variable
          panels = fetchData();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power vision',
      theme: ThemeData(
        canvasColor: Colors.teal[50],
        scaffoldBackgroundColor: Colors.yellow[100],
      ),
      home: Scaffold(
        backgroundColor: Colors.yellowAccent,
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: Text(
            'Power vision',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true,
          actions: [
            // Settings button
            IconButton(
              icon: Icon(
                Icons.settings,
                color: Colors.white,
              ),
              onPressed: () {
                // Navigate to the settings page
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: FutureBuilder<List<Panel>>(
            future: panels,
            builder: (context, snapshot) {
              // Check if a connection has been accomplished
              if (snapshot.connectionState == ConnectionState.done) {

                // Check if new data has arrived
                if (snapshot.hasData) {
                  // Recent panels is the same as panels variable but global
                  recentPanels = snapshot.data!;

                  // Current panel contains the panel being displayed currently on the screen
                  if (stringCurrentPanel == "Panel 1") currentPanel = recentPanels[0];
                  else if (stringCurrentPanel == "Panel 2") currentPanel = recentPanels[1];
                  else currentPanel = recentPanels[2];

                  // Data has successfully been fetched
                  loadedData = true;
                } 
                else if (snapshot.hasError) {
                  return Text("Something went wrong, please try again later.");
                }
              }
              // Display all widgets related to current selected panel
              return PanelWidget();
            },
          ),
        ),
        drawer: Drawer(
          // List view for choosing the panel to display on the screen
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text(
                  'Panels',
                   style: TextStyle(
                     fontSize: 50,
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                   ),
                ),
                decoration: BoxDecoration(
                  color: Colors.teal[200],
                ),
              ),
              // Display list tiles
              for (int panel = 1; panel <= 3; panel++) ListTile(
                //tileColor: Colors.orange[300],
                title: Text(
                  'Panel ' + panel.toString(),
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 20,
                  ),
                  ),
                onTap: () {
                  // If new data is fetched
                  if (recentPanels.isNotEmpty) {
                    setState(() {         
                      // Current panel displayed on the screen
                      currentPanel = recentPanels[panel - 1];
                      stringCurrentPanel = "Panel " + panel.toString();

                      // Room temperature not selected
                      roomTemperature = false;
                    });
                  }
                }
              ), 
              // Room temperature tile
              ListTile(
                title: Text(
                  'Room Temperature',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 20,
                  ),
                  ),
                onTap: () {
                  if (recentPanels.isNotEmpty) {
                    setState(() {
                      // Since room temperature is fetched through panel 2
                      currentPanel = recentPanels[2];
                      stringCurrentPanel = "Panel 2";

                      // Room temperature is selected
                      roomTemperature = true;
                    });
                  }
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
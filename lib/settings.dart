// Local imports
import 'panelsData.dart';
import 'settingsPageWidget.dart';

// Flutter imports
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  // Stores temperature setting value
  late Future<List<double>> initSettingValue; 

  @override
  void initState() {
    super.initState();
    // Assigns setting values from the cloud
    initSettingValue = getInitSettingValues();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power vision',  
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.yellow[100],
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: Text(
            'Settings',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true,
          // Back button
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              // Go back to home page
              Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          alignment: Alignment.topCenter,
          child: FutureBuilder<List<double>>(
            future: initSettingValue,
            builder: (context, snapshot) {
              // Check if a connection has been accomplished
              if (snapshot.connectionState == ConnectionState.done) {

                // Check if setting values have arrived
                if (snapshot.hasData) {
                  // Recent settings value is the same as init settings value variable but global
                  recentSettingsValue = snapshot.data!;
                  return SettingsPageWidget();
                }
                else if (snapshot.hasError) {
                  return Text("Something went wrong, please try again later.");
                }
              }
              // Indicating that the data is loading
              return Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
}
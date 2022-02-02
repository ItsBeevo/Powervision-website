// Local imports
import 'database.dart';
import 'settingsPageWidget.dart';

// Dart imports
import 'dart:core';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// Flutter imports
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: non_constant_identifier_names
String V45 = "50";

// Last minute the data has been fetched from the cloud server
int lastMinute = -1;

// Indicating if the user has selected room temperature
bool roomTemperature = false;

// Contains latest data fetched in the last minute
List<Panel> recentPanels = [];

// Current selected panel, Displayed on the screen
Panel currentPanel = Panel(Vs: []);

// String representing the title of the page
String stringCurrentPanel = "Panel 1";

// Contains latest temperature setting values
List<double> recentSettingsValue = [];

// Contains latest heat overflow values for all panels and room temperature
List<dynamic> heatOverflow = [false, false, false, false];

// Booleans indicating wether to send instant notification for every panel
List<List<dynamic>> currentInstantNotif = [];

// Contains latest fault values for fault 4 in all three panels
List<dynamic> currentFaultFaultValues = [];

// Contains latest fault values for every step for every fault in all three panels
List<List<List<dynamic>>> currentFaultValues = [];

// Contains latest updated vertical fault dates
List<List<dynamic>> verticalFault = [];

// Controllers for temperature setting values for all three panels and room temperature
List<TextEditingController> curControllers = [];

// Controllers for custom timer for fault 4 in all three panels
List<TextEditingController> currentCustomCustomControllers = [];

// Controllers for custom timer for every step for every fault in all three panels
List<List<List<TextEditingController>>> currentCustomControllers = [];

// Links for getting the data from cloud server
List links = [
  'PanelOneLink',
  'PanelTwoLink',
  'PanelThreeLink'
];

// Links for updating data in cloud server
List updateLinks = [
  'PanelOneUpdateLink',
  'PanelTwoUpdateLink',
  'PanelThreeUpdateLink'
];

// Class for the newly fetched data from cloud server every minute
class Panel {
  // List for every V in the panel
  // ignore: non_constant_identifier_names
  final List Vs;

  Panel({
    // ignore: non_constant_identifier_names
    required this.Vs,
  });

  factory Panel.fromJson(List<dynamic> json) {
    return Panel(
      Vs: json,
    );
  }
}

// Executes every minute, Fetches data form the cloud server
Future<List<Panel>> fetchData() async {
  
  // Contains new data from cloud server for all three panels
  List<Panel> panels = [];

  for (int panel = 0; panel < 3; panel++) {

    // Contains new data for the current panel
    Panel newPanel = Panel(Vs: []);

    for (int v = 1; v <= 12; v++) {

      // Get link for current panel
      String link = links[panel];
      link += v.toString();

      // Request V data from cloud server
      final response = await http.get(Uri.parse(link));
      List<dynamic> responseList = jsonDecode(response.body);

      // Add V data to current panel
      newPanel.Vs.add(responseList[0]);
    }
    // Request temperature data from cloud server
    final response43 = await http.get(Uri.parse(links[panel] + "43"));
    List<dynamic> responseList43 = jsonDecode(response43.body);

    // Add temperature data to current panel
    newPanel.Vs.add(responseList43[0]);

    // Request KVAR data from cloud server
    final response99 = await http.get(Uri.parse(links[panel] + "99"));
    List<dynamic> responseList99 = jsonDecode(response99.body);

    // Add KVAR data to current panel
    newPanel.Vs.add(responseList99[0]);

    // Add current panel data to all panels
    panels.add(newPanel);
  }

  // Request room temperature data from cloud server
  final response45 = await http.get(Uri.parse(links[1] + "45"));
  List<dynamic> responseList45 = jsonDecode(response45.body);

  // Assign room temperature data to V45 variable
  V45 = responseList45[0];

  // Assign new data to recentPanels variable
  recentPanels = panels;

  // Save the data into the database
  // addData(panels);

  // Erase all the data from the database
  // clearDatabase();

  // Set all faults to default
  // setFaultsToDefault();
  
  // Check temperature for overflows
  // checkTemperature();

  // Check all faults for all panels
  // checkFaults();

  return panels;
}

void checkFaults() {

  // Check vertical fault for every step for every fault in every panel
  checkVerticalFault();

  // Check horizontal fault for every panel
  checkHorizontalFault();
}

Future<List<List<dynamic>>> checkVerticalFault() async {

  // Get faults document
  DocumentReference data = FirebaseFirestore.instance.collection("Miscellaneous").doc("Faults");
  DocumentSnapshot querySnapshot = await data.get();

  // Convert faults document to a map
  var document = querySnapshot.data() as LinkedHashMap<String, dynamic>;

  // Get instant notifications document
  DocumentReference dataInstant = FirebaseFirestore.instance.collection("Miscellaneous").doc("Instant notifications");
  DocumentSnapshot querySnapshotInstant = await dataInstant.get();

  // Convert instant notifications document to a map
  var documentInstant = querySnapshotInstant.data() as LinkedHashMap<String, dynamic>;

  // Get notifications document
  DocumentReference dataNotif = FirebaseFirestore.instance.collection("Miscellaneous").doc("Notifications");
  DocumentSnapshot querySnapshotNotif = await dataNotif.get();

  // Convert notifications document to a map
  var documentNotif = querySnapshotNotif.data() as LinkedHashMap<String, dynamic>;

  // Contains updated data for fault 1 and fault 2 for all three panels
  List<List<dynamic>> retData = [];

  for (int panel = 0; panel < 3; panel++) {

    // List containing dates describing every step for fault 1
    dynamic currentDataFault1 = document["Panel " + (panel + 1).toString()]["Fault 1"];

    // List containing dates describing every step for fault 2
    dynamic currentDataFault2 = document["Panel " + (panel + 1).toString()]["Fault 2"];

    for (int v = 0; v < 12; v++) {
      // Check if current V in current panel is ON
      if (recentPanels[panel].Vs[v] == '255') {

        // Cancel timer in fault 2 for current V in current panel
        currentDataFault2["V" + (v + 1).toString()] = ["01/01/2020 00:00", "01/01/2020 00:00"];

        // From date & time currently active for the timer
        String fromDate = currentDataFault1["V" + (v + 1).toString()]![0];

        // To date & time currently active for the timer
        String toDate = currentDataFault1["V" + (v + 1).toString()]![1];

        // Current date & time 
        String currentDate = DateFormat('dd/MM/yyyy kk:mm').format(DateTime.now());

        // Timer set for current V in current panel
        dynamic timer = documentNotif["Panel " + (panel + 1).toString()]["Fault 1"][v];

        // If there wasn't any timer set
        if (toDate == "01/01/2020 00:00") {

          // Set a timer for 24 Hours as an inital timer
          currentDataFault1["V" + (v + 1).toString()] = ["01/01/2020 00:00", addDate(DateTime.now(), 24)];
        }
        // If timer has eneded
        else if (compareDateTime(toDate, currentDate)) {

          // Check if it's the first timer to be set
          if (fromDate == "01/01/2020 00:00") {

            // Check if the user requested an instant notification for current V in current panel
            if (documentInstant["Panel " + (panel + 1).toString()][0]) {

              // Send an email notification
              sendVerticalNotif(panel, 1, v);
            }
          }
          // If it's not the first time, Send anyways
          else {

            // Send an email notification
            sendVerticalNotif(panel, 1, v);
          }
          // User did not request a second notification
          if (timer == null) {

            // Set a really far date
            currentDataFault1["V" + (v + 1).toString()] = [toDate, "01/01/2051 00:00"];
          }
          // User requested a second notification
          else {

            // Update timer by the requested period
            currentDataFault1["V" + (v + 1).toString()] = [toDate, addDate(DateTime.now(), timer)];
          }
        }
      }
      // Check if current V in current panel is OFF
      else {

        // Cancel timer in fault 1 for current V in current panel
        currentDataFault1["V" + (v + 1).toString()] = ["01/01/2020 00:00", "01/01/2020 00:00"];

        // From date & time currently active for the timer
        String fromDate = currentDataFault2["V" + (v + 1).toString()]![0];

        // To date & time currently active for the timer
        String toDate = currentDataFault2["V" + (v + 1).toString()]![1];

        // Current date & time 
        String currentDate = DateFormat('dd/MM/yyyy kk:mm').format(DateTime.now());

        // Timer set for current V in current panel
        dynamic timer = documentNotif["Panel " + (panel + 1).toString()]["Fault 2"][v];

        // If there wasn't any timer set
        if (toDate == "01/01/2020 00:00") {

          // Set a timer for 24 Hours as an inital timer
          currentDataFault2["V" + (v + 1).toString()] = ["01/01/2020 00:00", addDate(DateTime.now(), 24)];
        }
        // If timer has eneded
        else if (compareDateTime(toDate, currentDate)) {

           // Check if it's the first timer to be set
          if (fromDate == "01/01/2020 00:00") {

            // Check if the user requested an instant notification for current V in current panel
            if (documentInstant["Panel " + (panel + 1).toString()][0]) {

              // Send an email notification
              sendVerticalNotif(panel, 2, v);
            }
          }
          else {
            // Send an email notification
            sendVerticalNotif(panel, 2, v);
          }
          // User did not request a second notification
          if (timer == null) {

            // Set a really far date
            currentDataFault2["V" + (v + 1).toString()] = [toDate, "01/01/2051 00:00"];
          }
          // User requested a second notification
          else {

            // Update timer by the requested period
            currentDataFault2["V" + (v + 1).toString()] = [toDate, addDate(DateTime.now(), timer)];
          }
        }
      }
      // Update faults data for current panel
      data.update({
        "Panel " + (panel + 1).toString(): {
          "Fault 1": currentDataFault1,
          "Fault 2": currentDataFault2,
          "Fault 3": document["Panel " + (panel + 1).toString()]["Fault 3"],  
          "Fault 4": document["Panel " + (panel + 1).toString()]["Fault 4"],
        },
      });
    }
    // Add updated data 
    retData.add([currentDataFault1, currentDataFault2]);
  }
  // Assign updated vertical fault data 
  verticalFault = retData;

  return retData;
}

void checkHorizontalFault() async {

  // Get faults document
  DocumentReference data = FirebaseFirestore.instance.collection("Miscellaneous").doc("Faults");
  DocumentSnapshot querySnapshot = await data.get();

  // Convert faults document into a map
  var document = querySnapshot.data() as LinkedHashMap<String, dynamic>;

  // Get instant notifications document
  DocumentReference dataInstant = FirebaseFirestore.instance.collection("Miscellaneous").doc("Instant notifications");
  DocumentSnapshot querySnapshotInstant = await dataInstant.get();

  // Convert instant notifications into a map
  var documentInstant = querySnapshotInstant.data() as LinkedHashMap<String, dynamic>;

  // Get notifications document
  DocumentReference dataNotif = FirebaseFirestore.instance.collection("Miscellaneous").doc("Notifications");
  DocumentSnapshot querySnapshotNotif = await dataNotif.get();

  // Convert notifications document into a map
  var documentNotif = querySnapshotNotif.data() as LinkedHashMap<String, dynamic>;

  for (int panel = 0; panel < 3; panel++) {

    // Bool indicating all steps to be OFF
    bool allZeros = true;

    for (int v = 0; v < 12; v++) {

      // If one of them is ON
      if (recentPanels[panel].Vs[v].toString() == "255") {
        allZeros = false;
      }
    }

    // If all steps are OFF
    if (allZeros) {

      // Current fault documents for current panel
      Map<String, dynamic> currentDocument = document["Panel " + (panel + 1).toString()]!;

      // To date & time currently active for the timer
      String toDate = currentDocument.values.first;

      // Current date & time
      String currentDate = DateFormat('dd/MM/yyyy kk:mm').format(DateTime.now());

       // Timer set for fault 4 in current panel
      int currentTimer = (documentNotif["Panel " + (panel + 1).toString()]!["Fault 4"] == null ? -1 : documentNotif["Panel " + (panel + 1).toString()]!["Fault 4"]);

      // If there wasn't any timer set
      if (toDate == "01/01/2020 00:00") {
        
        // Check if user requested an instant notification
        if (documentInstant["Panel " + (panel + 1).toString()]![1]) {

          // Send email notification
          sendHorizontalNotif(panel);
        }

        // Update faults data
        data.update({
          "Panel " + (panel + 1).toString(): {
            "Fault 1": verticalFault[panel][0],
            "Fault 2": verticalFault[panel][1],
            "Fault 3": document["Panel " + (panel + 1).toString()]["Fault 3"],  
            "Fault 4": {(currentTimer == -1 ? "01/01/2020 00:00" : currentDate): (currentTimer == -1 ? "01/01/2020 00:00" : addDate(DateTime.now(), currentTimer))},
          },
        });
      }
      // If timer has ended
      else if (compareDateTime(toDate, currentDate)) {

        // Send email notification
        sendHorizontalNotif(panel);

        // Update faults data
        data.update({
          "Panel " + (panel + 1).toString(): {
            "Fault 1": verticalFault[panel][0],
            "Fault 2": verticalFault[panel][1],
            "Fault 3": document["Panel " + (panel + 1).toString()]["Fault 3"],  
            "Fault 4": {(currentTimer == -1 ? "01/01/2020 00:00" : toDate): (currentTimer == -1 ? "01/01/2020 00:00" : addDate(DateTime.now(), currentTimer))},
          },
        });
      }
    } 
    // If one of them was ON
    else {

      // Update faults data
      data.update({
          "Panel " + (panel + 1).toString(): {
            "Fault 1": verticalFault[panel][0],
            "Fault 2": verticalFault[panel][1],
            "Fault 3": document["Panel " + (panel + 1).toString()]["Fault 3"],  
            "Fault 4": {"01/01/2020 00:00": "01/01/2020 00:00"},
          },
      });
    }
  }
}

// Send an email notification for vertical fault
void sendVerticalNotif(int panel, int fault, int v) async {

  // Date & time now
  DateTime time = DateTime.now();

  // Fomrat it into a string 
  String currentDateTime = DateFormat('dd/MM/yyyy kk:mm').format(time);

  // Send an email
  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json', 
    },
    body: json.encode({
      'service_id': 'service_g6kqskl',
      'template_id': 'template_z9293ra',
      'user_id': 'user_BWgqO9fwiaX3J1LE5nlu1',
      'template_params': {
        // Subject
        'user_subject': "Critical Error in Step " + (v + 1).toString() + " in Panel " + (panel + 1).toString() + " @ GIZA CABLE INDUSTRIES",
        // Body
        'user_message': "Step " + (v + 1).toString() + " in Panel " + (panel + 1).toString() + " contains a permanent " + (fault == 1 ? "ON" : "OFF") + " contactor on date: " + currentDateTime.split(" ")[0] + ", time: " + currentDateTime.split(" ")[1] + ".",
        // Email
        'user_email': 'giza.cable.industries@gmail.com',
        'user_name': 'Giza cable industries',
        'from_email': 'giza.cable.industries@gmail.com',
      },
    }),
  );
  print(response.body);
}

// Send an email notification for horizontal fault
void sendHorizontalNotif(int panel) async {

  // Date & time now
  DateTime time = DateTime.now();

  // Fomrat it into a string 
  String currentDateTime = DateFormat('dd/MM/yyyy kk:mm').format(time);

  // Send an email
  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json', 
    },
    body: json.encode({
      'service_id': 'service_g6kqskl',
      'template_id': 'template_z9293ra',
      'user_id': 'user_BWgqO9fwiaX3J1LE5nlu1',
      'template_params': {
        // Subject
        'user_subject': "Main Breaker of Panel " + (panel + 1).toString() + " is tripped @ GIZA CABLE INDUSTRIES",
        // Body
        'user_message': "Main Breaker is tripped in Panel " + (panel + 1).toString() + " on date: " + currentDateTime.split(" ")[0] + ", time: " + currentDateTime.split(" ")[1] + ".",
        // Email
        'user_email': 'giza.cable.industries@gmail.com',
        'user_name': 'Giza cable industries',
        'from_email': 'giza.cable.industries@gmail.com',
      },
    }),
  );
  print(response.body);
}

// Add an amount of hours to a certain date & time
String addDate(DateTime currentDate, int timer) {

  // Date & time after adding the timer to it
  var newDate = currentDate.add(Duration(hours: timer));
  
  // Formatted string for new date & time
  String returnDate = DateFormat('dd/MM/yyyy kk:mm').format(newDate);

  return returnDate;
}

// Check temperature overflow 
void checkTemperature() async { 

  // Get document for heat overflow
  DocumentReference data = FirebaseFirestore.instance.collection('Miscellaneous').doc('Heat overflow');
  DocumentSnapshot querySnapshot = await data.get();

  // Convert heat overflow document to a map
  var documents = querySnapshot.data() as LinkedHashMap<String, dynamic>;

  // Assign data to global list heatOverflow
  heatOverflow = documents.values.first;

  for (int panel = 0; panel < 3; panel++) {

    // Check if recent panels has any data
    if (recentPanels[panel].Vs.isNotEmpty) {

      // Request setting value for current panel from cloud
      final response47 = await http.get(Uri.parse(links[panel] + "47"));
      List<dynamic> responseList47 = jsonDecode(response47.body);

      // Setting value for current panel
      var currentTemperature47 = double.parse(responseList47[0]);

      // Current temperature value for current panel
      var currentTemperature43 = double.parse(recentPanels[panel].Vs[12]);

      // Check overflow 
      if (currentTemperature43 >= currentTemperature47) {

        // Check if it has already overflowed before and an email has been sent
        if (!heatOverflow[panel]) {

          // Send an email notification
          alertHeatOverflow((panel + 1).toString(), currentTemperature43, currentTemperature47);

          // Assign it as true, so that no more emails will be sent unless a change occurs
          heatOverflow[panel] = true;

          // Update database with new values
          data.update({'Values': heatOverflow});
        }
      } 
      // Reset overflow values
      else {
        
        // Assign it as false, to catch any new heat overflows occuring in this panel
        heatOverflow[panel] = false;

        // Update database with new values
        data.update({'Values': heatOverflow});
      }
    }
  }

  // Request setting value for room temperature from cloud
  final response48 = await http.get(Uri.parse(links[1] + "48"));
  List<dynamic> responseList48 = jsonDecode(response48.body);

  // Request current room temperature from the cloud
  final response45 = await http.get(Uri.parse(links[1] + "45"));
  List<dynamic> responseList45 = jsonDecode(response45.body);

  // Setting value for room temperature
  var currentTemperature48 = double.parse(responseList48[0]);

  // Current room temperature
  var currentTemperature45 = double.parse(responseList45[0]);

  // Check overflow
  if (currentTemperature45 >= currentTemperature48) {

    // Check if it has already overflowed before and an email has been sent
    if (!heatOverflow[3]) {

      // Send an email notification
      alertHeatOverflow((4).toString(), currentTemperature45, currentTemperature48);

      // Assign it as true, so that no more emails will be sent unless a change occurs
      heatOverflow[3] = true;

      // Update database with new values
      data.update({'Values': heatOverflow});
    }
  } 
  // Reset overflow values
  else {

    // Assign it as false, to catch any new heat overflows occuring in this panel
    heatOverflow[3] = false;

    // Update database with new values
    data.update({'Values': heatOverflow});
  }
}

// Send email notification in case of overflow
Future alertHeatOverflow(String panelOverheated, double currentTemperature, double setTemperature) async {

  // Date & time now
  DateTime time = DateTime.now();

  // Format it into a string
  String currentDateTime = DateFormat('dd/MM/yyyy kk:mm').format(time);

  // Send an email
  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json', 
    },
    body: json.encode({
      'service_id': 'service_g6kqskl',
      'template_id': 'template_z9293ra',
      'user_id': 'user_BWgqO9fwiaX3J1LE5nlu1',
      'template_params': {
        // Subject
        'user_subject': (panelOverheated == '4' ? 'Room' : 'Panel ' + panelOverheated) + ' Over Temperature @ GIZA CABLE INDUSTRIES',
        // Body
        'user_message': (panelOverheated == '4' ? 'Room' : 'Panel ' + panelOverheated) + ' temperature (' + currentTemperature.toString().substring(0, min(currentTemperature.toString().length, 5)) + ' °C) exceeded the setting value (' + setTemperature.toString().substring(0, min(setTemperature.toString().length, 5)) + ' °C) on ' + currentDateTime,
        // Email
        'user_email': 'giza.cable.industries@gmail.com',
        'user_name': 'Giza cable industries',
        'from_email': 'giza.cable.industries@gmail.com',
      },
    }),
  );
  print(response.body);
}

// Get initial setting values for temperature for each panel
Future<List<double>> getInitSettingValues() async {

  // Get data for notifications from database
  querySnapshot = await data.get();

  // Get data for instant notifications from database
  querySnapshotInstant = await dataInstant.get();

  // Contains intital setting values for each panels and room temperature
  List<double> initSettingValue = [];

  for (int panel = 0; panel < 3; panel++) {
    
    // Request setting value for current panel from cloud server
    final response47 = await http.get(Uri.parse(links[panel] + "47"));
    List<dynamic> responseList47 = jsonDecode(response47.body);

    // Add it to all panels
    initSettingValue.add(double.parse(responseList47[0]));
  }

  // Request setting value for room temperature
  final response48 = await http.get(Uri.parse(links[1] + "48"));
  List<dynamic> responseList48 = jsonDecode(response48.body);

  // Add it to all panels
  initSettingValue.add(double.parse(responseList48[0]));
  
  return initSettingValue;
}

// Update setting value for a certain panel
void updateSettingValue(int panel, String newSettingValue) {
  http.get(Uri.parse(updateLinks[panel] + newSettingValue));
}

// Update setting values for all three panels
void updateSettingValues() {
  for (int panel = 0; panel < 3; panel++) {

    // Check if text box is not empty
    if (curControllers[panel].text.isNotEmpty) {
      
      // Set new values
      updateSettingValue(panel, curControllers[panel].text);
    }
  }

  // Check if text box for room temperature is not empty
  if (curControllers[3].text.isNotEmpty) {
    http.get(Uri.parse("http://blynk-cloud.com/bZTtn6slTnhdjlFMYA_u0udSX_z5ugaj/update/V48?value=" + curControllers[3].text));
  }
}

// Update notification values in database
void updateNotifValues() {

  for (int panel = 0; panel < 3; panel++) {
    for (int fault = 0; fault < 3; fault++) {
      for (int v = 0; v < 12; v++) {
        // If current fault values is set to custom
        if (currentFaultValues[panel][fault][v] == -1) {

          // Check if text box is empty
          if (currentCustomControllers[panel][fault][v].text.isEmpty) {

            // Set value as default
            currentFaultValues[panel][fault][v] = 24;
          }
          else {

            // Set value as text in text box
            currentFaultValues[panel][fault][v] = int.parse(currentCustomControllers[panel][fault][v].text);
          }
        }
      }
    }
    // If value for fault 4 is set to custom
    if (currentFaultFaultValues[panel] == -1) {

      // Check if text box is empty
      if (currentCustomCustomControllers[panel].text.isEmpty) {

        // Set value as default
        currentFaultFaultValues[panel] = 24;
      }
      else {

        // Set value as text in text box
        currentFaultFaultValues[panel] = int.parse(currentCustomCustomControllers[panel].text);
      }
    }
  }

  // Update instant notification data in database 
  dataInstant.update({
    "Panel 1": currentInstantNotif[0],
    "Panel 2": currentInstantNotif[1],
    "Panel 3": currentInstantNotif[2]
  });

  // Update notification data in database
  data.update({
    "Panel 1": {
      "Fault 1": currentFaultValues[0][0],
      "Fault 2": currentFaultValues[0][1],
      "Fault 3": currentFaultValues[0][2],
      "Fault 4": currentFaultFaultValues[0],
    },
    "Panel 2": {
      "Fault 1": currentFaultValues[1][0],
      "Fault 2": currentFaultValues[1][1],
      "Fault 3": currentFaultValues[1][2],
      "Fault 4": currentFaultFaultValues[1],
    },
    "Panel 3": {
      "Fault 1": currentFaultValues[2][0],
      "Fault 2": currentFaultValues[2][1],
      "Fault 3": currentFaultValues[2][2],
      "Fault 4": currentFaultFaultValues[2],
    },
  });
}

// Send verification code as an email for authentication
void sendVerificationCode(String code) async {

  // Send an email
  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json', 
    },
    body: json.encode({
      'service_id': 'service_g6kqskl',
      'template_id': 'template_z9293ra',
      'user_id': 'user_BWgqO9fwiaX3J1LE5nlu1',
      'template_params': {
        // Subject
        'user_subject': 'Verification code @ GIZA CABLE INDUSTRIES',
        // Body
        'user_message': 'Your verification code is ' + code,
        // Email
        'user_email': 'giza.cable.industries@gmail.com',
        'user_name': 'Giza cable industries',
        'from_email': 'giza.cable.industries@gmail.com',
      },
    }),
  );
  print(response.body);
}

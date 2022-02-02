// Local imports
import 'panelsData.dart';
import 'chartsKVAR.dart';
import 'chartsTemp.dart';

// Dart imports
import 'dart:html';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

// Flutter imports
import 'package:flutter/material.dart';

// Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';

// Last selected dates
String lastFromDate = "", lastToDate = "";

// Indicates if data required for the CSV file is converted 
bool recievedData = true;

// Contains the room temperature data required for the CSV file
List<List<dynamic>> roomTempData = [];

// Contains the panels data required for the CSV file
List<List<List<dynamic>>> convertedData = [];

// Compare date & time Strings
// Returns true if String from is earlier than String to, false otherwise
bool compareDateTime(String from, String to) {
  int dayFrom = int.parse(from.substring(0, 2));
  int monthFrom = int.parse(from.substring(3, 5));
  int yearFrom = int.parse(from.substring(6, 10));
  int hourFrom = int.parse(from.substring(11, 13));
  int minuteFrom = int.parse(from.substring(14, 16));
  int dayTo = int.parse(to.substring(0, 2));
  int monthTo = int.parse(to.substring(3, 5));
  int yearTo = int.parse(to.substring(6, 10));
  int hourTo = int.parse(to.substring(11, 13));
  int minuteTo = int.parse(to.substring(14, 16));
  if (yearFrom < yearTo) return true;
  if (yearFrom > yearTo) return false;
  if (monthFrom < monthTo) return true;
  if (monthFrom > monthTo) return false;
  if (dayFrom < dayTo) return true;
  if (dayFrom > dayTo) return false;
  if (hourFrom < hourTo) return true;
  if (hourFrom > hourTo) return false;
  if (minuteFrom < minuteTo) return true;
  if (minuteFrom > minuteTo) return false;
  return false;
}

// ignore: must_be_immutable
class ConvertData extends StatefulWidget {

  // Contain newly selected dates
  String fromDate = "", toDate = "";

  ConvertData(String fromDate, String toDate) {
    
    // Assign newly selected dates to fromDate and toDate
    this.fromDate = fromDate;
    this.toDate = toDate;

    // Check if toDate is earlier than fromDate
    if (!compareDateTime(fromDate, toDate)) {

      // Swap them to avoid errors
      String tmp = fromDate;
      fromDate = toDate;
      toDate = tmp;
    }
  }

  @override
  _ConvertDataState createState() => _ConvertDataState();
}

class _ConvertDataState extends State<ConvertData> {

  // Function that gets data from database and arranges it in a List for a CSV file 
  Future<List<List<List<dynamic>>>> convertData(String fromDate, String toDate) async {

    // Contains raw data from database
    // Panel -> Vs -> [[Date & Time, Value]]
    List<List<List<List<String>>>> _convertedData = [];

    for (int panel = 1; panel <= 3; panel++) {

      // Current raw panel data
      List<List<List<String>>> currentConvertedData = [];

      for (int v = 1; v <= 12; v++) {
        
        // Contains current step data and converts it into a map
        DocumentReference dataA = FirebaseFirestore.instance.collection('Panel ' + panel.toString()).doc('V' + v.toString());
        DocumentSnapshot querySnapshotA = await dataA.get();
        var documentsA = querySnapshotA.data() as Map<String, dynamic>;

        // Converting the map into a list to sort it
        List<List<String>> newDocumentsA = [];
        for (var i in documentsA.keys) {
          newDocumentsA.add([i, documentsA[i]]);
        }

        // Sorting the document according to date & time
        newDocumentsA.sort((a, b) => compareEarly(a, b));

        // Add it to current raw panel data
        currentConvertedData.add(newDocumentsA);
      }
      // Contains current KVAR data and converts it into a map
      DocumentReference dataB = FirebaseFirestore.instance.collection('Panel ' + panel.toString()).doc('V99');
      DocumentSnapshot querySnapshotB = await dataB.get();
      var documentsB = querySnapshotB.data() as Map<String, dynamic>;

      // Converting the map into a list to sort it
      List<List<String>> newDocumentsB = [];
      for (var i in documentsB.keys) {
        newDocumentsB.add([i, documentsB[i]]);
      }

      // Sorting the document according to date & time
      newDocumentsB.sort((a, b) => compareEarly(a, b));

      // Add it to current raw panel data
      currentConvertedData.add(newDocumentsB);

      // Contains current temperature data and converts it into a map
      DocumentReference dataC = FirebaseFirestore.instance.collection('Panel ' + panel.toString()).doc('V43');
      DocumentSnapshot querySnapshotC = await dataC.get();
      var documentsC = querySnapshotC.data() as Map<String, dynamic>;

      // Converting the map into a list to sort it
      List<List<String>> newDocumentsC = [];
      for (var i in documentsC.keys) {
        newDocumentsC.add([i, documentsC[i]]);
      }

      // Sorting the document according to date & time
      newDocumentsC.sort((a, b) => compareEarly(a, b));

      // Add it to current raw panel data
      currentConvertedData.add(newDocumentsC);

      // In case of panel 2, An extra room temperature should be fetched and added
      if (panel == 2) {

         // Contains current room temperature data and converts it into a map
        DocumentReference dataD = FirebaseFirestore.instance.collection('Panel ' + panel.toString()).doc('V45');
        DocumentSnapshot querySnapshotD = await dataD.get();
        var documentsD = querySnapshotD.data() as Map<String, dynamic>;

        // Converting the map into a list to sort it
        List<List<String>> newDocumentsD = [];
        for (var i in documentsD.keys) {
          newDocumentsD.add([i, documentsD[i]]);
        }

        // Sorting the document according to date & time
        newDocumentsD.sort((a, b) => compareEarly(a, b));

        // Add it to current raw panel data
        currentConvertedData.add(newDocumentsD);
      }
      // Add current raw panel data to total panels data
      _convertedData.add(currentConvertedData);
    }

    // --------------------------------------------
    // After getting data from database, we arrange it to be suitable for the CSV file
    
    // Contains arranged data from database
    // Panel -> [[Date, Time, S1, S2, etc], ]
    List<List<List<dynamic>>> newConvertedData = [];

    for (int panel = 0; panel < 3; panel++) {

      // Contains current panel arranged data
      List<List<dynamic>> currentNewConvertedData = [];

      for (int i = 0; i < _convertedData[0][0].length; i++) {

        // Contains current row which will be shown in CSV file
        List<dynamic> currentCurrentNewConvertedData = [];

        // Current date & time of this record
        List<String> currentDateTime = _convertedData[panel][0][i][0].split(' ');

        // Adding data & time to this row
        currentCurrentNewConvertedData.add(currentDateTime[0]);
        currentCurrentNewConvertedData.add(currentDateTime[1].substring(0, 5));

        // Adding steps, KVAR and temperature values to this row
        for (int v = 0; v < 14; v++) {
          currentCurrentNewConvertedData.add(_convertedData[panel][v][i][1]);
        }

        // In case of panel 2, add room temperature
        if (panel == 1) {
          currentCurrentNewConvertedData.add(_convertedData[panel][14][i][1]);
        }

        // Add current row to the list of this panel
        currentNewConvertedData.add(currentCurrentNewConvertedData);
      }
      // Add current panel arranged data to total panels
      newConvertedData.add(currentNewConvertedData);
    }

    // --------------------------------------------
    // After arranging the data from the database, we cut from the data only the required part
    // which is starting at lastFromDate, ending at lastToDate

    // Contains stripped data
    // Panel -> [[Date, Time, S1, S2, etc], ]
    List<List<List<dynamic>>> strippedConvertedData = [];

    // Clearing old room temperature data
    roomTempData.clear();

    for (int panel = 0; panel < 3; panel++) {

      // Contains current row
      List<List<dynamic>> currentNewConvertedData = [];

      // Heading for the CSV file
      List<dynamic> currentTitle = [];

      // Add all the headings
      currentTitle.add("Date");
      currentTitle.add("Time");
      for (int v = 1; v <= 12; v++) {
        currentTitle.add("S" + v.toString());
      }
      currentTitle.add("KVAR");
      currentTitle.add("Temp");

      // In case of panel 2, add only date, time and room temp
      if (panel == 1) {
        roomTempData.add(["Date", "Time", "Room temp"]);
      }

      // Add it to the start of panel data
      currentNewConvertedData.add(currentTitle);

      for (int i = 0; i < newConvertedData[panel].length; i++) {
        // Get current date & time for this row
        String currentDateTime = newConvertedData[panel][i][0] + ' ' + newConvertedData[panel][i][1];

        // In case it's not in the selected range, leave it
        if (compareDateTime(currentDateTime, lastFromDate) || compareDateTime(lastToDate, currentDateTime)) {
          continue;
        }

        // In case of panel 2, add data to roomTempData list and remove the last element (Room temperature) from panel 2
        // In order not to be downloaded with panel 2 data
        if (panel == 1) {
          roomTempData.add([newConvertedData[panel][i][0], newConvertedData[panel][i][1], newConvertedData[panel][i].last]);
          newConvertedData[panel][i].removeLast();
          currentNewConvertedData.add(newConvertedData[panel][i]);
        }
        // Otherwise just add the row to the panel data
        else {
          currentNewConvertedData.add(newConvertedData[panel][i]);
        }
      }
      // Add this row to panel data
      strippedConvertedData.add(currentNewConvertedData);
    }

    // Assign ready data to the List that will be converted to the CSV file
    convertedData = strippedConvertedData;

    setState(() {
      // Indicate that the data is ready for the CSV file
      recievedData = true;
    });

    return strippedConvertedData;
  }

  @override
  void initState() {
    super.initState();
    // Prepare data for the initally selected dates
    convertData(widget.fromDate, widget.toDate);
  }

  @override 
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Prepare data for the newly selected dates
    convertData(widget.fromDate, widget.toDate);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                // Download CSV button
                child: ElevatedButton(
                  child: Text(
                    "Export as CSV file",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.deepOrangeAccent,
                    fixedSize: Size(300, 50),
                  ),
                  // Enable if data is converted and ready to be download
                  onPressed: (!recievedData ? null : () {
                    // Convert data into CSV file and download it
                    downloadCSV(int.parse(stringCurrentPanel.substring(6, 7)) - 1);
                  }),
                ),
              ),
            ],
          ),
          (recievedData ? SizedBox() : Padding(
            padding: EdgeInsets.all(200),
            child: CircularProgressIndicator(),
          )),

          // Add the KVAR chart in case of panel 1, panel 2 and panel 3
          // making sure that data is also converted and ready
          (!recievedData || roomTemperature ? SizedBox() : SeriesKVARBar(createData())),

          (recievedData && !roomTemperature ? SizedBox(height: 20) : SizedBox()),

          // Add the Temperature chart in case of panel 1, panel 2, panel 3 and room temperature
          // making sure that data is also converted and ready
          (!recievedData ? SizedBox() : SeriesTempBar(createTempData())),
        ],
      ),
    );
  }
}

// Add newly fetched data to database
void addData(List<Panel> panels) async {

  // Current date & time
  DateTime time = DateTime.now();
  String currentDateTime = DateFormat('dd/MM/yyyy kk:mm').format(time);

  // In case the website is visited by multiple users,
  // This bool avoids adding the same record multiple times to the database
  bool quit = false;

  for (int panel = 1; panel <= 3; panel++) {
    for (int v = 1; v <= 12; v++) {
      // Getting current V data and converting it into a map
      DocumentReference data = FirebaseFirestore.instance.collection('Panel ' + panel.toString()).doc('V' + v.toString());
      DocumentSnapshot querySnapshot = await data.get();
      var documents = querySnapshot.data() as Map<String, dynamic>;

      // If the last record has the same date & time as now, 
      // Don't add this field again
      if (documents.keys.first == currentDateTime) {
        quit = true;
        break;
      }

      // Merge step data into existing fields
      data
      .set(
        {currentDateTime: panels[panel - 1].Vs[v - 1]},
        SetOptions(merge: true)
      );
    }
    if (quit) {
      break;
    }
    // Getting current panel temperature data
    DocumentReference data = FirebaseFirestore.instance.collection('Panel ' + panel.toString()).doc('V43');

    // Merging temperature data into other fields
    data
    .set(
      {currentDateTime: panels[panel - 1].Vs[12]},
      SetOptions(merge: true)
    );

    // Getting current panel KVAR data
    data = FirebaseFirestore.instance.collection('Panel ' + panel.toString()).doc('V99');

    // Merging KVAR data into other fields
    data
    .set(
      {currentDateTime: panels[panel - 1].Vs[13]},
      SetOptions(merge: true)
    );

    // In case of panel 2, add new room temperature data
    if (panel == 2) {

      // Getting current panel room temperature data
      data = FirebaseFirestore.instance.collection('Panel ' + panel.toString()).doc('V45');

      // Merging room temperature data into other fields
      data
      .set(
        {currentDateTime: V45},
        SetOptions(merge: true)
      );
    }
  }
} 

// Preparing date & time to be compared
int compareEarly(List<String> a, List<String> b) {
  List<String> currentDateTimeA = a[0].split(' '), currentDateTimeB = b[0].split(' ');
  // Return -1 if a is earlier than b
  if (compareDateTime(currentDateTimeA[0] + ' ' + currentDateTimeA[1], currentDateTimeB[0] + ' ' + currentDateTimeB[1])) {
    return -1;
  }
  // Otherwise return 1
  return 1;
}

// Converting panels data into CSV file and downloading it
void downloadCSV(int panel) {

  // If currently room temperature is selected, 
  // Download CSV for the room temperature instead
  if (roomTemperature) {
    downloadCSVRoom();
    return;
  }

  // Converting into CSV file
  String panelCSV = ListToCsvConverter().convert(convertedData[panel]);

  // Downloading the CSV file
  new AnchorElement(href: "data:text/plain;charset=utf-8,$panelCSV")
      ..setAttribute("download", "panel" + (panel + 1).toString() + "Data" + ".csv")
      ..click();
}

// Converting room temperature data into CSV file and downloading it
void downloadCSVRoom() {

  // Converting into CSV file
  String roomCSV = ListToCsvConverter().convert(roomTempData);

  // Downloading the CSV file
  new AnchorElement(href: "data:text/plain;charset=utf-8,$roomCSV")
      ..setAttribute("download", "roomTemperature" + "Data" + ".csv")
      ..click();
}

// Ignore, used only when testing
void clearDatabase() {
  for (int panel = 1; panel <= 3; panel++) {
    for (int v = 1; v <= 12; v++) {
      DocumentReference documentReference = FirebaseFirestore.instance.collection("Panel " + panel.toString()).doc("V" + v.toString());
      documentReference.delete();
    }
    DocumentReference documentReferenceA = FirebaseFirestore.instance.collection("Panel " + panel.toString()).doc("V43");
    documentReferenceA.delete();
    DocumentReference documentReferenceB = FirebaseFirestore.instance.collection("Panel " + panel.toString()).doc("V99");
    documentReferenceB.delete();
    if (panel == 2) {
      DocumentReference documentReferenceC = FirebaseFirestore.instance.collection("Panel " + panel.toString()).doc("V45");
      documentReferenceC.delete();
    }
  }
}

// Ignore, used only when testing
void setFaultsToDefault() {
  DocumentReference data = FirebaseFirestore.instance.collection("Miscellaneous").doc("Faults");

  Map<String, List<String>> defaultData = {};
  for (int v = 1; v <= 12; v++) {
    defaultData["V" + v.toString()] = ["01/01/2020 00:00", "01/01/2020 00:00"];
  } 

  data.update({
    "Panel 1": {
      "Fault 1": defaultData,
      "Fault 2": defaultData,
      "Fault 3": defaultData,  
      "Fault 4": {"01/01/2020 00:00": "01/01/2020 00:00"},
    },
    "Panel 2": {
      "Fault 1": defaultData,
      "Fault 2": defaultData,
      "Fault 3": defaultData,  
      "Fault 4": {"01/01/2020 00:00": "01/01/2020 00:00"},
    },
    "Panel 3": {
      "Fault 1": defaultData,
      "Fault 2": defaultData,
      "Fault 3": defaultData,  
      "Fault 4": {"01/01/2020 00:00": "01/01/2020 00:00"},
    },
  });
}
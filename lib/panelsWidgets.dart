// Local imports 
import 'main.dart';
import 'database.dart';
import 'panelsData.dart';

// Dart imports
import 'dart:ui';
import 'package:intl/intl.dart';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class PanelWidget extends StatefulWidget {
  @override
  _PanelWidgetState createState() => _PanelWidgetState();
}

class _PanelWidgetState extends State<PanelWidget> {

  // From date & time selected
  DateTime fromDate = DateTime(2021, 1, 1, 0, 0);

  // To date & time selected
  DateTime toDate = DateTime.now();

  // Formatted date & time strings
  String fromDateFormatted = "";
  String toDateFormatted = "";

  @override
  void initState() {
    super.initState();

    // Format selected from date & time
    fromDateFormatted = DateFormat('dd/MM/yyyy kk:mm').format(fromDate);

    // Format selected to date & time
    toDateFormatted = DateFormat('dd/MM/yyyy kk:mm').format(toDate);

    // Assign them to the global variables
    lastFromDate = fromDateFormatted;
    lastToDate = toDateFormatted;

    // Add leading zeros if needed
    if (fromDateFormatted[fromDateFormatted.length - 4] == '4') {
      fromDateFormatted = fromDateFormatted.replaceAll("24:", "00:");
    }
    if (toDateFormatted[toDateFormatted.length - 4] == '4') {
      toDateFormatted = toDateFormatted.replaceAll("24:", "00:");
    }
    setState(() {
      // Indicate that converted data needed for the CSV file is not recieved 
      recievedData = false;
    });

    // Request new data with required from and to date & time
    ConvertData(fromDateFormatted, toDateFormatted);
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(height: 50),
            // Title of the page
            (roomTemperature ? Text(
              "Room temperature",
              textScaleFactor: 2,
              style: TextStyle(
                fontWeight:FontWeight.bold,
                fontSize: 40,
                color: Colors.orangeAccent,
              ),
            ) : 
            Text(
              stringCurrentPanel,
              textScaleFactor: 2,
              style: TextStyle(
                fontWeight:FontWeight.bold,
                fontSize: 40,
                color: Colors.orangeAccent,
              ),
            )),
            SizedBox(height: 70),
            // Display table only if one of the panels is selected, 
            // and the data is loaded
            (roomTemperature ? SizedBox(height: 0) : 
            (!loadedData ?
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
              child: Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )) :
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
              // Table containing data fetched every minute
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder.all(width: 4.0, color: Colors.teal),
                children: [
                  // First row
                  TableRow(
                    children: [
                      for (int v = 1; v <= 12; v++) Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'S' + v.toString(),
                          textScaleFactor: 2, 
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Special ones for the KVAR and Temperature
                      Padding(padding: EdgeInsets.all(8), child: Text('KVAR', textScaleFactor: 2, textAlign: TextAlign.center,),),
                      Padding(padding: EdgeInsets.all(8), child: Text('Temp', textScaleFactor: 2, textAlign: TextAlign.center,),),
                    ],
                  ),
                  // Second row
                  TableRow(
                    children: [
                      for (int v = 0; v < 12; v++) Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          (currentPanel.Vs[v].toString() == '255' ? '1' : currentPanel.Vs[v].toString()),
                          textScaleFactor: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Special ones for KVAR and Temperature
                      Padding(padding: const EdgeInsets.all(8), child: Text(currentPanel.Vs[13].toString(), textScaleFactor: 2, textAlign: TextAlign.center,),),
                      Padding(padding: const EdgeInsets.all(8), child: Text(currentPanel.Vs[12].toString(), textScaleFactor: 2, textAlign: TextAlign.center,),),
                    ],
                  ),
                ],
              ),
            ))),
            (!loadedData && !roomTemperature ? SizedBox(height: 62) : SizedBox(height: 0)),
            (!roomTemperature ? SizedBox(height: 100) : SizedBox(height: 0)),

            // Date & time selection boxes
            Padding(
              padding: EdgeInsets.all(0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // From date button
                  TextButton(
                    onPressed: () {
                      DatePicker.showDateTimePicker(
                        context,
                        showTitleActions: true,
                        minTime: DateTime(2020, 1, 1, 0, 0),
                        // Change in case we passed 2050 :D
                        maxTime: DateTime(2050, 12, 31, 23, 59),
                        theme: DatePickerTheme(
                          backgroundColor: Colors.black,
                          itemStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        // If the user clicked on 'done'
                        onConfirm: (date) {
                          setState(() {
                            // Assign new date into fromDate
                            fromDate = date;

                            // Format the newly selected date
                            fromDateFormatted = DateFormat('dd/MM/yyyy kk:mm').format(fromDate);

                            // Assign it to the global variable
                            lastFromDate = fromDateFormatted;

                            // Add leading zeros if needed
                            if (fromDateFormatted[fromDateFormatted.length - 4] == '4') {
                              fromDateFormatted = fromDateFormatted.replaceAll("24:", "00:");
                            }
                            // New data should be shown, so assign false to recievedData
                            recievedData = false;

                            // Request data for the newly selected data & time range
                            ConvertData(fromDateFormatted, toDateFormatted);
                          });
                        },
                        locale: LocaleType.en);
                    },
                    child: Text(
                      fromDateFormatted,
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Icon(
                    Icons.arrow_forward_rounded,
                  ),
                  SizedBox(width: 20),
                  // To date button
                  TextButton(
                    onPressed: () {
                      DatePicker.showDateTimePicker(
                        context,
                        showTitleActions: true,
                        minTime: DateTime(2020, 1, 1, 0, 0),
                         // Change in case we passed 2050 :D
                        maxTime: DateTime(2050, 12, 31, 23, 59),
                        theme: DatePickerTheme(
                          backgroundColor: Colors.black,
                          itemStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        // If the user clicked on 'done'
                        onConfirm: (date) {
                          setState(() {
                            // Assign new date into toDate
                            toDate = date;

                            // Format the newly selected date
                            toDateFormatted = DateFormat('dd/MM/yyyy kk:mm').format(toDate);

                            // Assign it to the global variable
                            lastToDate = toDateFormatted;

                            // Add leading zeros if needed
                            if (toDateFormatted[toDateFormatted.length - 4] == '4') {
                              toDateFormatted = toDateFormatted.replaceAll("24:", "00:");
                            }
                            // New data should be shown, so assign false to recievedData
                            recievedData = false;

                            // Request data for the newly selected data & time range
                            ConvertData(fromDateFormatted, toDateFormatted);
                          }); 
                        },
                        locale: LocaleType.en);
                    },
                    child: Text(
                      toDateFormatted,
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: ConvertData(lastFromDate, lastToDate),
            ),
          ],
        ),
      )
    );
  }
}
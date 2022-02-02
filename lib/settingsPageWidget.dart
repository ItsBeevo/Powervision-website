// Local imports
import 'panelsData.dart';
import 'AuthenticationPage.dart';

// Dart imports
import 'dart:math';
import 'dart:collection';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';

// Get reference to Notifications document in database
DocumentReference data = FirebaseFirestore.instance.collection('Miscellaneous').doc('Notifications');
late DocumentSnapshot querySnapshot;

// Get reference to Instant notifications document in database
DocumentReference dataInstant = FirebaseFirestore.instance.collection('Miscellaneous').doc('Instant notifications');
late DocumentSnapshot querySnapshotInstant;

class SettingsPageWidget extends StatefulWidget {
  @override
  _SettingsPageWidgetState createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {

  // Booleans indicating wether to send instant notification for every panel on screen
  List<List<dynamic>> instantNotif = [];

  // Contains current horizontal fault values on screen
  List<dynamic> faultFaultValues = [];

  // Contains current vertical fault values on screen
  List<List<List<dynamic>>> faultValues = [];

  // Controllers for custom timer for horizontal fault in all three panels on screen
  List<TextEditingController> customCustomControllers = [];

  // Controllers for custom timer for vertical fault on screen
  List<List<List<TextEditingController>>> customControllers = [];
  
  @override
  void initState() {
    super.initState();

    // Convert notifications document into a map
    var documents = querySnapshot.data() as LinkedHashMap<String, dynamic>;

    // Get initial value for faults
    for (int panel = 1; panel <= 3; panel++) {

      // Contains fault values for current panel
      List<List<dynamic>> curFaultValues = [];

      // Controllers for current panel text boxes
      List<List<TextEditingController>> curCustomControllers = [];

      for (int fault = 1; fault <= 3; fault++) {

        // Add current fault values for current fault for current panel from database
        curFaultValues.add(documents["Panel " + panel.toString()]["Fault " + fault.toString()]);

        // Contains initial values in text boxes for current fault for current panel
        List<TextEditingController> curCurCustomControllers = [];

        // Set initial values in text boxes for current fault for current panel
        for (var k in curFaultValues.last) {
          curCurCustomControllers.add(TextEditingController(text: k.toString()));
        }

        // Add current fault controller to current panel controllers
        curCustomControllers.add(curCurCustomControllers);
      }

      // Add fault values for current panel to all panels
      faultValues.add(curFaultValues);

      // Add controller for current panel to all panels
      customControllers.add(curCustomControllers);

      // Add initial values for fault 4
      faultFaultValues.add(documents["Panel " + panel.toString()]["Fault 4"]);

      // Add initial values for text boxes for fault 4
      customCustomControllers.add(TextEditingController(text: documents["Panel " + panel.toString()]["Fault 4"].toString()));
    }

    for (int panel = 0; panel < 3; panel++) {
      for (int fault = 0; fault < 3; fault++) {
        for (int v = 0; v < 12; v++) {

          // Check if fault value for current panel for current fault for current step is not one of the choice
          if (faultValues[panel][fault][v] != 1 && faultValues[panel][fault][v] != 24 && faultValues[panel][fault][v] != 48 && faultValues[panel][fault][v] != 72) {

            // Set the value to the old custom one
            customControllers[panel][fault][v] = TextEditingController(text: faultValues[panel][fault][v].toString());

            // Set it by -1 to indicate custom chosen
            faultValues[panel][fault][v] = -1;
          }
        }
      }

      // Check if fault value for current panel for fault 4 is not one of the choice
      if (faultFaultValues[panel] != 1 && faultFaultValues[panel] != 24 && faultFaultValues[panel] != 48 && faultFaultValues[panel] != 72) {

        // Set the value to the old custom one
        customCustomControllers[panel] = TextEditingController(text: faultFaultValues[panel].toString());

        // Set it by -1 to indicate custom chosen
        faultFaultValues[panel] = -1;
      }
    }

    // Convert instant notification document into a map
    var documentsInstant = querySnapshotInstant.data() as Map<String, dynamic>;

    // Add initial instant notification values
    for (int panel = 1; panel <= 3; panel++) {
      instantNotif.add(documentsInstant["Panel " + panel.toString()]);
    }
  }

  // List indicating the chosen fault for each panel
  List<int> chosenFault = [1, 1, 1];

  // List indicating the drop down state for each panel and room temperature
  List<bool> dropDown = [false, false, false, false];

  // List indicating the details drop down state for each panel
  List<bool> detailsDropDown = [false, false, false];

  // List indicating the chosen step for each panel
  List<String> chosenStep = ["Step 1", "Step 1", "Step 1"];

  // List indicating the choice to be displayed
  List<String> steps = ["Step 1", "Step 2", "Step 3", "Step 4", "Step 5", "Step 6", "Step 7", "Step 8", "Step 9", "Step 10", "Step 11", "Step 12"];

  // Controllers for setting temperature for each panel and room temperature
  List<TextEditingController> controllers = [TextEditingController(text: recentSettingsValue[0].toString()), TextEditingController(text: recentSettingsValue[1].toString()), TextEditingController(text: recentSettingsValue[2].toString()), TextEditingController(text: recentSettingsValue[3].toString())];

  // Title and drop down button for every panel
  Padding getPadding(int panel) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            "Panel " + (panel + 1).toString(),
            style: TextStyle(
              fontSize: 30,
              color: Colors.orange[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            width: 10,
          ),
          IconButton(
            onPressed: () {
              setState(() {
                // Toggle drop down bool for current panel
                dropDown[panel] = (dropDown[panel] ? false : true);
              });
            },
            icon: Icon(
              (dropDown[panel] ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // Elevated button for fault 1, fault 2 and fault 3
  ElevatedButton getElevatedButton(int panel, String text, dynamic value) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          // Set fault value of current panel of current fault of current step to the chosen value
          faultValues[panel][chosenFault[panel] - 1][int.parse(chosenStep[panel].split(" ").last) - 1] = value;
        });
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        primary: (faultValues[panel][chosenFault[panel] - 1][int.parse(chosenStep[panel].split(" ").last) - 1] == value ? (text == "Disable" ? Colors.red : Colors.green) : Colors.orange),
      ),
    );
  }

  // Elevated button for fault 4
  ElevatedButton getElevatedButtonTwo(int panel, String text, dynamic value) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          // Set fault value of current panel of fault 4 to the chosen value
          faultFaultValues[panel] = value;
        });
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        primary: (faultFaultValues[panel] == value ? (text == "Disable" ? Colors.red : Colors.green) : Colors.orange),
      ),
    );
  }

  // Button for applying current step settings to all other steps in current panel
  FloatingActionButton getFloatingButton(int panel) {
    return FloatingActionButton(
      child: Text(
        "Set as\ndefault",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      hoverColor: Colors.lightBlue,
      splashColor: Colors.green,
      onPressed: () {
        setState(() {
          for (int fault = 0; fault < 3; fault++) {
            for (int v = 0; v < 12; v++) {

              // Check if current step is set to custom
              if (faultValues[panel][chosenFault[panel] - 1][int.parse(chosenStep[panel].split(" ").last) - 1] == -1) {

                // Check if text box is empty
                if (customControllers[panel][chosenFault[panel] - 1][int.parse(chosenStep[panel].split(" ").last) - 1].text.isEmpty) {

                  // Set value to default
                  faultValues[panel][fault][v] = 24;
                }
                else {

                  // Set all other steps to the value of current text box of current step
                  faultValues[panel][fault][v] = int.parse(customControllers[panel][chosenFault[panel] - 1][int.parse(chosenStep[panel].split(" ").last) - 1].text);
                }
              }
              else {

                // Set all other steps to the value of current chosen choice of current step
                faultValues[panel][fault][v] = faultValues[panel][chosenFault[panel] - 1][int.parse(chosenStep[panel].split(" ").last) - 1];
              }
            }
          }
        });
      },
    );
  }

  // Text for showing details in current panel
  Text getText(int panel, int fault, int v) {
    return Text(
      (faultValues[panel][fault][v] == null ? "Disabled" : (faultValues[panel][fault][v] != -1 ? (faultValues[panel][fault][v]) : int.parse(customControllers[panel][fault][v].text)).toString() + " Hour" + ((faultValues[panel][fault][v] != -1 ? faultValues[panel][fault][v] : int.parse(customControllers[panel][fault][v].text)) > 1 ? "s" : "")),
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Row containing values for which step, fault 1, fault 2 and fault 3
  Row getRow(int panel, int v) {
    return Row(
      children: [
        Text(
          "Step " + ((v + 1).toString().length == 1 ? "0" + (v + 1).toString() : (v + 1).toString()),
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 20),
        getText(panel, 0, v),
        SizedBox(width: 20),
        getText(panel, 1, v),
        SizedBox(width: 20),
        getText(panel, 2, v),
      ],
    );
  }

  // Container for current panel (Drop down)
  Container getContainer(int panel) {
    return Container(
      child: Column(
        children: [
          // Temperature setting value
          Row(
            children: [
              SizedBox(width: 40),
              Text(
                "Temperature setting value",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: 100,
              ),
              // Text box for temperature setting value for current panel
              Container(
                width: 200.0,
                child: TextField(
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[0-9-]+")),
                  ],
                  controller: controllers[panel],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(color: Colors.purpleAccent),
                    hintText: "Enter temperature setting value"
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Choosing fault from 1 to 3, choosing step from 1 to 12
          Row(
            children: [
              SizedBox(width: 20),
              // Left arrow 
              IconButton(
                onPressed: () {
                  setState(() {
                    chosenFault[panel] = max(chosenFault[panel] - 1, 1);
                  });
                },
                icon: Icon(Icons.arrow_left),
              ),
              SizedBox(width: 5),
              // Display currently selected fault 
              Text(
                "Fault type " + chosenFault[panel].toString(),
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 5),
              // Right arrow
              IconButton(
                onPressed: () {
                  setState(() {
                    chosenFault[panel] = min(chosenFault[panel] + 1, 3);
                  });
                },
                icon: Icon(Icons.arrow_right),
              ),
              SizedBox(width: 20),
              // Steps drop down button
              DropdownButton(
                value: chosenStep[panel],
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                icon: Icon(Icons.keyboard_arrow_down),
                items: steps.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items)
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    // Set chosen step to current selected one
                    chosenStep[panel] = newValue!;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 15),
          // Instant notification and it's switch for faults 1, 2 & 3
          Row(
            children: [
              SizedBox(width: 40),
              Text(
                "Instant notification",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Switch(
                onChanged: (bool newValue) {
                  setState(() {
                    // Update instant notification of current panel of fault 1, 2 & 3 with new value
                    instantNotif[panel][0] = newValue;
                  });
                },
                value: instantNotif[panel][0],
                activeColor: Colors.green,  
                activeTrackColor: Colors.lightGreen,  
                inactiveThumbColor: Colors.white70,  
                inactiveTrackColor: Colors.white,  
              ),
            ],
          ),
          SizedBox(height: 15),
          // Choices for faults 1, 2 & 3 notification timer
          Row(
            children: [
              SizedBox(width: 40),
              getElevatedButton(panel, "1 Hour", 1),
              SizedBox(width: 10),
              getElevatedButton(panel, "24 Hours", 24),
              SizedBox(width: 10),
              getElevatedButton(panel, "48 Hours", 48),
              SizedBox(width: 10),
              getElevatedButton(panel, "72 Hours", 72),
              SizedBox(width: 10),
              getElevatedButton(panel, "Custom", -1),
              SizedBox(width: 10),
              getElevatedButton(panel, "Disable", null),
              SizedBox(width: 20),
              getFloatingButton(panel),
            ],
          ),
          SizedBox(height: 20),
          // Custom text box for faults 1, 2 & 3
          Row(
            children: [
              SizedBox(width: 525),
              (faultValues[panel][chosenFault[panel] - 1][int.parse(chosenStep[panel].split(" ").last) - 1] != -1 ? SizedBox(width: 100) :
              Container(
                width: 100.0,
                height: 70.0,
                child: TextField(
                  maxLength: 3,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[0-9]+")),
                  ],
                  controller: customControllers[panel][chosenFault[panel] - 1][int.parse(chosenStep[panel].split(" ").last) - 1],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(color: Colors.purpleAccent),
                    hintText: "Enter custom hours",
                  ),
                ),
              )),
            ],
          ),
          SizedBox(height: 20),
          // Fault 4 title
          Row(
            children: [
              SizedBox(width: 65),
              Text(
                "Fault type 4",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          // Instant notification and it's switch for fault 4
          Row(
            children: [
              SizedBox(width: 40),
              Text(
                "Instant notification",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Switch(
                onChanged: (bool newValue) {
                  setState(() {
                    // Update instant notification of current panel of fault 4 with new value
                    instantNotif[panel][1] = newValue;
                  });
                },
                value: instantNotif[panel][1],
                activeColor: Colors.green,  
                activeTrackColor: Colors.lightGreen,  
                inactiveThumbColor: Colors.white70,  
                inactiveTrackColor: Colors.white,  
              ),
            ],
          ),
          SizedBox(height: 15),
          // Choices for fault 4 notification timer
          Row(
            children: [
              SizedBox(width: 40),
              getElevatedButtonTwo(panel, "1 Hour", 1),
              SizedBox(width: 10),
              getElevatedButtonTwo(panel, "24 Hours", 24),
              SizedBox(width: 10),
              getElevatedButtonTwo(panel, "48 Hours", 48),
              SizedBox(width: 10),
              getElevatedButtonTwo(panel, "72 Hours", 72),
              SizedBox(width: 10),
              getElevatedButtonTwo(panel, "Custom", -1),
              SizedBox(width: 10),
              getElevatedButtonTwo(panel, "Disable", null),
            ],
          ),
          (faultFaultValues[panel] != -1 ? SizedBox(height: 20) : SizedBox(height: 20)),
          (faultFaultValues[panel] != -1 ? SizedBox() : 
          // Custom text box for fault 4
          Row(
            children: [
              SizedBox(width: 525),
              Container(
                width: 100.0,
                height: 70.0,
                child: TextField(
                  maxLength: 3,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[0-9]+")),
                  ],
                  controller: customCustomControllers[panel],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(color: Colors.purpleAccent),
                    hintText: "Enter custom hours",
                  ),
                ),
              )
            ],
          )),
          // Show details drop down
          Row(
            children: [
              SizedBox(width: 40),
              Text(
                "Show details",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: 5,
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    // Toggle details drop down bool
                    detailsDropDown[panel] = (detailsDropDown[panel] ? false : true);
                  });
                },
                icon: Icon(
                  (detailsDropDown[panel] ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                  size: 25,
                ),
              ),
            ],
          ),
          SizedBox(width: 35),
          (!detailsDropDown[panel] ? SizedBox() : 
          // Details displayed in details drop down
          Row(
            children: [
              SizedBox(width: 40),
              Container(
                width: 600,
                color: Colors.yellow[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Headers
                    Row(
                      children: [
                        Text(
                          "Step",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 57),
                        Text(
                          "Fault 1",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 47),
                        Text(
                          "Fault 2",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 47),
                        Text(
                          "Fault 3",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Actual data for current panel
                    for (int v = 0; v < 12; v++) getRow(panel, v),
                  ],
                ),
              )
            ],
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(70),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Panel 1 title
          getPadding(0),
          (!dropDown[0] ? SizedBox() :
          // Panel 1 drop down 
          getContainer(0)),
          Divider(color: Colors.blue[700]),
          // Panel 2 title
          getPadding(1),
          (!dropDown[1] ? SizedBox() :
          // Panel 2 drop down 
          getContainer(1)),
          Divider(color: Colors.blue[700]),
          // Panel 3 title
          getPadding(2),
          (!dropDown[2] ? SizedBox() :
          // Panel 3 drop down 
          getContainer(2)),
          Divider(color: Colors.blue[700]),
          // Room temperature title
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Room temperature",
                      style: TextStyle(
                        color: Colors.orange[400],
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          // Toggle drop down for room temperature
                          dropDown[3] = (dropDown[3] ? false : true);
                        });
                      },
                      icon: Icon(
                        (dropDown[3] ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          (!dropDown[3] ? SizedBox() : 
          // Room temperature drop down
          Container(
            child: Row(
              children: [
                SizedBox(width: 40),
                Text(
                  "Room temperature setting value",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: 115,
                ),
                Container(
                  width: 200.0,
                  child: TextField(
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9-]+")),
                    ],
                    controller: controllers[3],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Colors.purpleAccent),
                      hintText: "Enter room temperature setting value"
                    ),
                  ),
                ),
              ],
            ),
          )),
          Divider(color: Colors.blue[700]),
          SizedBox(height: 20),
          // Save button
          ElevatedButton(
            child: Text(
              "Save", 
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              // Assign all local variables to global variables
              curControllers = controllers;
              currentCustomControllers = customControllers;
              currentCustomCustomControllers = customCustomControllers;
              currentInstantNotif = instantNotif;
              currentFaultValues = faultValues;
              currentFaultFaultValues = faultFaultValues;
              // Go to authentication page
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuthenticationPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              fixedSize: Size(120, 40),
              primary: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
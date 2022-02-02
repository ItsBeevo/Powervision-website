// Local imports
import 'panelsData.dart';

// Dart imports
import 'dart:math';
import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_verification_code/flutter_verification_code.dart';

class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {

  // Timer displayed after recieving the code
  int intTimer = 59;

  // Code entered by user
  String code = "";

  // Generated code
  String requiredCode = "";

  // Currently adding the code
  bool editing = false;

  // Indicates that the timer is done
  bool buttonEnabled = false;

  // Indicates user entering an incorrect code
  bool incorrectCode = false;

  // Starts timer after sending the code
  void startTimer() {
    // Updates timer every second
    const oneSec = const Duration(seconds: 1);
    Timer.periodic(
      oneSec,
      (Timer timer) {
        // If the timer is done
        if (intTimer == 0) {
          setState(() {
            // Cancel the timer
            timer.cancel();

            // Enable clicking the button again
            buttonEnabled = true;
          });
        } 
        else {
          setState(() {
            // Decrement the timer every second
            intTimer--;
          });
        }
      },
    );
  }

  // Generate a random 6 digit code
  void generateCode() {
    String newRequiredCode = "";
    for (int i = 0; i < 6; i++) {
      newRequiredCode += Random().nextInt(9).toString();
    }
    requiredCode = newRequiredCode;
  }

  @override
  void initState() {
    super.initState();

    generateCode();

    // Send required code to the email
    sendVerificationCode(requiredCode);

    // Start a one minute timer
    startTimer();
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
            'Authentication',
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
              // Go back to settings page
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: <Widget>[
            SizedBox(height: 50,),
            Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'Enter your verification code',
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
            // Show an indicator that the entered code is incorrect
            (!incorrectCode ? Text("") : 
            Text(
              "Incorrect code!",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )),
            // Verification code box
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VerificationCode(
                  textStyle: TextStyle(
                    fontSize: 30,
                    color: Colors.orange[900]
                  ),
                  underlineColor: Colors.orangeAccent,
                  length: 6,
                  //clearAll: Icons.clear,
                  // After 6 digits are entered
                  onCompleted: (String value) {
                    setState(() {
                      // Assign these 6 digits into code variable
                      code = value;
                    });
                    // Check if entered code is correct
                    if (code == requiredCode) {
                      // Apply new temperature setting values
                      updateSettingValues();

                      // Update noitification timers
                      updateNotifValues();

                      // Go back to settings page
                      Navigator.pop(context);
                    }
                    // Code entered is incorrect
                    else {
                      incorrectCode = true;
                    }
                  },
                  // If the user is still entering the digits
                  onEditing: (bool value) {
                    setState(() {
                      editing = value;
                      incorrectCode = false;
                    });
                    if (!editing) FocusScope.of(context).unfocus();
                  },
                  digitsOnly: true,
                ),
              ],
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Resend code button
                ElevatedButton(
                  child: Text(
                    "Resend code",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // If the one minute timer is done
                  onPressed: (!buttonEnabled ? null : () {
                    // Generate a new code
                    generateCode();

                    // Send the new code to the email
                    sendVerificationCode(requiredCode);

                    // Start the one minute timer 
                    startTimer();

                    setState(() {
                      intTimer = 59;

                      // Disable the button
                      buttonEnabled = false;
                    });
                  }),
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(120, 20),
                    primary: Colors.deepOrange,
                  ),
                ),
                SizedBox(width: 10,),
                // If timer is running, Display it
                (intTimer == 0 ? Text("") : 
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.orange,
                    ),
                    shape: BoxShape.circle, 
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(5),
                      child: Text(
                      intTimer.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        ),
                      ),
                    ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
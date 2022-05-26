import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'package:iot_home_automation/model/device_model.dart';
import 'package:iot_home_automation/model/user_model.dart';

import 'package:iot_home_automation/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);
  final FirebaseApp app = Firebase.app();
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  UserModel loggedInUser = UserModel();
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  bool _autoAcceptPairingRequests = false;
  int _discoverableTimeoutSecondsLeft = 0;
  Timer? _discoverableTimeoutTimer;
  //final databaseRef = FirebaseDatabase.instance.ref();
  bool value1 = true;
  bool value2 = true;
  bool value3 = true;
  Device light = Device("Light", false);
  Device fan = Device("Fan", false);
  final hourController = TextEditingController();
  final minuteController = TextEditingController();
  static get app => Firebase.app();

  //initialize firebasefirestore receiving data
  @override
  void initState() {
    // TODO: implement initState

    super.initState();

    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get()
        .then((value) {
      loggedInUser = UserModel.fromMap(value.data());
      setState(() {});
    });
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final hourField = TextFormField(
        autofocus: false,
        controller: hourController,
        keyboardType: TextInputType.number,
        validator: (value) {
          RegExp regex = RegExp(r'[0-2][0-9]');
          if (value!.isEmpty) {
            return ("hour cannot be empty");
          }
          if (!regex.hasMatch(value)) {
            return ("Enter Valid hour");
          }
        },
        onSaved: (value) {
          hourController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Hour",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ));
    final minuteField = TextFormField(
        autofocus: false,
        controller: minuteController,
        keyboardType: TextInputType.number,
        validator: (value) {
          RegExp regex = RegExp(r'[0-5][0-9]');
          if (value!.isEmpty) {
            return ("Enter a minute please");
          }
          if (!regex.hasMatch(value)) {
            return ("enter a valid minute");
          }
        },
        onSaved: (value) {
          hourController.text = value!;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Minute",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ));
    Size media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                child: Image.asset(
                  "assets/logo.jpg",
                  fit: BoxFit.contain,
                ),
              ),
              const Text(
                "Welcome",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "${loggedInUser.firstName} ${loggedInUser.secondName}",
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text("${loggedInUser.email}"),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(child: hourField),
                  Expanded(child: minuteField),
                  ElevatedButton(
                      onPressed: () {
                        postAlarmToDatabase();
                      },
                      child: Text("Save"))
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
                  scrollDirection: Axis.horizontal,
                  children: List.generate(1, (_) {
                    return Column(
                      children: <Widget>[
                        _buildRoutinesItem(media, light.name, light),
                        SizedBox(height: 5),
                        _buildRoutinesItem(media, fan.name, fan),
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                                width: media.width * .6,
                                child: ListTile(
                                  title: Text("Bluetooth"),
                                  trailing: ElevatedButton(
                                      onPressed: () {
                                        blu();
                                      },
                                      child: GestureDetector(
                                        child: Icon(Icons.bluetooth_audio),
                                        onTap: blu,
                                      )),
                                )),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              ActionChip(
                  label: const Text("Logout"),
                  onPressed: () {
                    logout(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutinesItem(Size media, String text, Device device) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: media.width * .6,
          child: ListTile(
            title: Text(text),
            trailing: buildIOSSwitch(device),
          ),
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  Widget buildIOSSwitch(Device device) {
    postActionsToDatabase(device);
    return Transform.scale(
      scale: 1.1,
      child: CupertinoSwitch(
        value: device.state,
        onChanged: (value) => setState(
          () => device.state = value,
        ),
      ),
    );
  }

  final referenceDatabase = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          "https://iot-home-automation-bd892-default-rtdb.europe-west1.firebasedatabase.app/");

  final deviceStat = TextEditingController();

  void postActionsToDatabase(Device device) async {
    deviceStat.text = device.state.toString();
    final DatabaseReference ref = referenceDatabase.ref();
    ref
        .child("users")
        .child("${user?.uid}")
        .update({device.name: device.state}).asStream();

    deviceStat.clear();
  }

  void postAlarmToDatabase() async {
    var hour = int.tryParse(hourController.text);

    final DatabaseReference ref = referenceDatabase.ref();
    ref.child("users").child("${user?.uid}").update({"hour": hour}).asStream();
    var minute = int.tryParse(minuteController.text);
    ref
        .child("users")
        .child("${user?.uid}")
        .update({"minute": minute}).asStream();
  }

  Future<void> blu() async {
    // Some simplest connection :F
    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(_address);
      print('Connected to the device');

      connection.input?.listen((Uint8List data) {
        print('Data incoming: ${ascii.decode(data)}');
        connection.output.add(data); // Sending data

        if (ascii.decode(data).contains('!')) {
          connection.finish(); // Closing connection
          print('Disconnecting by local host');
        }
      }).onDone(() {
        print('Disconnected by remote request');
      });
    } catch (exception) {
      print('Cannot connect, exception occured');
    }
  }
}

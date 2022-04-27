import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  //final databaseRef = FirebaseDatabase.instance.ref();
  bool value = true;

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
  }

  @override
  Widget build(BuildContext context) {
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
                height: 150,
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
                height: 50,
              ),
              Image.asset(
                value ? 'assets/on.png' : 'assets/off.png',
                height: 200,
              ),
              buildIOSSwitch(),
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

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  Widget buildIOSSwitch() {
    postActionsToDatabase();
    return Transform.scale(
      scale: 1.1,
      child: CupertinoSwitch(
        value: value,
        onChanged: (value) => setState(() => this.value = value),
      ),
    );
  }

  final referenceDatabase = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          "https://iot-home-automation-bd892-default-rtdb.europe-west1.firebasedatabase.app/");

  final statusLed = TextEditingController();

  void postActionsToDatabase() async {
    statusLed.text = value.toString();
    final DatabaseReference ref = referenceDatabase.ref();
    ref.child("devices").update({'light': value}).asStream();

    statusLed.clear();
  }
}

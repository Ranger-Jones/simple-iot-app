import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:iot_app/models/led.dart';
import 'package:iot_app/models/temperature.dart';

class DatabaseFunctions {
  static final FirebaseDatabase firebaseDatabase = FirebaseDatabase();
  static Future<List<LedState>> getLEDState() async {
    List<LedState> list = [];
    LedState ledResult = LedState(
      ledStateInt: 0,
      internalName: "",
      name: "",
      color: "",
    );
    DatabaseReference redLedRef = FirebaseDatabase.instance.ref("test/redled");
    DatabaseReference greenLedRef =
        FirebaseDatabase.instance.ref("test/greenled");

    TransactionResult redLedResult =
        await redLedRef.runTransaction((Object? led) {
      // Ensure a post at the ref exists.
      if (led == null) {
        print("Red LED not found");
        return Transaction.abort();
      }
      print("Red LED found");
      Map<String, dynamic> _led = Map<String, dynamic>.from(led as Map);

      ledResult = LedState.fromJson(_led);

      list.add(ledResult);

      return Transaction.success(_led);
    });

    TransactionResult greenLedResult =
        await greenLedRef.runTransaction((Object? led) {
      // Ensure a post at the ref exists.
      if (led == null) {
        print("Green LED not found");
        return Transaction.abort();
      }
      print("Green LED found");
      Map<String, dynamic> _led = Map<String, dynamic>.from(led as Map);

      ledResult = LedState.fromJson(_led);

      list.add(ledResult);
      // Return the new data.
      return Transaction.success(_led);
    });

    return list;
  }

  static Future<String> turnOn(int state, String path, LedState led) async {
    final ledData = {
      "state": state,
      "internal_name": led.internalName,
      "name": led.name,
      "color": led.color,
    };

    final Map<String, Map> updates = {};
    updates[path] = ledData;

    await FirebaseDatabase.instance.ref().update(updates);

    return "Success";
  }

}

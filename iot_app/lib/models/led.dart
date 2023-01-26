import 'dart:convert';

LedState ledStateFromJson(String str) => LedState.fromJson(json.decode(str));

String ledStateToJson(LedState data) => json.encode(data.toJson());

class LedState {
  LedState({
    required this.ledStateInt,
    required this.internalName,
    required this.name,
    required this.color,
  });

  int ledStateInt;
  String internalName;
  String name;
  String color;

  factory LedState.fromJson(Map<dynamic, dynamic> json) => LedState(
        ledStateInt: json["state"] ?? 0,
        internalName: json["internal_name"],
        name: json["name"] ?? "",
        color: json["color"] ?? "",
      );

  Map<dynamic, dynamic> toJson() => {
        "state": ledStateInt,
        "internal_name": internalName,
        "name": name,
        "color": color,
      };
}

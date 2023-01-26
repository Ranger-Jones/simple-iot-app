import 'dart:convert';

Temperature temperatureFromJson(String str) =>
    Temperature.fromJson(json.decode(str));

String temperatureToJson(Temperature data) => json.encode(data.toJson());

class Temperature {
  Temperature({
    required this.temperature,
    required this.humidity,
    required this.key,
  });

  double temperature;
  double humidity;
  int key;

  factory Temperature.fromJson(Map<String, dynamic> json) => Temperature(
        temperature: json["temperature"]?.toDouble(),
        key: json["key"] ?? 0,
        humidity: json["humidtity"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "temperature": temperature,
        "key": key,
      };
}

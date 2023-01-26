import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:iot_app/functions/database_functions.dart';
import 'package:iot_app/models/led.dart';
import 'package:iot_app/models/temperature.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'firebase_options.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(IoTApp());
}

class IoTApp extends StatelessWidget {
  IoTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NeumorphicApp(
      title: 'IoTApp',
      theme: NeumorphicThemeData(
        baseColor: Color(0xFFFFFFFF),
        lightSource: LightSource.topLeft,
        depth: 10,
      ),
      themeMode: ThemeMode.dark,
      darkTheme: NeumorphicThemeData(
        baseColor: Color(0xFF3E3E3E),
        lightSource: LightSource.topLeft,
        depth: 6,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<LedState> leds = [];
  List<Temperature> temperatures = [];

  LedState? led;

  TooltipBehavior? _tooltipBehavior;

  final Query dbRef =
      FirebaseDatabase.instance.ref().child("test/temperatures");

  List<int> intervalSteps = [];

  void getData() async {
    List<LedState> ledsResult = await DatabaseFunctions.getLEDState();
    print(ledsResult);
    setState(() {
      leds = ledsResult;
    });
  }

  @override
  void initState() {
    getData();
    _tooltipBehavior = TooltipBehavior(enable: true);
    getData();
    super.initState();
  }

  void changeLed(LedState led, String path) async {
    String fullPath = "test/" + path;
    await DatabaseFunctions.turnOn(led.ledStateInt == 0 ? 1 : 0, fullPath, led);

    getData();
  }

  Color getColor(LedState led) {
    Color? colorOfLed;

    switch (led.color) {
      case "green":
        colorOfLed = Colors.green;
        break;
      case "red":
        colorOfLed = Colors.red;
        break;
      default:
        Colors.white;
        break;
    }

    return colorOfLed!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.of(context)!.isUsingDark
          ? Color(0xFF3E3E3E)
          : Colors.white,
      body: Container(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(
              height: 48,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NeumorphicButton(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  style: NeumorphicStyle(
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(64)),
                  ),
                  onPressed: () {
                    setState(() {
                      if (NeumorphicTheme.of(context)!.isUsingDark) {
                        NeumorphicTheme.of(context)!.themeMode =
                            ThemeMode.light;
                      } else {
                        NeumorphicTheme.of(context)!.themeMode = ThemeMode.dark;
                      }
                    });
                  },
                  child: NeumorphicIcon(
                    !NeumorphicTheme.of(context)!.isUsingDark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    style: NeumorphicStyle(
                      color: NeumorphicTheme.of(context)!.isUsingDark
                          ? Colors.white
                          : Color(0xFF3E3E3E),
                    ),
                    size: 24,
                  ),
                ),
                SizedBox(
                  width: 24,
                )
              ],
            ),
            StreamBuilder(
              stream: dbRef.onValue,
              builder: (context, snap) {
                if (snap.hasData &&
                    !snap.hasError &&
                    snap.data!.snapshot.value != null) {
                  List<Temperature> tempData = [];
                  List _rawData =
                      List.from(snap.data!.snapshot.value as dynamic);
                  _rawData =
                      _rawData.sublist(_rawData.length - 15, _rawData.length);
                  int counter = 0;
                  _rawData.forEach((element) {
                    if (element != null) {
                      counter++;
                      tempData.add(
                        Temperature(
                          temperature: element["temperature"].toDouble() ?? 0,
                          humidity: element["humidtity"] == null
                              ? 0
                              : element["humidtity"].toDouble(),
                          key: counter,
                        ),
                      );
                    }
                  });
                  return Container(
                    padding: const EdgeInsets.only(
                      right: 18,
                      left: 12,
                      top: 24,
                      bottom: 12,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: LineChart(
                            sensorData(tempData),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 74, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "${tempData.last.temperature}°C",
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: NeumorphicTheme.of(context)!
                                              .isUsingDark
                                          ? Colors.white
                                          : Color(
                                              0xFF3E3E3E,
                                            ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.thermostat,
                                    size: 42,
                                    color:
                                        NeumorphicTheme.of(context)!.isUsingDark
                                            ? Colors.white
                                            : Color(0xFF3E3E3E),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    "${tempData.last.humidity}%",
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: NeumorphicTheme.of(context)!
                                              .isUsingDark
                                          ? Colors.white
                                          : Color(
                                              0xFF3E3E3E,
                                            ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.water_drop_rounded,
                                    size: 42,
                                    color:
                                        NeumorphicTheme.of(context)!.isUsingDark
                                            ? Colors.white
                                            : Color(0xFF3E3E3E),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                } else
                  return Text("No data");
              },
            ),
            Divider(
              color: NeumorphicTheme.of(context)!.isUsingDark
                  ? Colors.white
                  : Color(0xFF3E3E3E),
            ),
            SizedBox(height: 12),
            leds == []
                ? Container()
                : Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: leds
                          .map((led) => NeumorphicButton(
                                style: NeumorphicStyle(
                                  color: led.ledStateInt == 1
                                      ? getColor(led)
                                      : NeumorphicTheme.of(context)!.isUsingDark
                                          ? Color(0xFF3E3E3E)
                                          : Colors.white, //customize color here
                                ),
                                onPressed: () =>
                                    changeLed(led, led.internalName),
                                child: NeumorphicIcon(
                                  Icons.light,
                                  style: NeumorphicStyle(
                                    depth: 4,
                                    color:
                                        NeumorphicTheme.of(context)!.isUsingDark
                                            ? Colors.white
                                            : Color(0xFF3E3E3E),
                                  ),
                                  size: 128,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
            SizedBox(
              height: 36,
            ),
            NeumorphicButton(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              style: NeumorphicStyle(
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(64)),
              ),
              onPressed: () => getData(),
              child: NeumorphicIcon(
                Icons.update,
                style: NeumorphicStyle(
                  color: NeumorphicTheme.of(context)!.isUsingDark
                      ? Colors.white
                      : Color(0xFF3E3E3E),
                ),
                size: 24,
              ),
            ),
            Flexible(child: Container(), flex: 1),
          ],
        ),
      ),
    );
  }

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Color(0xff4e4965), width: 4),
          left: BorderSide(color: Colors.transparent),
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      );

  LineChartData sensorData(List<Temperature> data) {
    double maxVal = data[0].temperature;
    double minVal = data[0].temperature;

    data.forEach((tempData) {
      if (tempData.temperature > maxVal) {
        maxVal = tempData.temperature;
      }

      if (tempData.humidity > maxVal) {
        maxVal = tempData.humidity.toDouble();
      }

      if (tempData.temperature < minVal) {
        minVal = tempData.temperature;
      }

      if (tempData.humidity < minVal) {
        minVal = tempData.humidity.toDouble();
      }
    });

    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
      ),
      borderData: borderData,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: sensorDataBottomTitles,
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: sensorDataLeftTitles(),
        ),
      ),
      gridData: FlGridData(show: false),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          color: Colors.redAccent[200],
          barWidth: 8,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
          spots: data
              .map((tempData) =>
                  FlSpot(tempData.key.toDouble(), tempData.temperature))
              .toList(),
        ),
        LineChartBarData(
          isCurved: true,
          color: Colors.blueAccent[300],
          barWidth: 8,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
          spots: data
              .map((tempData) =>
                  FlSpot(tempData.key.toDouble(), tempData.humidity.toDouble()))
              .toList(),
        )
      ],
      minX: 1,
      maxX: 15,
      maxY: maxVal + 5,
      minY: minVal - 5,
    );
  }

  Widget sensorDataLeftTitleWidget(double value, TitleMeta meta) {
    var style = TextStyle(
        color: NeumorphicTheme.of(context)!.isUsingDark
            ? Colors.white
            : Color(0xFF3E3E3E),
        fontSize: 14,
        fontWeight: FontWeight.bold);

    String text = "";

    if (value.toInt() % 10 == 0) {
      return Text(value.toInt().toString(),
          style: style, textAlign: TextAlign.center);
    } else {
      return Text("");
    }
  }

  SideTitles sensorDataLeftTitles() => SideTitles(
        getTitlesWidget: sensorDataLeftTitleWidget,
        showTitles: true,
        interval: 1,
        reservedSize: 40,
      );

  SideTitles get sensorDataBottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: sensorDataBottomTitlesWidget,
      );

  Widget sensorDataBottomTitlesWidget(double value, TitleMeta meta) {
    var style = TextStyle(
      color: NeumorphicTheme.of(context)!.isUsingDark
          ? Colors.white
          : Color(0xFF3E3E3E),
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 14:
        text = Text('30m', style: style);
        break;
      case 12:
        text = Text('1h', style: style);
        break;
      case 10:
        text = Text('1h30m', style: style);
        break;
      case 8:
        text = Text('2h', style: style);
        break;
      case 6:
        text = Text('2h30m', style: style);
        break;
      case 4:
        text = Text('3h', style: style);
        break;
      case 2:
        text = Text('3h30m', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }
}

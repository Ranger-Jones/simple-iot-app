

#include <Arduino.h>
#include "DHT.h"
#if defined(ESP32)
#include <WiFi.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#endif
#include <Firebase_ESP_Client.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

#define TEMPPIN D1

#define DHTTYPE DHT11

DHT dht(TEMPPIN, DHTTYPE);

#define WIFI_SSID "" // input your home or public wifi name
#define WIFI_PASSWORD ""

#define API_KEY ""
#define DATABASE_URL ""

// Define Firebase Data object
FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;

bool signupOK = false;

int redLed = D2;
int greenLed = D3;

int temperatureValueCount = -1;
int ledState;

void manipulateLed(String path, int port)
{
  if (Firebase.RTDB.getInt(&fbdo, path))
  {
    if (fbdo.dataType() == "int")
    {
      ledState = fbdo.intData();
      Serial.print(path);
      Serial.print(" : ");
      Serial.println(ledState);
      if (ledState == 1)
      {
        digitalWrite(port, HIGH);
      }
      else
      {
        digitalWrite(port, LOW);
      }
    }
  }

  else
  {
    Serial.println(fbdo.errorReason());
  }
}

void setup()
{
  Serial.begin(115200);

  // start temperature and humidity sensor
  dht.begin();

  pinMode(redLed, OUTPUT);
  pinMode(greenLed, OUTPUT);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");

  pinMode(LED_BUILTIN, OUTPUT);
  bool on1 = false;
  bool on2 = true;

  while (WiFi.status() != WL_CONNECTED)
  {
    if (on1)
    {
      digitalWrite(redLed, HIGH);
    }
    else
    {
      digitalWrite(redLed, LOW);
    }

    if (on2)
    {
      digitalWrite(greenLed, HIGH);
    }
    else
    {
      digitalWrite(greenLed, LOW);
    }

    on1 = !on1;
    on2 = !on2;

    Serial.print(".");
    delay(250);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  /* Assign the api key (required) */
  config.api_key = API_KEY;
  /* Assign the RTDB URL (required) */
  config.database_url = DATABASE_URL;

  /* Sign up */
  if (Firebase.signUp(&config, &auth, "", ""))
  {
    Serial.println("ok");
    signupOK = true;
  }
  else
  {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop()
{
  delay(1000);
  if (Firebase.ready() && signupOK)
  {
    manipulateLed("test/redled/state", redLed);
    manipulateLed("test/greenled/state", greenLed);
    if ((millis() - sendDataPrevMillis > 900000 || sendDataPrevMillis == 0))
    {
      sendDataPrevMillis = millis();

      if (temperatureValueCount == -1 && Firebase.RTDB.getInt(&fbdo, "test/temperature_value_count"))
      {
        if (fbdo.dataType() == "int")
        {
          temperatureValueCount = fbdo.intData();
        }
      }

      temperatureValueCount++;

      if (Firebase.RTDB.setInt(&fbdo, "test/temperature_value_count", temperatureValueCount))
      {
        Serial.println("INCREASED TEMPERATURE COUNT");
      }
      else
      {
        Serial.println("FAILED");
        Serial.println("REASON: " + fbdo.errorReason());
      }

      float humidity = dht.readHumidity(); // die Luftfeuchtigkeit auslesen und unter „Luftfeutchtigkeit“ speichern

      float temperature = dht.readTemperature();
      String temperaturePath = "test/temperatures/" + String(temperatureValueCount) + "/";

      if (Firebase.RTDB.setFloat(&fbdo, temperaturePath + "temperature", temperature) && Firebase.RTDB.setFloat(&fbdo, temperaturePath + "humidtity", humidity))
      {
        Serial.println("PASSED");
        Serial.println("PATH: " + fbdo.dataPath());
        Serial.println("TYPE: " + fbdo.dataType());
      }
      else
      {
        Serial.println("TEMP UPLOAD FAILED");
        Serial.println("REASON: " + fbdo.errorReason());
      }
    }
  }
}

// Copyright (c) 2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Get weather forecast with the D programming language
// https://github.com/workhorsy/d-weather-forecast

/++
Get weather forecast with the D programming language. It first gets your longitude
and latitude using http://ipinfo.io. Then looks up your weather using
http://forecast.weather.gov.

Home page:
$(LINK https://github.com/workhorsy/d-weather-forecast)

Version: 1.0.0

License:
Boost Software License - Version 1.0

Examples:
----
import std.stdio : stdout;
import WeatherForecast : getForecast;

getForecast(delegate(string latitude, string longitude, string temperature, string weather) {
	stdout.writefln("latitude: %s", latitude);
	stdout.writefln("longitude: %s", longitude);
	stdout.writefln("temperature: %s", temperature);
	stdout.writefln("weather: %s", weather);
});
----
+/

module WeatherForecast;


/++
Returns the weather forecast using a callback.

Params:
 cb = The callback to fire when weather info has been downloaded.
+/
void getForecast(void delegate(string latitude, string longitude, string temperature, string weather) cb) {
	import std.stdio : stdout, stderr;
	import std.json : JSONValue, parseJSON;
	import std.string : chomp;
	import std.array : split;
	import std.conv : to;
	import ipinfo : getIpinfo, IpinfoData, httpGet;

	getIpinfo(delegate(IpinfoData data, Exception err) {
		if (err) {
			stderr.writefln("%s", err);
		} else {
			string url = "http://forecast.weather.gov/MapClick.php?lat=" ~ data.latitude ~ "&lon=" ~ data.longitude ~ "&FcstType=json";

			httpGet(url, delegate(int status, string response) {
				if (status != 200) {
					stderr.writefln("Request for Weather data failed with status code: %s", status);
					return;
				}

				string temperature = "";
				string weather = "";
				try {
					JSONValue j = parseJSON(response);
					temperature = j["currentobservation"]["Temp"].str();
					weather = j["data"]["weather"][0].str();
				} catch (Throwable) {
					stderr.writefln("Failed to parse Weather server JSON response: %s", response);
					return;
				}

				cb(data.latitude, data.longitude, temperature, weather);
			});
		}
	});
}

unittest {
	import BDD;
	import ipinfo : httpGet;

	immutable string RESULT_IP = 
	`{
		"ip": "8.8.8.8",
		"loc": "37.7749,-122.4194",
		"org": "AS15169 Google Inc.",
		"city": "Mountain View",
		"region": "California",
		"country": "US",
		"postal": "94043"
	}`;
	immutable string RESULT_WEATHER =
	`{
		"data": { "weather": [ "Hot" ] },
		"currentobservation": { "Temp" : "70" } }
	}`;

	httpGet = delegate(string url, void delegate(int status, string response) cb) {
		import std.string : startsWith;

		if (url.startsWith("https://ipinfo.io/json")) {
			cb(200, RESULT_IP);
		} else if (url.startsWith("http://forecast.weather.gov/MapClick.php?lat=")) {
			cb(200, RESULT_WEATHER);
		}
	};

	describe("WeatherForecast",
		it("Should get a forecast", delegate() {
			WeatherForecast.getForecast(delegate(string latitude, string longitude, string temperature, string weather) {
				latitude.shouldEqual("37.7749");
				longitude.shouldEqual("-122.4194");
				temperature.shouldEqual("70");
				weather.shouldEqual("Hot");
			});
		}),
	);
}

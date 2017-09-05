// Copyright (c) 2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Get weather report with the D programming language
// https://github.com/workhorsy/d-weather

/++
Get weather report with the D programming language. It first gets your longitude
and latitude using http://ipinfo.io. Then looks up your weather using
http://forecast.weather.gov.

Home page:
$(LINK https://github.com/workhorsy/d-weather)

Version: 1.0.0

License:
Boost Software License - Version 1.0

Examples:
----
import std.stdio : stdout;
import Weather : getForecast;

getForecast(delegate(string latitude, string longitude, string temperature, string weather) {
	stdout.writefln("latitude: %s", latitude);
	stdout.writefln("longitude: %s", longitude);
	stdout.writefln("temperature: %s", temperature);
	stdout.writefln("weather: %s", weather);
});
----
+/

module Weather;

void delegate(string url, void delegate(int status, string response) cb) httpGet;
private void delegate(string url, void delegate(int status, string response) cb) httpGetDefault;

static this() {
	httpGetDefault = delegate(string url, void delegate(int status, string response) cb) {
		import std.stdio : stdout, stderr;
		import std.net.curl : HTTP, CurlException, get;

		auto http = HTTP();
		string content = "";

		try {
			content = cast(string) get(url, http);
		} catch (CurlException ex) {
			stderr.writefln("!!! url: %s", url);
			stderr.writefln("!!! CurlException: %s", ex.msg);
			//stderr.writefln("!!!!!!!!!!!!!!!! CurlException: %s", ex);
		}

		ushort status = http.statusLine().code;
		cb(status, content);
	};

	httpGet = httpGetDefault;
}

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

	// Get latitude and longitude from ip address
	httpGet("http://ipinfo.io/loc", delegate(int status, string response) {
		if (status != 200) {
			stderr.writefln("Request for lat and lon data failed with status code: %s", status);
			return;
		}

		string[] result = split(response, ",");
		string latitude = chomp(result[0]);
		string longitude = chomp(result[1]);

		string url = "http://forecast.weather.gov/MapClick.php?lat=" ~ latitude ~ "&lon=" ~ longitude ~ "&FcstType=json";
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

			cb(latitude, longitude, temperature, weather);
		});
	});
}

unittest {
	import BDD;

	immutable string RESULT_IP = "37.7749,-122.4194\r\n";
	immutable string RESULT_WEATHER =
	`{
		"data": { "weather": [ "Hot" ] },
		"currentobservation": { "Temp" : "70" } }
	}`;

	Weather.httpGet = delegate(string url, void delegate(int status, string response) cb) {
		import std.string : startsWith;

		if (url.startsWith("http://ipinfo.io/loc")) {
			cb(200, RESULT_IP);
		} else if (url.startsWith("http://forecast.weather.gov/MapClick.php?lat=")) {
			cb(200, RESULT_WEATHER);
		}
	};

	describe("Weather",
		it("Should get a forecast", delegate() {
			Weather.getForecast(delegate(string latitude, string longitude, string temperature, string weather) {
				latitude.shouldEqual("37.7749");
				longitude.shouldEqual("-122.4194");
				temperature.shouldEqual("70");
				weather.shouldEqual("Hot");
			});
		}),
	);
}

// Copyright (c) 2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Get weather report with the D programming language
// https://github.com/workhorsy/d-weather


module Weather;



void getForecast(void delegate(string url, void delegate(int status, string response) cb) http_cb, void delegate(string latitude, string longitude, string temperature, string weather) cb) {
	import std.stdio : stdout, stderr;
	import std.json : JSONValue, parseJSON;
	import std.string : chomp;
	import std.array : split;
	import std.conv : to;

	// Get latitude and longitude from ip address
	http_cb("http://ipinfo.io/loc", delegate(int status, string response) {
		if (status != 200) {
			stderr.writefln("Request for lat and lon data failed with status code: %s", status);
			return;
		}

		string[] result = split(response, ",");
		string latitude = chomp(result[0]);
		string longitude = chomp(result[1]);

		string url = "http://forecast.weather.gov/MapClick.php?lat=" ~ latitude ~ "&lon=" ~ longitude ~ "&FcstType=json";
		http_cb(url, delegate(int status, string response) {
			if (status != 200) {
				stderr.writefln("Request for Weather data failed with status code: %s", status);
				return;
			}

			try {
				JSONValue j = parseJSON(response);
				string temperature = j["currentobservation"]["Temp"].str();
				auto weather = j["data"]["weather"][0].str();

				cb(latitude, longitude, temperature, weather);
			} catch (Throwable) {
				stderr.writefln("Failed to parse Weather server JSON response: %s", response);
			}
		});
	});
}

void httpGet(string url, void delegate(int status, string response) cb) {
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
}


unittest {
	import BDD;

	immutable string RESULT_IP = "37.7749,-122.4194\r\n";
	immutable string RESULT_WEATHER =
	`{
		"data": { "weather": [ "Hot" ] },
		"currentobservation": { "Temp" : "70" } }
	}`;

	void httpGetMock(string url, void delegate(int status, string response) cb) {
		import std.string : startsWith;

		if (url.startsWith("http://ipinfo.io/loc")) {
			cb(200, RESULT_IP);
		} else if (url.startsWith("http://forecast.weather.gov/MapClick.php?lat=")) {
			cb(200, RESULT_WEATHER);
		}
	}

	describe("Weather",
		it("Should get a forecast", delegate() {
			Weather.getForecast(&httpGetMock, delegate(string latitude, string longitude, string temperature, string weather) {
				latitude.shouldEqual("37.7749");
				longitude.shouldEqual("-122.4194");
				temperature.shouldEqual("70");
				weather.shouldEqual("Hot");
			});
		}),
	);
}


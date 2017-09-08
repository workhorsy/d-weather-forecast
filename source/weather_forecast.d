// Copyright (c) 2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Get weather forecast with the D programming language
// https://github.com/workhorsy/d-weather-forecast

/++
Get weather forecast with the D programming language. It first gets your longitude
and latitude using http://ipinfo.io. Then uses them to look up your 
weather using http://forecast.weather.gov.

Home page:
$(LINK https://github.com/workhorsy/d-weather-forecast)

Version: 1.0.0

License:
Boost Software License - Version 1.0

Examples:
----
import std.stdio : stdout, stderr;
import weather_forecast : getForecast, WeatherData;

getForecast(delegate(WeatherData weather_data, Exception err) {
	if (err) {
		stderr.writefln("%s", err);
	} else {
		stdout.writefln("latitude: %s", weather_data.latitude);
		stdout.writefln("longitude: %s", weather_data.longitude);
		stdout.writefln("city: %s", weather_data.city);
		stdout.writefln("region: %s", weather_data.region);
		stdout.writefln("country: %s", weather_data.country);
		stdout.writefln("postal: %s", weather_data.postal);
		stdout.writefln("temperature: %s", weather_data.temperature);
		stdout.writefln("summary: %s", weather_data.summary);
	}
});
----
+/

module weather_forecast;


/++
Data gathered in WeatherData:
----
struct WeatherData {
	string latitude;
	string longitude;
	string city;
	string region;
	string country;
	string postal;
	string temperature;
	string summary;
}
----
+/

struct WeatherData {
	string latitude;
	string longitude;
	string city;
	string region;
	string country;
	string postal;
	string temperature;
	string summary;
}

/++
Returns the weather forecast using a callback.

Params:
 cb = The callback to fire when weather info has been downloaded.

Throws:
	If it fails to download or parse the JSON response.
+/
void getForecast(void delegate(WeatherData weather_data, Exception err) cb) {
	import std.stdio : stdout, stderr;
	import std.json : JSONValue, parseJSON;
	import std.string : chomp, format;
	import std.array : split;
	import std.conv : to;
	import ipinfo : getIpinfo, IpinfoData, httpGet;

	WeatherData weather_data;

	getIpinfo(delegate(IpinfoData ipinfo_data, Exception err) {
		if (err) {
			stderr.writefln("%s", err);
		} else {
			string URL = "http://forecast.weather.gov/MapClick.php?lat=" ~ ipinfo_data.latitude ~ "&lon=" ~ ipinfo_data.longitude ~ "&FcstType=json";

			httpGet(URL, delegate(int status, string response) {
				if (status != 200) {
					auto err = new Exception("Request for \"%s\" failed with status code: %s".format(URL, status));
					cb(weather_data, err);
					return;
				}

				try {
					JSONValue j = parseJSON(response);

					weather_data.latitude = ipinfo_data.latitude;
					weather_data.longitude = ipinfo_data.longitude;
					weather_data.city = ipinfo_data.city;
					weather_data.region = ipinfo_data.region;
					weather_data.country = ipinfo_data.country;
					weather_data.postal = ipinfo_data.postal;
					weather_data.temperature = j["currentobservation"]["Temp"].str();
					weather_data.summary = j["data"]["weather"][0].str();
				} catch (Throwable) {
					auto err = new Exception("Failed to parse \"%s\" JSON response".format(URL));
					cb(weather_data, err);
					return;
				}

				cb(weather_data, null);
			});
		}
	});
}


// Copyright (c) 2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Get weather report with the D programming language
// https://github.com/workhorsy/d-weather

module Weather;

import std.stdio : stdout, stderr;
import core.stdc.time : time_t;
import std.concurrency : Tid;


immutable time_t UPDATE_SECONDS = 60 * 60; // 1 hour

time_t g_last_update_time = 0;
string g_latitude = "";
string g_longitude = "";
string g_temperature = "Unknown";
string g_weather = "Unknown";


string[string] Save() {
	import std.conv : to;

	string[string] retval;

	retval["g_last_weather_update_time"] = to!string(g_last_update_time);
	retval["g_latitude"] = to!string(g_latitude);
	retval["g_longitude"] = to!string(g_longitude);
	retval["g_temperature"] = to!string(g_temperature);
	retval["g_weather"] = to!string(g_weather);

	return retval;
}

void StartLookup() {
	import std.concurrency : spawn, send, thisTid;

	auto childTid = spawn(&getLocalWeather, thisTid);
	send(childTid, g_last_update_time);
}

void CheckForResult(string data_str) {
	import std.conv : to;

	string[string] data = to!(string[string])(data_str);
	foreach (key, value ; data) {
		final switch (key) {
			case "latitude":
				g_latitude = value;
				break;
			case "longitude":
				g_longitude = value;
				break;
			case "temperature":
				g_temperature = value;
				break;
			case "weather":
				g_weather = value;
				break;
		}
	}

	stdout.writefln("Got weather data from the network.");
}

private void makeWeatherHttpRequest(void delegate(string[string] message) cb) {
	import std.json : JSONValue, parseJSON;
	import std.string : chomp;
	import std.array : split;
	import std.conv : to;

	// Get latitude and longitude from ip address
	HttpGet("http://ipinfo.io/loc", delegate(int status, string response) {
//		stdout.writeln(status);
//		stdout.writeln(response);

		if (status != 200) {
			stderr.writefln("Request for lat and lon data failed with status code: %s", status);
			return;
		}

		string[] result = split(response, ",");
		string latitude = chomp(result[0]);
		string longitude = chomp(result[1]);

		string url = "http://forecast.weather.gov/MapClick.php?lat=" ~ latitude ~ "&lon=" ~ longitude ~ "&FcstType=json";
		HttpGet(url, delegate(int status, string response) {
//		stdout.writeln(status);
//		stdout.writeln(response);

			if (status != 200) {
				stderr.writefln("Request for Weather data failed with status code: %s", status);
				return;
			}

		try {
				JSONValue j = parseJSON(response);
				string temperature = j["currentobservation"]["Temp"].str();
				auto weather = j["data"]["weather"][0].str();

				string[string] retval;
				retval["latitude"] = latitude;
				retval["longitude"] = longitude;
				retval["temperature"] = temperature;
				retval["weather"] = weather;

				string[string] message;
				message["action"] = "weather";
				message["data_str"] = retval.to!string;
				cb(message);
			//stdout.writefln("!!! temperature: %s", temperature);
		} catch (Throwable) {
			stderr.writefln("Failed to parse weather server JSON response: %s", response);
		}
		});
	});
}

private void getLocalWeather(Tid ownerTid) {
	import core.stdc.time : time;
	import std.concurrency : send, receive;
	import std.conv : to;

	// Receive a message from the owner thread
	receive((time_t last_update_time) {
		// Only update if this is the first run, or the current time is 1 hour after the last update time
		const time_t time_now = time(null);
		const time_t diff_seconds = time_now - last_update_time;
		//std::cout << "diff: " << diff_seconds << std::endl;
		if (last_update_time != 0 && diff_seconds < UPDATE_SECONDS) {
			stdout.writefln("Using cached weather data.");
			stdout.writefln("Seconds since last weather check: %s", diff_seconds);
			return;
		}
		last_update_time = time_now;

		// Make the actual HTTP request
		makeWeatherHttpRequest(delegate(string[string] message) {
			message["last_update_time"] = to!string(last_update_time);
			send(ownerTid, message.to!string);
		});
	});
}

private void HttpGet(string url, void delegate(int status, string response) cb) {
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


int main() {
	import std.concurrency : receiveTimeout;
	import std.datetime : dur;
	import std.conv : to;
	import core.thread : Thread, seconds;

	Weather.StartLookup();

	receiveTimeout(dur!("nsecs")(-1), (string message_str) {
		string[string] message = message_str.to!(string[string]);
		//stdout.writefln("Message %s", message);

		time_t last_update_time;
		if ("last_update_time" in message) {
			last_update_time = message["last_update_time"].to!time_t;
		}

		switch (message["action"]) {
			case "weather":
				Weather.CheckForResult(message["data_str"]);
				Weather.g_last_update_time = last_update_time;
				break;
			default:
				break;
		}
	});

	while (true) {
		foreach (name, value ; Weather.Save()) {
			stdout.writefln("%s=%s", name, value);
		}
		stdout.writefln("");

		Thread.sleep(5.seconds);
	}

	return 0;
}

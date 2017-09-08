

import BDD;

unittest {
	import weather_forecast : getForecast, WeatherData;
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

	describe("weather_forecast",
		it("Should get a forecast", delegate() {
			getForecast(delegate(WeatherData weather_data, Exception err) {
				err.shouldBeNull();

				weather_data.latitude.shouldEqual("37.7749");
				weather_data.longitude.shouldEqual("-122.4194");
				weather_data.city.shouldEqual("Mountain View");
				weather_data.region.shouldEqual("California");
				weather_data.country.shouldEqual("US");
				weather_data.postal.shouldEqual("94043");
				weather_data.temperature.shouldEqual("70");
				weather_data.summary.shouldEqual("Hot");
			});
		}),
	);
}

int main() {
	return BDD.printResults();
}




int main() {
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

	return 0;
}
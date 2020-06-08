# D Weather Forecast
Get weather forecast from http://forecast.weather.gov with the D programming language

# Example

```d
import weather_forecast : getForecast, WeatherData;
import std.stdio : stdout;

getForecast(delegate(WeatherData weather_data, Exception err) {
  if (! err) {
    stdout.writefln("%s, %s", weather_data.city, weather_data.region);
    stdout.writefln("%s", weather_data.summary);
    stdout.writefln("%s F", weather_data.temperature);
  }
});

/*
San Francisco, California
Mostly Sunny
76 F
*/

```

# Documentation

[https://workhorsy.github.io/d-weather-forecast/2.0.0/](https://workhorsy.github.io/d-weather-forecast/2.0.0/)

# Generate documentation

```
dub --build=docs
```

# Run unit tests

```
dub test
```

[![Dub version](https://img.shields.io/dub/v/d-weather-forecast.svg)](https://code.dlang.org/packages/d-weather-forecast)
[![Dub downloads](https://img.shields.io/dub/dt/d-weather-forecast.svg)](https://code.dlang.org/packages/d-weather-forecast)
[![License](https://img.shields.io/badge/license-BSL_1.0-blue.svg)](https://raw.githubusercontent.com/workhorsy/d-weather-forecast/master/LICENSE)
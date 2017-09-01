# D Weather
Get weather report with the D programming language

# Documentation

[https://workhorsy.github.io/d-weather/$VERSION/](https://workhorsy.github.io/d-weather/$VERSION/)

# Generate documentation

```
dmd -c -D source/weather.d -Df=docs/$VERSION/index.html
```

# Run unit tests

```
dub test --main-file=test/main.d
```

[![Dub version](https://img.shields.io/dub/v/d-weather.svg)](https://code.dlang.org/packages/d-weather)
[![Dub downloads](https://img.shields.io/dub/dt/d-weather.svg)](https://code.dlang.org/packages/d-weather)
[![License](https://img.shields.io/badge/license-BSL_1.0-blue.svg)](https://raw.githubusercontent.com/workhorsy/d-weather/master/LICENSE)

# Scion

Scion is a web browser engine written in Swift that forks parts of WebKit and blends seamlessly with it.
The broad vision is to replace components gradually while preserving WebKit's behavior.

This project is currently under heavy development, with layout and rendering modules approaching readiness. These are ports of the original WebKit code, an approach chosen because of the relative imprecision of W3C standards in these areas. Future work in other modules is likely to use designs and implementations entirely different from WebKit's, while still matching observable behavior.

## Getting the Code

Run the following command to clone Scion's Git repository:

```
git clone https://github.com/asuhan/scion scion
```

## Building Scion

Currently, development is done using Swift 6.0.3 from Ubuntu 26.04 APT repositories.
Other Linux and Swift combinations might work, but haven't been tested.

The build command used during development and known to work:

```
Tools/Scripts/build-webkit --no-speech-synthesis --no-bubblewrap-sandbox --no-thunder --no-skia --gtk --debug
```

## Running Scion

To try Scion's inline formatting:

```
SCION_USE_IFC_LAYOUT=1 WebKitBuild/GTK/Debug/bin/MiniBrowser
```

Most automated fast layout tests currently pass with this setting, with most issues clustered around floating elements.
One such example is [initial-letter-clearance.html](https://github.com/asuhan/scion/blob/scion/LayoutTests/fast/css-generated-content/initial-letter-clearance.html).
Nearly all real-world websites I've tested, including very complex ones, appear to work correctly.

While fixing these remaining issues in isolation is entirely feasible, the current focus is on completing
and integrating Scion's rendering and layout modules. This functionality is controlled by the `SCION_USE_RENDERING=1`
environment variable setting. Currently, only trivial pages work with this setting, but this is quickly progressing
towards full functionality that matches WebKit.

# capnproto-dart: Cap'n Proto for Dart

![Build, Test & Lint](https://github.com/JonasWanke/capnproto-dart/workflows/Build,%20Test%20&%20Lint/badge.svg)
[![Coverage](https://codecov.io/gh/JonasWanke/capnproto-dart/branch/master/graph/badge.svg)](https://codecov.io/gh/JonasWanke/rrule)

[Cap'n Proto](https://capnproto.org) is an extremely efficient protocol for sharing data and capabilities, and capnproto-dart is a pure Dart implementation.

The [example folder](https://github.com/JonasWanke/capnproto-dart/tree/master/example) contains sample structs and a sample message, and a full walkthrough of using this package in [example/main.dart](https://github.com/JonasWanke/capnproto-dart/blob/master/example/main.dart).

In this early stage, this package only supports decoding messages containing primitive values and lists of primitives or structs. The following features are not yet supported:

- encoding messages
- packed messages
- enums, groups & unions
- default values
- inter-segment pointers with a two-word landing pad
- RPCs/Capabilities

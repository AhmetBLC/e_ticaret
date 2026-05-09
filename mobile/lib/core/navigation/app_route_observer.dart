import 'package:flutter/material.dart';

/// Global [RouteObserver] for refreshing lists when returning to a screen.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

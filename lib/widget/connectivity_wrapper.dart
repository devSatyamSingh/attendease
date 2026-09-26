import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../services/connectivity_service.dart';
import '../view/no_internet_screen.dart';

class ConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  ConsumerState<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<ConnectivityWrapper> {
  bool _forceHideOverlay = false;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(connectivityStatusProvider);

    // Reset the manual "hide" flag the moment the real status flips to
    // disconnected again, so a fresh drop always shows the overlay.
    ref.listen(connectivityStatusProvider, (previous, next) {
      if (next.value == InternetStatus.disconnected) {
        setState(() => _forceHideOverlay = false);
      }
    });

    final bool isDisconnected = statusAsync.value == InternetStatus.disconnected && !_forceHideOverlay;

    return Stack(
      children: [
        widget.child,
        if (isDisconnected)
          NoInternetScreen(
            onClose: () => setState(() => _forceHideOverlay = true),
          ),
      ],
    );
  }
}
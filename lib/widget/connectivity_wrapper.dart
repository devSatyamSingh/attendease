import 'dart:async';
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

class _ConnectivityWrapperState extends ConsumerState<ConnectivityWrapper>
    with WidgetsBindingObserver {
  bool _forceHideOverlay = false;
  bool _verifiedDisconnected = false;

  // Har verification run ko ek id dete hain, taaki koi purana/stale
  // retry loop galti se naye state ko overwrite na kare.
  int _verifyToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume hote hi purana signal/overlay turant clear karo, aur radio
    // ko settle hone ka time dekar fresh, multi-attempt verify chalao.
    if (state == AppLifecycleState.resumed) {
      _verifyToken++;
      setState(() {
        _verifiedDisconnected = false;
        _forceHideOverlay = false;
      });
      _startVerification(initialDelay: const Duration(milliseconds: 1000));
    }
  }

  void _onStreamStatus(InternetStatus? status) {
    if (status == InternetStatus.connected) {
      _verifyToken++; // koi chal rahi verification cancel kar do
      if (mounted) setState(() => _verifiedDisconnected = false);
    } else if (status == InternetStatus.disconnected) {
      _startVerification(initialDelay: const Duration(milliseconds: 500));
    }
  }

  /// Ek hi failed check pe bharosa nahi karte. Kam se kam 3 baar,
  /// thode-thode gap se try karte hain — sirf teeno fail hon tabhi
  /// overlay dikhate hain. Beech me kabhi bhi internet mil jaye to
  /// turant ruk jate hain.
  Future<void> _startVerification({required Duration initialDelay}) async {
    final myToken = ++_verifyToken;
    const attempts = [
      Duration(milliseconds: 0),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];

    await Future.delayed(initialDelay);

    for (final gap in attempts) {
      if (gap > Duration.zero) await Future.delayed(gap);
      if (!mounted || myToken != _verifyToken) return; // stale ho gaya

      final hasInternet = await checkInternetNow();
      if (!mounted || myToken != _verifyToken) return;

      if (hasInternet) {
        setState(() => _verifiedDisconnected = false);
        return;
      }
    }

    if (mounted && myToken == _verifyToken) {
      setState(() => _verifiedDisconnected = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(connectivityStatusProvider);

    ref.listen(connectivityStatusProvider, (previous, next) {
      _onStreamStatus(next.value);
    });

    final bool isDisconnected = _verifiedDisconnected && !_forceHideOverlay;

    return Stack(
      children: [
        widget.child,
        if (isDisconnected)
          NoInternetScreen(
            onClose: () => setState(() {
              _forceHideOverlay = true;
              _verifiedDisconnected = false;
            }),
          ),
      ],
    );
  }
}
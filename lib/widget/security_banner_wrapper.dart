// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../viewmodel/device_security_viewmodel.dart';
//
// /// Poori app ke upar red banner dikhata hai jab fake GPS / root / emulator mile.
// /// Check hota hai: app start, app resume (Developer Options se wapas aane pe), aur har 15 sec.
// class SecurityBannerWrapper extends ConsumerStatefulWidget {
//   final Widget child;
//   const SecurityBannerWrapper({super.key, required this.child});
//
//   @override
//   ConsumerState<SecurityBannerWrapper> createState() =>
//       _SecurityBannerWrapperState();
// }
//
// class _SecurityBannerWrapperState extends ConsumerState<SecurityBannerWrapper>
//     with WidgetsBindingObserver {
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _timer = Timer.periodic(const Duration(seconds: 15), (_) => _recheck());
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) _recheck();
//   }
//
//   void _recheck() {
//     if (!mounted) return;
//     ref.read(deviceSecurityProvider.notifier).recheck();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final security = ref.watch(deviceSecurityProvider).value;
//     final bool blocked = security != null && !security.isSafe;
//
//     // NOTE: Column ke children ki positions fixed rakhi hain taaki banner
//     // aane/jaane pe Navigator ka state reset na ho.
//     return Column(
//       children: [
//         blocked ? _buildBanner(security.message) : const SizedBox.shrink(),
//         Expanded(
//           child: MediaQuery.removePadding(
//             context: context,
//             removeTop: blocked, // banner ne status bar area le liya
//             child: widget.child,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBanner(String message) {
//     return Material(
//       color: const Color(0xFFD32F2F),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
//           child: Row(
//             children: [
//               const Icon(Icons.warning_amber_rounded,
//                   color: Colors.white, size: 20),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   message,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               TextButton(
//                 onPressed: _recheck,
//                 child: const Text(
//                   "Recheck",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
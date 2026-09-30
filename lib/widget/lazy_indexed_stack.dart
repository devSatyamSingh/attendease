import 'package:flutter/material.dart';

/// IndexedStack jaisa hi, bas tab ki screen tabhi build hoti hai jab user
/// pehli baar us tab pe jaye. Ek baar khul gayi to state bani rehti hai.
/// Isse app start pe saari tabs ki APIs ek saath nahi chalti.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List<bool>.generate(
      widget.children.length,
          (i) => i == widget.index,
    );
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index < _activated.length) {
      _activated[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          _activated[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}
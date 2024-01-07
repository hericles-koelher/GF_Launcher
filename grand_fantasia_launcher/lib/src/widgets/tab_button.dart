import 'package:flutter/material.dart';

class TabButton extends StatefulWidget {
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  final VoidCallback? onPressed;
  final Widget child;

  const TabButton({
    super.key,
    this.onEnter,
    this.onPressed,
    required this.child,
    this.onExit,
  });

  @override
  State<TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<TabButton> {
  var cursor = SystemMouseCursors.basic;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      onEnter: (details) {
        setState(() {
          cursor = SystemMouseCursors.click;
        });

        widget.onEnter?.call();
      },
      onExit: (_) {
        setState(() {
          cursor = SystemMouseCursors.basic;
        });

        widget.onExit?.call();
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white54,
              width: 1.5,
            ),
            color: Colors.white54,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

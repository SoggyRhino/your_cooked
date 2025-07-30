import 'package:flutter/material.dart';

class DropDownButton extends StatefulWidget {
  final String label;
  final ButtonStyle style;
  final List<ElevatedButton> subButtons;
  final bool reverseExpansion;

  const DropDownButton({
    super.key,
    required this.label,
    required this.style,
    required this.subButtons,
    this.reverseExpansion = false,
  });

  @override
  State<DropDownButton> createState() => _DropDownButtonState();
}

class _DropDownButtonState extends State<DropDownButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final children = _getChildren();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.reverseExpansion ? children.reversed.toList() : children,
    );
  }

  List<Widget> _getChildren() {
    return [
      ElevatedButton(
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        style: widget.style,
        child: Text(widget.label),
      ),
      SizedBox(height: _isExpanded ? 8 : 0),
      if (_isExpanded)
        for (final subButton in widget.subButtons)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: subButton,
          ),
    ];
  }
}

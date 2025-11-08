import 'package:flutter/material.dart';

class TextIconButton extends StatelessWidget {
  final void Function()? onTap;
  final String? _text;
  final String? tooltip;
  final IconData iconData;
  final Color disabledColor;
  final BuildContext context;
  final Alignment alignment;

  const TextIconButton({
    super.key,
    this.tooltip,
    required String? text,
    required this.onTap,
    required this.iconData,
    required this.disabledColor,
    required this.alignment,
    required this.context,
  }) : _text = (text != null && text.length > 3) ? null : text;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Stack(
            alignment: _text != null ? alignment : Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 13, 17, 13),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 60),
                  child: Text(
                    _text ?? '',
                    style: TextStyle(
                      color: onTap != null ? null : disabledColor,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
              Icon(
                iconData,
                color: onTap != null
                    ? Theme.of(context).textTheme.bodyLarge!.color
                    : disabledColor,
              ),
            ],
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(width: 50, height: 50),
          ),
        ],
      ),
    );
  }
}

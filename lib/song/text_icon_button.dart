import 'package:flutter/material.dart';

class TextIconButton extends StatelessWidget {
  final void Function()? onTap;
  final String? text;
  final String? tooltip;
  final IconData iconData;
  final Color disabledColor;
  final BuildContext context;
  final Alignment alignment;

  const TextIconButton(
      {Key? key,
      this.tooltip,
      required this.text,
      required this.onTap,
      required this.iconData,
      required this.disabledColor,
      required this.alignment,
      required this.context})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Stack(
            alignment: text != null ? alignment : Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 13, 17, 13),
                child: Text(
                  text ?? '',
                  style: TextStyle(
                    color: onTap != null ? null : disabledColor,
                  ),
                ),
              ),
              Icon(
                iconData,
                color: onTap != null ? null : disabledColor,
              ),
            ],
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
    );
  }
}
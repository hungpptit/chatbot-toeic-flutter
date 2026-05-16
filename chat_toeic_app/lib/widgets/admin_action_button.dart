import 'package:flutter/material.dart';

enum AdminActionButtonType { view, edit, delete }

class AdminActionButton extends StatelessWidget {
  final AdminActionButtonType type;
  final VoidCallback onTap;
  final String? tooltip;

  const AdminActionButton({
    super.key,
    required this.type,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (type) {
      case AdminActionButtonType.view:
        color = const Color(0xFF38BDF8); // Sky blue
        icon = Icons.remove_red_eye_outlined;
        break;
      case AdminActionButtonType.edit:
        color = const Color(0xFFFACC15); // Amber/Yellow
        icon = Icons.edit_outlined;
        break;
      case AdminActionButtonType.delete:
        color = const Color(0xFFF87171); // Rose/Red
        icon = Icons.delete_outline_rounded;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? _getDefaultTooltip(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: color.withOpacity(0.1),
          splashColor: color.withOpacity(0.2),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  String _getDefaultTooltip() {
    switch (type) {
      case AdminActionButtonType.view:
        return 'Xem chi tiết';
      case AdminActionButtonType.edit:
        return 'Chỉnh sửa';
      case AdminActionButtonType.delete:
        return 'Xóa';
    }
  }
}

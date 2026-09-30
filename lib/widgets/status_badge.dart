import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (s) {
      case 'pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Đang chờ';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'processing':
      case 'inprogress':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        label = 'Đang xử lý';
        icon = Icons.engineering_rounded;
        break;
      case 'completed':
      case 'resolved':
      case 'paid':
      case 'active':
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        label = s == 'paid' ? 'Đã thanh toán' : (s == 'approved' ? 'Đã duyệt' : 'Hoàn thành');
        icon = Icons.check_circle_rounded;
        break;
      case 'overdue':
      case 'urgent':
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = s == 'overdue' ? 'Quá hạn' : (s == 'rejected' ? 'Từ chối' : 'Khẩn cấp');
        icon = Icons.error_rounded;
        break;
      case 'cancelled':
      case 'inactive':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = s == 'inactive' ? 'Hết hiệu lực' : 'Đã hủy';
        icon = Icons.cancel_rounded;
        break;
      case 'closed':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        label = 'Đã đóng';
        icon = Icons.lock_rounded;
        break;
      case 'high':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFEA580C);
        label = 'Ưu tiên cao';
        icon = Icons.priority_high_rounded;
        break;
      case 'normal':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4F46E5);
        label = 'Bình thường';
        icon = Icons.horizontal_rule_rounded;
        break;
      case 'low':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Thấp';
        icon = Icons.arrow_downward_rounded;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = status;
        icon = Icons.info_outline_rounded;
    }

    if (customLabel != null) {
      label = customLabel!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

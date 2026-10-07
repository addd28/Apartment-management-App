import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/app_constants.dart';
import '../models/invoice_model.dart';

class ReceiptDialog extends StatelessWidget {
  final InvoiceModel invoice;
  final PaymentModel? payment;

  const ReceiptDialog({
    super.key,
    required this.invoice,
    this.payment,
  });

  static void show(BuildContext context, {required InvoiceModel invoice, PaymentModel? payment}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReceiptDialog(invoice: invoice, payment: payment),
    );
  }

  String _formatVND(double amount) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final p = payment ?? (invoice.payments.isNotEmpty ? invoice.payments.first : null);
    final txnRef = p?.transactionRef ?? (p?.id != null ? 'VNPAY_${p!.id}' : 'VNPAY_${invoice.id}');
    final payTime = p?.paymentDate ?? DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark Circle
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF059669),
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Thanh toán thành công',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                _formatVND(invoice.totalAmount),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Dashed Line Divider with Title
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'BIÊN NHẬN THANH TOÁN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                ],
              ),
              const SizedBox(height: 20),

              // Details
              _buildRow('Mã hóa đơn', invoice.invoiceNumber),
              _buildRow('Căn hộ', 'Phòng ${invoice.apartmentId}'),
              _buildRow('Kỳ thanh toán', 'Tháng ${invoice.month}/${invoice.year}'),
              _buildRow('Số tiền', _formatVND(invoice.totalAmount), isAmount: true),
              _buildRow('Phương thức', 'VNPAY'),
              _buildRow('Mã giao dịch', txnRef, isMonospace: true),
              _buildRow('Thời gian', dateFormat.format(payTime)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trạng thái', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ĐÃ THANH TOÁN',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF475569)),
                      label: const Text('Sao chép', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: 'BIÊN NHẬN THANH TOÁN\nMã HĐ: ${invoice.invoiceNumber}\nCăn hộ: Phòng ${invoice.apartmentId}\nKỳ: Tháng ${invoice.month}/${invoice.year}\nSố tiền: ${_formatVND(invoice.totalAmount)}\nMã GD: $txnRef\nTrạng thái: ĐÃ THANH TOÁN',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép thông tin biên nhận')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isAmount = false, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isAmount ? const Color(0xFF059669) : const Color(0xFF0F172A),
                fontWeight: isAmount ? FontWeight.bold : FontWeight.w600,
                fontSize: isAmount ? 14 : 13,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

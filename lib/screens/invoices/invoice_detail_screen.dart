import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_constants.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/receipt_dialog.dart';
import '../../widgets/status_badge.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _service = InvoiceService();
  InvoiceModel? _invoice;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inv = await _service.getInvoiceById(widget.invoiceId);
      setState(() {
        _invoice = inv;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showPaymentDialog() {
    if (_invoice == null) return;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thanh toán hóa đơn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Box số tiền
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số tiền', style: TextStyle(fontSize: 15, color: AppConstants.textSecondary, fontWeight: FontWeight.w500)),
                    Text(
                      _formatVND(_invoice!.totalAmount),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Phương thức thanh toán',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
              ),
              const SizedBox(height: 10),

              // Card VNPAY duy nhất
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'VNPAY',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VNPAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF065F46))),
                          SizedBox(height: 2),
                          Text('Thanh toán online', style: TextStyle(fontSize: 13, color: Color(0xFF047857))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF059669), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Thanh toán online an toàn qua VNPAY. Sau khi xác nhận thanh toán thành công, hóa đơn sẽ tự động chuyển sang trạng thái Đã thanh toán.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                ),
              ),
              const SizedBox(height: 22),

              CustomButton(
                text: 'Thanh toán',
                isLoading: isSubmitting,
                onPressed: () async {
                  setModalState(() => isSubmitting = true);
                  try {
                    final paymentUrl = await _service.createVnpayPayment(_invoice!.id);
                    if (!mounted) return;
                    Navigator.pop(ctx);

                    if (paymentUrl.isNotEmpty) {
                      final uri = Uri.parse(paymentUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        // Fallback: Show link dialog if cannot launch
                        _showPaymentUrlDialog(paymentUrl);
                      }
                      // Tải lại sau khi quay về từ VNPAY
                      Future.delayed(const Duration(seconds: 3), _loadDetail);
                    } else {
                      throw Exception('Không nhận được liên kết thanh toán từ VNPAY.');
                    }
                  } catch (e) {
                    setModalState(() => isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thanh toán chưa thành công: ${e.toString().replaceFirst('Exception: ', '')}')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thanh toán VNPAY'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng mở liên kết sau trên trình duyệt để hoàn tất thanh toán:'),
            const SizedBox(height: 10),
            SelectableText(url, style: const TextStyle(fontSize: 12, color: AppConstants.primaryColor)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  String _formatVND(double amount) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(_invoice != null ? 'Hóa đơn ${_invoice!.invoiceNumber}' : 'Chi Tiết Hóa Đơn'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: AppConstants.dangerColor)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadDetail, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Total Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppConstants.primaryColor, AppConstants.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _invoice!.title ?? 'Hóa đơn T${_invoice!.month}/${_invoice!.year}',
                                  style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                                ),
                                if (!_invoice!.isUnpaid && _invoice!.status.toLowerCase() != 'unpaid')
                                  StatusBadge(status: _invoice!.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatVND(_invoice!.totalAmount),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hạn thanh toán: ${dateFormat.format(_invoice!.dueDate)}',
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                            if (_invoice!.paidAmount > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Đã thanh toán: ${_formatVND(_invoice!.paidAmount)} (Còn lại: ${_formatVND(_invoice!.remainingAmount)})',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF6EE7B7)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Item Details Breakdown
                      const Text(
                        'Chi tiết bảng kê phí',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppConstants.borderColor),
                        ),
                        child: _invoice!.details.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                  child: Text('Không có mục chi tiết nào.', style: TextStyle(color: AppConstants.textSecondary)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _invoice!.details.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final item = _invoice!.details[idx];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Text(
                                      item.serviceName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    subtitle: item.description != null
                                        ? Text(item.description!, style: const TextStyle(fontSize: 12))
                                        : Text(
                                            '${item.quantity} x ${_formatVND(item.unitPrice)}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                    trailing: Text(
                                      _formatVND(item.amount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Payment history
                      if (_invoice!.payments.isNotEmpty) ...[
                        const Text(
                          'Lịch sử nộp tiền',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppConstants.borderColor),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _invoice!.payments.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final p = _invoice!.payments[idx];
                              Color iconBg;
                              IconData iconData;
                              Color iconColor;
                              String statusLabel;

                              if (p.isConfirmed) {
                                iconBg = const Color(0xFFD1FAE5);
                                iconColor = AppConstants.secondaryColor;
                                iconData = Icons.check_circle_outline;
                                statusLabel = 'Đã duyệt';
                              } else if (p.isPending) {
                                iconBg = const Color(0xFFFEF3C7);
                                iconColor = const Color(0xFFD97706);
                                iconData = Icons.hourglass_empty;
                                statusLabel = 'Chờ BQL duyệt';
                              } else {
                                iconBg = const Color(0xFFFEE2E2);
                                iconColor = AppConstants.dangerColor;
                                iconData = Icons.cancel_outlined;
                                statusLabel = 'Từ chối';
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: iconBg,
                                  child: Icon(iconData, color: iconColor, size: 20),
                                ),
                                title: Row(
                                  children: [
                                    Text(_formatVND(p.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: iconBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${p.paymentMethod} • ${dateFormat.format(p.paymentDate)}'),
                                    if (p.transactionRef != null && p.transactionRef!.isNotEmpty)
                                      Text('Mã GD: ${p.transactionRef}', style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary)),
                                    if (p.isRejected && p.notes != null && p.notes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text('Lý do: ${p.notes}', style: const TextStyle(fontSize: 12, color: AppConstants.dangerColor, fontWeight: FontWeight.w500)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Nút hành động: Nếu đã PAID -> Xem biên nhận; Nếu chưa PAID -> Thanh toán
                      if (_invoice!.isPaid) ...[
                        CustomButton(
                          text: 'Xem biên nhận',
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFF059669),
                          onPressed: () => ReceiptDialog.show(context, invoice: _invoice!),
                        ),
                      ] else if (!_invoice!.isCancelled) ...[
                        CustomButton(
                          text: 'Thanh toán',
                          icon: Icons.payment_rounded,
                          onPressed: _showPaymentDialog,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}


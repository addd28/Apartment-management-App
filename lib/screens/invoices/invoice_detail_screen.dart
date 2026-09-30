import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
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
    final amountController = TextEditingController(
      text: _invoice!.remainingAmount.toStringAsFixed(0),
    );
    final refController = TextEditingController();
    final noteController = TextEditingController();
    String paymentMethod = 'BankTransfer';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thanh Toán Hóa Đơn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Số tiền thanh toán (VNĐ)',
                controller: amountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text(
                'Phương thức thanh toán',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'BankTransfer', child: Text('Chuyển khoản Ngân hàng')),
                  DropdownMenuItem(value: 'Cash', child: Text('Tiền mặt tại quầy BQL')),
                  DropdownMenuItem(value: 'VNPay', child: Text('Ví điện tử / Thẻ')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => paymentMethod = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Mã tham chiếu / Số biên lai (Tùy chọn)',
                hint: 'Ví dụ: FT231908231',
                controller: refController,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Ghi chú',
                hint: 'Nội dung nộp tiền...',
                controller: noteController,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Xác Nhận Nộp Tiền',
                isLoading: isSubmitting,
                onPressed: () async {
                  final amt = double.tryParse(amountController.text) ?? 0.0;
                  if (amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Số tiền thanh toán phải lớn hơn 0.')),
                    );
                    return;
                  }

                  setModalState(() => isSubmitting = true);
                  try {
                    await _service.createPayment(
                      invoiceId: _invoice!.id,
                      amount: amt,
                      paymentMethod: paymentMethod,
                      transactionRef: refController.text.isNotEmpty ? refController.text : null,
                      notes: noteController.text.isNotEmpty ? noteController.text : null,
                    );
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thanh toán thành công!'),
                        backgroundColor: AppConstants.secondaryColor,
                      ),
                    );
                    _loadDetail();
                  } catch (e) {
                    setModalState(() => isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppConstants.borderColor),
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppConstants.borderColor),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _invoice!.payments.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final p = _invoice!.payments[idx];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFD1FAE5),
                                  child: Icon(Icons.check, color: AppConstants.secondaryColor, size: 18),
                                ),
                                title: Text(_formatVND(p.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${p.paymentMethod} - ${dateFormat.format(p.paymentDate)}'),
                                trailing: p.transactionRef != null
                                    ? Text(p.transactionRef!, style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary))
                                    : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Pay Now Button (if still remaining amount)
                      if (!_invoice!.isPaid && _invoice!.remainingAmount > 0) ...[
                        CustomButton(
                          text: 'Thanh Toán Ngay (${_formatVND(_invoice!.remainingAmount)})',
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'invoice_detail_screen.dart';
import 'payment_history_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _service = InvoiceService();
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentFilter = 'All';

  final List<Map<String, String>> _filters = [
    {'label': 'Tất cả', 'value': 'All'},
    {'label': 'Chưa thanh toán', 'value': 'Pending'},
    {'label': 'Đã thanh toán', 'value': 'Paid'},
    {'label': 'Quá hạn', 'value': 'Overdue'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getMyInvoices(status: _currentFilter);
      setState(() {
        _invoices = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
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
        title: const Text('Hóa Đơn & Tiền Phí'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử thanh toán',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchInvoices,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _currentFilter == f['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(f['label']!),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppConstants.textPrimary,
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      selectedColor: AppConstants.primaryColor,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _currentFilter = f['value']!;
                          });
                          _fetchInvoices();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: AppConstants.dangerColor)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchInvoices, child: const Text('Thử lại')),
                          ],
                        ),
                      )
                    : _invoices.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_rounded,
                            title: 'Không có hóa đơn',
                            description: _currentFilter == 'All'
                                ? 'Căn hộ của bạn hiện không có hóa đơn nào cần xử lý.'
                                : 'Không có hóa đơn nào thuộc trạng thái "$_currentFilter".',
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchInvoices,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _invoices.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final inv = _invoices[idx];
                                return InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => InvoiceDetailScreen(invoiceId: inv.id),
                                      ),
                                    );
                                    _fetchInvoices();
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppConstants.borderColor),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.receipt_outlined, color: AppConstants.primaryColor, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  inv.title ?? 'Hóa đơn T${inv.month}/${inv.year}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppConstants.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            StatusBadge(status: inv.status, fontSize: 11),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatVND(inv.totalAmount),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppConstants.primaryDark,
                                              ),
                                            ),
                                            Text(
                                              'Hạn: ${dateFormat.format(inv.dueDate)}',
                                              style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                                            ),
                                          ],
                                        ),
                                        if (!inv.isPaid && inv.remainingAmount > 0) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Còn lại: ${_formatVND(inv.remainingAmount)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppConstants.dangerColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Text(
                                                'Chạm để thanh toán >',
                                                style: TextStyle(fontSize: 12, color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../models/apartment_model.dart';
import '../../services/apartment_service.dart';
import '../../services/move_request_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateMoveRequestScreen extends StatefulWidget {
  const CreateMoveRequestScreen({super.key});

  @override
  State<CreateMoveRequestScreen> createState() => _CreateMoveRequestScreenState();
}

class _CreateMoveRequestScreenState extends State<CreateMoveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _plateController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  final _apartmentService = ApartmentService();
  final _moveService = MoveRequestService();

  List<ApartmentModel> _myApartments = [];
  ApartmentModel? _selectedApartment;
  String _selectedType = 'MoveIn';
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  bool _isLoading = false;
  bool _isFetchingApt = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  @override
  void dispose() {
    _descController.dispose();
    _plateController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadApartments() async {
    try {
      final list = await _apartmentService.getMyApartments();
      setState(() {
        _myApartments = list;
        if (list.isNotEmpty) _selectedApartment = list.first;
        _isFetchingApt = false;
      });
    } catch (_) {
      setState(() => _isFetchingApt = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedApartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn căn hộ thực hiện.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _moveService.createMoveRequest(
        apartmentId: _selectedApartment!.id,
        type: _selectedType,
        scheduledDate: _scheduledDate,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        description: _descController.text,
        vehicleLicensePlate: _plateController.text,
        driverName: _driverNameController.text,
        driverPhone: _driverPhoneController.text,
        notes: _notesController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi đơn đăng ký chuyển đồ!'),
          backgroundColor: AppConstants.secondaryColor,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Đăng Ký Chuyển Đồ'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
      ),
      body: _isFetchingApt
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppConstants.dangerColor, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Apartment
                    const Text('Căn hộ thực hiện', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ApartmentModel>(
                      isExpanded: true,
                      value: _selectedApartment,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _myApartments.map((apt) {
                        return DropdownMenuItem<ApartmentModel>(
                          value: apt,
                          child: Text('Phòng ${apt.apartmentNumber} (${apt.buildingName ?? 'Tòa nhà'})'),
                        );
                      }).toList(),
                      onChanged: (apt) => setState(() => _selectedApartment = apt),
                    ),
                    const SizedBox(height: 16),

                    // Move Type
                    const Text('Loại hình chuyển đồ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedType = 'MoveIn'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == 'MoveIn' ? AppConstants.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedType == 'MoveIn' ? AppConstants.primaryColor : AppConstants.borderColor,
                                  width: _selectedType == 'MoveIn' ? 1.8 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Chuyển vào (MoveIn)',
                                  style: TextStyle(
                                    fontWeight: _selectedType == 'MoveIn' ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedType == 'MoveIn' ? AppConstants.primaryDark : AppConstants.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedType = 'MoveOut'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == 'MoveOut' ? AppConstants.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedType == 'MoveOut' ? AppConstants.primaryColor : AppConstants.borderColor,
                                  width: _selectedType == 'MoveOut' ? 1.8 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Chuyển đi (MoveOut)',
                                  style: TextStyle(
                                    fontWeight: _selectedType == 'MoveOut' ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedType == 'MoveOut' ? AppConstants.primaryDark : AppConstants.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Scheduled Date & Time
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ngày thực hiện', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppConstants.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 18, color: AppConstants.primaryColor),
                                      const SizedBox(width: 8),
                                      Text(dateFormat.format(_scheduledDate)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bắt đầu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _pickTime(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppConstants.borderColor),
                                  ),
                                  child: Center(child: Text(_formatTime(_startTime))),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kết thúc', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _pickTime(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppConstants.borderColor),
                                  ),
                                  child: Center(child: Text(_formatTime(_endTime))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    CustomTextField(
                      label: 'Mô tả danh mục đồ đạc cồng kềnh',
                      hint: 'Ví dụ: Tủ lạnh, Giường ngủ, Sofa, Máy giặt, 10 thùng carton...',
                      controller: _descController,
                      maxLines: 3,
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Vui lòng liệt kê danh sách đồ đạc' : null,
                    ),
                    const SizedBox(height: 16),

                    // Vehicle & Driver info
                    CustomTextField(
                      label: 'Biển số xe tải / ba gác (Tùy chọn)',
                      hint: 'Ví dụ: 29C-888.88',
                      controller: _plateController,
                      prefixIcon: Icons.local_shipping_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Tên tài xế (Tùy chọn)',
                            hint: 'Họ tên',
                            controller: _driverNameController,
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'SĐT tài xế',
                            hint: 'Số liên hệ',
                            controller: _driverPhoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Ghi chú thêm cho BQL / An ninh',
                      hint: 'Yêu cầu mở thang máy hàng, giữ chỗ đỗ xe bốc dỡ...',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Gửi Đơn Đăng Ký Chuyển Đồ',
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

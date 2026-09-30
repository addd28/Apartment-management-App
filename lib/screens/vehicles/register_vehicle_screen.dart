import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../models/apartment_model.dart';
import '../../services/apartment_service.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  final _noteController = TextEditingController();
  final _apartmentService = ApartmentService();
  final _vehicleService = VehicleService();

  List<ApartmentModel> _myApartments = [];
  ApartmentModel? _selectedApartment;
  String _selectedType = 'Motorbike';
  bool _isLoading = false;
  bool _isFetchingApt = true;
  String? _errorMessage;

  final List<Map<String, dynamic>> _types = [
    {'value': 'Motorbike', 'label': 'Xe máy', 'icon': Icons.two_wheeler_rounded},
    {'value': 'Car', 'label': 'Ô tô', 'icon': Icons.directions_car_rounded},
    {'value': 'ElectricBike', 'label': 'Xe máy điện', 'icon': Icons.electric_moped_rounded},
    {'value': 'Bicycle', 'label': 'Xe đạp', 'icon': Icons.pedal_bike_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _noteController.dispose();
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedApartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn căn hộ đăng ký.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _vehicleService.registerVehicle(
        apartmentId: _selectedApartment!.id,
        type: _selectedType,
        licensePlate: _plateController.text,
        brand: _brandController.text,
        color: _colorController.text,
        notes: _noteController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký phương tiện thành công!'),
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
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Đăng Ký Gửi Xe'),
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
                    const Text('Căn hộ đăng ký', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

                    // Vehicle Type
                    const Text('Loại phương tiện', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: _types.map((t) {
                        final isSel = _selectedType == t['value'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () => setState(() => _selectedType = t['value']),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSel ? AppConstants.primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? AppConstants.primaryColor : AppConstants.borderColor,
                                    width: isSel ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      t['icon'],
                                      color: isSel ? AppConstants.primaryColor : AppConstants.textSecondary,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t['label'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        color: isSel ? AppConstants.primaryDark : AppConstants.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // License Plate
                    CustomTextField(
                      label: 'Biển số xe',
                      hint: 'Ví dụ: 29A-123.45',
                      controller: _plateController,
                      prefixIcon: Icons.badge_outlined,
                      validator: (val) {
                        if (_selectedType != 'Bicycle' && (val == null || val.trim().isEmpty)) {
                          return 'Vui lòng nhập biển số xe';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Brand
                    CustomTextField(
                      label: 'Hãng xe',
                      hint: 'Ví dụ: Honda, Yamaha, Toyota, VinFast...',
                      controller: _brandController,
                      prefixIcon: Icons.directions_car_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Color
                    CustomTextField(
                      label: 'Màu sơn xe',
                      hint: 'Ví dụ: Đen, Trắng, Đỏ...',
                      controller: _colorController,
                      prefixIcon: Icons.palette_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    CustomTextField(
                      label: 'Ghi chú thêm',
                      hint: 'Mô tả vị trí gửi mong muốn hoặc đặc điểm nhận dạng...',
                      controller: _noteController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Xác Nhận Đăng Ký Gửi Xe',
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

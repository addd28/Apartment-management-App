import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_constants.dart';
import '../../models/apartment_model.dart';
import '../../services/apartment_service.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateMaintenanceScreen extends StatefulWidget {
  const CreateMaintenanceScreen({super.key});

  @override
  State<CreateMaintenanceScreen> createState() => _CreateMaintenanceScreenState();
}

class _CreateMaintenanceScreenState extends State<CreateMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _apartmentService = ApartmentService();
  final _maintenanceService = MaintenanceService();
  final _picker = ImagePicker();

  List<ApartmentModel> _myApartments = [];
  ApartmentModel? _selectedApartment;
  String _selectedPriority = 'Normal';
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isFetchingApartments = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadApartments() async {
    try {
      final list = await _apartmentService.getMyApartments();
      setState(() {
        _myApartments = list;
        if (list.isNotEmpty) {
          _selectedApartment = list.first;
        }
        _isFetchingApartments = false;
      });
    } catch (e) {
      setState(() {
        _isFetchingApartments = false;
        _errorMessage = 'Không tải được danh sách căn hộ của bạn.';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() {
          _selectedImages.add(File(picked.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thêm hình ảnh sự cố',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppConstants.primaryColor),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppConstants.primaryColor),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedApartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn căn hộ báo hỏng.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _maintenanceService.createRequest(
        apartmentId: _selectedApartment!.id,
        title: _titleController.text,
        description: _descController.text,
        priority: _selectedPriority,
        imageFiles: _selectedImages,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu bảo trì trực tiếp tới Kỹ thuật viên (Staff)!'),
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
        title: const Text('Gửi Yêu Cầu Bảo Trì'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
      ),
      body: _isFetchingApartments
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info banner: Direct workflow
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: AppConstants.primaryColor, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Yêu cầu được gửi thẳng tới Kỹ thuật viên (Staff) để xử lý nhanh, không qua phê duyệt trung gian.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.primaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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

                    // Apartment Selector
                    const Text(
                      'Căn hộ gặp sự cố',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ApartmentModel>(
                      isExpanded: true,
                      value: _selectedApartment,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppConstants.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppConstants.borderColor),
                        ),
                      ),
                      items: _myApartments.map((apt) {
                        return DropdownMenuItem<ApartmentModel>(
                          value: apt,
                          child: Text(
                            'Phòng ${apt.apartmentNumber} (${apt.buildingName ?? 'Tòa nhà'} - Tầng ${apt.floorNumber ?? apt.floorId})',
                          ),
                        );
                      }).toList(),
                      onChanged: (apt) {
                        setState(() {
                          _selectedApartment = apt;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Priority Selector
                    const Text(
                      'Mức độ ưu tiên',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityRadio('Normal', 'Bình thường', const Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        _buildPriorityRadio('High', 'Ưu tiên cao', const Color(0xFFEA580C)),
                        const SizedBox(width: 8),
                        _buildPriorityRadio('Urgent', 'Khẩn cấp', const Color(0xFFDC2626)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    CustomTextField(
                      label: 'Tiêu đề sự cố',
                      hint: 'Ví dụ: Hỏng vòi nước bồn rửa, Cúp điện phòng khách...',
                      controller: _titleController,
                      prefixIcon: Icons.report_problem_outlined,
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tiêu đề sự cố' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    CustomTextField(
                      label: 'Mô tả chi tiết',
                      hint: 'Mô tả hiện tượng hư hỏng, vị trí cụ thể trong căn hộ...',
                      controller: _descController,
                      maxLines: 4,
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Vui lòng mô tả chi tiết sự cố' : null,
                    ),
                    const SizedBox(height: 20),

                    // Attachments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ảnh chụp hiện trường',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: const Text('Thêm ảnh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_selectedImages.isEmpty)
                      InkWell(
                        onTap: _showImageSourceDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppConstants.borderColor, style: BorderStyle.solid),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, color: AppConstants.textSecondary, size: 30),
                                SizedBox(height: 6),
                                Text(
                                  'Chụp hoặc tải ảnh hiện trường (Tùy chọn)',
                                  style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, idx) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[idx],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Submit Button
                    CustomButton(
                      text: 'Gửi Yêu Cầu Ngay',
                      icon: Icons.send_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPriorityRadio(String value, String title, Color color) {
    final isSelected = _selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriority = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppConstants.borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: isSelected ? color : AppConstants.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

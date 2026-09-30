import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/empty_state.dart';
import 'register_vehicle_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _service = VehicleService();
  List<VehicleModel> _vehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getMyVehicles();
      setState(() {
        _vehicles = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDelete(int id, String? plate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đăng ký gửi xe?'),
        content: Text('Bạn có chắc chắn muốn hủy đăng ký xe "${plate ?? 'này'}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteVehicle(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đăng ký phương tiện.')),
      );
      _fetchVehicles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return Icons.directions_car_rounded;
      case 'electricbike':
        return Icons.electric_moped_rounded;
      case 'bicycle':
        return Icons.pedal_bike_rounded;
      default:
        return Icons.two_wheeler_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Phương Tiện & Thẻ Gửi Xe'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchVehicles,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final registered = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const RegisterVehicleScreen()),
          );
          if (registered == true) _fetchVehicles();
        },
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Đăng ký xe', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      ElevatedButton(onPressed: _fetchVehicles, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _vehicles.isEmpty
                  ? EmptyState(
                      icon: Icons.directions_car_filled_outlined,
                      title: 'Chưa có phương tiện đăng ký',
                      description: 'Căn hộ của bạn hiện chưa đăng ký gửi ô tô, xe máy hoặc xe điện nào.',
                      buttonText: 'Đăng ký xe mới',
                      onButtonPressed: () async {
                        final registered = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterVehicleScreen()),
                        );
                        if (registered == true) _fetchVehicles();
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchVehicles,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _vehicles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final v = _vehicles[idx];
                          return Container(
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
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_getVehicleIcon(v.type), color: AppConstants.primaryColor, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            v.licensePlate ?? 'Chưa có biển số',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              v.typeLabel,
                                              style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${v.brand ?? 'Khác'} ${v.color != null ? '• ${v.color}' : ''} • P.${v.apartmentNumber}',
                                        style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                      ),
                                      if (v.parkingCardNumber != null && v.parkingCardNumber!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.credit_card_rounded, size: 14, color: AppConstants.secondaryColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Mã thẻ: ${v.parkingCardNumber}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.secondaryColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.dangerColor),
                                  tooltip: 'Hủy đăng ký',
                                  onPressed: () => _handleDelete(v.id, v.licensePlate),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

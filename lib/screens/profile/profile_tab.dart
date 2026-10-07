import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../core/storage_service.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../contracts/contract_list_screen.dart';
import '../household/household_members_screen.dart';
import '../invoices/payment_history_screen.dart';
import '../utilities/utility_usage_screen.dart';
import '../vehicles/vehicle_list_screen.dart';
import 'edit_profile_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _authService = AuthService();
  final _apartmentService = ApartmentService();

  UserModel? _user;
  List<ApartmentMemberModel> _members = [];
  List<ContractModel> _contracts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getProfile();
      final members = await _apartmentService.getMyMembers();
      final contracts = await _apartmentService.getMyContracts();
      setState(() {
        _user = user;
        _members = members;
        _contracts = contracts;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _user = StorageService.getUser();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
        title: const Text('Tài Khoản Cư Dân', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppConstants.primaryColor),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppConstants.primaryLight,
                          child: Text(
                            (_user?.fullName.isNotEmpty == true)
                                ? _user!.fullName[0].toUpperCase()
                                : 'R',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _user?.fullName ?? 'Cư Dân',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CƯ DÂN CHÍNH THỨC (RESIDENT)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.secondaryColor),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.phone_outlined, size: 20, color: AppConstants.textSecondary),
                                const SizedBox(height: 4),
                                Text(
                                  _user?.phoneNumber ?? 'Chưa cập nhật',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 30, color: AppConstants.borderColor),
                            Column(
                              children: [
                                const Icon(Icons.email_outlined, size: 20, color: AppConstants.textSecondary),
                                const SizedBox(height: 4),
                                Text(
                                  _user?.email ?? 'Chưa cập nhật',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resident Management Services Menu
                  const Text(
                    'Dịch vụ & Tiện ích căn hộ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppConstants.borderColor),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.description_outlined, color: AppConstants.primaryColor),
                          title: const Text('Hợp đồng căn hộ'),
                          subtitle: Text(_contracts.isNotEmpty ? '${_contracts.length} hợp đồng có hiệu lực' : 'Xem chi tiết hợp đồng thuê/ở'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ContractListScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.family_restroom_rounded, color: AppConstants.primaryColor),
                          title: const Text('Thành viên hộ gia đình'),
                          subtitle: Text(_members.isNotEmpty ? '${_members.length} người cùng căn hộ' : 'Danh sách cư dân cùng phòng'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HouseholdMembersScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.speed_rounded, color: AppConstants.primaryColor),
                          title: const Text('Chỉ số điện & nước'),
                          subtitle: const Text('Lịch sử chốt số công tơ định kỳ'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UtilityUsageScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.two_wheeler_rounded, color: AppConstants.primaryColor),
                          title: const Text('Phương tiện gửi xe'),
                          subtitle: const Text('Quản lý xe ô tô, xe máy, xe điện'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VehicleListScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.history_rounded, color: AppConstants.primaryColor),
                          title: const Text('Lịch sử thanh toán'),
                          subtitle: const Text('Biên lai thu phí & giao dịch'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contracts Quick Preview
                  if (_contracts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hợp đồng gần đây',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ContractListScreen()),
                            );
                          },
                          child: const Text('Xem tất cả'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ..._contracts.take(2).map((c) => InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ContractListScreen()),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppConstants.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'HĐ: ${c.contractNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.primaryDark),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        c.status,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.secondaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Căn hộ: P.${c.apartmentNumber ?? c.apartmentId} • Tiền thuê: ${_formatVND(c.monthlyRent)}/tháng',
                                  style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hiệu lực: ${dateFormat.format(c.startDate)} - ${dateFormat.format(c.endDate)}',
                                  style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 10),
                  ],

                  // Settings Menu
                  const Text(
                    'Cài đặt & Bảo mật',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppConstants.borderColor),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined, color: AppConstants.primaryColor),
                          title: const Text('Chỉnh sửa thông tin cá nhân'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            if (_user != null) {
                              final updated = await Navigator.push<UserModel?>(
                                context,
                                MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
                              );
                              if (updated != null) {
                                setState(() => _user = updated);
                              }
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.lock_outline_rounded, color: AppConstants.primaryColor),
                          title: const Text('Đổi mật khẩu'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.dns_outlined, color: AppConstants.primaryColor),
                          title: const Text('Máy chủ kết nối'),
                          subtitle: Text(StorageService.getBaseUrl(), style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  CustomButton(
                    text: 'Đăng Xuất Tài Khoản',
                    color: AppConstants.dangerColor,
                    isOutlined: true,
                    icon: Icons.logout_rounded,
                    onPressed: _handleLogout,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

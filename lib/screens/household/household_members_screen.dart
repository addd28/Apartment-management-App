import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../models/apartment_model.dart';
import '../../services/apartment_service.dart';
import '../../widgets/empty_state.dart';

class HouseholdMembersScreen extends StatefulWidget {
  const HouseholdMembersScreen({super.key});

  @override
  State<HouseholdMembersScreen> createState() => _HouseholdMembersScreenState();
}

class _HouseholdMembersScreenState extends State<HouseholdMembersScreen> {
  final _apartmentService = ApartmentService();
  List<ApartmentMemberModel> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _apartmentService.getMyMembers();
      setState(() {
        _members = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
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
        title: const Text('Thành Viên Căn Hộ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppConstants.primaryColor),
            onPressed: _loadMembers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppConstants.dangerColor, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppConstants.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMembers,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _members.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'Chưa có danh sách thành viên',
                            description: 'Không tìm thấy hồ sơ thành viên thuộc căn hộ của bạn trên hệ thống.',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F766E).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hộ gia đình cư trú',
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tổng số: ${_members.length} người',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(_members.length, (idx) {
                            final m = _members[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppConstants.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: m.isOwner ? const Color(0xFFFEF3C7) : AppConstants.primaryLight,
                                        child: Icon(
                                          m.isOwner ? Icons.star_rounded : Icons.person_rounded,
                                          color: m.isOwner ? const Color(0xFFD97706) : AppConstants.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    m.fullName ?? 'Thành viên',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppConstants.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (m.isOwner) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      'Chủ hộ',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFFD97706),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Quan hệ: ${m.relationship} • P.${m.apartmentNumber ?? m.apartmentId}',
                                              style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  if (m.phoneNumber != null && m.phoneNumber!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 16, color: AppConstants.textSecondary),
                                          const SizedBox(width: 8),
                                          Text(
                                            'SĐT: ${m.phoneNumber}',
                                            style: const TextStyle(fontSize: 13, color: AppConstants.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (m.citizenId != null && m.citizenId!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.badge_outlined, size: 16, color: AppConstants.textSecondary),
                                          const SizedBox(width: 8),
                                          Text(
                                            'CCCD: ${m.citizenId}',
                                            style: const TextStyle(fontSize: 13, color: AppConstants.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (m.joinedAt != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppConstants.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ngày vào ở: ${dateFormat.format(m.joinedAt!)}',
                                          style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
    );
  }
}

import 'package:ireader_mobile_edition/core/memo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/widgets/admin_list.dart';
import 'package:ireader_mobile_edition/widgets/admin_sidebar.dart';
import 'package:ireader_mobile_edition/widgets/admin_top_header.dart';
import 'package:ireader_mobile_edition/model/admin.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/admin/admin/add_admin.dart';
import 'package:ireader_mobile_edition/views/admin/admin/add_admin_dialog.dart';

class ManageAdminScreen extends StatefulWidget {
  const ManageAdminScreen({super.key});

  @override
  State<ManageAdminScreen> createState() => _ManageAdminScreenState();
}

class _ManageAdminScreenState extends State<ManageAdminScreen>
    with MemoMixin<ManageAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  Stream<QuerySnapshot> _fetchAdmins() {
    return _firestore.collection('admins').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddAdmin() {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddAdminScreen()),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AddAdminDialog(admin: null),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(child: AdminSidebar(activeRoute: AdminRoute.admins)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const AdminSidebar(activeRoute: AdminRoute.admins),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminTopHeader(
                  pageTitle: 'Manage Admins',
                  pageSubtitle: 'Administrator accounts and access control',
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: memo('_fetchAdmins', () => _fetchAdmins()),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading admins'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }

                      var admins = snapshot.data!.docs
                          .map(
                            (doc) => Admin.fromMap(
                              doc.id,
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                      if (_selectedFilter != 'All') {
                        admins = admins
                            .where((a) => a.status == _selectedFilter)
                            .toList();
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      if (query.isNotEmpty) {
                        admins = admins.where((a) {
                          final name =
                              '${a.firstname} ${a.middlename ?? ''} ${a.lastname}'
                                  .toLowerCase();
                          return name.contains(query) ||
                              a.email.toLowerCase().contains(query);
                        }).toList();
                      }

                      return Column(
                        children: [
                          _buildToolbar(
                            admins.length,
                            snapshot.data!.docs.length,
                          ),
                          Expanded(child: _buildTable(admins)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(int shown, int total) {
    return AdminListToolbar(
      search: SizedBox(
        height: 38,
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search admins by name or email',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppTheme.textSecondaryColor,
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
      filters: [
        _filterTab('All'),
        _filterTab('ACTIVE', label: 'Active'),
        _filterTab('INACTIVE', label: 'Inactive'),
      ],
      actions: [
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: _openAddAdmin,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterTab(String value, {String? label}) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            ),
          ),
          child: Center(
            child: Text(
              label ?? value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<Admin> admins) {
    if (admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 52,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No admins found',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AdminListHeader(
            columns: [('NAME', 3), ('EMAIL', 3), ('STATUS', 2)],
            actionsWidth: 100,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: admins.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderColor),
              itemBuilder: (context, index) => _buildRow(admins[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Admin admin) {
    final isActive = admin.status == 'ACTIVE';
    final fullName =
        '${admin.firstname} ${admin.middlename != null && admin.middlename!.isNotEmpty ? "${admin.middlename} " : ""}${admin.lastname}'
            .trim();

    return AdminListRow(
      avatar: InitialAvatar(name: fullName, fallback: 'A'),
      title: fullName,
      detail: admin.email,
      isActive: isActive,
      actionsWidth: 100,
      actions: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            final isMobile = MediaQuery.of(context).size.width <= 768;
            if (isMobile) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddAdminScreen(admin: admin)),
              );
            } else {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AddAdminDialog(admin: admin),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isActive,
          activeThumbColor: const Color(0xFF16A34A),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (val) async {
            final newStatus = val ? 'ACTIVE' : 'INACTIVE';
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(val ? 'Activate Admin' : 'Deactivate Admin'),
                content: Text(
                  val
                      ? 'Set this admin as active?'
                      : 'Set this admin as inactive?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            );
            if (confirmed ?? false) {
              _firestore.collection('admins').doc(admin.id).update({
                'status': newStatus,
              });
            }
          },
        ),
      ],
    );
  }
}

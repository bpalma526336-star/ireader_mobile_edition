import 'package:ireader_mobile_edition/core/memo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/core/firestore_collections.dart';
import 'package:ireader_mobile_edition/model/division.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/admin/division/add_division_dialog.dart';
import 'package:ireader_mobile_edition/views/admin/division/compare_division.dart';
import 'package:ireader_mobile_edition/views/admin/school/manage_school.dart';
import 'package:ireader_mobile_edition/widgets/admin_list.dart';
import 'package:ireader_mobile_edition/widgets/admin_sidebar.dart';
import 'package:ireader_mobile_edition/widgets/admin_top_header.dart';

class ManageDivisionScreen extends StatefulWidget {
  const ManageDivisionScreen({super.key});

  @override
  State<ManageDivisionScreen> createState() => _ManageDivisionScreenState();
}

class _ManageDivisionScreenState extends State<ManageDivisionScreen>
    with MemoMixin<ManageDivisionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _fetchDivisions() =>
      _firestore.collection(FirestoreCollections.divisions).snapshots();

  void _openAdd() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddDivisionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(child: AdminSidebar(activeRoute: AdminRoute.divisions)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const AdminSidebar(activeRoute: AdminRoute.divisions),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminTopHeader(
                  pageTitle: 'Manage Divisions',
                  pageSubtitle: 'Organize schools under divisions',
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: memo('_fetchDivisions', () => _fetchDivisions()),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Center(
                          child: Text('Error loading divisions'),
                        );
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }

                      var divisions = snapshot.data!.docs
                          .map(
                            (d) => Division.fromMap(
                              d.id,
                              d.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                      if (_selectedFilter != 'All') {
                        divisions = divisions
                            .where((d) => d.status == _selectedFilter)
                            .toList();
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      if (query.isNotEmpty) {
                        divisions = divisions
                            .where((d) => d.name.toLowerCase().contains(query))
                            .toList();
                      }

                      return Column(
                        children: [
                          _buildToolbar(),
                          Expanded(child: _buildTable(divisions)),
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

  Widget _buildToolbar() {
    return AdminListToolbar(
      search: SizedBox(
        height: 38,
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search divisions',
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
            onPressed: _openAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Division'),
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
        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CompareDivision()),
              );
            },
            icon: const Icon(Icons.compare_arrows, size: 16),
            label: const Text('Compare Division'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimaryColor,
              side: const BorderSide(color: AppTheme.borderColor),
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

  Widget _buildTable(List<Division> divisions) {
    if (divisions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 52,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No divisions found',
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
            columns: [('DIVISION NAME', 4), ('STATUS', 2)],
            actionsWidth: 100,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: divisions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderColor),
              itemBuilder: (context, i) => _buildRow(divisions[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Division division) {
    final isActive = division.status == 'ACTIVE';

    return AdminListRow(
      avatar: InitialAvatar(name: division.name, fallback: 'D'),
      title: division.name,
      isActive: isActive,
      titleFlex: 4,
      actionsWidth: 100,
      actions: [
        Tooltip(
          message: 'View school',
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManageSchoolScreen(division: division),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                size: 15,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isActive,
          activeThumbColor: const Color(0xFF16A34A),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (val) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(val ? 'Activate Division' : 'Deactivate Division'),
                content: Text(
                  val
                      ? 'Set "${division.name}" as active?'
                      : 'Set "${division.name}" as inactive?',
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
              _firestore
                  .collection(FirestoreCollections.divisions)
                  .doc(division.id)
                  .update({'status': val ? 'ACTIVE' : 'INACTIVE'});
            }
          },
        ),
      ],
    );
  }
}

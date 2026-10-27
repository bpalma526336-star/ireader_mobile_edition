import 'package:ireader_mobile_edition/core/memo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/core/firestore_collections.dart';
import 'package:ireader_mobile_edition/model/division.dart';
import 'package:ireader_mobile_edition/model/school.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/admin/school/add_school_dialog.dart';
import 'package:ireader_mobile_edition/views/admin/school/compare_school.dart';
import 'package:ireader_mobile_edition/views/admin/schoolyear/manage_schoolyear.dart';
import 'package:ireader_mobile_edition/widgets/admin_list.dart';
import 'package:ireader_mobile_edition/widgets/admin_top_header.dart';

class ManageSchoolScreen extends StatefulWidget {
  final Division division;
  const ManageSchoolScreen({super.key, required this.division});

  @override
  State<ManageSchoolScreen> createState() => _ManageSchoolScreenState();
}

class _ManageSchoolScreenState extends State<ManageSchoolScreen>
    with MemoMixin<ManageSchoolScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Division> _divisions = [];

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDivisions() async {
    final snap = await _firestore
        .collection(FirestoreCollections.divisions)
        .get();
    if (!mounted) return;
    setState(() {
      _divisions = snap.docs
          .map((d) => Division.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Stream<QuerySnapshot> _fetchSchools() => _firestore
      .collection(FirestoreCollections.schools)
      .where('divisionid', isEqualTo: widget.division.id)
      .snapshots();

  String _divisionName(String id) {
    final match = _divisions.where((d) => d.id == id);
    return match.isNotEmpty ? match.first.name : '—';
  }

  void _openAdd() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddSchoolDialog(division: widget.division),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // drawer: isDesktop
      //     ? null
      //     : Drawer(child: AdminSidebar(activeRoute: AdminRoute.schools)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (isDesktop) const AdminSidebar(activeRoute: AdminRoute.schools),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminTopHeader(
                  pageTitle: 'Manage Schools',
                  pageSubtitle: 'Assign schools to divisions',
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: memo('_fetchSchools', () => _fetchSchools()),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading schools'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }

                      var schools = snapshot.data!.docs
                          .map(
                            (d) => School.fromMap(
                              d.id,
                              d.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                      if (_selectedFilter != 'All') {
                        schools = schools
                            .where((s) => s.status == _selectedFilter)
                            .toList();
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      if (query.isNotEmpty) {
                        schools = schools
                            .where((s) => s.name.toLowerCase().contains(query))
                            .toList();
                      }

                      return Column(
                        children: [
                          _buildToolbar(),
                          Expanded(child: _buildTable(schools)),
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
            hintText: 'Search schools',
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
        // SizedBox(
        //   height: 38,
        //   child: OutlinedButton.icon(
        //     onPressed: () => showDialog(
        //       context: context,
        //       barrierDismissible: false,
        //       builder: (_) => const MigrateSchoolDialog(),
        //     ),
        //     icon: const Icon(Icons.sync, size: 16),
        //     label: const Text('Migrate Data'),
        //     style: OutlinedButton.styleFrom(
        //       foregroundColor: AppTheme.primaryColor,
        //       side: const BorderSide(color: AppTheme.primaryColor),
        //       padding: const EdgeInsets.symmetric(horizontal: 14),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(8),
        //       ),
        //       textStyle: const TextStyle(
        //         fontSize: 13,
        //         fontWeight: FontWeight.w600,
        //       ),
        //     ),
        //   ),
        // ),
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: _openAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add School'),
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
                MaterialPageRoute(
                  builder: (_) => CompareSchool(division: widget.division),
                ),
              );
            },
            icon: const Icon(Icons.compare_arrows, size: 16),
            label: const Text('Compare Schools'),
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

  Widget _buildTable(List<School> schools) {
    if (schools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 52,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No schools found',
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
            columns: [('SCHOOL NAME', 4), ('DIVISION', 3), ('STATUS', 2)],
            actionsWidth: 140,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: schools.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderColor),
              itemBuilder: (context, i) => _buildRow(schools[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(School school) {
    final isActive = school.status == 'ACTIVE';

    return AdminListRow(
      avatar: InitialAvatar(name: school.name, fallback: 'S'),
      title: school.name,
      subtitle: school.address,
      detail: _divisionName(school.divisionid),
      isActive: isActive,
      titleFlex: 4,
      detailFlex: 3,
      statusFlex: 2,
      actionsWidth: 140,
      actions: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageSchoolyearScreen(
                division: widget.division,
                school: school,
              ),
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
              Icons.calendar_month_outlined,
              size: 15,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                AddSchoolDialog(school: school, division: widget.division),
          ),
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
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(val ? 'Activate School' : 'Deactivate School'),
                content: Text(
                  val
                      ? 'Set "${school.name}" as active?'
                      : 'Set "${school.name}" as inactive?',
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
                  .collection(FirestoreCollections.schools)
                  .doc(school.id)
                  .update({'status': val ? 'ACTIVE' : 'INACTIVE'});
            }
          },
        ),
      ],
    );
  }
}

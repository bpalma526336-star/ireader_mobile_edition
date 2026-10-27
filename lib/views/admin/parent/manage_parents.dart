import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ireader_mobile_edition/model/parent.dart';
import 'package:ireader_mobile_edition/theme.dart';
import 'package:ireader_mobile_edition/views/admin/parent/add_parent.dart';
import 'package:ireader_mobile_edition/views/admin/parent/add_parent_dialog.dart';
import 'package:ireader_mobile_edition/views/admin/parent/view_students.dart';
import 'package:ireader_mobile_edition/widgets/admin_list.dart';
import 'package:ireader_mobile_edition/widgets/admin_sidebar.dart';
import 'package:ireader_mobile_edition/widgets/admin_top_header.dart';

class ManageParents extends StatefulWidget {
  const ManageParents({super.key});

  @override
  State<ManageParents> createState() => _ManageParentsState();
}

class _ManageParentsState extends State<ManageParents> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  void _openAddParent() {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddParent(parent: null)),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AddParent(parent: null),
      );
    }
  }

  Stream<QuerySnapshot> fetchParents() {
    return firestore.collection('parents').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(child: AdminSidebar(activeRoute: AdminRoute.parents)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) AdminSidebar(activeRoute: AdminRoute.parents),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminTopHeader(
                  pageTitle: 'Manage Parents',
                  pageSubtitle: 'Parent accounts and section assignments',
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        fetchParents(), // Assuming you have a function to fetch parents
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading parents'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }

                      var parents = snapshot.data!.docs
                          .map(
                            (doc) => Parent.fromMap(
                              doc.id,
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                      if (_selectedFilter != 'All') {
                        parents = parents
                            .where((p) => p.status == _selectedFilter)
                            .toList();
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      if (query.isNotEmpty) {
                        parents = parents.where((p) {
                          final name =
                              '${p.firstname} ${p.middlename ?? ''} ${p.lastname}'
                                  .toLowerCase();
                          return name.contains(query) ||
                              p.accesscode.toLowerCase().contains(query);
                        }).toList();
                      }

                      return Column(
                        children: [
                          _buildToolbar(),
                          Expanded(child: _buildTable(parents)),
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
            hintText: 'Search teachers by name or email',
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
            onPressed: _openAddParent,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Parent'),
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

  Widget _buildTable(List<Parent> parents) {
    if (parents.isEmpty) {
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
              'No parents found',
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
            columns: [('NAME', 3), ('Access Code', 3), ('STATUS', 2)],
            actionsWidth: 140,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: parents.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderColor),
              itemBuilder: (context, index) => _buildRow(parents[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Parent parent) {
    final isActive = parent.status == 'ACTIVE';
    final fullName =
        '${parent.firstname} ${parent.middlename != null && parent.middlename!.isNotEmpty ? "${parent.middlename} " : ""}${parent.lastname}'
            .trim();

    return AdminListRow(
      avatar: InitialAvatar(name: fullName, fallback: 'P'),
      title: fullName,
      detail: parent.accesscode,
      isActive: isActive,
      actionsWidth: 140,
      actions: [
        IconButton(
          tooltip: 'View Students',
          icon: const Icon(
            Icons.people_outline,
            size: 18,
            color: AppTheme.textSecondaryColor,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ViewParentStudent(parent: parent),
              ),
            );
          },
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            final isMobile = MediaQuery.of(context).size.width <= 768;
            if (isMobile) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddParent(parent: parent)),
              );
            } else {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AddParentDialog(parent: parent),
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
                title: Text(val ? 'Activate Parent' : 'Deactivate Parent'),
                content: Text(
                  val
                      ? 'Set this parent as active?'
                      : 'Set this parent as inactive?',
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
              firestore.collection('parents').doc(parent.id).update({
                'status': newStatus,
              });
            }
          },
        ),
      ],
    );
  }
}

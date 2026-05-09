import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:rumah_jahit/features/payroll/data/payroll_providers.dart';
import '../../../core/utils/currency_utils.dart';

import 'widgets/employee_list_tile.dart';
import 'widgets/add_employee_form.dart';

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final employeesAsync = ref.watch(employeesStreamProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.storefront, size: 20, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Rumah Jahit',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: colors.primary,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddEmployeeForm(),
              );
            },
            icon: Icon(Icons.person_add_outlined, color: colors.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: GoogleFonts.inter(color: Colors.red),
          ),
        ),
        data: (employees) {
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada karyawan',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tambahkan karyawan terlebih dahulu',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              140,
            ),
            itemCount: employees.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 16, color: Colors.black12),
            itemBuilder: (context, index) {
              final emp = employees[index];
              return Dismissible(
                key: Key(emp.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Hapus Karyawan?',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                      ),
                      content: Text(
                        'Apakah Anda yakin ingin menghapus ${emp.name} dari daftar karyawan?',
                        style: GoogleFonts.inter(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Hapus',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  ref.read(userRepositoryProvider).delete(emp.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${emp.name} telah dihapus'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: EmployeeListTile(
                  name: emp.name,
                  role: emp.roleDisplay,
                  avatarUrl: emp.imageUrl,
                  unpaidAmount: formatCurrency(emp.cashAdvanceBalance),
                  onTap: () {
                    context.push('/payroll/detail', extra: emp);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

}

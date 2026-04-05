import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';
import '../domain/payroll_record.dart';
import '../domain/tailor_annual_stat.dart';
import 'user_repository.dart';
import 'payroll_repository.dart';

// ── Repository Providers ──

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository();
});

// ── Stream Providers ──

final allUsersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchAll();
});

final tailorsStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchTailors();
});

final employeesStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchEmployees();
});

/// Payroll records for a specific user, parameterized by userId
final payrollByUserProvider =
    StreamProvider.family<List<PayrollRecord>, String>((ref, userId) {
  return ref.watch(payrollRepositoryProvider).watchByUser(userId);
});

/// Unpaid payroll records for a specific user
final unpaidPayrollByUserProvider =
    StreamProvider.family<List<PayrollRecord>, String>((ref, userId) {
  return ref.watch(payrollRepositoryProvider).watchByUser(userId).map(
      (list) => list.where((record) => record.status == 'UNPAID').toList());
});

/// Watch annual stats for a specific user and year
/// Param format: "userId_year"
final tailorAnnualStatsProvider =
    StreamProvider.family<TailorAnnualStat?, String>((ref, param) {
  final parts = param.split('_');
  final userId = parts[0];
  final year = int.parse(parts[1]);
  return ref.watch(payrollRepositoryProvider).watchAnnualStats(userId, year);
});

/// Paid payroll records for a specific user
final paidPayrollByUserProvider =
    StreamProvider.family<List<PayrollRecord>, String>((ref, userId) {
  return ref.watch(payrollRepositoryProvider).watchByUser(userId).map(
      (list) => list.where((record) => record.status == 'PAID').toList());
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rumah_jahit/features/settings/data/settings_repository.dart';
import 'package:rumah_jahit/features/settings/domain/wage_category.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(FirebaseFirestore.instance);
});

final wageCategoriesStreamProvider = StreamProvider<List<WageCategory>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchWageCategories();
});

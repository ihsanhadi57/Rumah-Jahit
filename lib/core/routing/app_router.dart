import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main_layout.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/activation_pending_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/pos/presentation/pos_screen.dart';
import '../../features/pos/presentation/checkout_screen.dart';
import '../../features/pos/presentation/transaction_history_screen.dart';
import '../../features/pos/presentation/receipt_screen.dart';
import '../../features/pos/domain/transaction_model.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/inventory/presentation/product_detail_screen.dart';
import '../../features/inventory/presentation/spk_detail_screen.dart';
import '../../features/inventory/presentation/raw_material_detail_screen.dart';
import '../../features/payroll/presentation/payroll_screen.dart';
import 'package:rumah_jahit/features/payroll/domain/app_user.dart';
import '../../features/payroll/presentation/employee_detail_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';

// Kunci navigasi global
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _sectionANavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'sectionANav',
);
final _sectionBNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'sectionBNav',
);
final _sectionCNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'sectionCNav',
);
final _sectionDNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'sectionDNav',
);

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/auth',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isOnAuth = state.matchedLocation == '/auth';

    // Not logged in -> force to auth
    if (user == null) {
      return isOnAuth ? null : '/auth';
    }

    // Logged in but on auth page -> go to dashboard
    if (isOnAuth) {
      return '/dashboard';
    }

    return null;
  },
  routes: <RouteBase>[
    // Auth route
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    // Activation pending route
    GoRoute(
      path: '/activation-pending',
      builder: (context, state) => const ActivationPendingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Dashboard
        StatefulShellBranch(
          navigatorKey: _sectionANavigatorKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'finance',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const FinanceScreen(),
                ),
              ],
            ),
          ],
        ),
        // Tab 2: Kasir POS
        StatefulShellBranch(
          navigatorKey: _sectionBNavigatorKey,
          routes: [
            GoRoute(
              path: '/pos',
              builder: (context, state) => const PosScreen(),
              routes: [
                GoRoute(
                  path: 'checkout',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CheckoutScreen(),
                ),
                GoRoute(
                  path: 'history',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const TransactionHistoryScreen(),
                ),
                GoRoute(
                  path: 'receipt',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final tx = state.extra as TransactionModel;
                    return ReceiptScreen(transaction: tx);
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 3: Gudang & SPK
        StatefulShellBranch(
          navigatorKey: _sectionCNavigatorKey,
          routes: [
            GoRoute(
              path: '/inventory',
              builder: (context, state) => const InventoryScreen(),
              routes: [
                GoRoute(
                  path: 'product-detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return ProductDetailScreen(
                      productName: extra['name'] as String,
                      productType: extra['type'] as String,
                      schoolLevels:
                          extra['schoolLevels'] as List<String>? ?? const [],
                    );
                  },
                ),
                GoRoute(
                  path: 'spk-detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final spkId = state.extra as String;
                    return SpkDetailScreen(spkId: spkId);
                  },
                ),
                GoRoute(
                  path: 'raw-material-detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final materialId = state.extra as String;
                    return RawMaterialDetailScreen(materialId: materialId);
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 4: Karyawan & Payroll
        StatefulShellBranch(
          navigatorKey: _sectionDNavigatorKey,
          routes: [
            GoRoute(
              path: '/payroll',
              builder: (context, state) => const PayrollScreen(),
              routes: [
                GoRoute(
                  path: 'detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final emp = state.extra as AppUser;
                    return EmployeeDetailScreen(employee: emp);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

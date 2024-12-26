import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tablets/src/features/deleted_transactions/view/deleted_transaction_screen.dart';
import 'package:tablets/src/features/home/view/home_screen.dart';
import 'package:tablets/src/features/categories/view/category_screen.dart';
import 'package:tablets/src/features/customers/view/customer_screen.dart';
import 'package:tablets/src/features/pending_transactions/pending_transactions.dart';
import 'package:tablets/src/features/products/view/product_screen.dart';
import 'package:tablets/src/features/gps_locations/presentation/sales_men_live_location_screen.dart';
import 'package:tablets/src/features/regions/view/regions_screen.dart';
import 'package:tablets/src/features/salesmen/view/salesman_screen.dart';
import 'package:tablets/src/features/settings/view/settings_screen.dart';
import 'package:tablets/src/features/transactions/view/transaction_screen.dart';
import 'package:tablets/src/features/vendors/view/vendor_screen.dart';
import 'package:tablets/src/routers/go_router_refresh_stream.dart';
import 'package:tablets/src/features/authentication/view/login_screen.dart';
import 'package:tablets/src/routers/not_found_screen.dart';

enum AppRoute {
  home,
  login,
  transactions,
  products,
  salesman,
  settings,
  categories,
  pendingTransactions,
  gps,
  customers,
  vendors,
  regions,
  deletedTransactions
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final goRouterProvider = Provider<GoRouter>(
  (ref) {
    final firebaseAuth = ref.watch(firebaseAuthProvider);
    return GoRouter(
      initialLocation: '/login',
      // debugLogDiagnostics: true, // print route in the console
      redirect: (context, state) {
        final bool isLoggedIn = firebaseAuth.currentUser != null;
        final String currentLocation = state.uri.path;
        // if user isn't logged in, redirect to login page
        if (!isLoggedIn) {
          return '/login';
        }
        // if user is just logged in, redirect to home page
        if (currentLocation == '/login') {
          return '/home';
        }
        // otherwise, no redirection is needed, user will go as he intended
        return null;
        // i didn't use and redirect to signup, because user can't signup
        // only addmin can create new accounts
      },
      refreshListenable: GoRouterRefreshStream(firebaseAuth.authStateChanges()),
      routes: <GoRoute>[
        GoRoute(
          path: '/home',
          name: AppRoute.home.name,
          builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          name: AppRoute.login.name,
          builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/products',
          name: AppRoute.products.name,
          builder: (BuildContext context, GoRouterState state) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/transactions',
          name: AppRoute.transactions.name,
          builder: (BuildContext context, GoRouterState state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: '/salesmen',
          name: AppRoute.gps.name,
          builder: (BuildContext context, GoRouterState state) =>
              const SalesmenLiveLocationScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: AppRoute.settings.name,
          builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/categories',
          name: AppRoute.categories.name,
          builder: (BuildContext context, GoRouterState state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/pending_transactions',
          name: AppRoute.pendingTransactions.name,
          builder: (BuildContext context, GoRouterState state) => const PendingTransactions(),
        ),
        GoRoute(
          path: '/salesman',
          name: AppRoute.salesman.name,
          builder: (BuildContext context, GoRouterState state) => const SalesmanScreen(),
        ),
        GoRoute(
          path: '/customers',
          name: AppRoute.customers.name,
          builder: (BuildContext context, GoRouterState state) => const CustomerScreen(),
        ),
        GoRoute(
          path: '/vendors',
          name: AppRoute.vendors.name,
          builder: (BuildContext context, GoRouterState state) => const VendorScreen(),
        ),
        GoRoute(
          path: '/regions',
          name: AppRoute.regions.name,
          builder: (BuildContext context, GoRouterState state) => const RegionsScreen(),
        ),
        GoRoute(
          path: '/deleted-transactions',
          name: AppRoute.deletedTransactions.name,
          builder: (BuildContext context, GoRouterState state) => const DeletedTransactionsScreen(),
        ),
      ],
      errorBuilder: (context, state) => const NotFoundScreen(),
    );
  },
);

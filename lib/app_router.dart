import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/tables/screens/table_grid_screen.dart';
import 'features/table_detail/screens/table_detail_screen.dart';
import 'features/menu/screens/menu_screen.dart';
import 'features/cart/screens/cart_screen.dart';
import 'features/orders/screens/order_tracking_screen.dart';
import 'features/orders/screens/order_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/tables',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/tables';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tables',
                builder: (context, state) => const TableGridScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrderTrackingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/tables/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TableDetailScreen(tableId: id);
        },
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) {
          final tableId = int.parse(state.uri.queryParameters['tableId'] ?? '0');
          return MenuScreen(tableId: tableId);
        },
      ),
      GoRoute(
        path: '/orders/:orderNo',
        builder: (context, state) {
          final orderNo = state.pathParameters['orderNo']!;
          return OrderDetailScreen(orderNo: orderNo);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) {
          final tableId = int.parse(state.uri.queryParameters['tableId'] ?? '0');
          return CartScreen(tableId: tableId);
        },
      ),
    ],
  );
});

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.table_restaurant_outlined),
            selectedIcon: Icon(Icons.table_restaurant),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

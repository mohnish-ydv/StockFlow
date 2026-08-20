import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/sf_ui.dart';
import 'account_screen.dart';
import 'auth_screen.dart';
import 'chats_screen.dart';
import 'guest_account_screen.dart';
import 'home_screen.dart';
import 'my_stock_screen.dart';
import 'search_screen.dart';
import 'sell_screen.dart';

class HomeShell extends StatefulWidget {
  final StockFlowApi api;
  final VoidCallback onSessionChanged;

  const HomeShell({super.key, required this.api, required this.onSessionChanged});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  bool get loggedIn => widget.api.currentUser != null;

  Future<bool> _authenticate(AuthMode mode) async {
    if (loggedIn) return true;
    var completed = false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AuthScreen(
          api: widget.api,
          initialMode: mode,
          onDone: () {
            completed = true;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (completed && mounted) {
      setState(() {});
      widget.onSessionChanged();
    }
    return completed;
  }

  Future<void> _logout() async {
    await widget.api.logout();
    if (!mounted) return;
    setState(() => index = 0);
    widget.onSessionChanged();
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          api: widget.api,
          requireAuth: () => _authenticate(AuthMode.signIn),
        ),
      ),
    );
  }

  Future<void> _openTab(int value) async {
    if (value == 0 || value == 4) {
      setState(() => index = value);
      return;
    }
    if (!loggedIn) {
      final ok = await _authenticate(AuthMode.signIn);
      if (!ok || !mounted) return;
    }
    setState(() => index = value);
  }

  List<Widget> get pages => [
        HomeScreen(
          api: widget.api,
          openSearch: _openSearch,
          requireAuth: () => _authenticate(AuthMode.signIn),
          openSell: () => _openTab(2),
        ),
        loggedIn ? ChatsScreen(api: widget.api) : const SizedBox.shrink(),
        loggedIn ? SellScreen(api: widget.api) : const SizedBox.shrink(),
        loggedIn
            ? MyStockScreen(api: widget.api, onStartSelling: () => _openTab(2))
            : const SizedBox.shrink(),
        loggedIn
            ? AccountScreen(
                api: widget.api,
                logout: _logout,
                onOpenMyStock: () => _openTab(3),
                onStartSelling: () => _openTab(2),
              )
            : GuestAccountScreen(authenticate: _authenticate),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return Scaffold(
            backgroundColor: StockFlowTheme.ink,
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    backgroundColor: StockFlowTheme.surface,
                    selectedIndex: index,
                    onDestinationSelected: _openTab,
                    labelType: NavigationRailLabelType.all,
                    indicatorColor: StockFlowTheme.brandSoft,
                    leading: const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: SfBrandMark(size: 40),
                    ),
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: Text('Home')),
                      NavigationRailDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake_rounded), label: Text('Deals')),
                      NavigationRailDestination(icon: Icon(Icons.add_circle_outline_rounded), selectedIcon: Icon(Icons.add_circle_rounded), label: Text('Sell')),
                      NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: Text('My stock')),
                      NavigationRailDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: Text('Account')),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: IndexedStack(index: index, children: pages)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: StockFlowTheme.ink,
          body: SafeArea(bottom: false, child: IndexedStack(index: index, children: pages)),
          bottomNavigationBar: _MarketplaceBottomNav(index: index, onTap: _openTab),
        );
      },
    );
  }
}

class _MarketplaceBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _MarketplaceBottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: StockFlowTheme.surface,
        border: Border(top: BorderSide(color: StockFlowTheme.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              Expanded(child: _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home', selected: index == 0, onTap: () => onTap(0))),
              Expanded(child: _NavItem(icon: Icons.handshake_outlined, selectedIcon: Icons.handshake_rounded, label: 'Deals', selected: index == 1, onTap: () => onTap(1))),
              Expanded(child: _NavItem(icon: Icons.add_circle_outline_rounded, selectedIcon: Icons.add_circle_rounded, label: 'Sell', selected: index == 2, onTap: () => onTap(2), emphasized: true)),
              Expanded(child: _NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'My stock', selected: index == 3, onTap: () => onTap(3))),
              Expanded(child: _NavItem(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Account', selected: index == 4, onTap: () => onTap(4))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool emphasized;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emphasized)
              Transform.translate(
                offset: const Offset(0, -7),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? StockFlowTheme.accentStrong : StockFlowTheme.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: StockFlowTheme.surface, width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x281769FF), blurRadius: 13, offset: Offset(0, 5))],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 27),
                ),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 34,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? StockFlowTheme.brandSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(selected ? selectedIcon : icon, size: 21, color: selected ? StockFlowTheme.accent : StockFlowTheme.muted),
              ),
            SizedBox(height: emphasized ? 0 : 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(fontSize: 9.8, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? StockFlowTheme.accentStrong : StockFlowTheme.muted),
            ),
          ],
        ),
      );
}

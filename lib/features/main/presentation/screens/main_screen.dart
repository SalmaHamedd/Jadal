import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/widgets/jadal_bottom_nav_bar.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../blog/presentation/screens/all_blogs_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../live_debate/presentation/pages/debate_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/jadal_app_drawer.dart';

/// Global key so any nested tab screen (each has its own Scaffold) can open
/// the shell's drawer via `mainScaffoldKey.currentState?.openDrawer()` — a
/// plain `Scaffold.of(context).openDrawer()` from inside a tab would only
/// find that tab's own nested Scaffold, not this one (§9).
final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

/// The app shell after login: the shared gradient backdrop with no AppBar (so
/// the wash runs edge-to-edge) and the bottom navigation between the four
/// sections — Home, Debates (backend list with its stage tabs), Blog (§2.5 —
/// replaced Search, which now lives behind the home app-bar icon) and
/// Profile. Also owns the nav drawer (§9); swipe-to-open is restricted to the
/// Home tab so it doesn't fight with gestures on the other tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DebateListScreen(),
    AllBlogsScreen(inShell: true),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return JadalGradientBackground(
      child: Scaffold(
        key: mainScaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: const JadalAppDrawer(),
        drawerEnableOpenDragGesture: _selectedIndex == 0,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
        bottomNavigationBar: JadalBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            JadalNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: loc.navHome,
            ),
            JadalNavItem(
              icon: Icons.forum_outlined,
              activeIcon: Icons.forum,
              label: loc.navDebates,
            ),
            JadalNavItem(
              icon: Icons.article_outlined,
              activeIcon: Icons.article,
              label: loc.navBlog,
            ),
            JadalNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: loc.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

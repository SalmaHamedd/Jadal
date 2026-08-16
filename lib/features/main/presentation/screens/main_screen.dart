import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_cubit/app_cubit.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/widgets/jadal_bottom_nav_bar.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../di/injection_container.dart' as di;
import '../../../blog/presentation/screens/all_blogs_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../live_debate/presentation/pages/debate_list_screen.dart';
import '../../../notifications/data/push_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/jadal_app_drawer.dart';

/// Global key so any nested tab screen (each has its own Scaffold) can open
/// the shell's drawer via `mainScaffoldKey.currentState?.openDrawer` — a
/// plain `Scaffold.of(context).openDrawer` from inside a tab would only
/// find that tab's own nested Scaffold, not this one.
final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

/// The app shell after login: the shared gradient backdrop with no AppBar (so
/// the wash runs edge-to-edge) and the bottom navigation between the four
/// sections — Home, Debates (backend list with its stage tabs), Blog (—
/// replaced Search, which now lives behind the home app-bar icon) and
/// Profile. Also owns the nav drawer; swipe-to-open is restricted to the
/// Home tab so it doesn't fight with gestures on the other tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// Index of the Profile tab in [_MainScreenState._screens].
const int _profileTabIndex = 3;

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DebateListScreen(),
    AllBlogsScreen(inShell: true),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // This is the one place every authenticated entry path converges on:
    // a fresh login AND a restart with a stored token both land here. Doing it
    // in the login flow alone would leave a user who never logs out again
    // permanently unregistered, and would miss FCM token rotation.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPush());
  }

  Future<void> _initPush() async {
    if (!mounted) return;
    final push = di.sl<PushService>();
    await push.registerToken(
      locale: context.read<AppCubit>().state.locale.languageCode,
    );
    // Safe only now: the navigator is mounted, so a tap that cold-started the
    // app can actually push its destination route.
    await push.handleColdStart();
  }

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
          // Profile paints a full-bleed cover that must run behind the status
          // bar, so that tab opts out of the shell's top inset and lets its
          // own AppBar (which applies the inset itself) handle it. Every tab
          // has an AppBar, so none of them lose their status-bar spacing.
          top: _selectedIndex != _profileTabIndex,
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

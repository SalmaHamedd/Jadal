import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../live_debate/presentation/pages/debate_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';

/// The app shell after login: the shared gradient backdrop with no AppBar (so
/// the wash runs edge-to-edge) and the bottom navigation between the four
/// sections — Home, Debates (backend list with its stage tabs), Search and
/// Profile. Theme/locale toggles live in the Profile tab's app bar for now
/// (until a dedicated settings screen exists).
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
    SearchScreen(),
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
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: JadalColors.primaryOrange,
          unselectedItemColor: JadalColors.judgesGrey,
          selectedLabelStyle:
              const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: loc.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.forum_outlined),
              activeIcon: const Icon(Icons.forum),
              label: loc.navDebates,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search),
              label: loc.navSearch,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: loc.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

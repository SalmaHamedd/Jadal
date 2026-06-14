import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/widgets/locale_toggle_button.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/widgets/theme_toggle_button.dart';
import 'package:jadal_app/features/home/presentation/screens/home_screen.dart';
import 'package:jadal_app/features/temp_home/presentation/screens/temp_home_screen.dart';
import 'package:jadal_app/features/search/presentation/screens/search_screen.dart';
import 'package:jadal_app/features/profile/presentation/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TempHomeScreen(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدل', style: TextStyle(fontSize: 20)),
        actions: const [
          LocaleToggleButton(),
          SizedBox(width: 6),
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: JadalColors.primaryOrange,
        unselectedItemColor: JadalColors.judgesGrey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_clock_outlined),
            activeIcon: Icon(Icons.lock_clock),
            label: 'مؤقت',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'بحث',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

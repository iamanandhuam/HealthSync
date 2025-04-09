import 'package:flutter/material.dart';
import 'package:health_sync/chat_with.dart';
import 'package:health_sync/settings.dart';
import 'package:logger/logger.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'display_data_from_sw.dart';
import 'user_input_page.dart';
import 'user_info_page.dart';
import 'style.dart';
import 'goal_dashboard.dart';

var logger = Logger();

void main() {
  runApp(const MyApp());
}

bool hasFetchedHealthDataOnce = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smartwatch Simulator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "HEALTH SYNC",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryPurple,
                fontSize: 35,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(), // Loading indicator
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    SmartWatchDashboard(),
    SettingsPage(),
    GoalDashboardPage(),
    UserInputPage(),
    ChatWithAiPage(),
    UserInfoPage(),
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
        title: const Text(
          "HEALTH SYNC",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryPurple, // Using RGBA for clarity
            fontSize: 25,
          ),
        ),
        //centerTitle: true, // Center the title in the AppBar
        //elevation: 1, // Add a subtle shadow to the AppBar
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: lightGreyShadow,
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: primaryPurple,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.watch_rounded),
                label: 'Wearable',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(
                  FontAwesomeIcons.gear,
                ),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.track_changes),
                label: 'Goals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_rounded, size: 30),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat with AI',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_sharp),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

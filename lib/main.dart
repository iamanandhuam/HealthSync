import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'user_input_page.dart';
import 'landing_page.dart';
import 'loading_indicator.dart';

var logger = Logger();

void main() {
  runApp(const MyApp());
}

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
      initialRoute: '/',
      routes: {
        '/': (context) => const Startingpage(),
        '/landing_page': (context) => const HomePage(),
        '/second': (context) => const SecondPage(),
      },
    );
  }
}

class Startingpage extends StatelessWidget {
  const Startingpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "HEALTH SYNC",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: const Color.fromRGBO(160, 103, 234, 1),
                    fontSize: 30,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: DotsLoading(),
            ),
          ),
        ],
      ),
    );
  }
}

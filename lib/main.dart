import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'budget_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OneHotelApp());
}

class OneHotelApp extends StatelessWidget {
  const OneHotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneHotel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return HomePage(department: args);
        },
        '/budget': (context) => const BudgetPage(),
      },
    );
  }
}
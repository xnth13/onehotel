import 'package:flutter/material.dart';
import 'database_helper.dart'; // Importa tu DatabaseHelper
import 'login_page.dart'; // Importa la página de inicio de sesión
import 'history_page.dart';
import 'budget_page.dart';
import 'home_page.dart';

void main() async {
  // Asegura que los plugins de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la base de datos. Esto creará el archivo de base de datos
  // y las tablas la primera vez que la aplicación se ejecute en el dispositivo.
  await DatabaseHelper.instance.database;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posadas One Silao',
      debugShowCheckedModeBanner: false, // Puedes cambiar esto a true para ver el banner de debug
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Puedes mantener o ajustar tus temas existentes
        colorScheme: ColorScheme.fromSwatch(
           primarySwatch: Colors.blue,
           accentColor: const Color(0xFF003366),
         ),
         appBarTheme: const AppBarTheme(
           backgroundColor: Color(0xFF003366),
           titleTextStyle: TextStyle(
             color: Colors.white,
             fontSize: 20,
             fontWeight: FontWeight.bold,
           ),
           iconTheme: IconThemeData(color: Colors.white),
         ),
      ),
      // Define tus rutas nombradas. Ajusta si son diferentes en tu proyecto.
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(), // La página inicial es el Login
        // Asegúrate de tener las otras páginas definidas aquí si las usas con rutas nombradas
        // '/home': (context) => HomePage(), // Ejemplo: Si HomePage no requiere argumentos
        // '/budget': (context) => BudgetPage(),
        // '/history': (context) => HistoryPage(),
      },
      // Si manejas rutas con argumentos, puedes mantener onGenerateRoute
      onGenerateRoute: (settings) {
         switch (settings.name) {
           case '/home':
             // Ejemplo de cómo pasar argumentos si HomePage los necesita
             final args = settings.arguments as String? ?? 'Usuario'; // Valor por defecto
             return MaterialPageRoute(builder: (context) => HomePage(department: args));
           case '/budget':
             return MaterialPageRoute(builder: (context) => BudgetPage());
           case '/history':
             return MaterialPageRoute(builder: (context) => HistoryPage());
           default:
             // Si la ruta no se encuentra, puedes redirigir o mostrar un error
             return MaterialPageRoute(builder: (context) => LoginPage());
         }
      },
    );
  }
}

// Asegúrate de que las páginas BudgetPage y HistoryPage existan e importarlas
// import 'budget_page.dart';
// import 'history_page.dart';


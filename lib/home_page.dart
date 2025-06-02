import 'package:flutter/material.dart';
import 'database_helper.dart'; // Importa tu DatabaseHelper
// Importa las páginas a las que navegas desde aquí
import 'purchase_form.dart';
import 'history_page.dart';
import 'budget_page.dart'; // Si tienes una página para el presupuesto

class HomePage extends StatefulWidget {
   // Puedes recibir argumentos si los necesitas, como el nombre de usuario/departamento
  final String department;
  const HomePage({Key? key, this.department = 'Usuario'}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _totalExpenses = 0.0;
  double _currentBudget = 0.0; // <-- Agrega esta línea

  @override
  void initState() {
    super.initState();
    _loadTotalExpenses();
    _loadCurrentBudget(); // <-- Agrega esta línea
  }

  // Función para cargar el total de gastos desde la base de datos
  Future<void> _loadTotalExpenses() async {
    try {
      // Obtiene el total de gastos de la tabla 'purchases' usando el DatabaseHelper
      double totalExpenses = await DatabaseHelper.instance.getTotalExpenses();
      setState(() {
        _totalExpenses = totalExpenses; // Actualiza la variable de estado
      });
      await _loadCurrentBudget(); // <-- Así siempre se actualiza el presupuesto al volver
    } catch (e) {
      // Manejo de errores
      print("Error loading total expenses: $e");
      // Opcional: mostrar un mensaje de error al usuario
    }
  }

  Future<void> _loadCurrentBudget() async {
    try {
      double budget = await DatabaseHelper.instance.getBudget();
      setState(() {
        _currentBudget = budget;
      });
    } catch (e) {
      print("Error loading budget: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Control de Gastos - ${widget.department}'), // Muestra el departamento
        // Puedes añadir un botón de "refrescar" para actualizar el total de gastos
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTotalExpenses, // Llama a la función para recargar los gastos
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Presupuesto actual en la parte superior
            Text(
              'Presupuesto Actual: \$${_currentBudget.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 10),
            // Presupuesto restante
            Text(
              'Presupuesto Restante: \$${(_currentBudget - _totalExpenses).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: (_currentBudget - _totalExpenses) < 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Total de Gastos Registrados:',
              style: TextStyle(fontSize: 20),
            ),
            // Muestra el total de gastos obtenidos de la base de datos
            Text(
              '\$${_totalExpenses.toStringAsFixed(2)}', // Formatea el monto a 2 decimales
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF003366)), // Tu color
            ),
            const SizedBox(height: 40),
            // Botones para navegar a otras funcionalidades
            ElevatedButton.icon(
              onPressed: () async {
                // Navega a la página para agregar una nueva compra
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PurchaseFormPage()), // Navega
                );
                // Después de agregar una compra y regresar, refresca el total de gastos
                _loadTotalExpenses();
              },
               icon: const Icon(Icons.add_circle_outline),
              label: const Text('Agregar Nueva Compra'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF003366),
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                 textStyle: const TextStyle(fontSize: 18),
                 foregroundColor: Colors.white, // Color del texto e icono
               ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                 // Navega a la página del historial de compras
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()), // Navega
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Ver Historial de Compras'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF003366),
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                 textStyle: const TextStyle(fontSize: 18),
                 foregroundColor: Colors.white,
               ),
            ),
             const SizedBox(height: 20),
            // Si tienes una página para establecer/ver el presupuesto
            ElevatedButton.icon(
              onPressed: () {
                 // Navega a la página del presupuesto
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetPage()), // Navega
                );
              },
               icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Gestionar Presupuesto'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF003366),
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                 textStyle: const TextStyle(fontSize: 18),
                 foregroundColor: Colors.white,
               ),
            ),
          ],
        ),
      ),
    );
  }
}
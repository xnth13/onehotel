import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart'; // Importa tu DatabaseHelper

class BudgetPage extends StatefulWidget {
   // Puedes recibir argumentos si los necesitas, como el nombre de usuario/departamento
   // Si el presupuesto es por usuario
  final String username; // Ejemplo: si el presupuesto es por usuario
  const BudgetPage({Key? key, this.username = 'Usuario'}) : super(key: key);


  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final TextEditingController _budgetController = TextEditingController();
  double _currentBudget = 0.0; // Para mostrar el presupuesto actual
  double _totalExpenses = 0.0; // Para mostrar el total de gastos
  bool _isLoading = true; // Variable para indicar si los datos se están cargando

  @override
  void initState() {
    super.initState();
    _loadBudgetData(); // Carga el presupuesto y gastos al iniciar
  }

   @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // Carga el presupuesto actual del usuario (si aplica) y el total de gastos
  Future<void> _loadBudgetData() async {
  setState(() { _isLoading = true; });
  try {
    double loadedBudget = await DatabaseHelper.instance.getBudget();
    double totalExpenses = await DatabaseHelper.instance.getTotalExpenses();
    setState(() {
      _currentBudget = loadedBudget;
      _totalExpenses = totalExpenses;
      _isLoading = false;
    });
  } catch (e) {
    print("Error loading budget data: $e");
    setState(() { _isLoading = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al cargar datos del presupuesto.')),
    );
  }
}


  // Guarda el presupuesto en la base de datos
  void _setBudget() async {
    final newBudgetAmount = double.tryParse(_budgetController.text);

    if (newBudgetAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto de presupuesto inválido. Ingresa solo números.')),
      );
      return;
    }

     try {
       await DatabaseHelper.instance.updateBudget(newBudgetAmount);
       setState(() {
         _currentBudget = newBudgetAmount;
         _budgetController.clear();
       });
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Presupuesto guardado con éxito!')),
       );
       _loadBudgetData();
     } catch (e) {
       print("Error saving budget: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el presupuesto.')),
        );
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Presupuesto'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Muestra indicador si está cargando
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Muestra el presupuesto actual y el total de gastos
                   Text(
                     'Presupuesto Actual: \$${_currentBudget.toStringAsFixed(2)}',
                     style: const TextStyle(fontSize: 20),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Gastos Registrados: \$${_totalExpenses.toStringAsFixed(2)}',
                     style: const TextStyle(fontSize: 20),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Presupuesto Restante: \$${(_currentBudget - _totalExpenses).toStringAsFixed(2)}',
                     style: TextStyle(
                       fontSize: 20,
                       fontWeight: FontWeight.bold,
                       color: (_currentBudget - _totalExpenses) < 0 ? Colors.red : Colors.green, // Rojo si se excede, verde si hay saldo
                     ),
                   ),
                  const SizedBox(height: 24),
                  const Text(
                    'Establecer Nuevo Presupuesto:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Campo de texto para ingresar el nuevo presupuesto
                  TextField(
                    controller: _budgetController,
                    decoration: const InputDecoration(labelText: 'Monto del Presupuesto'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true), // Teclado numérico con decimales
                  ),
                  const SizedBox(height: 16),
                  // Botón para guardar el presupuesto
                  ElevatedButton(
                    onPressed: _setBudget, // Llama a la función para guardar el presupuesto
                     style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF003366), // Tu color de fondo
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         textStyle: const TextStyle(fontSize: 18),
                         foregroundColor: Colors.white, // Color del texto
                     ),
                    child: const Text('GUARDAR PRESUPUESTO'),
                  ),
                   const SizedBox(height: 20),
                  // Nota que ya tenías en tu código original
                  const Text(
                    'Nota: Establezca el presupuesto total disponible para todos los departamentos. '
                    'Las compras registrarán descuentos automáticos sobre este monto.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
    );
  }
}

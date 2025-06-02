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
       // **Importante:** Debes implementar un método en DatabaseHelper para obtener el presupuesto del usuario
       // Este es solo un EJEMPLO hipotético. Ajusta según cómo guardes el presupuesto.
       // Si el presupuesto es global y lo guardas en una tabla diferente, la lógica cambiaría.

       // Ejemplo (asumiendo que añadiste un método getBudgetByUsername en DatabaseHelper):
       // Map<String, dynamic>? user = await DatabaseHelper.instance.getUserByUsername(widget.username);
       // double loadedBudget = user?['budget'] ?? 0.0; // Obtiene el presupuesto o 0.0 si es null

       // Por ahora, si no tienes un método para obtener el presupuesto guardado,
       // puedes inicializar _currentBudget a 0.0 o a un valor por defecto.
       // Si el presupuesto es GLOBAL, podrías tener una única entrada en otra tabla.
       // Asumimos que ya tienes una forma de obtener el presupuesto actual (incluso si es 0.0 la primera vez)
       // Para este ejemplo, mantendremos _currentBudget como una variable de estado que se actualiza al guardar.
       // Si tu presupuesto está guardado en DB, la línea de abajo REALMENTE debería cargarlo.
       // Por ahora, la dejaré comentada o la inicializaré:
       // _currentBudget = 0.0; // O carga desde DB si ya implementaste el método


       // Obtiene el total de gastos de la base de datos
       double totalExpenses = await DatabaseHelper.instance.getTotalExpenses();

       setState(() {
         // _currentBudget = loadedBudget; // Descomenta y usa si cargas el presupuesto de DB
         _totalExpenses = totalExpenses;
         _isLoading = false; // Oculta el indicador de carga
       });
     } catch (e) {
        print("Error loading budget data: $e");
        setState(() { _isLoading = false; }); // Oculta incluso si hay error
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
       // **Importante:** Debes implementar un método en DatabaseHelper para actualizar el presupuesto.
       // Este es solo un EJEMPLO hipotético. Ajusta según cómo guardes el presupuesto.
       // Si el presupuesto es por usuario, necesitarías el username.
       // Si es global, la lógica sería diferente.

       // Ejemplo (asumiendo que añadiste un método updateBudget en DatabaseHelper):
       // int rowsAffected = await DatabaseHelper.instance.updateBudget(newBudgetAmount, widget.username); // Si es por usuario
       // int rowsAffected = await DatabaseHelper.instance.updateGlobalBudget(newBudgetAmount); // Si es global

       // Para este ejemplo, simplemente actualizaremos la variable de estado y asumiremos
       // que tienes o añadirás la lógica de base de datos para guardar.
       // Si la base de datos falla, el estado visual no coincidirá.
       // DEBES AÑADIR LA LÓGICA DE BASE DE DATOS AQUÍ.

       setState(() {
         _currentBudget = newBudgetAmount; // Actualiza la variable de estado (si la guardas aquí)
         _budgetController.clear(); // Limpia el campo de texto
       });

       // **Aquí es donde deberías llamar al método de tu DatabaseHelper para guardar el nuevo presupuesto.**
       // Ejemplo:
       // await DatabaseHelper.instance.updateBudget(newBudgetAmount); // Llama a tu método de guardado

       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Presupuesto guardado con éxito!')),
       );

       // Opcional: Recarga los datos para asegurarte de que todo está sincronizado
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


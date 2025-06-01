import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final TextEditingController _budgetController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }

  Future<void> _loadCurrentBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final currentBudget = prefs.getDouble('initial_budget') ?? 0.0;
    _budgetController.text = currentBudget > 0 ? currentBudget.toStringAsFixed(2) : '';
  }

  Future<void> _setBudget() async {
    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un monto válido')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    
    if (budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a cero')),
      );
      setState(() => _isLoading = false);
      return;
    }
    
    await prefs.setDouble('initial_budget', budget);
    await prefs.setDouble('current_budget', budget);
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presupuesto actualizado correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Establecer Presupuesto'),
        backgroundColor: const Color(0xFF003366),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Presupuesto Inicial',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      hintText: 'Ej: 10000.00',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _setBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('GUARDAR PRESUPUESTO'),
                  ),
                  const SizedBox(height: 20),
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
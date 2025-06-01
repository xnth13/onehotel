import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'purchase_form.dart';
import 'budget_page.dart';

class HomePage extends StatefulWidget {
  final String department;

  const HomePage({super.key, required this.department});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;
  double _totalSpent = 0.0;

  bool _canViewAnalytics() {
    return widget.department == 'Gerente' || widget.department == 'Sistemas';
  }

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final purchasesJson = prefs.getStringList('purchases') ?? [];
    
    setState(() {
      _purchases = purchasesJson.map((json) {
        final parts = json.split('|');
        return {
          'department': parts[0],
          'establishment': parts[1],
          'date': DateTime.parse(parts[2]),
          'total': double.parse(parts[3]),
          'description': parts[4],
          'timestamp': DateTime.parse(parts[5]),
        };
      }).toList();
      
      _totalSpent = _purchases.fold(0.0, (sum, purchase) => sum + (purchase['total'] as double));
      _isLoading = false;
    });
  }

  Future<double> _getCurrentBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('current_budget') ?? 0.0;
  }

  Future<double> _getInitialBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('initial_budget') ?? 0.0;
  }

Widget _buildBudgetInfo() {
  return FutureBuilder(
    future: _getInitialBudget(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox();
      }
      
      final initialBudget = snapshot.data ?? 0.0;
      
      return FutureBuilder(
        future: _getCurrentBudget(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox();
          }
          
          final currentBudget = snapshot.data ?? 0.0;
          final percentage = initialBudget > 0 
              ? (currentBudget / initialBudget * 100).clamp(0, 100)
              : 0.0;
          
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PRESUPUESTO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      if (widget.department == 'Gerente')
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => Navigator.pushNamed(context, '/budget')
                              .then((_) => setState(() {})),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (initialBudget > 0) ...[
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      color: percentage > 20 
                          ? Colors.green 
                          : percentage > 10 
                              ? Colors.orange 
                              : Colors.red,
                      minHeight: 10,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Disponible: \$${currentBudget.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Inicial: \$${initialBudget.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (initialBudget <= 0 && widget.department == 'Gerente') ...[
                    const SizedBox(height: 10),
                    const Text(
                      'No hay presupuesto configurado',
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/budget')
                          .then((_) => setState(() {})),
                      child: const Text('CONFIGURAR PRESUPUESTO INICIAL'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Map<String, double> _getDepartmentSpending() {
    final Map<String, double> spending = {};
    
    for (final purchase in _purchases) {
      final dept = purchase['department'];
      final amount = purchase['total'] as double;
      
      spending.update(dept, (value) => value + amount, ifAbsent: () => amount);
    }
    
    return spending;
  }

  List<PieChartSectionData> _getPieChartSections() {
    final spending = _getDepartmentSpending();
    if (spending.isEmpty) return [];
    
    final total = spending.values.fold(0.0, (sum, amount) => sum + amount);
    
    return spending.entries.map((entry) {
      final percentage = (entry.value / total * 100).round();
      final color = _getDepartmentColor(entry.key);
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getDepartmentColor(String department) {
    final colors = {
      'Controlaría': const Color(0xFF4285F4),
      'Ama de Llaves': const Color(0xFF34A853),
      'Sistemas': const Color(0xFFFBBC05),
      'Gerente': const Color(0xFFEA4335),
    };
    
    return colors[department] ?? Colors.grey;
  }

  Widget _buildSpendingChart() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_purchases.isEmpty) {
      return const Center(
        child: Text(
          'No hay compras registradas\n\nPresiona el botón + para agregar una',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: _getPieChartSections(),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Total gastado: \$${_totalSpent.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    if (!_canViewAnalytics()) return const SizedBox();
    
    final spending = _getDepartmentSpending();
    if (spending.isEmpty) return const SizedBox();
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Desglose por departamento:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...spending.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getDepartmentColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key),
                    ),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPurchases() {
    if (!_canViewAnalytics()) return const SizedBox();
    if (_purchases.isEmpty) return const SizedBox();
    
    final recentPurchases = _purchases
      ..sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Últimas compras:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recentPurchases.take(3).map((purchase) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          purchase['establishment'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '\$${purchase['total'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      '${purchase['date'].day}/${purchase['date'].month}/${purchase['date'].year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POSADAS ONE SILAO'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAppInfo(context),
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildBudgetInfo(),
          if (_canViewAnalytics()) ...[
            const Text(
              'Distribución de Gastos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            _buildSpendingChart(),
            _buildLegend(),
            _buildRecentPurchases(),
            const SizedBox(height: 20),
          ] else ...[
            const Center(
              child: Text(
                'Modo de registro de compras\n\nSolo el Gerente y Sistemas pueden ver los reportes',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
          ],
          
          _buildButtonSection(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Bienvenido/a, ${widget.department}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _canViewAnalytics() 
                  ? 'Acceso completo a reportes' 
                  : 'Modo registro de compras',
              style: const TextStyle(
                fontSize: 16, 
                color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonSection(BuildContext context) {
    return Column(
      children: [
        _buildFeatureButton(
          context,
          icon: Icons.add_shopping_cart,
          label: 'Registrar Nueva Compra',
          onPressed: () => _navigateToPurchaseForm(context),
        ),
        if (_canViewAnalytics()) ...[
          const SizedBox(height: 15),
          _buildFeatureButton(
            context,
            icon: Icons.history,
            label: 'Historial Completo',
            onPressed: () => _showHistoryMessage(context),
          ),
        ],
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToPurchaseForm(context),
      backgroundColor: const Color(0xFF003366),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF003366),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF003366)),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToPurchaseForm(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseForm(department: widget.department),
      ),
    );
    
    if (result == true) {
      await _loadPurchases();
    }
  }

  void _showHistoryMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial en desarrollo')),
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de la App'),
        content: const Text(
          'POSADAS ONE SILAO\n\n'
          'Sistema de Control de Gastos\n'
          'Versión 1.0.0\n\n'
          'Registre las compras realizadas por cada departamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
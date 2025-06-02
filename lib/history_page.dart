import 'package:flutter/material.dart';
import 'database_helper.dart'; // Importa tu DatabaseHelper
import 'dart:io'; // Necesario para usar File'; 


class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key); // Añade constructor si es necesario

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _purchases = []; // Lista para almacenar las compras de la base de datos
  bool _isLoading = true; // Variable para indicar si los datos se están cargando

  @override
  void initState() {
    super.initState();
    _loadPurchases(); // Llama a la función para cargar las compras al iniciar la página
  }

  // Función para cargar las compras desde la base de datos
  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true; // Muestra el indicador de carga
    });
    try {
      // Obtiene la lista de compras desde la base de datos, ordenadas por fecha descendente (las más recientes primero)
      List<Map<String, dynamic>> purchases = await DatabaseHelper.instance.getPurchases();
      setState(() {
        _purchases = purchases; // Actualiza la lista de compras en el estado
        _isLoading = false; // Oculta el indicador de carga
      });
    } catch (e) {
      // Manejo de errores al cargar los datos de la base de datos
      print("Error loading purchases: $e");
      setState(() {
        _isLoading = false; // Oculta el indicador de carga incluso si hay error
      });
      // Muestra un mensaje de error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el historial de compras')),
      );
    }
  }

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Compras'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Muestra un indicador de carga mientras carga
          : _purchases.isEmpty
              ? const Center(child: Text('No hay compras registradas.')) // Mensaje si la lista está vacía
              : ListView.builder(
                  itemCount: _purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = _purchases[index]; // Obtiene el mapa de datos de la compra

                    return Card( // Usamos un Card para cada compra para una mejor presentación
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 2.0, // Sombra suave
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Muestra la descripción de la compra
                            Text(
                              purchase['description'] ?? 'Sin descripción', // Usa 'Sin descripción' si es null
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            // Muestra el monto de la compra, formateado a 2 decimales
                            Text(
                              'Monto: \$${purchase['amount']?.toStringAsFixed(2) ?? '0.00'}', // Usa '0.00' si es null
                            ),
                            const SizedBox(height: 4),
                             // Muestra la fecha de la compra, formateada si usas intl
                             Text('Fecha: ${purchase['date'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            // --- Lógica para mostrar la imagen del ticket ---
                            // Verifica si hay una ruta de imagen guardada
                            if (purchase['imagePath'] != null && purchase['imagePath'].isNotEmpty)
                              Container(
                                height: 150, // Altura fija para la imagen mostrada
                                width: double.infinity, // Ancho máximo
                                decoration: BoxDecoration( // Opcional: Borde redondeado para la imagen
                                   borderRadius: BorderRadius.circular(8.0),
                                   border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect( // Recorta la imagen para que tenga bordes redondeados
                                   borderRadius: BorderRadius.circular(8.0),
                                   child: Image.file(
                                     File(purchase['imagePath']), // Crea un objeto File desde la ruta guardada
                                     fit: BoxFit.cover, // Ajusta la imagen para cubrir el espacio
                                     // Builder para manejar errores de carga de imagen (ej: si el archivo fue eliminado)
                                     errorBuilder: (context, error, stackTrace) {
                                        print("Error al cargar la imagen en historial: ${purchase['imagePath']} - $error");
                                        return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)); // Muestra un ícono si falla
                                      },
                                   ),
                                ),
                              ),
                            // --- Fin de la lógica de la imagen ---
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

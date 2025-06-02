import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart'; // Importa tu DatabaseHelper
import 'dart:io'; // Necesario para usar el tipo File

class PurchaseFormPage extends StatefulWidget {
  const PurchaseFormPage({Key? key}) : super(key: key); // Añade constructor si es necesario

  @override
  _PurchaseFormPageState createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends State<PurchaseFormPage> {
  // Controladores para los campos de texto
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Variable para almacenar el archivo de la imagen seleccionada/tomada
  File? _imageFile;

  @override
  void dispose() {
    // Limpia los controladores cuando el widget se destruye
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Función para tomar una foto con la cámara
  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Guarda el archivo de la imagen
      });
    }
  }

  // Función para seleccionar una imagen de la galería
  Future<void> _selectPicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Guarda el archivo de la imagen
      });
    }
  }

  // Función para guardar la compra en la base de datos
  void _savePurchase() async {
    // Valida que los campos obligatorios no estén vacíos
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa la descripción y el monto')),
      );
      return;
    }

    final description = _descriptionController.text;
    final amount = double.tryParse(_amountController.text); // Intenta parsear el monto a double

    if (amount == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto inválido. Ingresa solo números.')),
      );
      return;
    }

    try {
       // Crea un mapa con los datos de la compra para insertarlos en la base de datos
      Map<String, dynamic> newPurchase = {
        'description': description,
        'amount': amount,
        'date': DateTime.now().toIso8601String(), // Guarda la fecha y hora actual en formato string ISO 8601
        'imagePath': _imageFile?.path ?? '', // Guarda la ruta del archivo de imagen, o una cadena vacía si no se seleccionó ninguna foto
      };

      // Inserta la compra en la base de datos utilizando el DatabaseHelper
      int result = await DatabaseHelper.instance.insertPurchase(newPurchase);

      if (result > 0) {
        // Si la inserción fue exitosa (sqflite devuelve el ID del nuevo registro, que es > 0)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra guardada con éxito!')),
        );
        // Limpia los campos después de guardar
        _descriptionController.clear();
        _amountController.clear();
        setState(() {
           _imageFile = null; // Limpia la imagen seleccionada
        });

        // Puedes opcionalmente cerrar esta página o navegar a otra después de guardar
        // Navigator.pop(context);
      } else {
        // Si hubo un error y la inserción no fue exitosa
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la compra')),
        );
      }
    } catch (e) {
      // Manejo de errores generales durante el proceso de guardado
      print("Error al guardar la compra en la base de datos: $e");
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Error al guardar la compra.')),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Compra'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Campo de texto para la descripción
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            // Campo de texto para el monto
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Monto'),
              keyboardType: TextInputType.numberWithOptions(decimal: true), // Teclado numérico con opción de decimal
            ),
            const SizedBox(height: 20),
            // Botones para tomar o seleccionar foto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon( // Usamos ElevatedButton.icon para un ícono y texto
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera_alt), // Ícono de cámara
                  label: const Text('Tomar Foto'),
                ),
                 ElevatedButton.icon(
                  onPressed: _selectPicture,
                  icon: const Icon(Icons.photo_library), // Ícono de galería
                  label: const Text('Seleccionar Foto'),
                ),
              ],
            ),
             const SizedBox(height: 16),
             // Muestra la imagen seleccionada/tomada si existe
             if (_imageFile != null)
               Image.file(
                 _imageFile!, // Usa el archivo de imagen
                 height: 150, // Altura fija para la imagen mostrada
                 fit: BoxFit.cover, // Ajusta la imagen para cubrir el espacio
                 errorBuilder: (context, error, stackTrace) {
                   // Manejo básico de error si la imagen no se puede cargar
                   return const Center(child: Text('Error al cargar la imagen'));
                 },
               ),
            const SizedBox(height: 24),
            // Botón para guardar la compra
            ElevatedButton(
              onPressed: _savePurchase, // Llama a la función para guardar en la base de datos
              style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF003366), // Tu color de fondo
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 minimumSize: const Size(double.infinity, 50) // Ancho completo
              ),
              child: const Text(
                'Guardar Compra',
                style: TextStyle(fontSize: 16, color: Colors.white), // Color del texto
              ),
            ),
          ],
        ),
      ),
    );
  }
}
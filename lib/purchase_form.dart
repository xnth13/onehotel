import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class PurchaseForm extends StatefulWidget {
  final String department;
  
  const PurchaseForm({super.key, required this.department});

  @override
  State<PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _establishmentController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _ticketImage;
  DateTime _purchaseDate = DateTime.now();
  bool _isLoading = false;
  bool _isCameraAvailable = true;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _ticketImage = File(pickedFile.path);
          _isCameraAvailable = true;
        });
      }
    } catch (e) {
      setState(() => _isCameraAvailable = false);
      _showError('Error al acceder a la cámara: ${e.toString()}');
    }
  }

  Future<bool> _updateBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBudget = prefs.getDouble('current_budget') ?? 0.0;
    
    if (currentBudget < amount) {
      _showError('❌ Presupuesto insuficiente');
      return false;
    }
    
    await prefs.setDouble('current_budget', currentBudget - amount);
    return true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003366),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _purchaseDate) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ticketImage == null) {
      _showError('Por favor, capture una imagen del ticket');
      return;
    }

    final amount = double.tryParse(_totalController.text) ?? 0.0;
    final budgetUpdated = await _updateBudget(amount);
    if (!budgetUpdated) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPurchases = prefs.getStringList('purchases') ?? [];
      
      final purchaseString = 
        '${widget.department}|'
        '${_establishmentController.text.trim()}|'
        '${_purchaseDate.toString()}|'
        '${_totalController.text}|'
        '${_descriptionController.text.trim()}|'
        '${DateTime.now().toString()}';
      
      currentPurchases.add(purchaseString);
      await prefs.setStringList('purchases', currentPurchases);

      _showSuccess('✅ Compra registrada exitosamente');
      await Future.delayed(const Duration(seconds: 1));
      _resetForm();
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('❌ Error al guardar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _establishmentController.clear();
    _totalController.clear();
    _descriptionController.clear();
    setState(() {
      _ticketImage = null;
      _purchaseDate = DateTime.now();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
     ) );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _establishmentController.dispose();
    _totalController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Compra'),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading 
          ? _buildLoadingIndicator()
          : _buildFormContent(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003366)),
          ),
          const SizedBox(height: 20),
          Text(
            'Guardando compra de ${widget.department}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Departamento: ${widget.department}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildEstablishmentField(),
            const SizedBox(height: 20),
            _buildDateField(context),
            const SizedBox(height: 20),
            _buildTotalField(),
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 20),
            _buildScanSection(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEstablishmentField() {
    return TextFormField(
      controller: _establishmentController,
      decoration: InputDecoration(
        labelText: 'Establecimiento',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.store, color: Color(0xFF003366)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value?.trim().isEmpty ?? true 
          ? 'Ingrese el nombre del establecimiento' 
          : null,
    );
  }

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de compra',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF003366)),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF003366)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalField() {
    return TextFormField(
      controller: _totalController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Total de compra',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF003366)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Ingrese el total';
        final amount = double.tryParse(value!);
        if (amount == null) return 'Formato inválido';
        if (amount <= 0) return 'El monto debe ser mayor a 0';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Descripción (opcional)',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.description, color: Color(0xFF003366)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: 3,
    );
  }

  Widget _buildScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScanButton(),
        const SizedBox(height: 15),
        _buildTicketPreview(),
        if (!_isCameraAvailable)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Cámara no disponible. Verifique los permisos.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildScanButton() {
    return OutlinedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.camera_alt, color: Color(0xFF003366)),
      label: const Text(
        'Capturar Ticket',
        style: TextStyle(color: Color(0xFF003366)),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        side: const BorderSide(color: Color(0xFF003366)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTicketPreview() {
    return _ticketImage == null
        ? _buildEmptyTicketPlaceholder()
        : _buildTicketImage();
  }

  Widget _buildEmptyTicketPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Imagen del ticket requerida',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ticket capturado:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _ticketImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.red[600],
              child: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                onPressed: () => setState(() => _ticketImage = null),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003366),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'GUARDAR COMPRA',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
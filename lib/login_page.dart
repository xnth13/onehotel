import 'package:flutter/material.dart';
// Asegúrate de importar tu DatabaseHelper y la página a la que navegas después del login
import 'database_helper.dart';
import 'home_page.dart'; // Asegúrate que este es el nombre de tu archivo de HomePage

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key); // Añade constructor si es necesario

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para los campos de texto
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variable para controlar el estado de carga del botón
  bool _isLoading = false;

  @override
  void dispose() {
    // Limpia los controladores cuando el widget se destruye
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método para manejar el inicio de sesión
  void _login() async {
    // Valida que los campos no estén vacíos
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa usuario y contraseña')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Muestra el indicador de carga
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      // Obtiene el usuario de la base de datos por nombre de usuario
      Map<String, dynamic>? user = await DatabaseHelper.instance.getUserByUsername(username);

      setState(() {
        _isLoading = false; // Oculta el indicador de carga
      });

      // Verifica si se encontró un usuario y si la contraseña coincide
      // **Importante:** Esta comparación de contraseña en texto plano es insegura.
      // En una aplicación real, DEBES usar hashing de contraseñas.
      if (user != null && user['password'] == password) {
        // Credenciales correctas, navega a la página principal
        // Puedes pasar argumentos si tu HomePage los necesita, como el nombre de usuario o departamento
        Navigator.pushReplacementNamed(context, '/home', arguments: username); // Ejemplo con ruta nombrada y argumento
        // O si usas MaterialPageRoute:
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(department: username))); // Ajusta el argumento
      } else {
        // Credenciales incorrectas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos')),
        );
      }
    } catch (e) {
      // Manejo de errores al interactuar con la base de datos
      print("Error durante el inicio de sesión: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error. Inténtalo de nuevo.')),
      );
    }
  }

  // Método para registrar un nuevo usuario (Opcional, si tu app tiene registro)
  // **Advertencia:** Este es solo un ejemplo básico. La seguridad es crítica aquí.
   void _registerUser() async {
      final username = _usernameController.text;
      final password = _passwordController.text;

       if (username.isEmpty || password.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Por favor, ingresa usuario y contraseña para registrar.')),
         );
         return;
       }

       setState(() {
         _isLoading = true;
       });

       try {
         // Intenta insertar el nuevo usuario en la base de datos
         // conflictAlgorithm: ConflictAlgorithm.ignore evita errores si el username ya existe
         int result = await DatabaseHelper.instance.insertUser({
           'username': username,
           'password': password, // **PELIGROSO: No guardes contraseñas en texto plano en producción**
         });

         setState(() {
            _isLoading = false;
         });

         if (result != -1) { // Si el resultado no es -1, la inserción fue exitosa (o se ignoró por duplicado)
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Usuario registrado con éxito!')),
           );
            // Limpiar campos después de registrar
            _usernameController.clear();
            _passwordController.clear();
         } else {
            // Esto podría ocurrir si el nombre de usuario ya existe
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El nombre de usuario ya existe o hubo un error al registrar.')),
            );
         }
       } catch (e) {
         print("Error al registrar usuario: $e");
          setState(() {
             _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al registrar usuario.')),
          );
       }
   }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Puedes mantener tu AppBar si tienes una en el login
      // appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Puedes incluir aquí tu logo y textos si los tienes
              // Ejemplo basado en el contexto que me diste:
              // Image.asset('assets/images/Logo_posadas.png', width: 100),
              // const SizedBox(height: 10),
              // const Text('Posadas one silao', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              // const SizedBox(height: 5),
              // const Text('Control de Gastos', style: TextStyle(fontSize: 16, color: Colors.white70)),
              // const SizedBox(height: 30),

              Card( // Envuelve el formulario en un Card si lo deseas
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Contraseña'),
                        obscureText: true, // Para ocultar la contraseña
                      ),
                      const SizedBox(height: 24),
                      // Muestra el indicador de carga o el botón de login
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login, // Llama al método de login
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003366), // Tu color de fondo
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 50) // Ancho completo
                              ),
                              child: const Text(
                                'Iniciar Sesión',
                                style: TextStyle(fontSize: 16, color: Colors.white), // Color del texto
                              ),
                            ),
                       // Si tienes un botón de registro, aquí iría
                       // const SizedBox(height: 16),
                       // TextButton(
                       //   onPressed: _registerUser, // Llama al método de registro
                       //   child: const Text('Registrarse'),
                       // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
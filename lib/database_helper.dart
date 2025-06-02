import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async'; // Necesario para Future

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  // Este getter asíncrono inicializa la base de datos si no existe
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Método para inicializar (abrir o crear) la base de datos
  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath(); // Obtiene la ruta estándar para bases de datos
    String path = join(databasesPath, 'posadas_one.db'); // Nombre del archivo de la base de datos

    return await openDatabase(
      path,
      version: 1, // Versión de la base de datos
      onCreate: _onCreate, // Se llama la primera vez que se crea la base de datos
      onUpgrade: _onUpgrade, // Se llama cuando se actualiza la versión
    );
  }

  // Este método se ejecuta solo cuando la base de datos se crea por primera vez
  Future<void> _onCreate(Database db, int version) async {
    print("Creando tablas en la base de datos...");

    // Crea la tabla de usuarios
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');

    // Crea la tabla de compras
    await db.execute('''
      CREATE TABLE purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        amount REAL,
        date TEXT,
        imagePath TEXT
      )
    ''');

    // Crea la tabla de presupuesto
    await db.execute('''
      CREATE TABLE budget(
        id INTEGER PRIMARY KEY,
        amount REAL
      )
    ''');
    await db.insert('budget', {'id': 1, 'amount': 0.0});

    // --- Inserta tus usuarios predefinidos de departamento en la tabla 'users' ---
    print("Insertando usuarios de departamento predefinidos...");

    // Define tus usuarios de departamento como un mapa (igual que antes)
    final Map<String, String> departmentPasswords = {
      'Controlaría': 'control123',
      'Ama de Llaves': 'ama456',
      'Sistemas': 'sistemas789',
      'Gerente': 'gerente012',
    };

    // Itera sobre el mapa e inserta cada usuario en la tabla 'users'
    for (var entry in departmentPasswords.entries) {
      await db.insert(
        'users', // Nombre de la tabla
        {
          'username': entry.key,     // El nombre del departamento es el username
          'password': entry.value,   // La contraseña asociada
        },
        // conflictAlgorithm: ConflictAlgorithm.ignore evita duplicados por username UNIQUE
        // Aunque en _onCreate la tabla está vacía, es una buena práctica general
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      print("Usuario '${entry.key}' insertado.");
    }
    // --- Fin de la inserción de usuarios predefinidos ---

     print("Tablas creadas y usuarios iniciales insertados.");
  }

  // Este método se ejecuta cuando la versión de la base de datos cambia
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí manejarías las migraciones de la base de datos si cambias la estructura
    print("Actualizando base de datos de la versión $oldVersion a $newVersion...");
    // Ejemplo básico: si pasas de v1 a v2 y quieres añadir una columna
    // if (oldVersion < 2) {
    //   await db.execute("ALTER TABLE purchases ADD COLUMN category TEXT;");
    // }
  }

  // --- Métodos CRUD (Create, Read, Update, Delete) para las tablas ---

  // Insertar un nuevo usuario
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await instance.database;
    // conflictAlgorithm: ConflictAlgorithm.ignore evita duplicados por username UNIQUE
    return await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Obtener todos los usuariosAaA
  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await instance.database;
    return await db.query('users');
  }

   // Obtener un usuario por nombre de usuario (para el login)
   // Este es el método que se usa en login_page.dart
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ?', // Cláusula WHERE para filtrar por username
      whereArgs: [username], // Argumentos para la cláusula WHERE
      limit: 1, // Solo necesitamos el primer resultado si hay múltiples (aunque username es UNIQUE)
    );
    if (results.isNotEmpty) {
      return results.first; // Retorna el primer usuario encontrado (debería ser único)
    }
    return null; // Retorna null si no se encontró el usuario
  }


  // Insertar una nueva compra
  Future<int> insertPurchase(Map<String, dynamic> purchase) async {
    Database db = await instance.database;
    return await db.insert('purchases', purchase);
  }

  // Obtener todas las compras ordenadas por fecha descendente
  Future<List<Map<String, dynamic>>> getPurchases() async {
    Database db = await instance.database;
    return await db.query('purchases', orderBy: 'date DESC');
  }

  // Obtener el total de los montos de las compras
  Future<double> getTotalExpenses() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT SUM(amount) FROM purchases');
    double total = result.first['SUM(amount)'] ?? 0.0;
    return total;
  }

  // Obtener el presupuesto global
  Future<double> getBudget() async {
    await ensureBudgetRowExists();
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('budget', where: 'id = ?', whereArgs: [1]);
    if (result.isNotEmpty) {
      return result.first['amount'] ?? 0.0;
    }
    return 0.0;
  }

  // Actualizar el presupuesto global
  Future<int> updateBudget(double amount) async {
    await ensureBudgetRowExists();
    Database db = await instance.database;
    return await db.update('budget', {'amount': amount}, where: 'id = ?', whereArgs: [1]);
  }

  // Asegurarse de que la fila del presupuesto existe
  Future<void> ensureBudgetRowExists() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('budget', where: 'id = ?', whereArgs: [1]);
    if (result.isEmpty) {
      await db.insert('budget', {'id': 1, 'amount': 0.0});
    }
  }

  // Puedes añadir más métodos según necesites:
  // Future<int> deletePurchase(int id) async { ... }
  // Future<int> updateUser(Map<String, dynamic> user) async { ... }
  // Future<int> updateBudget(double budget, String username) async { ... } // Ejemplo para actualizar presupuesto por usuario
}
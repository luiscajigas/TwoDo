# 📝 Two Do — Flutter + Supabase

App de gestión de tareas con Clean Architecture, Supabase como backend y soporte para adjuntar archivos.

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart
├── core/
│   └── supabase_client.dart
├── data/
│   ├── models/
│   │   └── task_model.dart
│   └── repositories/
│       └── task_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── task.dart
│   ├── repositories/
│   │   └── task_repository.dart
│   └── usecases/
│       ├── get_tasks.dart
│       ├── add_task.dart
│       └── toggle_task.dart
└── presentation/
    ├── providers/
    │   └── task_provider.dart
    └── screens/
        ├── main_screen.dart
        ├── home_screen.dart
        ├── add_task_screen.dart
        ├── saved_tasks_screen.dart
        └── stats_screen.dart
```

---

## ⚙️ Dependencias — `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^8.0.2
  supabase_flutter: ^2.12.0
  flutter_dotenv: ^5.1.0
  provider: ^6.1.2
  file_picker: ^8.1.7

flutter:
  uses-material-design: true
  assets:
    - .env
```

Luego ejecuta:

```bash
flutter pub get
```

---

## 🗄️ SQL — Supabase SQL Editor

Pega y ejecuta esto en **Supabase → SQL Editor**:

```sql
-- Tabla de tareas
CREATE TABLE tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  scheduled_time TEXT,
  category TEXT DEFAULT 'General',
  is_completed BOOLEAN DEFAULT FALSE,
  task_date DATE DEFAULT CURRENT_DATE,
  file_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar las 4 tareas iniciales
INSERT INTO tasks (title, scheduled_time, category, is_completed, task_date) VALUES
  ('Morning Workout', '8 A.M',  'Healthy',   false, CURRENT_DATE),
  ('Reading Book',    '10 A.M', 'Education', false, CURRENT_DATE),
  ('Job Tasks',       '11 A.M', 'Job',       false, CURRENT_DATE),
  ('Eating Breakfast','6 A.M',  'Healthy',   true,  CURRENT_DATE);

-- RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON tasks FOR ALL USING (true) WITH CHECK (true);

-- Bucket para archivos adjuntos
INSERT INTO storage.buckets (id, name, public)
VALUES ('task-files', 'task-files', true);

CREATE POLICY "Allow upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'task-files');

CREATE POLICY "Allow read" ON storage.objects
  FOR SELECT USING (bucket_id = 'task-files');
```

---

## 🔐 Variables de entorno — `.env`

Crea el archivo `.env` en la **raíz del proyecto** (junto a `pubspec.yaml`):

```
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_ANON_KEY
```

> Encuentra estos valores en Supabase → **Project Settings → API**.

---

## 📄 Archivos — dónde copiar cada uno

| Archivo | Ruta |
|---|---|
| `.env` | raíz del proyecto |
| `main.dart` | `lib/` |
| `task.dart` | `lib/domain/entities/` |
| `task_repository.dart` | `lib/domain/repositories/` |
| `get_tasks.dart` | `lib/domain/usecases/` |
| `add_task.dart` | `lib/domain/usecases/` |
| `toggle_task.dart` | `lib/domain/usecases/` |
| `task_model.dart` | `lib/data/models/` |
| `task_repository_impl.dart` | `lib/data/repositories/` |
| `task_provider.dart` | `lib/presentation/providers/` |
| `main_screen.dart` | `lib/presentation/screens/` |
| `home_screen.dart` | `lib/presentation/screens/` |
| `add_task_screen.dart` | `lib/presentation/screens/` |
| `saved_tasks_screen.dart` | `lib/presentation/screens/` |
| `stats_screen.dart` | `lib/presentation/screens/` |

---

## 📱 Pantallas

| Ícono | Pantalla | Descripción |
|---|---|---|
| 🏠 | `home_screen.dart` | Tareas de hoy, progreso circular, barra de progreso |
| ✅ | `saved_tasks_screen.dart` | Todas las tareas guardadas con estado |
| 📊 | `stats_screen.dart` | Estadísticas por categoría y completadas |
| ➕ | `add_task_screen.dart` | Agregar tarea con título, descripción, fecha, categoría y archivo adjunto |

---

## 📎 Adjuntar archivos (File Picker)

El picker soporta cualquier tipo de archivo (PDF, imágenes, docs, etc.).

- En **móvil/desktop**: muestra thumbnail real si es imagen.
- En **web**: muestra ícono del tipo de archivo (Flutter Web no soporta `File.path`).
- El archivo se sube a **Supabase Storage** → bucket `task-files`.
- La URL pública se guarda en la columna `file_url` de la tabla `tasks`.

### ⚠️ Fix para Flutter Web — `path is unavailable`

En Flutter Web, `File.path` no existe y lanza excepción. La solución es usar `withData: true` y trabajar con `bytes`:

**`add_task_screen.dart` — método `_pickFile()`:**

```dart
Future<void> _pickFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
      withData: true,        // obligatorio en web
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;

    // En web path no existe — file queda null pero nombre y size sí llegan
    File? file;
    if (picked.path != null && picked.path!.isNotEmpty) {
      final f = File(picked.path!);
      if (await f.exists()) file = f;
    }

    setState(() {
      _selectedFile = file;           // null en web, File en móvil/desktop
      _selectedFileName = picked.name;
      _selectedFileSize = picked.size; // siempre disponible
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }
}
```

**`task_repository_impl.dart` — método `uploadFile()`:**

```dart
Future<String?> uploadFile(File file) async {
  final fileName =
      '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
  final bytes = await file.readAsBytes(); // usa bytes, compatible con web
  await _client.storage
      .from('task-files')
      .uploadBinary(fileName, bytes);     // uploadBinary en vez de upload
  return _client.storage.from('task-files').getPublicUrl(fileName);
}
```

---

## 🌐 Fix completo para Flutter Web puro (sin `File`)

Si usas **solo Flutter Web** y nunca habrá path disponible, reemplaza las variables de estado en `add_task_screen.dart`:

```dart
// Cambiar esto:
File? _selectedFile;
String? _selectedFileName;
int? _selectedFileSize;

// Por esto:
Uint8List? _selectedBytes;   // bytes directos del picker
String? _selectedFileName;
int? _selectedFileSize;
```

Y en `_pickFile()`:

```dart
setState(() {
  _selectedBytes = picked.bytes;       // bytes directo, sin File
  _selectedFileName = picked.name;
  _selectedFileSize = picked.size;
});
```

Agrega en `task_repository_impl.dart`:

```dart
Future<String?> uploadBytes(Uint8List bytes, String fileName) async {
  final name = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
  await _client.storage.from('task-files').uploadBinary(name, bytes);
  return _client.storage.from('task-files').getPublicUrl(name);
}
```

---

## 🔍 Ver archivos subidos en Supabase

1. Abre [supabase.com](https://supabase.com) → tu proyecto
2. Menú izquierdo → **Storage**
3. Abre el bucket **`task-files`**
4. Verás todos los archivos subidos con nombre y fecha
5. Click en cualquier archivo → **"Get URL"** para el enlace público

La URL también está en: **Table Editor → tabla `tasks` → columna `file_url`**

---

## 🚀 Correr el proyecto

```bash
# Instalar dependencias
flutter pub get

# Web
flutter run -d chrome

# Android
flutter run -d android

# Windows
flutter run -d windows
```

---

## 🐛 Errores comunes

| Error | Causa | Solución |
|---|---|---|
| `path is unavailable on web` | Flutter Web no soporta `File.path` | Usar `withData: true` y `picked.bytes` |
| `No such bucket` | El bucket no fue creado | Ejecutar el SQL del bucket |
| `JWT expired` | La anon key expiró | Regenerar en Supabase → Settings → API |
| `RLS policy violation` | Sin política pública | Ejecutar el `CREATE POLICY` del SQL |
| `MissingPluginException` | `flutter pub get` no ejecutado | Correr `flutter pub get` y reiniciar |
| `Null check operator on null` | `.env` no cargado | Verificar que `.env` está en assets del `pubspec.yaml` |

import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  static const _green = Color(0xFF2ECC8F);
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Healthy';
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  // Usamos bytes en lugar de File para compatibilidad web/desktop
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  int? _selectedFileSize;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: true, // 👈 carga bytes, funciona en web y desktop
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;

      // Usar bytes directamente — siempre disponible con withData: true
      setState(() {
        _selectedBytes = picked.bytes;
        _selectedFileName = picked.name;
        _selectedFileSize = picked.size;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  void _clearFile() {
    setState(() {
      _selectedBytes = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  /// Sube bytes directamente a Supabase Storage
  Future<String?> _uploadFileBytes() async {
    if (_selectedBytes == null || _selectedFileName == null) return null;

    final client = Supabase.instance.client;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';

    await client.storage
        .from('task-files')
        .uploadBinary(fileName, _selectedBytes!);

    return client.storage.from('task-files').getPublicUrl(fileName);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un título')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Subir archivo por bytes si existe
      String? fileUrl;
      if (_selectedBytes != null) {
        fileUrl = await _uploadFileBytes();
      }

      final task = Task(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        scheduledTime: null,
        category: _selectedCategory,
        isCompleted: false,
        taskDate: _selectedDate,
        fileUrl: fileUrl,
      );

      await context.read<TaskProvider>().add(task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A2E)),
        title: const Text(
          'Adding Task',
          style: TextStyle(
              color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputBox(
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Task Title',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _inputBox(
              child: TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  helperText: '(Not Required)',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _greenOptionTile(
              icon: Icons.calendar_month_rounded,
              label:
                  'Select Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),

            _FilePickerTile(
              fileName: _selectedFileName,
              fileSizeBytes: _selectedFileSize,
              imageBytes: _selectedBytes,
              onTap: _pickFile,
              onClear: _selectedFileName != null ? _clearFile : null,
            ),

            const SizedBox(height: 24),

            const Text(
              'Choose Category',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  ['Healthy', 'Design', 'Job', 'Education', 'Sport', 'More']
                      .map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          selected ? const Color(0xFFE8F8F1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _green : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? _green : Colors.grey.shade600,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Adding',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: child,
    );
  }

  Widget _greenOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: const Color(0xFF2ECC8F),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    color: Color(0xFF2ECC8F), fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, color: Color(0xFF2ECC8F)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget _FilePickerTile
// ─────────────────────────────────────────────
class _FilePickerTile extends StatelessWidget {
  final String? fileName;
  final int? fileSizeBytes;
  final Uint8List? imageBytes; // 👈 bytes en lugar de File
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilePickerTile({
    this.fileName,
    this.fileSizeBytes,
    this.imageBytes,
    required this.onTap,
    this.onClear,
  });

  static const _green = Color(0xFF2ECC8F);

  bool get _hasFile => fileName != null;

  bool get _isImage =>
      fileName != null &&
      ['jpg', 'jpeg', 'png', 'gif', 'webp']
          .any((ext) => fileName!.toLowerCase().endsWith(ext));

  bool get _isPdf =>
      fileName != null && fileName!.toLowerCase().endsWith('pdf');

  bool get _isDoc =>
      fileName != null &&
      ['doc', 'docx'].any((ext) => fileName!.toLowerCase().endsWith(ext));

  IconData get _fileIcon {
    if (!_hasFile) return Icons.attach_file_rounded;
    if (_isImage) return Icons.image_rounded;
    if (_isPdf) return Icons.picture_as_pdf_rounded;
    if (_isDoc) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color get _fileIconColor {
    if (!_hasFile) return Colors.white;
    if (_isImage) return Colors.blue;
    if (_isPdf) return Colors.red;
    if (_isDoc) return Colors.blue.shade800;
    return Colors.orange;
  }

  String get _fileSizeLabel {
    if (fileSizeBytes == null) return '';
    final kb = fileSizeBytes! / 1024;
    if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '${kb.toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tile principal ──
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _hasFile
                  ? const Color(0xFFD0F5E8)
                  : const Color(0xFFE8F8F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hasFile ? _green : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _hasFile ? Colors.white : _green,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _hasFile
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    _fileIcon,
                    color: _hasFile ? _fileIconColor : Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasFile ? fileName! : 'Additional Files',
                        style: TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w700,
                          fontSize: _hasFile ? 13 : 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasFile
                            ? _fileSizeLabel
                            : 'Tap to attach a file',
                        style: TextStyle(
                          color: _green.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasFile)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: _green, shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onClear,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              color: Colors.red.shade400, size: 12),
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right, color: _green),
              ],
            ),
          ),
        ),

        // ── Preview card ──
        if (_hasFile) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                // Thumbnail: Image.memory con bytes si es imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: _isImage && imageBytes != null
                        ? Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _iconBox(),
                          )
                        : _iconBox(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1A1A2E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _fileIconColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fileName!.split('.').last.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _fileIconColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fileSizeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_upload_rounded,
                        color: _green.withOpacity(0.7), size: 22),
                    const SizedBox(height: 2),
                    Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 9,
                        color: _green.withOpacity(0.7),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _iconBox() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _fileIconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_fileIcon, color: _fileIconColor, size: 30),
      );
}
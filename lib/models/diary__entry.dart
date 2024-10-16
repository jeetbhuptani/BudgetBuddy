// TODO Implement this library.
import 'package:flutter/material.dart';

class DiaryEntryScreen extends StatefulWidget {
  final String title;
  final DateTime date;
  final String content;

  DiaryEntryScreen({super.key, this.title = '', DateTime? date, this.content = ''})
      : date = date ?? DateTime.now();

  @override
  // ignore: library_private_types_in_public_api
  _DiaryEntryScreenState createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
    _selectedDate = widget.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF673AB7), // Primary Color: Deep Purple
              onPrimary: Colors.white, // Text color on the primary color
              onSurface: Color(0xFF212121), // Main Text Color: Dark Gray
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveEntry() {
    // Add save functionality here
    // For example, saving to a database or updating state
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Entry'),
        backgroundColor: const Color(0xFF673AB7), // Primary Color: Deep Purple
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Text Field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Color(0xFF757575)), // Secondary Text Color
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF673AB7)), // Primary Color
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Date Picker
            Row(
              children: [
                Text(
                  'Date: ${_selectedDate.toLocal()}'.split(' ')[0],
                  style: const TextStyle(color: Color(0xFF212121)), // Main Text Color
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Color(0xFF03A9F4)), // Secondary Color: Light Blue
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Content Text Field
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  labelStyle: TextStyle(color: Color(0xFF757575)), // Secondary Text Color
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF673AB7)), // Primary Color
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveEntry,
        backgroundColor: const Color(0xFF673AB7), // Primary Color: Deep Purple
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}

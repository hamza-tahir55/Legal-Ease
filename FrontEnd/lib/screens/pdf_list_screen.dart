import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PDFListScreen extends StatefulWidget {
  const PDFListScreen({Key? key}) : super(key: key);

  @override
  _PDFListScreenState createState() => _PDFListScreenState();
}

class _PDFListScreenState extends State<PDFListScreen> {
  List<File> pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPDFs();
  }

  // Load PDFs from the app's directory
  Future<void> _loadPDFs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().whereType<File>().toList();
      setState(() {
        pdfFiles = files.where((file) => file.path.endsWith('.pdf')).toList();
      });
    } catch (e) {
      print("Error loading PDFs: $e");
    }
  }

  // Request storage permissions
  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if (await Permission.storage.isGranted) {
      // Proceed with saving the file
      if (pdfFiles.isNotEmpty) {
        _savePDFToDownloads(pdfFiles.first);  // Example: using the first PDF
      }
    } else {
      // Show permission denied message
      _showSnackBar("Storage permission denied.");
    }
  }

  // Save PDF to the Downloads folder
  Future<void> _savePDFToDownloads(File file) async {
    try {
      // Check Android version (if it's Android 9 or lower, we can directly use the Downloads folder)
      if (Platform.isAndroid && (await Permission.storage.isGranted)) {
        String downloadPath = "/storage/emulated/0/Download/"; // Android 9 path
        final fileName = file.path.split('/').last;
        final newFilePath = '$downloadPath$fileName';  // Save to Downloads folder

        // Print for debugging
        print("Saving PDF to: $newFilePath");

        // Check if the file already exists, if not, copy it
        if (await File(newFilePath).exists()) {
          _showSnackBar("File already exists in Downloads.");
          return;
        }

        await file.copy(newFilePath);  // Save file to the Downloads folder

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to: $newFilePath'), backgroundColor: Colors.green),
        );
      } else {
        // For Android 10+ (Scoped Storage), use getExternalStorageDirectories()
        final directories = await getExternalStorageDirectories();
        if (directories == null || directories.isEmpty) {
          _showSnackBar("Failed to access external storage directories.");
          return;
        }

        // Attempt to find the Downloads directory
        final downloadDirectory = directories.firstWhere(
              (dir) => dir.path.contains('Download'),
          orElse: () => Directory(''), // Empty directory fallback
        );

        if (downloadDirectory.path.isEmpty) {
          _showSnackBar("Download directory not found.");
          return;
        }

        final fileName = file.path.split('/').last;
        final newFilePath = '${downloadDirectory.path}/$fileName';  // Save to Downloads folder

        // Check if the file already exists, if not, copy it
        if (await File(newFilePath).exists()) {
          _showSnackBar("File already exists in Downloads.");
          return;
        }

        await file.copy(newFilePath);  // Save file to the Downloads folder

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to: $newFilePath'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Error saving PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save file: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Show SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Sign-out method to clear the PDF list and delete PDF files
  Future<void> _clearPDFs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      // Loop through each PDF file and delete it
      for (var file in files) {
        if (file is File && file.path.endsWith('.pdf')) {
          await file.delete();
          print("Deleted: ${file.path}");
        }
      }

      // Clear the UI list of PDFs
      setState(() {
        pdfFiles.clear();  // Clear the PDF list from the UI
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All PDFs cleared."), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("Error clearing PDFs: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to clear PDFs."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved PDFs"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _clearPDFs,  // Call the method to clear the PDFs
          ),
        ],
      ),
      body: pdfFiles.isEmpty
          ? const Center(child: Text("No saved PDFs found."))
          : ListView.builder(
        itemCount: pdfFiles.length,
        itemBuilder: (context, index) {
          final file = pdfFiles[index];
          return ListTile(
            title: Text(file.path.split('/').last),
            subtitle: Text(file.path),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _requestStoragePermission(), // Request permission and save file
            ),
          );
        },
      ),
    );
  }
}

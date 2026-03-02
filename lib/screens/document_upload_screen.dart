import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String patientId;
  DocumentUploadScreen({super.key, required this.patientId});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  bool _isUploading = false;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoadingReports = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await FirestoreService.getReports(widget.patientId);
      if (mounted) setState(() { _reports = reports; _isLoadingReports = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final platformFile = result.files.single;

    // Check file size (5MB = 5 * 1024 * 1024 bytes)
    final fileSize = platformFile.size;
    if (fileSize > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File size must be less than 5MB. Please choose a smaller file.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      File? file;
      if (platformFile.path != null) {
        file = File(platformFile.path!);
      }
      final bytes = platformFile.bytes;
      final fileName = platformFile.name;

      // Determine type from extension
      final ext = fileName.split('.').last.toLowerCase();
      String type = 'document';
      if (ext == 'pdf') type = 'prescription';
      if (['jpg', 'jpeg', 'png'].contains(ext)) type = 'scan';

      // Upload to Firebase Storage
      final fileUrl = await StorageService.uploadFile(
        file: file,
        bytes: bytes,
        patientId: widget.patientId,
        fileName: fileName,
      );

      // Save metadata to Firestore
      await FirestoreService.saveReport(
        patientId: widget.patientId,
        fileUrl: fileUrl,
        fileName: fileName,
        type: type,
      );

      // Add timeline event
      await FirestoreService.addTimelineEvent(
        patientId: widget.patientId,
        event: 'Report uploaded: $fileName',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File uploaded successfully!')),
      );
      await _loadReports(); // Refresh list and await completion before releasing loading state
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text('Upload Documents', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(color: Colors.grey.withValues(alpha: 0.2), height: 1)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Record', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5)),
            SizedBox(height: 8),
            Text('Upload prescriptions, lab reports, or scans (PDF, JPG, PNG).', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),

            SizedBox(height: 32),

            // Upload Area
            GestureDetector(
              onTap: _isUploading ? null : _pickAndUpload,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                ),
                child: Column(
                  children: [
                    if (_isUploading)
                      CircularProgressIndicator(color: Colors.blue)
                    else ...[
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.blue),
                      ),
                      SizedBox(height: 16),
                      Text('Tap to upload file', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      SizedBox(height: 8),
                      Text('Ensure the file is clear and readable.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 48),

            // Recent Uploads (from Firestore)
            Text('Recent Uploads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 16),

            if (_isLoadingReports)
              Center(child: CircularProgressIndicator())
            else if (_reports.isEmpty)
              Center(child: Text('No reports uploaded yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))))
            else
              ..._reports.map((report) {
                final name = report['fileName'] ?? 'Unknown';
                final type = report['type'] ?? 'document';
                final date = report['date'] != null
                    ? DateFormat('MMM dd, yyyy').format((report['date'] as dynamic).toDate())
                    : 'Unknown date';
                final isImage = name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png');

                return _buildFileItem(
                  icon: isImage ? Icons.image : Icons.picture_as_pdf,
                  iconColor: isImage ? Colors.blue : Colors.red,
                  name: name,
                  date: '$date • $type',
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem({required IconData icon, required Color iconColor, required String name, required String date}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor, )),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                SizedBox(height: 4),
                Text(date, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

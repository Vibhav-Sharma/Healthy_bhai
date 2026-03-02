import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _specialtyCtrl;
  late TextEditingController _hospitalCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;

  static const List<String> _specialties = [
    'General Medicine',
    'General Physician',
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'ENT (Otolaryngology)',
    'Gastroenterology',
    'Gynecology',
    'Hematology',
    'Internal Medicine',
    'Nephrology',
    'Neurology',
    'Oncology',
    'Ophthalmology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Radiology',
    'Rheumatology',
    'Surgery',
    'Urology',
    'Anesthesiology',
    'Pathology',
    'Dentistry',
    'Physiotherapy',
    'Ayurveda',
    'Homeopathy',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _specialtyCtrl = TextEditingController();
    _hospitalCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specialtyCtrl.dispose();
    _hospitalCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await FirestoreService.getDoctorProfile(widget.doctorId);
      if (data != null && mounted) {
        setState(() {
          _profile = data;
          _nameCtrl.text = data['name']?.toString() ?? '';
          _specialtyCtrl.text = data['specialty']?.toString() ?? '';
          _hospitalCtrl.text = data['hospital']?.toString() ?? '';
          _phoneCtrl.text = data['phone']?.toString() ?? '';
          _emailCtrl.text = data['email']?.toString() ?? '';
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number must be exactly 10 digits'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirestoreService.updateDoctorProfile(widget.doctorId, {
        'name': _nameCtrl.text.trim(),
        'specialty': _specialtyCtrl.text.trim(),
        'hospital': _hospitalCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text('Doctor Profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(color: Colors.grey[200], height: 1)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(child: Text('Profile not found'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar & ID
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).dividerColor, ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, size: 44, color: Colors.blue.shade700),
                            ),
                            SizedBox(height: 12),
                            Text(_nameCtrl.text.isNotEmpty ? 'Dr. ${_nameCtrl.text}' : 'Doctor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text(widget.doctorId, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 1)),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Editable Fields
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).dividerColor, ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            SizedBox(height: 20),

                            _buildField('Full Name', _nameCtrl, Icons.person),
                            _buildSpecialtyField(),
                            _buildField('Hospital', _hospitalCtrl, Icons.local_hospital),
                            _buildField('Phone', _phoneCtrl, Icons.phone, keyboard: TextInputType.phone),
                            _buildField('Email', _emailCtrl, Icons.email, enabled: false),

                            SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xffDC2626),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSaving
                                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ─── Specialty Searchable Dropdown ───
  Widget _buildSpecialtyField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: _specialtyCtrl.text),
        optionsBuilder: (TextEditingValue textEditingValue) {
          _specialtyCtrl.text = textEditingValue.text;
          if (textEditingValue.text.isEmpty) {
            return _specialties; // Show all when empty
          }
          final q = textEditingValue.text.toLowerCase();
          return _specialties.where((s) => s.toLowerCase().contains(q));
        },
        onSelected: (String selection) {
          _specialtyCtrl.text = selection;
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (val) => _specialtyCtrl.text = val,
            decoration: InputDecoration(
              labelText: 'Specialty',
              prefixIcon: Icon(Icons.medical_services, color: Colors.grey.shade500, size: 20),
              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200, maxWidth: 340),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(option, style: TextStyle(fontSize: 14)),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {TextInputType keyboard = TextInputType.text, bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        enabled: enabled,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
          filled: true,
          fillColor: enabled ? Theme.of(context).inputDecorationTheme.fillColor : Theme.of(context).scaffoldBackgroundColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        ),
      ),
    );
  }
}

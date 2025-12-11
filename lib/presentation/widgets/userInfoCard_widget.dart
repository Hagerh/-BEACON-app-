import 'package:flutter/material.dart';
import 'package:projectdemo/core/constants/colors.dart';

class UserinfocardWidget extends StatefulWidget {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? bloodType;
  final bool editable;
  final void Function(Map<String, String> data)? onSave; // Callback for save action

  const UserinfocardWidget({
    super.key,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.bloodType,
    this.editable = true, this.onSave,
  });

  @override
  State<UserinfocardWidget> createState() => _UserinfocardWidgetState();
}

class _UserinfocardWidgetState extends State<UserinfocardWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _bloodTypeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _addressController = TextEditingController(text: widget.address ?? '');
    _bloodTypeController = TextEditingController(text: widget.bloodType ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: AppColors.alertRed),
                  const SizedBox(width: 8),
                  Text(
                    'User Information',
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.alertRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: widget.editable,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (widget.editable && (value == null || value.isEmpty)) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: widget.editable,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (widget.editable && (value == null || value.isEmpty)) {
                    return 'Please enter your email';
                  }
                  if (widget.editable &&
                      value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                enabled: widget.editable,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (widget.editable && (value == null || value.isEmpty)) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                enabled: widget.editable,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: const Icon(Icons.home),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (widget.editable && (value == null || value.isEmpty)) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bloodTypeController,
                enabled: widget.editable,
                decoration: InputDecoration(
                  labelText: 'Blood Type',
                  hintText: 'e.g., O+, A-, B+',
                  prefixIcon: const Icon(Icons.bloodtype),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.editable)
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave!({
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'phone': _phoneController.text,
                        'address': _addressController.text,
                        'bloodType': _bloodTypeController.text,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryBackground,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }
}

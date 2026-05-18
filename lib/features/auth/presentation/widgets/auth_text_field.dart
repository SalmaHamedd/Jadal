import 'package:flutter/material.dart';
import 'package:jadal_app/core/colors.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final IconData? icon;

  const AuthTextField({
    super.key,
    required this.label,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.icon,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();

    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      validator: widget.validator,

      decoration: InputDecoration(
        prefixIcon: widget.icon != null
            ? Icon(widget.icon)
            : null,

        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              )
            : null,

        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.deepblue,
          ),
        ),

        labelStyle: const TextStyle(fontSize: 14),

        labelText: widget.label,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
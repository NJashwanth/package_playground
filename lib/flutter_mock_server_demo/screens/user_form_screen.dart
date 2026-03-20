import 'package:flutter/material.dart';

import '../models/user.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.user});

  /// Pass an existing [User] to edit it, or null to create a new one.
  final User? user;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  String _role = 'member';

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _role = u?.role ?? 'member';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      User(
        id: widget.user?.id ?? '',
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'New User'),
        actions: [TextButton(onPressed: _submit, child: const Text('Save'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User details',
                style: textTheme.titleSmall?.copyWith(color: colors.primary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Role',
                style: textTheme.titleSmall?.copyWith(color: colors.primary),
              ),
              const SizedBox(height: 12),
              _RoleSelector(
                selected: _role,
                onChanged: (role) => setState(() => _role = role),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(
                  _isEditing ? Icons.save_outlined : Icons.person_add_outlined,
                ),
                label: Text(_isEditing ? 'Save changes' : 'Create user'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const _roles = ['admin', 'member', 'viewer'];

  static const _icons = {
    'admin': Icons.admin_panel_settings_outlined,
    'member': Icons.group_outlined,
    'viewer': Icons.visibility_outlined,
  };

  static const _descriptions = {
    'admin': 'Full access to all resources',
    'member': 'Standard team access',
    'viewer': 'Read-only access',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _roles
          .map(
            (role) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RoleOption(
                role: role,
                icon: _icons[role]!,
                description: _descriptions[role]!,
                isSelected: selected == role,
                onTap: () => onChanged(role),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String role;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (bg, fg, borderColor) = switch (role) {
      'admin' =>
        isSelected
            ? (colors.errorContainer, colors.onErrorContainer, colors.error)
            : (colors.surface, colors.onSurface, colors.outlineVariant),
      'viewer' =>
        isSelected
            ? (
                colors.tertiaryContainer,
                colors.onTertiaryContainer,
                colors.tertiary,
              )
            : (colors.surface, colors.onSurface, colors.outlineVariant),
      _ =>
        isSelected
            ? (
                colors.primaryContainer,
                colors.onPrimaryContainer,
                colors.primary,
              )
            : (colors.surface, colors.onSurface, colors.outlineVariant),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${role[0].toUpperCase()}${role.substring(1)}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: fg.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: fg),
          ],
        ),
      ),
    );
  }
}

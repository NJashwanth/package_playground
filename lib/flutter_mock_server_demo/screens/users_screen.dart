import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/mock_server_service.dart';
import '../services/users_api_service.dart';
import 'user_form_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _server = MockServerService.instance;
  late final UsersApiService _api;

  List<User> _users = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = UsersApiService();
    _startAndLoad();
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  // ── server lifecycle ──────────────────────────────────────────────────────

  Future<void> _startAndLoad() async {
    if (!_server.isRunning) {
      try {
        await _server.start();
        setState(() {});
      } catch (e) {
        setState(() => _error = 'Failed to start server: $e');
        return;
      }
    }
    await _loadUsers();
  }

  Future<void> _toggleServer() async {
    if (_server.isRunning) {
      await _server.stop();
      setState(() {
        _users = [];
        _error = null;
      });
    } else {
      await _startAndLoad();
    }
    setState(() {});
  }

  // ── data ──────────────────────────────────────────────────────────────────

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _api.getAll();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openForm({User? user}) async {
    final result = await Navigator.push<User>(
      context,
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (result == null) return;

    try {
      if (user == null) {
        final created = await _api.create(
          name: result.name,
          email: result.email,
          role: result.role,
        );
        setState(() => _users.insert(0, created));
        _showSnack('${created.name} added');
      } else {
        final updated = await _api.update(
          id: user.id,
          name: result.name,
          email: result.email,
          role: result.role,
        );
        setState(() {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) _users[index] = updated;
        });
        _showSnack('${updated.name} updated');
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _deleteUser(User user) async {
    try {
      await _api.delete(user.id);
      setState(() => _users.removeWhere((u) => u.id == user.id));
      _showSnack('${user.name} deleted');
    } catch (e) {
      _showSnack('Error: $e');
      await _loadUsers(); // resync list if optimistic removal was wrong
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colors),
          if (_error != null)
            SliverToBoxAdapter(
              child: _ErrorBanner(
                message: _error!,
                onDismiss: () => setState(() => _error = null),
              ),
            ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_users.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(serverRunning: _server.isRunning),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              sliver: SliverList.separated(
                itemCount: _users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _UserCard(
                  user: _users[i],
                  onEdit: () => _openForm(user: _users[i]),
                  onDelete: () => _deleteUser(_users[i]),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _server.isRunning
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add User'),
            )
          : null,
    );
  }

  SliverAppBar _buildAppBar(ColorScheme colors) {
    return SliverAppBar.large(
      title: const Text('Users'),
      actions: [
        if (_server.isRunning)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadUsers,
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton.filled(
            icon: Icon(
              _server.isRunning
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outlined,
            ),
            tooltip: _server.isRunning ? 'Stop server' : 'Start server',
            style: IconButton.styleFrom(
              backgroundColor: _server.isRunning
                  ? colors.errorContainer
                  : colors.primaryContainer,
              foregroundColor: _server.isRunning
                  ? colors.onErrorContainer
                  : colors.onPrimaryContainer,
            ),
            onPressed: _toggleServer,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: _StatusBar(
          isRunning: _server.isRunning,
          userCount: _users.length,
        ),
      ),
    );
  }
}

// ── sub-widgets ───────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.isRunning, required this.userCount});

  final bool isRunning;
  final int userCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? const Color(0xFF4CAF50) : colors.outline,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isRunning ? 'http://localhost:8080' : 'Offline',
            style: style?.copyWith(
              color: isRunning ? colors.primary : colors.outline,
            ),
          ),
          if (isRunning) ...[
            const SizedBox(width: 16),
            Text(
              '$userCount user${userCount == 1 ? '' : 's'}',
              style: style?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: colors.onErrorContainer),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.serverRunning});

  final bool serverRunning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            serverRunning ? Icons.people_outline : Icons.power_off_outlined,
            size: 72,
            color: colors.outline,
          ),
          const SizedBox(height: 16),
          Text(
            serverRunning ? 'No users yet' : 'Server not running',
            style: textTheme.titleLarge?.copyWith(color: colors.outline),
          ),
          const SizedBox(height: 8),
          Text(
            serverRunning
                ? 'Tap + to add your first user'
                : 'Tap the play button to start',
            style: textTheme.bodyMedium?.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  final User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(user.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
      ),
      child: Card(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant, width: 0.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          leading: _Avatar(name: user.name, role: user.role),
          title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                user.email,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              _RoleChip(role: user.role),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          onTap: onEdit,
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final (bg, fg) = switch (role) {
      'admin' => (colors.errorContainer, colors.onErrorContainer),
      'viewer' => (colors.tertiaryContainer, colors.onTertiaryContainer),
      _ => (colors.primaryContainer, colors.onPrimaryContainer),
    };

    return CircleAvatar(
      backgroundColor: bg,
      child: Text(
        initials,
        style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 16),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (bg, fg) = switch (role) {
      'admin' => (colors.errorContainer, colors.onErrorContainer),
      'member' => (colors.primaryContainer, colors.onPrimaryContainer),
      'viewer' => (colors.tertiaryContainer, colors.onTertiaryContainer),
      _ => (colors.surfaceContainerHighest, colors.onSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

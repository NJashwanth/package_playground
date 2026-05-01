// Seed Firebase Remote Config with all playground keys.
//
// Configuration (in order of precedence):
//   1. CLI flags              --project-id=xxx  --service-account=path/to/sa.json
//   2. Shell env vars         FIREBASE_PROJECT_ID  SERVICE_ACCOUNT_PATH
//   3. .env file              FIREBASE_PROJECT_ID=xxx  (in project root)
//
// Usage:
//   dart run tool/seed_remote_config.dart
//   dart run tool/seed_remote_config.dart --dry-run
//   dart run tool/seed_remote_config.dart --overwrite
//   dart run tool/seed_remote_config.dart --project-id=my-project --service-account=./sa.json

// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';

// ── Keys to seed ─────────────────────────────────────────────────────────────
// Format: { 'firebase_key': ('VALUE_TYPE', 'default_value') }
// VALUE_TYPE: BOOLEAN | STRING | NUMBER
const _keys = {
  // UI flags
  'enable_dark_mode': ('BOOLEAN', 'false'),
  'show_premium_banner': ('BOOLEAN', 'true'),
  'onboarding_variant': ('STRING', 'control'),
  'home_grid_columns': ('NUMBER', '2'),
  // Feature flags
  'enable_checkout': ('BOOLEAN', 'true'),
  'enable_new_search': ('BOOLEAN', 'false'),
  'enable_live_chat': ('BOOLEAN', 'true'),
  // Config values
  'api_timeout_seconds': ('NUMBER', '30'),
  'max_cart_items': ('NUMBER', '10'),
  'promo_code': ('STRING', 'SAVE10'),
  'animation_speed_multiplier': ('NUMBER', '1.0'),
  // Direct-literal keys (not in RemoteConfigKeys class)
  'legacy_banner_enabled': ('BOOLEAN', 'false'),
  'app_theme_color': ('STRING', '#6200EE'),
  'cart_badge_style': ('STRING', 'dot'),
  'animation_speed': ('NUMBER', '1.0'),
  // ── Intentionally NOT seeded ─────────────────────────────────────────────
  // debug_mode              → code-only → audit code_only_keys: fail
  // experimental_feature_v2 → code-only → audit code_only_keys: fail
};

const _apiBase = 'https://firebaseremoteconfig.googleapis.com/v1';
const _scopes = ['https://www.googleapis.com/auth/firebase.remoteconfig'];

// ── .env loader ───────────────────────────────────────────────────────────────
// Reads KEY=VALUE lines; ignores comments and blank lines.
Map<String, String> _loadDotEnv([String path = '.env']) {
  final file = File(path);
  if (!file.existsSync()) return {};
  return Map.fromEntries(
    file.readAsLinesSync().where((l) => l.isNotEmpty && !l.startsWith('#') && l.contains('=')).map((l) {
      final idx = l.indexOf('=');
      return MapEntry(l.substring(0, idx).trim(), l.substring(idx + 1).trim());
    }),
  );
}

// ── Config resolution ─────────────────────────────────────────────────────────
String? _flag(List<String> args, String name) {
  final prefix = '--$name=';
  for (final a in args) {
    if (a.startsWith(prefix)) return a.substring(prefix.length);
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final overwrite = args.contains('--overwrite');

  // Merge env sources: .env file < shell env < CLI flags
  final env = {..._loadDotEnv(), ...Platform.environment};

  final projectId =
      _flag(args, 'project-id') ?? env['FIREBASE_PROJECT_ID'];
  final saPath =
      _flag(args, 'service-account') ?? env['SERVICE_ACCOUNT_PATH'] ?? './service-account.json';

  if (projectId == null || projectId.isEmpty) {
    stderr.writeln('ERROR: Firebase project ID not configured.\n'
        '  Set FIREBASE_PROJECT_ID in .env, export it as a shell variable,\n'
        '  or pass --project-id=your-project-id');
    exit(1);
  }

  if (dryRun) print('[dry-run] No changes will be written to Firebase.\n');

  // ── Auth ───────────────────────────────────────────────────────────────────
  final saFile = File(saPath);
  if (!saFile.existsSync()) {
    stderr.writeln('ERROR: Service account file not found at $saPath\n'
        '  Set SERVICE_ACCOUNT_PATH in .env or pass --service-account=path/to/sa.json\n'
        '  See service-account.example.json for the expected format.');
    exit(1);
  }

  final credentials = ServiceAccountCredentials.fromJson(
    jsonDecode(saFile.readAsStringSync()) as Map<String, dynamic>,
  );
  final authClient = await clientViaServiceAccount(credentials, _scopes);

  try {
    // ── GET current template ──────────────────────────────────────────────
    final url = Uri.parse('$_apiBase/projects/$projectId/remoteConfig');
    print('Fetching Remote Config template for project: $projectId');
    final getRes = await authClient.get(url);

    if (getRes.statusCode != 200) {
      stderr.writeln('GET failed (${getRes.statusCode}): ${getRes.body}');
      exit(1);
    }

    final etag = getRes.headers['etag'] ?? '*';
    final template = jsonDecode(getRes.body) as Map<String, dynamic>;
    final params =
        Map<String, dynamic>.from(template['parameters'] as Map? ?? {});

    print('Current keys in Firebase (${params.length}): '
        '${params.keys.join(', ')}\n');

    // ── Merge ─────────────────────────────────────────────────────────────
    int added = 0, updated = 0, skipped = 0;
    for (final entry in _keys.entries) {
      final key = entry.key;
      final (type, value) = entry.value;
      final alreadyExists = params.containsKey(key);

      if (alreadyExists && !overwrite) {
        print('  [skip]   $key');
        skipped++;
        continue;
      }

      params[key] = {
        'defaultValue': {'value': value},
        'valueType': type,
        'description': 'Seeded by seed_remote_config.dart',
      };

      if (alreadyExists) {
        print('  [update] $key = $value  ($type)');
        updated++;
      } else {
        print('  [add]    $key = $value  ($type)');
        added++;
      }
    }

    print('\nSummary: $added added, $updated updated, $skipped skipped.');

    if (added == 0 && updated == 0) {
      print('Nothing to do. Use --overwrite to force-update existing keys.');
      return;
    }

    if (dryRun) {
      print('\n[dry-run] Would PUT ${params.length} keys. Exiting without writing.');
      return;
    }

    // ── PUT updated template ──────────────────────────────────────────────
    template['parameters'] = params;
    final putRes = await authClient.put(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'If-Match': etag,
      },
      body: jsonEncode(template),
    );

    if (putRes.statusCode == 200) {
      print('\nFirebase Remote Config updated successfully.');
      print('Run the audit now: dart run feature_flag_audit');
    } else {
      stderr.writeln('PUT failed (${putRes.statusCode}):');
      stderr.writeln(putRes.body);
      exit(1);
    }
  } finally {
    authClient.close();
  }
}

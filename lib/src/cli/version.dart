part of '../cli.dart';

const String cliVersion = '0.1.6';

bool _isVersion(String value) =>
    value == '-v' || value == '--version' || value == 'version';

Future<void> _printVersionInfo() async {
  stdout.writeln('fdev version $cliVersion');
  final latest = await _fetchLatestVersion();
  _checkAndPrintUpdate(cliVersion, latest);
}

Future<String?> _fetchLatestVersion() async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 2);
  try {
    final uri = Uri.parse('https://pub.dev/api/packages/fdev');
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await utf8.decodeStream(response);
      final data = json.decode(body) as Map<String, dynamic>;
      final latest = data['latest'] as Map<String, dynamic>?;
      if (latest != null) {
        return latest['version'] as String?;
      }
    }
  } catch (_) {
    // Ignore network errors or timeouts to fail silently
  } finally {
    client.close(force: true);
  }
  return null;
}

void _checkAndPrintUpdate(String currentVersion, String? latestVersion) {
  if (latestVersion != null && _isNewerVersion(latestVersion, currentVersion)) {
    stdout.writeln();
    stdout.writeln(
      'A new version of fdev is available: $latestVersion (current: $currentVersion).',
    );
    stdout.writeln('Run `fdev upgrade` to update to the latest version.');
  }
}

/// Returns true when [candidate] is a higher pub-style version than [current].
bool _isNewerVersion(String candidate, String current) {
  final a = _parseVersionParts(candidate);
  final b = _parseVersionParts(current);
  if (a == null || b == null) {
    return candidate != current;
  }
  final len = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) {
    final left = i < a.length ? a[i] : 0;
    final right = i < b.length ? b[i] : 0;
    if (left > right) {
      return true;
    }
    if (left < right) {
      return false;
    }
  }
  return false;
}

List<int>? _parseVersionParts(String version) {
  final core = version.split(RegExp(r'[-+]')).first;
  final parts = core.split('.');
  if (parts.isEmpty) {
    return null;
  }
  final parsed = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null) {
      return null;
    }
    parsed.add(value);
  }
  return parsed;
}

Future<int> _upgrade(List<String> args) async {
  stdout.writeln('Upgrading fdev to the latest version...');

  final exitCode =
      await _runStep('dart', ['pub', 'global', 'activate', 'fdev']);
  if (exitCode == 0) {
    stdout.writeln('Successfully upgraded fdev!');
  } else {
    stdout.writeln('Failed to upgrade fdev.');
  }
  return exitCode;
}

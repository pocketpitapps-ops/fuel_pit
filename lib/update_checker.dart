import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

class UpdateChecker {
  static const _owner = 'pocketpitapps-ops';
  static const _repo = 'fuel_pit';

  /// Retorna a versão mais recente se for maior que a versão instalada.
  /// Se não houver update, retorna null.
  static Future<Version?> getLatestVersionIfNewer() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(info.version);

      final uri = Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?) ?? '';
      final latestVersionString = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;

      if (latestVersionString.isEmpty) return null;

      final latestVersion = Version.parse(latestVersionString);

      if (latestVersion > currentVersion) {
        return latestVersion;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> showUpdateDialog(
    BuildContext context,
    Version latestVersion,
  ) async {
    final downloadUrl = 'https://github.com/$_owner/$_repo/releases/latest';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Atualização disponível'),
          content: Text(
            'Está disponível a versão $latestVersion do Fuel Pit.\n'
            'Queres abrir a página de download?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Agora não'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final uri = Uri.parse(downloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Atualizar'),
            ),
          ],
        );
      },
    );
  }
}

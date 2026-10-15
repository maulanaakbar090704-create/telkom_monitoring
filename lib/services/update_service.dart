import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final String downloadUrl;
  final String changelog;
  final bool isForceUpdate;
  final bool hasUpdate;

  UpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.downloadUrl,
    required this.changelog,
    required this.isForceUpdate,
    required this.hasUpdate,
  });
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  bool _isChecking = false;
  bool _isDialogShowing = false;

  /// Memeriksa apakah ada pembaruan aplikasi dari Supabase
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      // Ambil rilis terbaru dari tabel app_versions
      final data = await Supabase.instance.client
          .from('app_versions')
          .select()
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) {
        return UpdateInfo(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          latestVersion: currentVersion,
          latestBuildNumber: currentBuildNumber,
          downloadUrl: '',
          changelog: '',
          isForceUpdate: false,
          hasUpdate: false,
        );
      }

      final latestBuildNumber = int.tryParse(data['build_number']?.toString() ?? '0') ?? 0;
      final latestVersion = (data['version_code'] ?? data['version'] ?? 'v$latestBuildNumber').toString();
      final downloadUrl = (data['download_url'] ?? data['apk_url'] ?? data['url'] ?? '').toString();
      final changelog = (data['changelog'] ?? data['description'] ?? 'Peningkatan performa dan perbaikan bug.').toString();
      final isForceUpdate = (data['is_force_update'] ?? data['force_update'] ?? false) as bool;

      // Cek apakah build di database lebih tinggi dari build yang terpasang
      final bool hasUpdate = (latestBuildNumber > currentBuildNumber) && downloadUrl.isNotEmpty;

      return UpdateInfo(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuildNumber,
        downloadUrl: downloadUrl,
        changelog: changelog,
        isForceUpdate: isForceUpdate,
        hasUpdate: hasUpdate,
      );
    } catch (e) {
      debugPrint('[UpdateService] Gagal memeriksa update: $e');
      return null;
    }
  }

  /// Cek update dan tampilkan dialog jika tersedia
  /// [silent]: Jika true, tidak akan memunculkan dialog/snackbar jika tidak ada update (cocok untuk startup)
  Future<void> checkAndPromptUpdate(BuildContext context, {bool silent = true}) async {
    if (_isChecking || _isDialogShowing) return;
    _isChecking = true;

    try {
      final updateInfo = await checkForUpdate();

      if (!context.mounted) {
        _isChecking = false;
        return;
      }

      if (updateInfo == null) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memeriksa pembaruan. Pastikan koneksi internet stabil.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _isChecking = false;
        return;
      }

      if (updateInfo.hasUpdate) {
        _isDialogShowing = true;
        await showDialog(
          context: context,
          barrierDismissible: !updateInfo.isForceUpdate,
          builder: (dialogContext) => _UpdateDialog(updateInfo: updateInfo),
        );
        _isDialogShowing = false;
      } else {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Aplikasi Anda sudah versi terbaru (v${updateInfo.currentVersion}).'),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } finally {
      _isChecking = false;
    }
  }
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const _UpdateDialog({required this.updateInfo});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;

  Future<void> _startOtaUpdate() async {
    final apkUrl = widget.updateInfo.downloadUrl.trim();
    if (apkUrl.isEmpty) {
      setState(() {
        _errorMessage = 'URL download tidak valid.';
      });
      return;
    }

    // Jika bukan Android (misal di Web / Desktop / iOS), buka link di browser
    if (kIsWeb || !Platform.isAndroid) {
      final uri = Uri.tryParse(apkUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = 'Menyiapkan unduhan...';
      _errorMessage = null;
    });

    try {
      OtaUpdate()
          .execute(
        apkUrl,
        destinationFilename: 'telkom_car_monitoring_${widget.updateInfo.latestBuildNumber}.apk',
      )
          .listen(
        (OtaEvent event) {
          if (!mounted) return;

          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final intValue = int.tryParse(event.value ?? '0') ?? 0;
              setState(() {
                _progress = (intValue / 100.0).clamp(0.0, 1.0);
                _statusMessage = 'Mengunduh pembaruan: $intValue%';
              });
              break;

            case OtaStatus.INSTALLING:
              setState(() {
                _progress = 1.0;
                _statusMessage = 'Membuka pemasang aplikasi...';
              });
              break;

            case OtaStatus.INSTALLATION_DONE:
              setState(() {
                _progress = 1.0;
                _statusMessage = 'Pemasangan selesai.';
              });
              break;

            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _statusMessage = 'Pengunduhan sedang berjalan.';
              });
              break;

            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _isDownloading = false;
                _errorMessage = 'Izin pemasangan aplikasi ditolak oleh Android.';
              });
              break;

            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            default:
              setState(() {
                _isDownloading = false;
                _errorMessage = 'Gagal mengunduh berkas update (${event.status.name}).';
              });
              break;
          }
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Terjadi kesalahan: $err';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Gagal memulai unduhan: $e';
      });
    }
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.tryParse(widget.updateInfo.downloadUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForce = widget.updateInfo.isForceUpdate;

    return PopScope(
      canPop: !isForce && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header dengan Badge Telkom
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.system_update_alt_rounded,
                    size: 38,
                    color: Color(0xFFBB0016),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Pembaruan Tersedia!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),

              // Versi info pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'v${widget.updateInfo.currentVersion} ➔ v${widget.updateInfo.latestVersion}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Changelog Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan Rilis:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.updateInfo.changelog,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _openExternalBrowser,
                  icon: const Icon(Icons.open_in_browser, size: 16),
                  label: const Text('Download Manual Lewat Browser', style: TextStyle(fontSize: 12)),
                ),
              ],

              // Download Progress Bar
              if (_isDownloading) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBB0016)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              if (!_isDownloading)
                Row(
                  children: [
                    if (!isForce) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Nanti',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _startOtaUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBB0016),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Update Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

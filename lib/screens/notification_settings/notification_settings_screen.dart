import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notifikasi Aplikasi Umum
  bool pushNotif = true;
  bool returnReminder = true;
  bool systemAlert = true;


  // Notifikasi Email Dinas
  bool emailNotif = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        pushNotif = prefs.getBool('notif_push') ?? true;
        returnReminder = prefs.getBool('notif_return_reminder') ?? true;
        systemAlert = prefs.getBool('notif_system') ?? true;


        emailNotif = prefs.getBool('notif_email') ?? true;
        isLoading = false;
      });
    }
  }

  Future<void> _updatePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferensi notifikasi disimpan'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBB0016)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. NOTIFIKASI UMUM APLIKASI
                  const Text(
                    'NOTIFIKASI APLIKASI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBB0016),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeThumbColor: const Color(0xFFBB0016),
                          activeTrackColor:
                              const Color(0xFFBB0016).withValues(alpha: 0.3),
                          title: const Text(
                            'Push Notification',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937)),
                          ),
                          subtitle: const Text(
                            'Pemberitahuan persetujuan dan status armada langsung di HP',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                          value: pushNotif,
                          onChanged: (val) {
                            setState(() => pushNotif = val);
                            _updatePref('notif_push', val);
                          },
                        ),
                        const Divider(
                            height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                        SwitchListTile(
                          activeThumbColor: const Color(0xFFBB0016),
                          activeTrackColor:
                              const Color(0xFFBB0016).withValues(alpha: 0.3),
                          title: const Text(
                            'Pengingat Pengembalian Mobil',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937)),
                          ),
                          subtitle: const Text(
                            'Alarm pengingat sebelum batas waktu peminjaman berakhir',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                          value: returnReminder,
                          onChanged: (val) {
                            setState(() => returnReminder = val);
                            _updatePref('notif_return_reminder', val);
                          },
                        ),
                        const Divider(
                            height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                        SwitchListTile(
                          activeThumbColor: const Color(0xFFBB0016),
                          activeTrackColor:
                              const Color(0xFFBB0016).withValues(alpha: 0.3),
                          title: const Text(
                            'Peringatan Sistem & Pemeliharaan',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937)),
                          ),
                          subtitle: const Text(
                            'Pengumuman maintenance sistem server atau armada pool',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                          value: systemAlert,
                          onChanged: (val) {
                            setState(() => systemAlert = val);
                            _updatePref('notif_system', val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. NOTIFIKASI EMAIL DINAS
                  const Text(
                    'NOTIFIKASI EMAIL DINAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBB0016),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      activeThumbColor: const Color(0xFFBB0016),
                      activeTrackColor:
                          const Color(0xFFBB0016).withValues(alpha: 0.3),
                      title: const Text(
                        'Pemberitahuan via Email',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937)),
                      ),
                      subtitle: const Text(
                        'Kirimkan salinan e-tiket peminjaman dan bukti pengembalian',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                      value: emailNotif,
                      onChanged: (val) {
                        setState(() => emailNotif = val);
                        _updatePref('notif_email', val);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFF1D4ED8), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pastikan izin notifikasi dan izin lokasi perangkat tetap aktif agar verifikasi penjemputan dan keselamatan armada dapat berjalan optimal.',
                            style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontSize: 11,
                                height: 1.45),
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
}
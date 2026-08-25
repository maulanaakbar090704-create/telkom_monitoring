import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool pushNotif = true;
  bool emailNotif = true;
  bool systemAlert = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3567),
        title: const Text('Pengaturan Notifikasi', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NOTIFIKASI APLIKASI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xFFBB0016),
                    title: const Text('Push Notification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Notifikasi pengingat pengembalian mobil', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: pushNotif,
                    onChanged: (val) => setState(() => pushNotif = val),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                  SwitchListTile(
                    activeColor: const Color(0xFFBB0016),
                    title: const Text('Peringatan Sistem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Pembaruan dan teguran dari admin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: systemAlert,
                    onChanged: (val) => setState(() => systemAlert = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('NOTIFIKASI EMAIL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: SwitchListTile(
                activeColor: const Color(0xFFBB0016),
                title: const Text('Pemberitahuan via Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Kirim resi dan bukti pinjam ke email dinas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: emailNotif,
                onChanged: (val) => setState(() => emailNotif = val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
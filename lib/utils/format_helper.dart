import 'dart:convert';
import 'package:flutter/widgets.dart';

/// Helper untuk formatting teks dan membersihkan tampilan dari string bertipe URL
/// agar UI aplikasi bersih, rapi, dan sesuai standar keamanan/presentasi.
class FormatHelper {
  /// Memformat kode loker atau barcode untuk tampilan UI.
  /// Jika teks barcode/QR yang dipindai mengandung URL (http/https/www/dsb),
  /// URL tersebut akan dihilangkan dan digantikan dengan format kode loker bersih atau status terverifikasi.
  static String formatLockerCodeForDisplay(dynamic rawCode) {
    if (rawCode == null) return '-';
    final str = rawCode.toString().trim();
    if (str.isEmpty) return '-';

    // Cek apakah string merupakan atau mengandung URL
    final isUrl = str.startsWith('http://') ||
        str.startsWith('https://') ||
        str.startsWith('www.') ||
        str.contains('://') ||
        str.contains('.com') ||
        str.contains('.co.id') ||
        str.contains('.id/') ||
        str.contains('.org');

    if (isUrl) {
      try {
        final uri = Uri.parse(str.startsWith('http') ? str : 'https://$str');
        // 1. Cek parameter query seperti ?code=... atau ?id=... atau ?locker=...
        for (final key in ['code', 'id', 'locker', 'loker', 'slot']) {
          final val = uri.queryParameters[key];
          if (val != null && val.isNotEmpty) {
            return _cleanCodeString(val);
          }
        }

        // 2. Cek path segmen terakhir jika ada (contoh: /loker/A01 -> LOKER-A01)
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          final lastSeg = segments.last;
          if (lastSeg.length <= 20 && !lastSeg.contains('.')) {
            return _cleanCodeString(lastSeg);
          }
        }
      } catch (_) {}

      // Fallback jika URL murni tanpa id spesifik
      return 'Loker Terverifikasi (QR)';
    }

    return _cleanCodeString(str);
  }

  /// Membersihkan teks catatan admin / pengelola dari URL foto (misal Supabase Storage URLs)
  /// agar tidak muncul link panjang yang merusak tampilan.
  static String sanitizeNoteForDisplay(dynamic rawNote) {
    if (rawNote == null) return '';
    String note = rawNote.toString().trim();
    if (note.isEmpty) return '';

    // Ganti URL dengan label rapi "[Foto Terlampir]"
    note = note.replaceAll(
      RegExp(r'https?:\/\/[^\s\|\]\)\>]+', caseSensitive: false),
      'Foto Terlampir',
    );

    // Bersihkan jika ada Loker Return yang berupa URL
    note = note.replaceAllMapped(
      RegExp(r'Loker Return:\s*([^\|\]]+)'),
      (match) {
        final val = match.group(1)?.trim() ?? '';
        return 'Loker Return: ${formatLockerCodeForDisplay(val)}';
      },
    );

    return note;
  }

  static String _cleanCodeString(String input) {
    var cleaned = input.trim();
    if (cleaned.toUpperCase().startsWith('LOKER-') || cleaned.toUpperCase().startsWith('LK-')) {
      return cleaned.toUpperCase();
    }
    // Jika hanya huruf/angka pendek, beri prefix LOKER- bila sesuai
    if (RegExp(r'^[A-Za-z0-9\-_]{2,10}$').hasMatch(cleaned) && !cleaned.contains(' ')) {
      return 'LOKER-${cleaned.toUpperCase()}';
    }
    return cleaned;
  }

  /// Memformat nama pengguna untuk dashboard agar rapi, proporsional, dan tidak berantakan:
  /// Menampilkan nama depan, dan jika nama panjang, menyingkat kata-kata berikutnya menjadi inisial.
  /// Contoh: "YUSUF BIL ASHARI SYAHRU RAMADHAN" -> "Yusuf B. A. S. R."
  /// Contoh: "Budi Santoso" -> "Budi Santoso"
  /// Contoh: "YUSUF" -> "Yusuf"
  static String formatUserDisplayName(dynamic rawName, {bool firstNameOnly = false}) {
    if (rawName == null) return '';
    final str = rawName.toString().trim();
    if (str.isEmpty || str == 'Memuat...' || str == 'Karyawan Telkom') {
      return str;
    }

    final words = str.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return str;

    String toTitleCase(String word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }

    final firstName = toTitleCase(words.first);

    if (firstNameOnly || words.length == 1) {
      return firstName;
    }

    // Jika nama panjang (> 2 kata atau total panjang karakter > 18)
    if (words.length > 2 || str.length > 18) {
      final initials = words.skip(1).map((w) => '${w[0].toUpperCase()}.').join(' ');
      return '$firstName $initials';
    }

    // Jika hanya 2 kata pendek
    return words.map(toTitleCase).join(' ');
  }

  /// Mengambil nama depan saja dari nama pengguna
  static String formatFirstNameOnly(dynamic rawName) {
    return formatUserDisplayName(rawName, firstNameOnly: true);
  }

  /// Mengembalikan ImageProvider yang tepat baik untuk URL Supabase Storage (http/https)
  /// maupun Data URI Base64 (data:image/...). Menjamin foto profil selalu tampil mulus.
  static ImageProvider? getImageProvider(dynamic rawUrl) {
    if (rawUrl == null) return null;
    final str = rawUrl.toString().trim();
    if (str.isEmpty || str == 'null') return null;

    if (str.startsWith('data:image/')) {
      try {
        final commaIdx = str.indexOf(',');
        final base64Data = commaIdx != -1 ? str.substring(commaIdx + 1) : str;
        return MemoryImage(base64Decode(base64Data));
      } catch (_) {
        return null;
      }
    }

    if (str.startsWith('http://') || str.startsWith('https://')) {
      return NetworkImage(str);
    }

    return null;
  }
}

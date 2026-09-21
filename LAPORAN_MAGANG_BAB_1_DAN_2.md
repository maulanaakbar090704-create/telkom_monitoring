# LAPORAN PRAKTEK KERJA MAGANG INDUSTRI

**SISTEM MONITORING DAN PEMINJAMAN KENDARAAN OPERASIONAL BERBASIS MOBILE APPLICATION DAN IOT GPS TRACKING (SIMDANGPS) TERINTEGRASI SUPABASE**  
*(Studi Kasus: PT. Telkom Akses Bogor)*

---

## HALAMAN JUDUL (COVER)

**LAPORAN PRAKTEK KERJA MAGANG INDUSTRI**

**SISTEM MONITORING DAN PEMINJAMAN KENDARAAN OPERASIONAL BERBASIS MOBILE APPLICATION DAN IOT GPS TRACKING (SIMDANGPS) TERINTEGRASI SUPABASE**  
*(Studi Kasus: PT. Telkom Akses Bogor)*

oleh:  
**Maulana Akbar**  
**085024010**

**PROGRAM STUDI DIII MANAJEMEN INFORMATIKA**  
**SEKOLAH VOKASI**  
**UNIVERSITAS PAKUAN**  
**BOGOR**  
**2026**

---

## HALAMAN PENGESAHAN

**Judul** : Sistem Monitoring dan Peminjaman Kendaraan Operasional Berbasis Mobile Application dan IoT GPS Tracking (SIMDANGPS) Terintegrasi Supabase (Studi Kasus: PT. Telkom Akses Bogor)  
**Nama** : Maulana Akbar  
**NPM** : 085024010  
**Program Studi** : DIII Manajemen Informatika  

<br>

**Mengesahkan,**

| Pembimbing II (Lapangan) <br> PT Telkom Akses Bogor | Pembimbing I <br> Sekolah Vokasi Universitas Pakuan |
| :---: | :---: |
| <br><br><br> **Pahreza Fajri Sulaeman** | <br><br><br> **Deden Ardiansyah, M.Kom.** |

<br>

**Mengetahui,**  
Ketua Program Studi Manajemen Informatika  
Sekolah Vokasi Universitas Pakuan  

<br><br><br>
**( ............................................................ )**  

---

## KATA PENGANTAR

Puji dan syukur penulis panjatkan ke hadirat Tuhan Yang Maha Esa, karena berkat rahmat dan karunia-Nya penulis dapat menyelesaikan Laporan Praktek Kerja Magang Industri (PKMI) ini dengan baik. Laporan ini disusun berdasarkan hasil kegiatan magang yang dilaksanakan di PT Telkom Akses Bogor dengan judul **"Sistem Monitoring dan Peminjaman Kendaraan Operasional Berbasis Mobile Application dan IoT GPS Tracking (SIMDANGPS) Terintegrasi Supabase"**.

Penyusunan laporan ini tidak terlepas dari bimbingan, arahan, serta dukungan dari berbagai pihak. Oleh karena itu, pada kesempatan ini penulis menyampaikan rasa terima kasih yang sebesar-besarnya kepada:

1. **Deden Ardiansyah, M.Kom.** selaku Dosen Pembimbing yang telah meluangkan waktu, memberikan bimbingan, arahan, dan masukan berharga dalam penyusunan laporan magang ini;
2. **Pahreza Fajri Sulaeman** selaku Pembimbing Lapangan di PT Telkom Akses Bogor yang telah membimbing, memfasilitasi, dan memberikan arahan teknis selama pelaksanaan magang industri;
3. **Dr. Lia Dahlia Iryani, S.E., M.Si.** selaku Dekan Sekolah Vokasi Universitas Pakuan;
4. **Ketua Program Studi Manajemen Informatika** Sekolah Vokasi Universitas Pakuan beserta seluruh dosen dan staf akademik yang telah memberikan bekal ilmu pengetahuan;
5. **Seluruh jajaran pimpinan dan staf PT Telkom Akses Bogor**, khususnya unit Shared Service, Business Support, dan Operasional Lapangan atas bantuan dan kerja sama yang diberikan;
6. **Kedua orang tua dan keluarga tercinta**, yang senantiasa memberikan doa tulus, motivasi moral, serta dukungan materiil;
7. **Rekan-rekan mahasiswa Program Studi DIII Manajemen Informatika Angkatan 2024**, serta sahabat-sahabat yang selalu memberikan semangat dan kebersamaan.

Penulis menyadari bahwa laporan ini masih memiliki keterbatasan. Oleh karena itu, saran dan kritik yang konstruktif sangat diharapkan demi penyempurnaan di masa mendatang. Semoga laporan ini dapat memberikan manfaat nyata bagi pengembangan ilmu pengetahuan dan implementasi teknologi informasi di dunia industri.

Bogor, Januari 2026  
Penulis,  

**Maulana Akbar**  
NPM. 085024010  

---

## DAFTAR ISI

* **HALAMAN PENGESAHAN** ................................................................................ i
* **KATA PENGANTAR** .......................................................................................... ii
* **DAFTAR ISI** ...................................................................................................... iii
* **DAFTAR GAMBAR** .......................................................................................... iv
* **DAFTAR TABEL** ............................................................................................... v
* **BAB I PENDAHULUAN** .................................................................................... 1
  * 1.1 Latar Belakang ................................................................................................ 1
  * 1.2 Tujuan Praktek Kerja Magang Industri ........................................................... 3
  * 1.3 Ruang Lingkup Praktek Kerja Magang Industri .............................................. 3
  * 1.4 Manfaat .......................................................................................................... 5
* **BAB II TINJAUAN INSTANSI DAN PUSTAKA** ................................................. 6
  * 2.1 Tinjauan Instansi ............................................................................................. 6
    * 2.1.1 Sejarah Instansi ........................................................................................ 6
    * 2.1.2 Visi dan Misi Instansi ............................................................................... 8
    * 2.1.3 Struktur Organisasi Instansi ..................................................................... 8
    * 2.1.4 Dokumentasi PKMI .................................................................................. 9
  * 2.2 Tinjauan Pustaka ............................................................................................ 10
    * 2.2.1 Sistem Informasi Manajemen Armada (*Fleet Management System*) .......... 10
    * 2.2.2 Aplikasi Mobile dan Framework Flutter ................................................... 10
    * 2.2.3 Platform Backend-as-a-Service (BaaS) Supabase dan PostgreSQL ............ 11
    * 2.2.4 Internet of Things (IoT) dan Mikrokontroler ESP32 ................................... 12
    * 2.2.5 Modul Global Positioning System (GPS) .................................................. 12
    * 2.2.6 Modul Komunikasi Seluler GSM/GPRS SIM800L .................................... 13
    * 2.2.7 Sistem Keamanan Smart Locker Berbasis QR Code ................................. 13
    * 2.2.8 Verifikasi Wajah Biometrik dan Inspeksi Citra Digital Kendaraan ............ 14
  * 2.3 Waktu dan Tempat Pelaksanaan PKMI ............................................................ 15
  * 2.4 Penelitian Terdahulu ........................................................................................ 15
  * 2.5 Tabel Perbandingan Penelitian ........................................................................ 17

---

# BAB I  
# PENDAHULUAN

### 1.1. Latar Belakang
Pengelolaan aset operasional perusahaan merupakan aspek fundamental dalam menunjang efektivitas dan produktivitas proses bisnis di era transformasi digital. Salah satu aset krusial yang menunjang kelancaran mobilitas kerja harian adalah armada kendaraan operasional kantor. Penggunaan kendaraan dinas yang tertib, transparan, dan terdata secara terstruktur menjadi syarat mutlak untuk memastikan kegiatan penanganan insiden, pemeliharaan berkala, hingga penugasan dinas dapat berjalan tepat waktu, aman, dan dapat dipertanggungjawabkan (akuntabel). Namun pada kenyataannya, banyak instansi perkantoran masih mengandalkan mekanisme peminjaman konvensional secara manual, seperti pencatatan di buku logbook fisik, pengisian lembaran formulir kertas, atau koordinasi non-formal melalui aplikasi pesan instan.

Mekanisme manual tersebut memiliki kelemahan mendasar yang berdampak langsung pada inefisiensi manajemen operasional. Pertama, pencatatan manual di atas kertas sangat rentan terhadap risiko kehilangan arsip fisik, kerusakan dokumen, serta kelalaian dalam mencatat data-data penting seperti angka odometer (kilometer pemakaian), identitas peminjam, tujuan perjalanan dinas, serta waktu pengembalian aktual. Kedua, pengawasan terhadap kondisi fisik kendaraan sebelum dan sesudah digunakan kerap tidak terdokumentasi secara objektif, sehingga menyulitkan penelusuran tanggung jawab apabila timbul kerusakan baru, goresan bodi, atau kehilangan perlengkapan kendaraan. Ketiga, pengelolaan kunci kendaraan yang disimpan secara konvensional di meja resepsionis atau pos keamanan tanpa pengamanan terintegrasi membuka celah pengambilan kunci tanpa persetujuan resmi (*unauthorized access*) atau keterlambatan pengembalian kunci fisik yang merugikan pengguna berikutnya.

Kondisi tersebut dirasakan secara langsung pada operasional PT Telkom Akses Wilayah Bogor. Sebagai anak perusahaan PT Telkom Indonesia (Persero) Tbk yang mengelola pembangunan dan pemeliharaan infrastruktur jaringan telekomunikasi pita lebar (*broadband fiber optic*), mobilitas teknisi dan staf operasional di wilayah Kota dan Kabupaten Bogor sangatlah tinggi. Setiap harinya, kendaraan operasional kantor dikerahkan untuk berbagai kegiatan darurat (*emergency recovery* kabel serat optik yang putus), patroli jalur kabel, kunjungan site, supervisi proyek jaringan, hingga distribusi logistik material instalasi. Berdasarkan hasil observasi selama pelaksanaan Praktek Kerja Magang Industri (PKMI), frekuensi permintaan kendaraan dinas mencapai puluhan transaksi setiap minggunya.

Dalam prosedur yang selama ini berjalan, karyawan yang hendak meminjam kendaraan harus mengisi formulir manual, mencari petugas *Person In Charge* (PIC) atau staf Business Support untuk meminta paraf persetujuan (*approval*), mengambil kunci di pos pengawas, serta mencatat angka odometer awal secara manual. Hambatan besar muncul ketika petugas PIC sedang tidak berada di kantor atau sedang bertugas di lapangan, yang mengakibatkan proses persetujuan tertunda dan menghambat percepatan penanganan gangguan jaringan pelanggan. Di sisi lain, pihak PIC dan manajemen tidak memiliki sarana pemantauan *real-time* mengenai posisi geografis kendaraan saat beroperasi di luar kantor, estimasi waktu kepulangan kendaraan, serta kecepatan operasional di jalan raya, sehingga memicu risiko penyalahgunaan kendaraan untuk kepentingan di luar kedinasan.

Perkembangan teknologi informasi, khususnya *Mobile Application*, *Internet of Things* (IoT), dan *Cloud Database*, memberikan peluang besar untuk memecahkan permasalahan tersebut secara holistik. Sistem yang dibangun mengintegrasikan dua sisi peran operasional utama, yaitu **Sisi Peminjam** dan **Sisi PIC (Person In Charge)**:
1. **Sisi Peminjam (Karyawan):** Menggunakan aplikasi *mobile* berbasis framework Flutter yang dapat diakses langsung melalui *smartphone* Android. Melalui aplikasi ini, karyawan dapat mengecek ketersediaan armada mobil secara *real-time*, mengisi formulir peminjaman terstruktur (tujuan, lokasi tugas, jadwal, dan KM awal), melakukan verifikasi identitas menggunakan teknologi *Face Verification*, mengunggah foto angka odometer fisik, serta mengakses kunci fisik kendaraan melalui pemindaian kode QR (*QR Code Scanner*) pada lemari penyimpanan pintar (*Smart Locker*). Saat mengembalikan kendaraan, peminjam diwajibkan mengunggah foto fisik kendaraan dari empat sisi (depan, belakang, sisi kanan, dan sisi kiri) serta foto odometer akhir untuk menjamin transparansi kondisi fisik kendaraan.
2. **Sisi PIC / Pengawas:** Dilengkapi dasbor persetujuan digital (*approval system*) untuk meninjau berkas peminjaman, foto wajah peminjam, odometer awal, dan tujuan tugas secara instan, serta memberikan keputusan ACC (menyetujui) atau menolak peminjaman kapan pun dan di mana pun. Selain itu, untuk menjawab kebutuhan pelacakan armada di jalan raya, dirancang perangkat keras IoT bernama **SIMDANGPS**. Perangkat ini terpasang di kendaraan operasional, menggabungkan mikrokontroler ESP32, modul pemosisian satelit *Global Positioning System* (GPS) untuk mendeteksi koordinat (latitude, longitude, speed), serta modul komunikasi seluler GSM/GPRS SIM800L.
3. **Integrasi Cloud Backend (Supabase):** Seluruh data telemetri lokasi dari SIMDANGPS dikirimkan secara langsung dan periodik (interval 15 detik) melalui koneksi internet HTTPS/REST API langsung menuju basis data *cloud* **Supabase** tanpa melalui perantara (*middleware*) pihak ketiga. Supabase menyediakan basis data PostgreSQL yang andal, penyimpanan awan (*Storage Bucket*) untuk foto bukti peminjaman, sistem otentikasi aman berbasis peran (*Role-Based Access Control*), serta fitur sinkronisasi *Realtime* yang memungkinkan PIC memantau pergerakan armada secara langsung (*live tracking*) di atas peta digital interaktif.

Melalui integrasi menyeluruh antara aplikasi *mobile* peminjam, sistem persetujuan PIC, perangkat telemetri IoT SIMDANGPS, dan *Smart Locker* berbasis Supabase ini, pengelolaan kendaraan dinas di PT Telkom Akses Bogor dapat bertransformasi menjadi sistem digital yang aman, transparan, cepat, dan akuntabel. Oleh karena itu, penulis menyusun laporan magang ini dengan judul: **"SISTEM MONITORING DAN PEMINJAMAN KENDARAAN OPERASIONAL BERBASIS MOBILE APPLICATION DAN IOT GPS TRACKING (SIMDANGPS) TERINTEGRASI SUPABASE (STUDI KASUS: PT. TELKOM AKSES BOGOR)"**.

---

### 1.2. Tujuan Praktek Kerja Magang Industri
Adapun tujuan dari pelaksanaan Praktek Kerja Magang Industri (PKMI) ini adalah:
1. Merancang dan membangun antarmuka aplikasi *mobile* berbasis Flutter untuk Sisi Peminjam yang memfasilitasi pemantauan ketersediaan mobil, pengisian formulir peminjaman, verifikasi biometrik wajah, dan pemindaian kode QR loker kunci.
2. Mengembangkan mekanisme audit fisik kendaraan secara digital pada modul pengembalian (*Return Screen*) yang mewajibkan dokumentasi foto 4 sisi kendaraan dan foto angka odometer akhir guna memastikan transparansi kondisi armada.
3. Merancang dan mengimplementasikan sistem *approval* digital untuk Sisi PIC (*Person In Charge*) agar dapat meninjau, memverifikasi, dan menyetujui (ACC) atau menolak permohonan peminjaman secara *real-time*.
4. Merancang dan mengimplementasikan perangkat keras IoT **SIMDANGPS** menggunakan mikrokontroler ESP32, modul GPS, dan modul seluler SIM800L yang terpasang pada kendaraan operasional untuk mengambil data koordinat dan kecepatan kendaraan.
5. Mengintegrasikan aliran data telemetri SIMDANGPS langsung ke basis data *cloud* Supabase secara *real-time* melalui protokol HTTPS/REST API tanpa perantara pihak ketiga, sehingga pergerakan armada dapat dipantau langsung pada peta digital oleh PIC.
6. Menerapkan integrasi sistem keamanan fisik pengambilan dan pengembalian kunci menggunakan *Smart Locker* berbasis pemindaian kode QR.

---

### 1.3. Ruang Lingkup Praktek Kerja Magang Industri
Ruang lingkup dan batasan masalah dalam perancangan sistem ini mencakup:
a. **Sisi Pengguna (Peminjam):**
   - Aplikasi dibangun untuk platform *mobile* Android menggunakan framework Flutter dan bahasa pemrograman Dart.
   - Otentikasi pengguna menggunakan akun terdaftar di Supabase Auth (ID Karyawan / Email dan Kata Sandi) dilengkapi opsi *Remember Me*.
   - Fitur katalog armada menampilkan status kendaraan secara *real-time* (*Available*, *In Use*, dan *Pending Approval*).
   - Pengisian formulir peminjaman mencakup: nama mobil, nomor pelat, tujuan dinas, lokasi penugasan, tanggal & jam keberangkatan, serta angka odometer awal.
   - Fitur verifikasi ganda: *Face Verification* (pengambilan foto wajah peminjam langsung melalui kamera) dan unggah foto angka odometer fisik.
   - Pemindaian kode QR (*QR Scanner*) pada kompartemen loker fisik (*Smart Locker*) untuk validasi pengambilan kunci setelah status pemesanan disetujui (ACC).
   - Modul pengembalian kendaraan (*Return Screen*) dengan kewajiban melampirkan 4 foto bodi kendaraan (depan, belakang, samping kanan, samping kiri), foto odometer akhir, input KM akhir, dan scan QR penutupan loker kunci.
b. **Sisi Pengawas / PIC (Person In Charge):**
   - Dasbor persetujuan (*approval system*) untuk memeriksa rincian data peminjam, foto wajah peminjam, tujuan penugasan, dan angka odometer awal.
   - Mekanisme persetujuan: tombol ACC yang otomatis mengubah status booking menjadi `active` dan mengizinkan pembukaan loker, serta tombol Tolak (*reject*) disertai catatan revisi/alasan.
   - Antarmuka pemantauan langsung (*live tracking*) armada yang menampilkan penanda lokasi kendaraan (*marker*), status bergerak/berhenti, dan kecepatan laju kendaraan di atas peta digital.
   - Verifikasi pengembalian: pengecekan kelayakan foto 4 sisi bodi kendaraan dan penghitungan selisih jarak tempuh (kilometer pemakaian) sebelum status peminjaman diubah menjadi `completed`.
c. **Sisi Perangkat Keras IoT (SIMDANGPS) dan Smart Locker:**
   - Perangkat IoT SIMDANGPS terdiri dari mikrokontroler ESP32, modul penerima sinyal satelit GPS, dan modul seluler GSM/GPRS SIM800L yang dilengkapi kartu SIM aktif dengan paket data seluler.
   - ESP32 diprogram untuk mengekstraksi data koordinat lintang (*latitude*), bujur (*longitude*), dan kecepatan (*speed*) dari kalimat NMEA, mengemas data dalam format JSON payload, dan mengirimkannya secara berkala (interval 15 detik) via protokol HTTPS POST langsung ke REST API Supabase.
   - Pengujian perangkat IoT difokuskan pada armada mobil operasional PT Telkom Akses di wilayah Bogor yang memiliki jangkauan sinyal jaringan seluler.
   - Sistem *Smart Locker* menggunakan simulasi kode QR unik pada loker fisik yang divalidasi dengan status transaksi di basis data untuk mengontrol kunci solenoid.
d. **Sisi Backend dan Basis Data:**
   - Menggunakan layanan *cloud* Supabase yang mencakup basis data relasional PostgreSQL, Supabase Auth untuk manajemen sesi dan token JWT, Supabase Storage Bucket untuk penyimpanan berkas citra (foto wajah, odometer, dan foto 4 sisi mobil), serta Supabase Realtime Engine.
   - Transmisi data dari aplikasi klien dan perangkat IoT mikrokontroler terhubung secara langsung (*direct API communication*) ke Supabase tanpa menggunakan perantara pihak ketiga seperti Make.com.

---

### 1.4. Manfaat
Pengembangan sistem monitoring dan peminjaman kendaraan operasional ini memberikan manfaat konkret sebagai berikut:

**a. Bagi PT Telkom Akses Bogor:**
1. Mengubah tata kelola administrasi armada kantor dari sistem manual berbasis kertas menjadi sistem digital terpusat (*paperless*) yang terstruktur dan aman.
2. Memudahkan PIC dalam melakukan verifikasi dan pemberian persetujuan (ACC) peminjaman kendaraan secara cepat tanpa terhambat keberadaan fisik di kantor.
3. Meningkatkan keamanan dan visibilitas aset perusahaan melalui pelacakan lokasi kendaraan secara *real-time* via modul GPS tracking.
4. Meminimalisasi risiko penyalahgunaan fasilitas kendaraan dinas di luar kepentingan kedinasan resmi perusahaan.
5. Menjamin transparansi dan akuntabilitas pemeliharaan kendaraan melalui arsip digital kondisi fisik 4 sisi bodi dan riwayat kilometer odometer yang tersimpan di *cloud storage*.

**b. Bagi Karyawan (Peminjam):**
1. Mempermudah pengecekan ketersediaan armada mobil secara mandiri melalui *smartphone* sebelum mengajukan perjalanan dinas.
2. Mempercepat proses birokrasi peminjaman kendaraan terutama pada situasi penanganan gangguan jaringan darurat (*emergency recovery*).
3. Memberikan kepastian pengambilan dan pengembalian kunci kendaraan secara tertib melalui loker pintar berotentikasi kode QR.

**c. Bagi Penulis / Mahasiswa:**
1. Menerapkan dan mengembangkan kompetensi akademik di bidang Manajemen Informatika, khususnya pemrograman aplikasi bergerak (*mobile programming* Flutter), arsitektur basis data relasional *cloud*, integrasi sistem *Internet of Things* (IoT), serta analisis proses bisnis sistem informasi.
2. Memperoleh pengalaman praktis dalam menganalisis permasalahan operasional riil di industri telekomunikasi nasional dan menghadirkan solusi teknologi yang tepat guna.
3. Melatih kemampuan pemecahan masalah (*problem solving*), perancangan sistem informasi terintegrasi, dan penyusunan laporan ilmiah sesuai kaidah akademik.

---

# BAB II  
# TINJAUAN INSTANSI DAN PUSTAKA

### 2.1. Tinjauan Instansi

#### 2.1.1. Sejarah Instansi
PT Telkom Akses (PTTA) didirikan secara resmi pada tanggal 12 Desember 2012 sebagai anak perusahaan strategis dari PT Telekomunikasi Indonesia (Persero) Tbk (Telkom Indonesia). Pembentukan PT Telkom Akses dilandasi oleh kebutuhan percepatan pembangunan, modernisasi, dan perluasan infrastruktur jaringan telekomunikasi pita lebar (*broadband*) berbasis kabel serat optik (*Fiber to the Home* / FTTH) di seluruh Nusantara. Telkom Akses mengemban misi penting sebagai tulang punggung Telkom Group dalam menghadirkan konektivitas digital yang handal, cepat, dan merata.

Pada tahun 2013, PT Telkom Akses mulai mengoperasikan proyek berskala masif berupa *New Development Infrastructure* dan *Managed Service Sentral Telepon Otomat* (STO) Mandiri, serta melaksanakan pembersihan infrastruktur tembaga lama (*dismantling*) untuk dimodernisasi menjadi kabel serat optik. Pada tahun yang sama, kapasitas keandalan teknis Telkom Akses terbukti sukses dalam mengawal infrastruktur jaringan telekomunikasi pada perhelatan tingkat internasional Konferensi Tingkat Tinggi (KTT) APEC 2013 di Nusa Dua, Bali.

Memasuki tahun 2014, Telkom Akses memegang peran vital dalam menjamin stabilitas telekomunikasi nasional selama momentum Pemilihan Umum 2014 dan berhasil mencatatkan pendapatan perusahaan sebesar Rp2,4 triliun. Pada tahun 2015, seiring pesatnya adopsi layanan IndiHome, jumlah pelanggan serat optik yang dikelola melampaui angka 1 juta pelanggan. Pada tahun yang sama, Telkom Akses turut mendukung kesuksesan infrastruktur telekomunikasi Konferensi Tingkat Tinggi Asia Afrika (KAA) ke-60 di Bandung. Pada tahun 2016, jumlah pelanggan IndiHome meningkat signifikan menjadi 1,6 juta, dan Telkom Akses secara resmi ditetapkan sebagai penyedia utama layanan pembangunan dan pemeliharaan jaringan bagi seluruh unit bisnis di naungan Telkom Group.

Pada tahun 2017, jumlah pelanggan serat optik melonjak hingga 2,9 juta sambungan. Di tahun ini, Telkom Akses mencatat prestasi internasional dengan meraih dua nominasi di ajang *Broadband World Forum* 2017, serta mendirikan akademi keahlian serat optik (*Fiber Academy*) untuk menggembleng kompetensi dan keselamatan kerja teknisi lapangan. Pada tahun 2018, dengan basis pelanggan mencapai 5,1 juta, Telkom Akses sukses mengawal keandalan jaringan pada ajang bergengsi Asian Games Jakarta-Palembang, Asian Para Games, serta Pertemuan Tahunan IMF-World Bank di Bali. Telkom Akses juga berada di garis terdepan dalam misi kemanusiaan tanggap bencana untuk pemulihan jaringan telekomunikasi pascagempa dan tsunami di Lombok, Palu-Donggala, serta Banten.

Pertumbuhan berkelanjutan berlanjut hingga tahun 2019 dengan jumlah pelanggan IndiHome mencapai 7 juta sambungan. Telkom Akses merealisasikan proyek modernisasi jaringan di berbagai kota besar di Indonesia seperti Jakarta, Bandung, Medan, Surabaya, dan Bogor, termasuk meresmikan proyek inovatif "STO Modern". Pada tahun 2020, di tengah tantangan pandemi COVID-19, Telkom Akses melayani lebih dari 8 juta pelanggan untuk mendukung aktivitas belajar dan bekerja dari rumah, penanganan bencana badai Seroja di NTT, gempa Mamuju, serta pengamanan konektivitas ajang PON XX di Papua.

Pada tahun 2021, PT Telkom Akses mencatatkan pendapatan tertinggi sepanjang sejarah berdirinya perusahaan, yaitu sebesar Rp8,7 triliun. Di tahun yang sama, perusahaan berperan aktif mendukung instalasi infrastruktur digital di Rumah Sakit Darurat Wisma Atlet Jakarta. Tahun 2022 menandai lompatan baru dengan peningkatan pelanggan menjadi 9,4 juta sambungan, serta pengawalan jaringan pada gelaran dunia MotoGP Mandalika dan KTT G20 di Bali.

Sejak tahun 2023 hingga saat ini, PT Telkom Akses terus mengukuhkan posisinya sebagai mitra strategis infrastruktur telekomunikasi terdepan di Indonesia. Perusahaan sukses mengawal jaringan pada KTT ASEAN di Labuan Bajo dan Jakarta, KTT AIS Forum, serta Piala Dunia FIFA U-17. Komitmen terhadap tata kelola perusahaan yang unggul dibuktikan dengan raihan Peringkat Emas pada SNI Awards serta penghargaan TOP GRC Awards. Di wilayah Jawa Barat, **PT Telkom Akses Wilayah Bogor** memegang peranan krusial dalam mengelola dan memelihara ribuan kilometer jaringan kabel serat optik, perangkat *Optical Distribution Cabinet* (ODC), *Optical Distribution Point* (ODP), serta ratusan ribu sambungan pelanggan di seluruh area Kota dan Kabupaten Bogor.

#### 2.1.2. Visi dan Misi Instansi
Dalam menjalankan perannya, PT Telkom Akses memiliki visi dan misi yang menjadi pedoman fundamental bagi segenap manajemen dan karyawannya:

**Visi:**  
*“Menjadi Mitra Strategis Pilihan Telekomunikasi di Indonesia untuk Memajukan Masyarakat”*

**Misi:**  
1. Mempercepat pembangunan infrastruktur digital dan pengelolaan layanan telekomunikasi yang berkualitas tinggi, handal, dan berdaya saing global.
2. Mengorkestrasikan ekosistem infrastruktur digital secara terpadu demi menghadirkan pengalaman pelanggan (*customer experience*) yang unggul dan memuaskan.
3. Mengembangkan talenta digital yang unggul, berkarakter, dan berintegritas serta membangun kapabilitas teknologi baru untuk memberikan nilai tambah terbaik bagi seluruh pemangku kepentingan (*stakeholders*).

#### 2.1.3. Struktur Organisasi Instansi
Operasional PT Telkom Akses Kantor Wilayah Bogor dipimpin oleh seorang *General Manager* (GM) yang membawahi sejumlah unit fungsional strategis untuk memastikan kegiatan pemeliharaan jaringan (*assurance*), konstruksi dan pasang baru (*provisioning*), serta unit pendukung operasional (*shared services*) dapat berjalan secara terkoordinasi dan selaras.

Struktur fungsional di PT Telkom Akses Bogor terdiri dari:
1. **General Manager (GM) Telkom Akses Bogor:** Pimpinan tertinggi yang menetapkan kebijakan strategis, pengawasan performa indikator kinerja utama (KPI), keselamatan kerja (K3), serta pencapaian target operasional wilayah Bogor.
2. **Manager Shared Service:** Membawahi administrasi perkantoran, tata kelola keuangan, pengelolaan sumber daya manusia, pengadaan sarana (*procurement*), serta manajemen aset fasilitas dan armada kendaraan dinas kantor.
3. **Officer Business Support:** Bertanggung jawab langsung atas administrasi surat-menyurat kedinasan, verifikasi pengajuan operasional, reimbursement perjalanan dinas, serta pengelolaan izin fasilitas kantor.
4. **Officer Fiber Academy:** Unit yang fokus pada pembinaan kompetensi teknis karyawan dan mitra kerja, standardisasi instalasi serat optik, dan kepatuhan keselamatan kerja lapangan.
5. **Officer Commerce & Supply Chain:** Mengelola logistik material instalasi telekomunikasi (kabel serat optik, ONT, splitter, perangkat pasif), inventaris gudang, serta administrasi mitra kerja lapangan.
6. **Unit Operasi dan Pemeliharaan (Assurance & Maintenance):** Divisi teknis lapangan yang bertugas menangani tiket perbaikan gangguan jaringan pelanggan (*troubleshooting*), pemeliharaan rutin jaringan kabel, dan mobilisasi cepat yang memerlukan armada kendaraan dinas.

```
       +--------------------------------------------------------+
       |             GENERAL MANAGER TELKOM AKSES BOGOR         |
       +--------------------------------------------------------+
                                   |
         +-------------------------+--------------------------+
         |                                                    |
+------------------------------------+        +-------------------------------+
|       MANAGER SHARED SERVICE       |        |   MANAGER OPERATION & ACCESS  |
+------------------------------------+        +-------------------------------+
         |                                                    |
         +--> Officer Business Support                        +--> Tim Assurance
         +--> Officer Fiber Academy                           +--> Tim Maintenance
         +--> Staff Commerce & Support                        +--> Tim Provisioning
         +--> Staff Procurement & Fleet
```

#### 2.1.4. Dokumentasi PKMI
Pelaksanaan kegiatan Praktek Kerja Magang Industri (PKMI) di PT Telkom Akses Bogor mencakup rangkaian interaksi langsung dengan unit kerja terkait. Kegiatan yang dilakukan meliputi pengenalan lingkungan dan tata tertib kerja instansi, studi observasi alur administrasi peminjaman armada, wawancara kendala operasional bersama staf Business Support dan PIC lapangan, perakitan dan pemrograman mikrokontroler IoT SIMDANGPS, pembuatan skema basis data di Supabase, hingga tahap pengujian fungsional aplikasi *mobile* bersama karyawan.

---

### 2.2. Tinjauan Pustaka

#### 2.2.1. Sistem Informasi Manajemen Armada (*Fleet Management System*)
Sistem Manajemen Armada (*Fleet Management System*) adalah sistem informasi terintegrasi yang memadukan teknologi perangkat lunak dan perangkat keras untuk mengoordinasikan, memantau, dan mengelola operasional kendaraan dinas secara komprehensif (Al-Taee et al., 2021). Penerapan sistem informasi manajemen armada pada instansi modern memisahkan fungsi operasional secara tegas ke dalam dua peran:
1. **Sisi Peminjam (*Requester*):** Memerlukan akses cepat untuk mengetahui status ketersediaan armada, mengajukan permohonan peminjaman secara terstruktur, memvalidasi identitas, dan melaporkan kondisi serah terima kendaraan.
2. **Sisi PIC (*Person In Charge / Approver*):** Bertindak sebagai pengawas aset yang berwenang meninjau kelayakan pengajuan, memberikan keputusan persetujuan (*approval*), memantau rute dan pergerakan armada secara *real-time*, serta memastikan aset kembali dalam kondisi prima.

Penerapan sistem informasi armada terbukti mampu mengeliminasi tumpang tindih jadwal penggunaan mobil, menekan risiko penyalahgunaan aset kantor, menghemat konsumsi bahan bakar, dan menciptakan tata kelola aset yang akuntabel (Pratama & Sukmana, 2023).

#### 2.2.2. Aplikasi Mobile dan Framework Flutter
Aplikasi *mobile* merupakan program perangkat lunak yang dirancang khusus untuk berjalan pada perangkat bergerak seperti *smartphone* dan tablet komputer. Flutter adalah *framework open-source* antarmuka pengguna (*UI toolkit*) yang dikembangkan oleh Google untuk membangun aplikasi yang dikompilasi secara *native* lintas platform (*cross-platform*) untuk Android, iOS, web, dan desktop hanya dari satu basis kode sumber tunggal (*single codebase*) (Windarta et al., 2024). 

Flutter menggunakan bahasa pemrograman Dart yang menerapkan kompilasi *Ahead-of-Time* (AOT) langsung ke kode mesin asli perangkat, sehingga memberikan performa render grafis yang stabil pada 60 hingga 120 *frames per second* (fps). Seluruh elemen antarmuka pada Flutter dibangun berbasis *widget*, memberikan fleksibilitas tinggi dalam perancangan desain antarmuka modern, interaktif, dan responsif. Dalam pengembangan aplikasi ini, Flutter dimanfaatkan untuk membangun antarmuka peminjaman, integrasi kamera untuk verifikasi wajah (*image_picker*), pemindaian kode QR loker (*mobile_scanner*), dan visualisasi peta pelacakan GPS.

#### 2.2.3. Platform Backend-as-a-Service (BaaS) Supabase dan PostgreSQL
Supabase adalah platform *Backend-as-a-Service* (BaaS) berbasis sumber terbuka (*open-source*) yang dirancang untuk menyediakan seluruh infrastruktur *backend* modern yang dibutuhkan oleh pengembang aplikasi (Raharjo & Setiawan, 2024). Keunggulan utama Supabase dibandingkan platform BaaS NoSQL konvensional adalah fondasi mesin basis datanya yang menggunakan **PostgreSQL**, salah satu sistem manajemen basis data relasional (RDBMS) kelas industri paling tangguh di dunia.

Layanan inti Supabase yang digunakan dalam sistem ini mencakup:
1. **Supabase Database (PostgreSQL):** Menyediakan skema relasional terstruktur dengan dukungan relasi *foreign key*, transaksi ACID, serta penyimpanan data koordinat lokasi.
2. **Supabase Authentication:** Menyediakan sistem otentikasi pengguna yang aman berbasis *JSON Web Tokens* (JWT), pengelolaan sesi, serta penerapan kontrol akses berbasis peran (*Role-Based Access Control* / RBAC) yang memisahkan hak akses peminjam biasa dengan PIC/Admin.
3. **Row-Level Security (RLS):** Kebijakan pengamanan data pada tingkat baris tabel di mana pengguna hanya memiliki otorisasi untuk melihat atau mengubah baris data miliknya, sedangkan PIC memiliki hak istimewa untuk meng-ACC transaksi dan memantau seluruh armada.
4. **Supabase Storage:** Wadah penyimpanan objek awan (*cloud bucket*) untuk menyimpan berkas citra digital berukuran besar secara terorganisasi, meliputi foto swafoto peminjam, foto odometer awal/akhir, dan foto dokumentasi 4 sisi kendaraan.
5. **Supabase Realtime:** Memanfaatkan protokol *WebSockets* untuk menyiarkan setiap perubahan data tabel (kejadian `INSERT`, `UPDATE`, `DELETE`) secara instan ke aplikasi klien tanpa perlu melakukan *polling* terus-menerus.

#### 2.2.4. Internet of Things (IoT) dan Mikrokontroler ESP32
*Internet of Things* (IoT) adalah paradigma teknologi di mana objek fisik di sekitar manusia disematkan komponen sensor, aktuator, mikrokontroler, dan konektivitas nirkabel untuk mengumpulkan dan mentransmisikan data secara mandiri melalui jaringan internet (Triyanto et al., 2023). Dalam perancangan modul pelacak armada SIMDANGPS, mikrokontroler utama yang dipilih adalah **ESP32**.

ESP32 merupakan modul mikrokontroler *System-on-Chip* (SoC) berkemampuan tinggi dan berbiaya efisien buatan Espressif Systems. ESP32 dilengkapi prosesor ganda (*dual-core*) Xtensa 32-bit LX6 dengan kecepatan frekuensi hingga 240 MHz, memori internal SRAM sebesar 520 KB, memori Flash eksternal 4 MB, serta konektivitas nirkabel Wi-Fi 802.11 b/g/n dan Bluetooth v4.2 terintegrasi. ESP32 memiliki beragam saluran komunikasi serial (UART, SPI, I2C) yang memungkinkan mikrokontroler berkomunikasi secara simultan dengan modul sensor GPS dan modul komunikasi seluler SIM800L.

#### 2.2.5. Modul Global Positioning System (GPS)
*Global Positioning System* (GPS) adalah sistem navigasi berbasis satelit yang dioperasikan untuk menyediakan informasi koordinat geografis tiga dimensi (garis lintang/latitude, garis bujur/longitude, dan ketinggian/altitude), kecepatan (*speed*), serta waktu global (*Universal Time Coordinated* / UTC) secara akurat di seluruh dunia tanpa dipengaruhi kondisi cuaca (Saputra & Wibowo, 2022).

Modul GPS yang digunakan (seperti seri u-blox NEO-6M) menerima sinyal radio dari minimal empat satelit GPS di orbit bumi untuk menghitung posisi kendaraan secara presisi menggunakan metode triangulasi. Data hasil kalkulasi posisi ditransmisikan ke pin UART mikrokontroler ESP32 dalam format standar internasional NMEA-0183 (terutama baris kalimat `$GPRMC` dan `$GPGGA`). Mikrokontroler kemudian melakukan proses pembedahan (*parsing*) teks NMEA menjadi nilai numerik desimal lintang, bujur, dan kecepatan dalam satuan km/jam sebelum dibungkus ke dalam format JSON.

#### 2.2.6. Modul Komunikasi Seluler GSM/GPRS SIM800L
Untuk memastikan data posisi kendaraan yang berada di jalan raya dapat dikirimkan ke server basis data *cloud* di luar jangkauan Wi-Fi kantor, diperlukan media transmisi nirkabel seluler. Modul **SIM800L** adalah modul seluler berukuran miniatur yang mendukung jaringan GSM/GPRS pada frekuensi quad-band (850/900/1800/1900 MHz) (Hidayat et al., 2023).

Modul SIM800L dikendalikan oleh mikrokontroler ESP32 menggunakan serangkaian instruksi *AT Commands* melalui komunikasi serial UART. Modul ini memiliki tumpukan protokol TCP/IP internal yang mendukung protokol HTTP dan HTTPS (SSL/TLS). Mikrokontroler ESP32 mengirimkan perintah AT untuk mengaktifkan koneksi paket data GPRS melalui APN penyedia seluler, membuka koneksi HTTPS aman, menyertakan kunci otentikasi (*API Key/Bearer Token*) Supabase pada *header* permintaan, dan mengirimkan koordinat lokasi kendaraan melalui metode `POST` langsung ke *endpoint* tabel basis data Supabase tanpa perantara pihak ketiga (*without third-party middleware*).

#### 2.2.7. Sistem Keamanan Smart Locker Berbasis QR Code
Sistem serah terima kunci fisik merupakan titik rawan dalam pengelolaan armada kantor. *Smart Locker* (Loker Kunci Pintar) adalah kompartemen penyimpanan fisik yang diamankan menggunakan mekanisme pengunci elektronik (*solenoid door lock*) yang dikendalikan secara terpadu melalui mikrokontroler dan sistem informasi (Nugroho et al., 2024).

Metode otentikasi yang digunakan adalah **Quick Response (QR) Code**, yaitu simbol barcode dua dimensi yang mampu menyimpan data alfanumerik dalam kerapatan tinggi serta memiliki fitur koreksi kesalahan (*error correction*). Setiap loker fisik memiliki kode QR identitas unik. Peminjam yang telah mendapatkan persetujuan (ACC) dari PIC dapat memindai kode QR tersebut menggunakan kamera aplikasi *mobile*. Sistem kemudian mencocokkan kode QR dengan data transaksi aktif di Supabase. Apabila status transaksi valid dan telah disetujui, sistem akan memicu relai atau mikrokontroler loker untuk membuka kunci solenoid, sehingga peminjam dapat mengambil kunci kendaraan dengan aman.

#### 2.2.8. Verifikasi Wajah Biometrik dan Inspeksi Citra Digital Kendaraan
Untuk mencegah peminjaman oleh pihak yang tidak sah atau peminjaman yang mengatasnamakan karyawan lain (*account sharing* / peminjaman fiktif), sistem menerapkan teknologi pengenalan biometrik wajah (*Face Verification*). Pengenalan wajah bekerja dengan menangkap swafoto wajah peminjam secara *real-time*, memindai titik-titik kontur wajah, dan memvalidasinya terhadap citra profil karyawan yang tersimpan di sistem (Kusuma et al., 2023).

Selain validasi identitas, integritas fisik kendaraan dijaga melalui inspeksi citra visual digital. Sebelum kendaraan digunakan dan sesaat setelah kendaraan dikembalikan, peminjam wajib mengambil foto kondisi fisik kendaraan dari empat sudut utama: tampak depan, belakang, samping kanan, dan samping kiri, disertai foto angka odometer pada dasbor. Berkas citra ini dikompresi dan diunggah langsung ke wadah *Supabase Storage*, menciptakan jejak audit digital (*digital audit trail*) permanen yang memudahkan PIC untuk mendeteksi apabila terjadi insiden, benturan, atau goresan baru pada bodi mobil selama masa peminjaman.

---

### 2.3. Waktu dan Tempat Pelaksanaan PKMI
Pelaksanaan kegiatan Praktek Kerja Magang Industri (PKMI) bertempat di:

- **Instansi Mitra:** PT Telkom Akses Wilayah Bogor
- **Alamat:** Jl. Pengadilan No. 14, RT 03/RW 01, Kelurahan Pabaton, Kecamatan Bogor Tengah, Kota Bogor, Jawa Barat 16121.
- **Waktu Pelaksanaan:** Dilaksanakan selama 3 (tiga) bulan penuh, terhitung mulai tanggal **1 September 2025 sampai dengan 1 Desember 2025**.
- **Jam Operasional Kerja:** Hari Senin hingga Jumat, pukul 08.00 WIB sampai dengan 17.00 WIB.

---

### 2.4. Penelitian Terdahulu
Dalam penyusunan sistem ini, dikaji empat penelitian terdahulu yang relevan sebagai landasan teoretis dan acuan komparasi sistem:

1. **Penelitian 1 (Kusuma & Arifin, 2023):**  
   *Judul:* "Rancang Bangun Sistem Monitoring Posisi Kendaraan Dinas Menggunakan GPS Tracker Berbasis ESP32 dan Protokol MQTT".  
   *Peneliti:* Kusuma, D. A., & Arifin, Z. (2023).  
   *Uraian:* Merancang prototipe pelacak lokasi kendaraan dinas menggunakan modul ESP32 dan GPS Neo-6M yang mengirim data koordinat ke broker server MQTT lokal untuk divisualisasikan pada antarmuka web. Hasil pengujian menunjukkan rata-rata waktu tunda transmisi data sebesar 2,4 detik. Namun penelitian ini belum memiliki alur peminjaman armada, verifikasi biometrik peminjam, maupun modul penyimpanan kondisi fisik kendaraan.

2. **Penelitian 2 (Pratama & Sukmana, 2023):**  
   *Judul:* "Pengembangan Sistem Informasi Peminjaman Kendaraan Operasional Kantor Berbasis Framework Flutter dan Firebase Firestore".  
   *Peneliti:* Pratama, R. Y., & Sukmana, H. T. (2023).  
   *Uraian:* Mengembangkan aplikasi *mobile* peminjaman kendaraan berbasis Flutter dengan basis data NoSQL Firebase Firestore. Aplikasi memfasilitasi pemilihan armada, jadwal peminjaman, dan persetujuan admin. Kelemahannya adalah belum terintegrasi dengan perangkat keras pelacak GPS fisik pada kendaraan, tidak ada pengamanan loker kunci fisik, serta verifikasi kondisi mobil hanya mengandalkan teks tanpa bukti foto visual 4 sisi.

3. **Penelitian 3 (Setiawan et al., 2024):**  
   *Judul:* "Implementasi Smart Key Locker Menggunakan QR Code dan Mikrokontroler Berbasis IoT untuk Pengelolaan Aset Otomotif".  
   *Peneliti:* Setiawan, B., Nugraha, F., & Hidayat, T. (2024).  
   *Uraian:* Merancang lemari kunci pintar berbasis mikrokontroler Arduino dan pemindai barcode untuk mengamankan kunci mobil kantor. Solenoid kunci berhasil terbuka dalam waktu 1,2 detik setelah kode QR divalidasi. Namun, sistem masih bersifat *standalone* dengan basis data lokal tanpa sinkronisasi basis data *cloud*, dan tidak terhubung dengan sistem pemantauan pergerakan kendaraan di lapangan.

4. **Penelitian 4 (Wahyudi & Marlina, 2024):**  
   *Judul:* "Sistem Pemantauan Armada dan Manajemen Perjalanan Dinas Berbasis REST API Supabase dan IoT SIM800L".  
   *Peneliti:* Wahyudi, I., & Marlina, S. (2024).  
   *Uraian:* Meneliti keandalan pengiriman koordinat kendaraan dari mikrokontroler dan modul SIM800L langsung menuju REST API Supabase PostgreSQL melalui jalur HTTPS. Hasilnya membuktikan penghematan kuota data seluler hingga 35% dibandingkan penggunaan layanan pihak ketiga (*third-party webhook*), dengan reliabilitas penyimpanan 99,2%. Namun penelitian ini belum merancang aplikasi peminjam, sistem verifikasi wajah, dan sistem persetujuan PIC.

---

### 2.5. Tabel Perbandingan Penelitian
Berdasarkan tinjauan penelitian terdahulu, disusun tabel perbandingan untuk memperlihatkan kebaruan (*novelty*), keunggulan, dan cakupan komprehensif dari sistem yang dibangun oleh penulis:

**Tabel 1. Perbandingan Penelitian Terdahulu dengan Sistem yang Dikembangkan**

| No | Peneliti & Tahun | Platform Antarmuka | Basis Data | Perangkat IoT / Hardware | Modul GPS & Seluler | Fitur Approval PIC | Fitur Verifikasi (Wajah & QR Locker) | Dokumentasi Foto 4 Sisi & Odo | Jalur Komunikasi Data |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Kusuma & Arifin (2023) | Website | MySQL | ESP32 | Modul GPS (Neo-6M) & Wi-Fi | Tidak Ada | Tidak Ada | Tidak Ada | Broker MQTT |
| 2 | Pratama & Sukmana (2023) | Mobile App (Flutter) | Firebase Firestore (NoSQL) | Tidak Ada | Tidak Ada | Ada (Dasbor Admin) | Tidak Ada | Tidak Ada (Hanya catatan teks) | REST API Firebase |
| 3 | Setiawan et al. (2024) | Desktop / Standalone | SQLite Lokal | Arduino Uno | Tidak Ada | Tidak Ada | Ada (QR Code Offline) | Tidak Ada | Komunikasi Serial Lokal |
| 4 | Wahyudi & Marlina (2024) | Website Monitoring | Supabase (PostgreSQL) | ESP32 | GPS & SIM800L | Tidak Ada | Tidak Ada | Tidak Ada | Direct HTTPS ke Supabase |
| 5 | **Maulana Akbar (2026 - Penulis)** | **Mobile App (Flutter) untuk Peminjam & PIC Dashboard** | **Supabase (PostgreSQL Relational + Realtime + Storage Bucket)** | **ESP32 Microcontroller + Smart Locker Solenoid** | **GPS Module + GSM/GPRS SIM800L (SIMDANGPS)** | **Ada (Review Berkas, Foto Wajah, ACC/Tolak Realtime)** | **Lengkap (Verifikasi Wajah Biometrik & Scan QR Smart Locker)** | **Lengkap (Foto 4 Sisi Kendaraan + Foto Odometer Awal & Akhir)** | **Direct HTTPS ke Supabase (Tanpa Make.com / Pihak Ketiga)** |

---

*Laporan Magang Industri — BAB I dan BAB II disusun untuk memenuhi persyaratan kurikulum Program Studi DIII Manajemen Informatika Sekolah Vokasi Universitas Pakuan Bogor.*

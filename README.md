# 🛍️ Smart Shopping

![Banner](assets/images/banner.png)

**Smart Shopping** adalah aplikasi asisten belanja cerdas yang dirancang untuk membantu Anda mengelola daftar belanja dengan lebih efisien, teratur, dan hemat. Dengan desain **Premium Pastel** yang elegan dan antarmuka yang sangat minimalis, aplikasi ini memberikan pengalaman pengguna yang menyenangkan dan profesional.

---

## ✨ Fitur Utama

### 📋 Manajemen Daftar Belanja
- **Kategorisasi Cerdas**: Kelompokkan belanjaan Anda berdasarkan kategori (Kebutuhan Pokok, Elektronik, Pakaian, dll) dengan ikon yang menarik.
- **Validasi Real-time**: Input barang yang responsif dengan deteksi error instan.
- **Multi-List**: Buat beberapa daftar belanja sekaligus untuk berbagai kebutuhan.

### 💰 Pelacak Anggaran & Harga
- **Format Mata Uang Premium**: Penulisan nominal otomatis menggunakan format Rupiah (Rp) dengan pemisah ribuan (titik) yang memudahkan pembacaan.
- **Budget Tracking**: Pantau sisa anggaran bulanan Anda secara *real-time* saat berbelanja.

### 🛠️ Fitur Cerdas (Smart Tools)
- **Kalkulator Diskon**: Hitung harga akhir barang diskon dalam hitungan detik.
- **Pembanding Harga**: Bandingkan dua produk dengan ukuran berbeda untuk menemukan harga termurah per unit.
- **Ekspor Laporan**: Unduh riwayat belanja Anda ke dalam format **PDF** untuk arsip atau dibagikan.

---

## 📸 Tampilan Aplikasi

![Mockups](assets/images/mockups.png)

---

## 🚀 Teknologi yang Digunakan

Aplikasi ini dibangun menggunakan teknologi terkini untuk menjamin performa dan stabilitas:

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.11.3)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Database Lokal**: [Hive](https://docs.hivedb.dev/) (NoSQL for super-fast storage)
- **PDF Generation**: [pdf](https://pub.dev/packages/pdf)
- **Export & Sharing**: [share_plus](https://pub.dev/packages/share_plus)
- **Fonts**: [Google Fonts - Itim](https://fonts.google.com/specimen/Itim)

---

## 🛠️ Instalasi

1. **Clone Repository**
   ```bash
   git clone https://github.com/MuhammadIsakiPrananda1/smart-shopping.git
   ```

2. **Dapatkan Dependensi**
   ```bash
   flutter pub get
   ```

3. **Jalankan Build Runner** (Untuk generate adapter Hive)
   ```bash
   flutter pub run build_runner build
   ```

4. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

---

## 🛡️ Kebijakan & Keamanan

Untuk informasi lebih mendalam mengenai kebijakan proyek kami, silakan cek dokumen berikut:
- [Kebijakan Keamanan (Security Policy)](SECURITY.md)
- [Panduan Kontribusi (Contributing)](CONTRIBUTING.md)
- [Kode Etik (Code of Conduct)](CODE_OF_CONDUCT.md)

---

## 📄 Lisensi

Proyek ini menggunakan lisensi **MIT**. Detail lengkap dapat ditemukan di file [LICENSE](LICENSE).

---

**Dibuat Oleh [Muhammad Isaki Prananda](https://github.com/MuhammadIsakiPrananda1)**

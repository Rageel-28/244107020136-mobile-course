class Mahasiswa {
  String nama;
  String kelas;
  int umur;

  Mahasiswa({required this.nama, required this.umur, required this.kelas});

  // Method untuk mengisi nama
  void setNama(String namaBaru) {
    nama = namaBaru;
  }

  // Method untuk mengisi umur
  void setUmur(int umurBaru) {
    umur = umurBaru;
  }

  // Method untuk mengisi kelas
  void setKelas(String kelasBaru) {
    kelas = kelasBaru;
  }

  // Method untuk menampilkan informasi mahasiswa
  String tampilkanInfo() {
    return 'Nama: $nama | Umur: $umur tahun | Kelas: $kelas';
  }

  @override
  String toString() {
    return tampilkanInfo();
  }
}

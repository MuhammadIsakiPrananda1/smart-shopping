class CategoryDetector {
  static const Map<String, List<String>> _categoryKeywords = {
    'Dapur': [
      'beras', 'minyak', 'gula', 'garam', 'telur', 'bumbu', 'kecap', 'saus', 'pasta',
      'sayur', 'buah', 'roti', 'susu', 'mentega', 'sereal', 'kopi', 'teh', 'bawang',
      'cabai', 'daging', 'ayam', 'ikan', 'mie', 'nasi', 'tepung', 'keju', 'yogurt'
    ],
    'Kamar Mandi': [
      'sabun', 'sampo', 'shampoo', 'odol', 'sikat', 'handuk', 'tisu', 'lulur',
      'conditioner', 'pembersih', 'deterjen', 'pewangi', 'shampoo', 'parfum',
      'pemutih', 'softener'
    ],
    'Elektronik': [
      'baterai', 'kabel', 'charger', 'lampu', 'remote', 'colokan', 'headset',
      'mouse', 'keyboard'
    ],
    'Kesehatan': [
      'obat', 'masker', 'vitamin', 'plester', 'alkohol', 'kasa', 'betadine'
    ],
  };

  static String detect(String itemName) {
    if (itemName.isEmpty) return 'Lainnya';
    
    final lowerItem = itemName.toLowerCase();
    
    for (var entry in _categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (lowerItem.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return 'Lainnya';
  }
}

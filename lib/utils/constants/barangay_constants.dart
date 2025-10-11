class LocationConstants {
  // Tagbilaran City Barangays (capital of Bohol)
  static const List<String> tagbilaranBarangays = [
    'Bool',
    'Booy',
    'Cabawan',
    'Cogon',
    'Dampas',
    'Dao',
    'Manga',
    'Mansasa',
    'Poblacion I',
    'Poblacion II',
    'Poblacion III',
    'San Isidro',
    'Taloto',
    'Tiptip',
    'Ubujan',
  ];

  static const List<String> balilihanBarangays = [
    'Baucan Norte',
    'Baucan Sur',
    'Boctol',
    'Boyog Norte',
    'Boyog Proper',
    'Boyog Sur',
    'Cabad',
    'Candasig',
    'Cantalid',
    'Cantomimbo',
    'Cogon',
    'Datag Norte',
    'Datag Sur',
    'Del Carmen Este (DCE) (Poblacion)',
    'Del Carmen Norte (DCN) (Poblacion)',
    'Del Carmen Sur (DCS) (Poblacion)',
    'Del Carmen Weste (DCW) (Poblacion)',
    'Del Rosario',
    'Dorol',
    'Haguilanan Grande',
    'Hanopol Este',
    'Hanopol Norte',
    'Hanopol Weste',
    'Magsija',
    'Maslog',
    'Sagasa',
    'Sal‑ing',
    'San Isidro',
    'San Roque',
    'Santo Niño',
    'Tagustusan',
  ];

  // All Bohol Municipalities and City
  static const List<String> boholMunicipalities = [
    'Tagbilaran',
    'Balilihan',
    // Add the rest of the municipalities here
    'Alburquerque',
    'Alicia',
    'Anda',
    'Antequera',
    'Baclayon',
    'Batuan',
    'Bien Unido',
    'Bilar',
    'Buenavista',
    'Calape',
    'Candijay',
    'Carmen',
    'Catigbian',
    'Clarin',
    'Corella',
    'Cortes',
    'Dagohoy',
    'Danao',
    'Dauis',
    'Dimiao',
    'Duero',
    'Garcia Hernandez',
    'Getafe',
    'Guindulman',
    'Inabanga',
    'Jagna',
    'Lila',
    'Loay',
    'Loboc',
    'Loon',
    'Mabini',
    'Maribojoc',
    'Panglao',
    'Pilar',
    'President Carlos P. Garcia',
    'Sagbayan',
    'San Isidro',
    'San Miguel',
    'Sevilla',
    'Sierra Bullones',
    'Sikatuna',
    'Talibon',
    'Trinidad',
    'Tubigon',
    'Ubay',
    'Valencia',
  ];

  // Map municipality name to its barangay list
  static const Map<String, List<String>> municipalityBarangays = {
    'Tagbilaran': tagbilaranBarangays,
    'Balilihan': balilihanBarangays,
    // Add more mappings as needed:
    // 'Alburquerque': alburquerqueBarangays,
    // 'Alicia': aliciaBarangays,
    // ...
  };

  // Get all municipalities sorted alphabetically
  static List<String> getSortedMunicipalities() {
    final municipalities = boholMunicipalities.toSet().toList();
    municipalities.sort();
    return municipalities;
  }

  // Get barangays for a given municipality, sorted alphabetically
  static List<String> getBarangaysForMunicipality(String municipality) {
    final barangays = municipalityBarangays[municipality] ?? [];
    final sortedBarangays = barangays.toList()..sort();
    return sortedBarangays;
  }
}
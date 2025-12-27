class MockData {
  MockData._();
  
  static List<Map<String, dynamic>> getMockFiles() {
    return [
      {'name': 'File_1.zip', 'size': 26713907, 'date': DateTime.now().subtract(Duration(days: 120))},
      {'name': 'File_2.wav', 'size': 13107200, 'date': DateTime.now().subtract(Duration(days: 90))},
      {'name': 'File_3.heic', 'size': 25389568, 'date': DateTime.now().subtract(Duration(days: 60))},
      {'name': 'File_4.dat', 'size': 20185088, 'date': DateTime.now().subtract(Duration(days: 12))},
      {'name': 'File_5.aac', 'size': 3774873, 'date': DateTime.now().subtract(Duration(days: 60))},
      {'name': 'File_6.jpg', 'size': 7340032, 'date': DateTime.now().subtract(Duration(days: 16))},
      {'name': 'File_7.mov', 'size': 154927104, 'date': DateTime.now().subtract(Duration(days: 29))},
    ];
  }
  
  static List<double> getMockChartData() {
    return [120, 118, 122, 119, 121, 126, 128];
  }
}
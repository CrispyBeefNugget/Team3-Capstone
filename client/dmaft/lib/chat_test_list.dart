class ChatTestList {
  static List<String> _testList = [
    'Arthur Ayala',
    'Giovanna Pritchett',
    'Alexus Jeter',
    'Jett Cotter',
  ];

  static void addToList(String name) {
    _testList.add(name);
  }
  
  static int getSize() {
    return _testList.length;
  }

  static List<String> getList() {
    return _testList;
  }

  static void removeFromList(String name) {
    if (_testList.contains(name)) {
      _testList.remove(name);
    }
  }
}
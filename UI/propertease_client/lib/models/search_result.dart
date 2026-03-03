class SearchResult<T> {
  int count = 0;
  T operator [](int index) {
    return result[index];
  }

  List<T> result = [];
}

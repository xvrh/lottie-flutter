/// Returns a position of the [value] in [sortedList], if it is there.
///
/// If the list isn't sorted according to the [compare] function, the result
/// is unpredictable.
///
/// If [compare] is omitted, this defaults to calling [Comparable.compareTo] on
/// the objects. In this case, the objects must be [Comparable].
///
/// Returns -1 if [value] is not in the list.
int binarySearch<E>(List<E> sortedList, E value,
    {int Function(E, E)? compare}) {
  compare ??= defaultCompare;
  return binarySearchBy<E, E>(sortedList, identity, compare, value);
}

/// Returns a position of the [value] in [sortedList], if it is there.
///
/// If the list isn't sorted according to the [compare] function on the [keyOf]
/// property of the elements, the result is unpredictable.
///
/// Returns -1 if [value] is not in the list by default.
///
/// If [start] and [end] are supplied, only that range is searched,
/// and only that range need to be sorted.
int binarySearchBy<E, K>(List<E> sortedList, K Function(E element) keyOf,
    int Function(K, K) compare, E value,
    [int start = 0, int? end]) {
  end = RangeError.checkValidRange(start, end, sortedList.length);
  var min = start;
  var max = end;
  var key = keyOf(value);
  while (min < max) {
    var mid = min + ((max - min) >> 1);
    var element = sortedList[mid];
    var comp = compare(keyOf(element), key);
    if (comp == 0) return mid;
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return -1;
}

/// A [Comparator] that asserts that its first argument is comparable.
///
/// The function behaves just like [List.sort]'s
/// default comparison function. It is entirely dynamic in its testing.
///
/// Should be used when optimistically comparing object that are assumed
/// to be comparable.
/// If the elements are known to be comparable, use [compareComparable].
int defaultCompare(Object? value1, Object? value2) =>
    (value1! as Comparable<Object?>).compareTo(value2);

/// A reusable identity function at any type.
T identity<T>(T value) => value;

/// A reusable typed comparable comparator.
int compareComparable<T extends Comparable<T>>(T a, T b) => a.compareTo(b);

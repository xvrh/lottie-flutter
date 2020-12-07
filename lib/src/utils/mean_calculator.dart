class MeanCalculator {
  double _sum = 0;
  int _n = 0;

  double get mean => _n == 0 ? 0 : _sum / _n;

  void add(double number) {
    _sum += number;
    _n++;
  }
}

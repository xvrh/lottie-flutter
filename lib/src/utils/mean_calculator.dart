class MeanCalculator {
  double _sum;
  int _n;

  double get mean => _n == 0 ? 0 : _sum / _n;

  void add(double number) {
    _sum += number;
    _n++;
  }
}

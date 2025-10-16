class HistoricalPrice {
  final DateTime timestamp;
  final double price;

  const HistoricalPrice({required this.timestamp, required this.price});

  factory HistoricalPrice.fromJson(List<dynamic> json) {
    return HistoricalPrice(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json[0] as int),
      price: (json[1] as num).toDouble(),
    );
  }
}

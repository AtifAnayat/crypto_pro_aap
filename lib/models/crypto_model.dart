class CryptoCurrency {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double priceChange24h;
  final double priceChangePercentage24h;
  final double marketCap;
  final int marketCapRank;
  final double totalVolume;
  final List<double> sparklineIn7d;
  final double high24h;
  final double low24h;
  final double circulatingSupply;

  const CryptoCurrency({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChange24h,
    required this.priceChangePercentage24h,
    required this.marketCap,
    required this.marketCapRank,
    required this.totalVolume,
    required this.sparklineIn7d,
    this.high24h = 0,
    this.low24h = 0,
    this.circulatingSupply = 0,
  });

  factory CryptoCurrency.fromJson(Map<String, dynamic> json) {
    return CryptoCurrency(
      id: json['id'] as String? ?? '',
      symbol: (json['symbol'] as String?)?.toUpperCase() ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      priceChange24h: (json['price_change_24h'] as num?)?.toDouble() ?? 0,
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
      marketCap: (json['market_cap'] as num?)?.toDouble() ?? 0,
      marketCapRank: json['market_cap_rank'] as int? ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
      sparklineIn7d: List<double>.from(
        (json['sparkline_in_7d']?['price'] as List<dynamic>?)?.map(
              (x) => (x as num).toDouble(),
            ) ??
            [],
      ),
      high24h: (json['high_24h'] as num?)?.toDouble() ?? 0,
      low24h: (json['low_24h'] as num?)?.toDouble() ?? 0,
      circulatingSupply: (json['circulating_supply'] as num?)?.toDouble() ?? 0,
    );
  }

  String get formattedPrice =>
      '\$${currentPrice.toStringAsFixed(currentPrice < 1 ? 6 : 2)}';
  String get formattedMarketCap => _formatLargeNumber(marketCap);
  String get formattedVolume => _formatLargeNumber(totalVolume);
  String get formattedHigh24h =>
      '\$${high24h.toStringAsFixed(currentPrice < 1 ? 6 : 2)}';
  String get formattedLow24h =>
      '\$${low24h.toStringAsFixed(currentPrice < 1 ? 6 : 2)}';
  String get formattedSupply =>
      _formatLargeNumber(circulatingSupply, isDollar: false);

  String _formatLargeNumber(double number, {bool isDollar = true}) {
    String prefix = isDollar ? '\$' : '';
    if (number >= 1e12) {
      return '$prefix${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '$prefix${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '$prefix${(number / 1e6).toStringAsFixed(2)}M';
    } else if (number >= 1e3) {
      return '$prefix${(number / 1e3).toStringAsFixed(2)}K';
    } else {
      return '$prefix${number.toStringAsFixed(2)}';
    }
  }
}

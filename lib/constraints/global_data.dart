class GlobalCryptoData {
  final double totalMarketCap;
  final double totalVolume;
  final double btcDominance;
  final double marketCapChange24h;

  const GlobalCryptoData({
    required this.totalMarketCap,
    required this.totalVolume,
    required this.btcDominance,
    required this.marketCapChange24h,
  });

  factory GlobalCryptoData.fromJson(Map<String, dynamic> json) {
    return GlobalCryptoData(
      totalMarketCap:
          (json['total_market_cap']?['usd'] as num?)?.toDouble() ?? 0,
      totalVolume: (json['total_volume']?['usd'] as num?)?.toDouble() ?? 0,
      btcDominance:
          (json['market_cap_percentage']?['btc'] as num?)?.toDouble() ?? 0,
      marketCapChange24h:
          (json['market_cap_change_percentage_24h_usd'] as num?)?.toDouble() ??
          0,
    );
  }

  String get formattedMarketCap => _formatLargeNumber(totalMarketCap);
  String get formattedVolume => _formatLargeNumber(totalVolume);
  String get formattedBtcDominance => '${btcDominance.toStringAsFixed(1)}%';
  String get formattedMarketChange =>
      '${marketCapChange24h >= 0 ? '+' : ''}${marketCapChange24h.toStringAsFixed(1)}%';

  static String _formatLargeNumber(double number) {
    if (number >= 1e12) {
      return '\$${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '\$${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '\$${(number / 1e6).toStringAsFixed(2)}M';
    } else if (number >= 1e3) {
      return '\$${(number / 1e3).toStringAsFixed(2)}K';
    } else {
      return '\$${number.toStringAsFixed(2)}';
    }
  }
}

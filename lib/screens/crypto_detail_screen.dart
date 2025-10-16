import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constraints/theme.dart';
import '../models/crypto_model.dart';
import '../provider/provider.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoCurrency crypto;

  const CryptoDetailScreen({Key? key, required this.crypto}) : super(key: key);

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  final List<String> timeframes = ['1h', '24h', '7d', '30d', '1y'];

  @override
  void initState() {
    super.initState();
    Provider.of<CryptoProvider>(
      context,
      listen: false,
    ).fetchHistoricalData(widget.crypto.id, '24h');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.crypto.name),
        backgroundColor: AppTheme.backgroundDark,
        actions: [
          Consumer<CryptoProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.isFavorite(widget.crypto.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: provider.isFavorite(widget.crypto.id)
                      ? AppTheme.accent
                      : Colors.white,
                ),
                onPressed: () => provider.toggleFavorite(widget.crypto.id),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundDark,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildChart(),
            _buildTimeframeSelector(),
            _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(widget.crypto.image),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) =>
                    const AssetImage('assets/placeholder.png'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.crypto.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.crypto.symbol,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.crypto.formattedPrice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.crypto.priceChangePercentage24h >= 0
                      ? AppTheme.accent.withOpacity(0.2)
                      : AppTheme.accentRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.crypto.priceChangePercentage24h >= 0 ? '+' : ''}${widget.crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: widget.crypto.priceChangePercentage24h >= 0
                        ? AppTheme.accent
                        : AppTheme.accentRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingChart) {
          return Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
          );
        }
        if (provider.error.isNotEmpty) {
          return _buildErrorWidget(provider.error);
        }
        if (provider.historicalData.isEmpty) {
          return Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'No chart data available',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          );
        }

        // Calculate min and max prices for better y-axis scaling
        final prices = provider.historicalData.map((e) => e.price).toList();
        final minPrice = prices.reduce(math.min);
        final maxPrice = prices.reduce(math.max);
        final priceRange = maxPrice - minPrice;
        final padding = priceRange * 0.1; // 10% padding for better visuals
        final minY = minPrice - padding;
        final maxY = maxPrice + padding;

        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: priceRange / 5, // Dynamic interval
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: priceRange / 5, // Dynamic interval for y-axis
                    getTitlesWidget: (value, meta) {
                      if (value < 0) return const Text('');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '\$${value.toStringAsFixed(widget.crypto.currentPrice < 1 ? 6 : 2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: provider.historicalData.length / 5,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 &&
                          index < provider.historicalData.length) {
                        final date = provider.historicalData[index].timestamp;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatDate(date, provider.selectedTimeframe),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: provider.historicalData
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.price))
                      .toList(),
                  isCurved: true,
                  color: widget.crypto.priceChangePercentage24h >= 0
                      ? AppTheme.accent
                      : AppTheme.accentRed,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        (widget.crypto.priceChangePercentage24h >= 0
                                ? AppTheme.accent
                                : AppTheme.accentRed)
                            .withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: AppTheme.cardDark,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      if (touchedSpot.spotIndex >= 0 &&
                          touchedSpot.spotIndex <
                              provider.historicalData.length) {
                        final date = provider
                            .historicalData[touchedSpot.spotIndex]
                            .timestamp;
                        return LineTooltipItem(
                          '\$${touchedSpot.y.toStringAsFixed(widget.crypto.currentPrice < 1 ? 6 : 2)}\n${_formatDate(date, provider.selectedTimeframe)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
                touchCallback: (event, touchResponse) {
                  if (touchResponse?.lineBarSpots != null) {
                    final index = touchResponse!.lineBarSpots!.length;
                    if (index >= 0 && index < provider.historicalData.length) {
                      provider.setHoveredData(
                        provider.historicalData[index].price,
                        provider.historicalData[index].timestamp,
                      );
                    }
                  } else {
                    provider.setHoveredData(null, null);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date, String timeframe) {
    switch (timeframe) {
      case '1h':
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      case '24h':
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      case '7d':
        return '${date.day}/${date.month}';
      case '30d':
        return '${date.day}/${date.month}';
      case '1y':
        return '${date.month}/${date.year}';
      default:
        return '${date.day}/${date.month}';
    }
  }

  Widget _buildTimeframeSelector() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: timeframes.map((timeframe) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(timeframe),
                  selected: provider.selectedTimeframe == timeframe,
                  selectedColor: AppTheme.primaryBlue,
                  backgroundColor: AppTheme.surfaceDark,
                  labelStyle: TextStyle(
                    color: provider.selectedTimeframe == timeframe
                        ? Colors.white
                        : Colors.white70,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      provider.fetchHistoricalData(widget.crypto.id, timeframe);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildDetailRow('Market Cap', widget.crypto.formattedMarketCap),
                _buildDetailRow('24h Volume', widget.crypto.formattedVolume),
                _buildDetailRow('24h High', widget.crypto.formattedHigh24h),
                _buildDetailRow('24h Low', widget.crypto.formattedLow24h),
                _buildDetailRow(
                  'Circulating Supply',
                  widget.crypto.formattedSupply,
                ),
                _buildDetailRow(
                  'Market Cap Rank',
                  '#${widget.crypto.marketCapRank}',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.white.withOpacity(0.1), height: 1),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.accentRed,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Error loading chart: $error',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Provider.of<CryptoProvider>(
                    context,
                    listen: false,
                  ).fetchHistoricalData(
                    widget.crypto.id,
                    Provider.of<CryptoProvider>(
                      context,
                      listen: false,
                    ).selectedTimeframe,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

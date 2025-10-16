import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constraints/global_data.dart';
import '../constraints/historical_prices.dart';
import '../models/crypto_model.dart';
import '../services/crpto_services.dart';

class CryptoProvider with ChangeNotifier {
  final List<CryptoCurrency> _cryptocurrencies = [];
  final List<HistoricalPrice> _historicalData = [];
  GlobalCryptoData? _globalData;
  bool _isLoading = true;
  bool _isLoadingChart = false;
  bool _isLoadingGlobal = true;
  String _error = '';
  WebSocketChannel? _channel;
  Timer? _refreshTimer;
  String _selectedTimeframe = '24h';
  double? _hoveredPrice;
  DateTime? _hoveredTime;
  String _searchQuery = '';
  final Set<String> _favorites = {};
  String _sortBy = 'marketCap';
  bool _isDisposed = false;

  List<CryptoCurrency> get cryptocurrencies =>
      List.unmodifiable(_cryptocurrencies);
  List<HistoricalPrice> get historicalData =>
      List.unmodifiable(_historicalData);
  GlobalCryptoData? get globalData => _globalData;
  bool get isLoading => _isLoading;
  bool get isLoadingChart => _isLoadingChart;
  bool get isLoadingGlobal => _isLoadingGlobal;
  String get error => _error;
  String get selectedTimeframe => _selectedTimeframe;
  double? get hoveredPrice => _hoveredPrice;
  DateTime? get hoveredTime => _hoveredTime;
  String get searchQuery => _searchQuery;
  Set<String> get favorites => Set.unmodifiable(_favorites);
  String get sortBy => _sortBy;

  List<CryptoCurrency> get filteredCryptocurrencies {
    var list = _searchQuery.isEmpty
        ? _cryptocurrencies
        : _cryptocurrencies
              .where(
                (c) =>
                    c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    c.symbol.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    if (_sortBy == 'price') {
      list.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
    } else if (_sortBy == 'change') {
      list.sort(
        (a, b) =>
            b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h),
      );
    } else {
      list.sort((a, b) => b.marketCap.compareTo(a.marketCap));
    }
    return list;
  }

  List<CryptoCurrency> get favoriteCryptocurrencies =>
      _cryptocurrencies.where((c) => _favorites.contains(c.id)).toList();

  bool isFavorite(String id) => _favorites.contains(id);

  CryptoProvider() {
    _initializeData();
    _setupWebSocket();
    _setupAutoRefresh();
  }

  void setHoveredData(double? price, DateTime? time) {
    _hoveredPrice = price;
    _hoveredTime = time;
    _safeNotifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _safeNotifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _safeNotifyListeners();
  }

  void toggleFavorite(String id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    _safeNotifyListeners();
  }

  Future<void> _initializeData() async {
    await fetchGlobalData();
    await fetchCryptoData();
  }

  void _setupWebSocket() {
    try {
      _channel?.sink.close();
      _channel = CryptoService.connectToWebSocket();
      _channel!.stream.listen(
        _handleWebSocketData,
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: () => _reconnectWebSocket(),
      );
    } catch (e) {
      debugPrint('Failed to setup WebSocket: $e');
      _reconnectWebSocket();
    }
  }

  void _handleWebSocketData(dynamic data) {
    try {
      final Map<String, dynamic> priceData = json.decode(data);

      for (int i = 0; i < _cryptocurrencies.length; i++) {
        final crypto = _cryptocurrencies[i];
        final coinKey = crypto.id.toLowerCase();

        if (priceData.containsKey(coinKey)) {
          final newPriceString = priceData[coinKey]?.toString();
          if (newPriceString == null) continue;

          try {
            final newPrice = double.parse(newPriceString);
            final oldPrice = crypto.currentPrice;
            final priceChange = newPrice - oldPrice;
            double priceChangePercentage = oldPrice != 0
                ? (priceChange / oldPrice) * 100
                : 0;

            _cryptocurrencies[i] = CryptoCurrency(
              id: crypto.id,
              symbol: crypto.symbol,
              name: crypto.name,
              image: crypto.image,
              currentPrice: newPrice,
              priceChange24h: priceChange,
              priceChangePercentage24h: priceChangePercentage,
              marketCap: crypto.marketCap,
              marketCapRank: crypto.marketCapRank,
              totalVolume: crypto.totalVolume,
              sparklineIn7d: crypto.sparklineIn7d,
              high24h: math.max(crypto.high24h, newPrice),
              low24h: math.min(crypto.low24h, newPrice),
              circulatingSupply: crypto.circulatingSupply,
            );
          } catch (e) {
            debugPrint('Error parsing price for ${crypto.id}: $e');
          }
        }
      }

      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error processing WebSocket data: $e');
    }
  }

  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        _setupWebSocket();
      }
    });
  }

  void _setupAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!_isDisposed) {
        await fetchGlobalData();
        await fetchCryptoData();
      }
    });
  }

  Future<void> fetchGlobalData() async {
    if (_isDisposed) return;

    try {
      _isLoadingGlobal = true;
      _safeNotifyListeners();
      _globalData = await CryptoService.fetchGlobalData();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingGlobal = false;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchCryptoData() async {
    if (_isDisposed) return;

    try {
      _error = '';
      _isLoading = true;
      _safeNotifyListeners();
      final data = await CryptoService.fetchCryptoData();
      _cryptocurrencies.clear();
      _cryptocurrencies.addAll(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchHistoricalData(String coinId, String timeframe) async {
    if (_isDisposed) return;

    _isLoadingChart = true;
    _selectedTimeframe = timeframe;
    _safeNotifyListeners();

    try {
      final int days = _getDaysForTimeframe(timeframe);
      final data = await CryptoService.fetchHistoricalData(coinId, days);
      _historicalData.clear();
      _historicalData.addAll(data);
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingChart = false;
      _safeNotifyListeners();
    }
  }

  int _getDaysForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1h':
        return 1;
      case '24h':
        return 1;
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '1y':
        return 365;
      default:
        return 7;
    }
  }

  Future<void> refreshData() async {
    await fetchGlobalData();
    await fetchCryptoData();
  }

  void _safeNotifyListeners() {
    if (_isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _channel?.sink.close();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

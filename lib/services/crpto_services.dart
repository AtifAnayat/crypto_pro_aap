import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constraints/global_data.dart';
import '../constraints/historical_prices.dart';
import '../models/crypto_model.dart';

class CryptoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const String _wsUrl =
      'wss://ws.coincap.io/prices?assets=bitcoin,ethereum,binancecoin,cardano,solana,ripple,polkadot,dogecoin,litecoin,chainlink';

  // Helper method for exponential backoff
  static Future<void> _delayWithBackoff(
    int attempt, {
    int maxDelay = 10000,
  }) async {
    final delay = math.min(1000 * math.pow(2, attempt).toInt(), maxDelay);
    await Future.delayed(Duration(milliseconds: delay));
  }

  static Future<List<CryptoCurrency>> fetchCryptoData({
    int page = 1,
    int perPage = 50,
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse(
                '$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=$perPage&page=$page&sparkline=true&price_change_percentage=24h',
              ),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data.map((json) => CryptoCurrency.fromJson(json)).toList();
        } else if (response.statusCode == 429) {
          final retryAfter = response.headers['retry-after'];
          final delaySeconds = int.tryParse(retryAfter ?? '5') ?? 5;
          debugPrint('429 Error: Retrying after $delaySeconds seconds');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        } else {
          throw Exception('Failed to load crypto data: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching crypto data (attempt ${attempt + 1}): $e');
        if (attempt < maxRetries - 1) {
          await _delayWithBackoff(attempt);
          continue;
        }
        throw Exception('Network error after $maxRetries retries: $e');
      }
    }
    throw Exception('Failed to fetch crypto data after $maxRetries retries');
  }

  static Future<GlobalCryptoData> fetchGlobalData({int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/global'))
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body)['data'];
          return GlobalCryptoData.fromJson(data);
        } else if (response.statusCode == 429) {
          final retryAfter = response.headers['retry-after'];
          final delaySeconds = int.tryParse(retryAfter ?? '5') ?? 5;
          debugPrint('429 Error: Retrying after $delaySeconds seconds');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        } else {
          throw Exception('Failed to load global data: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching global data (attempt ${attempt + 1}): $e');
        if (attempt < maxRetries - 1) {
          await _delayWithBackoff(attempt);
          continue;
        }
        throw Exception('Network error after $maxRetries retries: $e');
      }
    }
    throw Exception('Failed to fetch global data after $maxRetries retries');
  }

  static Future<List<HistoricalPrice>> fetchHistoricalData(
    String coinId,
    int days, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse(
                '$_baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days',
              ),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> prices = data['prices'] ?? [];
          if (prices.isEmpty) {
            throw Exception('No historical data available');
          }
          return prices
              .map((price) => HistoricalPrice.fromJson(price))
              .toList();
        } else if (response.statusCode == 429) {
          final retryAfter = response.headers['retry-after'];
          final delaySeconds = int.tryParse(retryAfter ?? '5') ?? 5;
          debugPrint('429 Error: Retrying after $delaySeconds seconds');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        } else {
          throw Exception(
            'Failed to load historical data: ${response.statusCode}',
          );
        }
      } catch (e) {
        debugPrint(
          'Error fetching historical data for $coinId (attempt ${attempt + 1}): $e',
        );
        if (attempt < maxRetries - 1) {
          await _delayWithBackoff(attempt);
          continue;
        }
        throw Exception('Network error after $maxRetries retries: $e');
      }
    }
    throw Exception(
      'Failed to fetch historical data after $maxRetries retries',
    );
  }

  static WebSocketChannel connectToWebSocket() {
    return WebSocketChannel.connect(Uri.parse(_wsUrl));
  }
}

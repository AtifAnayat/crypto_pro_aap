import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constraints/mini_chart_painter.dart';
import '../constraints/theme.dart';
import '../models/crypto_model.dart';
import '../provider/provider.dart';
import 'crypto_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
          ).createShader(bounds),
          child: const Text(
            'Crypto Live',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            Provider.of<CryptoProvider>(context, listen: false).refreshData(),
        color: AppTheme.primaryBlue,
        backgroundColor: AppTheme.cardDark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(
              child: Consumer<CryptoProvider>(
                builder: (context, provider, child) =>
                    _buildMarketOverview(provider),
              ),
            ),
            SliverToBoxAdapter(child: _buildFavoritesList()),
            SliverToBoxAdapter(child: _buildSortOptions()),
            _buildCryptoList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        onChanged: (value) => Provider.of<CryptoProvider>(
          context,
          listen: false,
        ).setSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Search cryptocurrencies...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white60, size: 28),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildMarketOverview(CryptoProvider provider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: provider.isLoadingGlobal
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                      ),
                    )
                  : provider.globalData == null
                  ? _buildErrorWidget(provider.error)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Market Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildMarketStat(
                              'Total Market Cap',
                              provider.globalData!.formattedMarketCap,
                              Icons.trending_up,
                            ),
                            const SizedBox(width: 12),
                            _buildMarketStat(
                              '24h Volume',
                              provider.globalData!.formattedVolume,
                              Icons.swap_horiz,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMarketStat(
                              'BTC Dominance',
                              provider.globalData!.formattedBtcDominance,
                              Icons.currency_bitcoin,
                            ),
                            const SizedBox(width: 12),
                            _buildMarketStat(
                              'Market Change',
                              provider.globalData!.formattedMarketChange,
                              Icons.percent,
                              color:
                                  provider.globalData!.marketCapChange24h >= 0
                                  ? AppTheme.accent
                                  : AppTheme.accentRed,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketStat(
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color ?? AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, child) {
        final favorites = provider.favoriteCryptocurrencies;
        if (favorites.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Favorites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final crypto = favorites[index];
                  return _buildFavoriteCard(crypto);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFavoriteCard(CryptoCurrency crypto) {
    return Container(
      width: 160,
      height: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(crypto.image),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) =>
                        const AssetImage('assets/placeholder.png'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  crypto.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Provider.of<CryptoProvider>(
                  context,
                  listen: false,
                ).toggleFavorite(crypto.id),
                child: const Icon(
                  Icons.favorite,
                  color: AppTheme.accent,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            crypto.formattedPrice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
            style: TextStyle(
              color: crypto.priceChangePercentage24h >= 0
                  ? AppTheme.accent
                  : AppTheme.accentRed,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'All Cryptocurrencies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          DropdownButton<String>(
            value: Provider.of<CryptoProvider>(context).sortBy,
            dropdownColor: AppTheme.cardDark,
            icon: const Icon(Icons.sort, color: Colors.white70),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: 'marketCap',
                child: Text(
                  'Market Cap',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem(
                value: 'price',
                child: Text('Price', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'change',
                child: Text(
                  '24h Change',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                Provider.of<CryptoProvider>(
                  context,
                  listen: false,
                ).setSortBy(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoList() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            ),
          );
        }
        if (provider.error.isNotEmpty) {
          return SliverToBoxAdapter(child: _buildErrorWidget(provider.error));
        }
        final cryptos = provider.filteredCryptocurrencies;
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final crypto = cryptos[index];
            return Consumer<CryptoProvider>(
              builder: (context, provider, child) =>
                  _buildCryptoCard(crypto, provider),
            );
          }, childCount: cryptos.length),
        );
      },
    );
  }

  Widget _buildCryptoCard(CryptoCurrency crypto, CryptoProvider provider) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CryptoDetailScreen(crypto: crypto),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(crypto.image),
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
                    crypto.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    crypto.symbol,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              height: 40,
              child: CustomPaint(
                painter: MiniChartPainter(
                  data: crypto.sparklineIn7d,
                  color: crypto.priceChangePercentage24h >= 0
                      ? AppTheme.accent
                      : AppTheme.accentRed,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  crypto.formattedPrice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: crypto.priceChangePercentage24h >= 0
                        ? AppTheme.accent
                        : AppTheme.accentRed,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => provider.toggleFavorite(crypto.id),
              child: Icon(
                provider.isFavorite(crypto.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: provider.isFavorite(crypto.id)
                    ? AppTheme.accent
                    : Colors.white70,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 40),
          const SizedBox(height: 12),
          Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Provider.of<CryptoProvider>(
              context,
              listen: false,
            ).refreshData(),
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
    );
  }
}

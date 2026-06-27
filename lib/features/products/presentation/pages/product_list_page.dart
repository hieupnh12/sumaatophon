import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badges/badges.dart' as badges;
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/product_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/cart_auth_helper.dart';
import '../../../notifications/presentation/notification_helpers.dart';
import '../../../notifications/presentation/widgets/notification_badge_icon.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_product_card.dart';
import 'product_detail_page.dart';
import 'product_search_page.dart';
import '../../../../main.dart';


class ProductListPage extends StatefulWidget {
  final Function()? onOpenCart;

  const ProductListPage({super.key, this.onOpenCart});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedBrand = 'All';

  bool _isFilterExpanded = false;
  double _currentMinPrice = 5000000;
  double _currentMaxPrice = 30000000;
  String _selectedRam = '8GB';
  String _selectedRom = '256GB';

  final List<String> _brandKeys = ['brand_all', 'Apple', 'Samsung', 'Google', 'Xiaomi'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSearchPage() async {
    final query = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: ProductSearchPage(
            initialQuery: _searchController.text,
          ),
        ),
      ),
    );

    if (!mounted || query == null) return;

    _searchController.text = query;
    _onSearchChanged(query);
    setState(() {});
  }

  void _onSearchChanged(String query) {
    context.read<ProductBloc>().add(SearchProductsEvent(query));
  }

  void _onBrandSelected(String brandKey) {
    final brand = brandKey == 'brand_all' ? 'All' : brandKey;
    setState(() {
      _selectedBrand = brand;
    });
    context.read<ProductBloc>().add(FilterProductsEvent(brand: brand));
  }

  String _brandLabel(String brandKey) {
    if (brandKey == 'brand_all') return context.tr('brand_all');
    return brandKey;
  }

  void _toggleFilter() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });
  }

  Widget _buildAdvancedFilter(ThemeData theme, bool isDark) {
    final rams = ['4GB', '8GB', '12GB', '16GB'];
    final roms = ['128GB', '256GB', '512GB', '1TB'];

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isFilterExpanded
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('price_range'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(_currentMinPrice / 1000000).toStringAsFixed(1)} ${context.tr('million')}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('${(_currentMaxPrice / 1000000).toStringAsFixed(1)} ${context.tr('million')}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(_currentMinPrice, _currentMaxPrice),
                    min: 0,
                    max: 50000000,
                    divisions: 50,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _currentMinPrice = values.start;
                        _currentMaxPrice = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr('ram'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rams.map((ram) {
                      final isSelected = _selectedRam == ram;
                      return ChoiceChip(
                        label: Text(ram, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRam = ram);
                        },
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr('rom'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roms.map((rom) {
                      final isSelected = _selectedRom == rom;
                      return ChoiceChip(
                        label: Text(rom, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRom = rom);
                        },
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pageBg = isDark ? AppColors.darkBackground : const Color(0xFFFCF9F8);
    final outlineVariant = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : const Color(0xFFC1C6D5).withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: pageBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFFCF9F8),
            surfaceTintColor: Colors.transparent,
            title: Text(
              'phoneShop',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: theme.colorScheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            actions: [
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDark = themeMode == ThemeMode.dark || 
                      (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
                  return IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      context.read<ThemeCubit>().toggleTheme();
                    },
                  );
                },
              ),
              NotificationBadgeIcon(
                icon: Icons.notifications_none_outlined,
                color: theme.colorScheme.onSurface,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                  if (context.mounted) reloadNotifications(context, silent: true);
                },
              ),
              BlocBuilder<CartBloc, CartState>(
                builder: (context, cartState) {
                  return IconButton(
                    icon: badges.Badge(
                      showBadge: cartState.totalItems > 0,
                      badgeContent: Text(
                        '${cartState.totalItems}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: AppColors.error,
                        padding: EdgeInsets.all(4),
                      ),
                      child: Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.onSurface),
                    ),
                    onPressed: () => openCartWithAuth(context),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: pageBg.withValues(alpha: 0.95),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          readOnly: true,
                          onTap: _openSearchPage,
                          decoration: InputDecoration(
                            hintText: context.tr('search_hint'),
                            hintStyle: TextStyle(
                              color: (isDark ? AppColors.darkTextSecondary : const Color(0xFF414753))
                                  .withValues(alpha: 0.6),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF6F3F2),
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: _isFilterExpanded
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        elevation: _isFilterExpanded ? 0 : 4,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                        child: InkWell(
                          onTap: _toggleFilter,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              _isFilterExpanded ? Icons.close : Icons.tune,
                              color: _isFilterExpanded ? theme.colorScheme.primary : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildAdvancedFilter(theme, isDark),

                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _brandKeys.length,
                    itemBuilder: (context, index) {
                      final brandKey = _brandKeys[index];
                      final brandValue = brandKey == 'brand_all' ? 'All' : brandKey;
                      final isSelected = _selectedBrand == brandValue;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark ? AppColors.darkSurface : const Color(0xFFEAE7E7)),
                          borderRadius: BorderRadius.circular(24),
                          elevation: isSelected ? 2 : 0,
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                          child: InkWell(
                            onTap: () => _onBrandSelected(brandKey),
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Text(
                                _brandLabel(brandKey),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : const Color(0xFF414753)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Product Grid
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const ShimmerProductCard(),
                  ),
                );
              } else if (state is ProductError) {
                return SliverFillRemaining(
                  child: Center(child: Text(state.message)),
                );
              } else if (state is ProductLoaded) {
                if (state.products.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.search_off_rounded, size: 80, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(height: 24),
                          Text(context.tr('not_found_title'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(context.tr('not_found_desc'), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        ],
                      ),
                    ),
                  );
                }
                
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverGrid.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: state.products.length,
                        itemBuilder: (context, index) {
                          final product = state.products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider(
                                    create: (_) => sl<ProductBloc>(),
                                    child: ProductDetailPage(
                                      productId: product.id,
                                      heroImageUrl: product.imageUrl,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (state.hasMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: state.isLoadingMore
                                  ? null
                                  : () {
                                      context
                                          .read<ProductBloc>()
                                          .add(LoadMoreProductsEvent());
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: state.isLoadingMore
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  : Text(
                                      context.tr('product_load_more'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          
          // Extra space at bottom for scrolling past bottom nav
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

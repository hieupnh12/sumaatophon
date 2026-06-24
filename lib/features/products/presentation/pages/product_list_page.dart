import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badges/badges.dart' as badges;
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/product_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_product_card.dart';
import 'product_detail_page.dart';
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

  final List<String> _brands = ['All', 'Apple', 'Samsung', 'Google', 'Xiaomi', 'Sony'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ProductBloc>().add(SearchProductsEvent(query));
  }

  void _onBrandSelected(String brand) {
    setState(() {
      _selectedBrand = brand;
    });
    context.read<ProductBloc>().add(FilterProductsEvent(brand: brand));
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
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.outlineVariant;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isFilterExpanded
          ? Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('price_range'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_currentMinPrice / 1000000).toStringAsFixed(1)} ${context.tr('million')}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(_currentMaxPrice / 1000000).toStringAsFixed(1)} ${context.tr('million')}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(_currentMinPrice, _currentMaxPrice),
                    min: 0,
                    max: 50000000,
                    divisions: 50,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: isDark ? AppColors.darkBorder : AppColors.outlineVariant,
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
                      return _FilterChip(
                        label: ram,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedRam = ram),
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
                      return _FilterChip(
                        label: rom,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedRom = rom),
                      );
                    }).toList(),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBrandChip(String brand, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onBrandSelected(brand),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryDeep
                  : (isDark ? AppColors.darkSurface : AppColors.lightSurfaceHigh),
              borderRadius: BorderRadius.circular(999),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryDeep.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              brand,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceLow = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                Icon(
                  Icons.menu_rounded,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                const SizedBox(width: 8),
                Text(
                  'phoneShop',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: isDark ? AppColors.primary : AppColors.primaryDeep,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDarkMode = themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness == Brightness.dark);
                  return IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
              ),
              BlocBuilder<CartBloc, CartState>(
                builder: (context, cartState) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: badges.Badge(
                        showBadge: cartState.totalItems > 0,
                        position: badges.BadgePosition.topEnd(top: 2, end: 2),
                        badgeContent: Text(
                          '${cartState.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        badgeStyle: const badges.BadgeStyle(
                          badgeColor: AppColors.error,
                          padding: EdgeInsets.all(4),
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CartPage()),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: TextStyle(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                          decoration: InputDecoration(
                            hintText: context.tr('search_hint'),
                            hintStyle: TextStyle(
                              color: (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.onSurfaceVariant)
                                  .withValues(alpha: 0.6),
                            ),
                            filled: true,
                            fillColor: surfaceLow,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.onSurfaceVariant,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryDeep,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: _isFilterExpanded
                            ? AppColors.primaryDeep.withValues(alpha: 0.12)
                            : AppColors.primaryDeep,
                        borderRadius: BorderRadius.circular(12),
                        elevation: _isFilterExpanded ? 0 : 4,
                        shadowColor: AppColors.primaryDeep.withValues(alpha: 0.3),
                        child: InkWell(
                          onTap: _toggleFilter,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              _isFilterExpanded ? Icons.close_rounded : Icons.tune_rounded,
                              color: _isFilterExpanded
                                  ? AppColors.primaryDeep
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAdvancedFilter(theme, isDark),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _brands
                        .map((brand) => _buildBrandChip(
                              brand,
                              _selectedBrand == brand,
                              isDark,
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
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
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 80,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('not_found_title'),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('not_found_desc'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
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
                                child: ProductDetailPage(productId: product.id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryDeep
                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
        ),
      ),
    );
  }
}

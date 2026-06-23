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

  final List<String> _brands = ['All', 'Apple', 'Samsung', 'Google', 'Xiaomi'];

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

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sliver App Bar
          SliverAppBar(
            floating: true,
            title: const Text('phoneShop', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            centerTitle: false,
            actions: [
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDark = themeMode == ThemeMode.dark || 
                      (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
                  return IconButton(
                    icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                    onPressed: () {
                      context.read<ThemeCubit>().toggleTheme();
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
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
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartPage()),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar & Filter & Brands
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Search Bar & Filter Icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: context.tr('search_hint'),
                            prefixIcon: const Icon(Icons.search),
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
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _toggleFilter,
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: _isFilterExpanded ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _isFilterExpanded ? Icons.close_rounded : Icons.tune_rounded, 
                            color: _isFilterExpanded ? theme.colorScheme.primary : Colors.white
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildAdvancedFilter(theme, isDark),

                // Brand Filters
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _brands.length,
                    itemBuilder: (context, index) {
                      final brand = _brands[index];
                      final isSelected = _selectedBrand == brand;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            brand,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) _onBrandSelected(brand);
                          },
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          showCheckmark: false,
                          side: BorderSide.none,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
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
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 6, // Show 6 skeleton items
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
                
                // phần này trả về liền về cho từng product card , tức là lấy id 
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ProductCard(
                        product: product,

                       // sử dụng BlocProvider mới để quản lí lít detail , để không bị lẫn lộn với bloc global trong main.dart đang quản list product ==> nếu sài chung thì detail emit của productDetailloading sẽ làm list cũng đổi state  
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
          
          // Extra space at bottom for scrolling past bottom nav
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_version.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';
import '../../presentation/bloc/product_bloc.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;
  String _selectedColor = '';
  String _selectedRamRom = '';

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadProductByIdEvent(widget.productId));
  }

  Color _resolveDisplayColor(String colorValue) {
    final value = colorValue.trim();
    final hex = value.replaceAll('#', '');
    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(hex)) {
      return Color(int.parse(hex, radix: 16));
    }

    switch (value.toLowerCase()) {
      case 'black':
        return const Color(0xFF000000);
      case 'white':
        return const Color(0xFFFFFFFF);
      case 'blue':
        return const Color(0xFF2196F3);
      case 'red':
        return const Color(0xFFF44336);
      case 'green':
        return const Color(0xFF4CAF50);
      case 'gold':
      case 'yellow':
        return const Color(0xFFFFD700);
      case 'silver':
      case 'gray':
      case 'grey':
        return const Color(0xFFC0C0C0);
      case 'pink':
        return const Color(0xFFE91E63);
      case 'purple':
        return const Color(0xFF9C27B0);
      case 'orange':
        return const Color(0xFFFF9800);
      case 'titanium':
        return const Color(0xFF878681);
      case 'natural':
        return const Color(0xFFE3D5C3);
      default:
        return Colors.blueGrey;
    }
  }

  ProductVersion? _selectedVersion(Product product) {
    if (product.versions.isEmpty) return null;
    return product.findVersion(color: _selectedColor, ramRom: _selectedRamRom);
  }

  void _addSelectedToCart(BuildContext context, Product product) {
    final version = _selectedVersion(product);
    if (version == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('product_version_unavailable'))),
      );
      return;
    }
    if (!version.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('product_version_out_of_stock'))),
      );
      return;
    }
    context.read<CartBloc>().add(AddToCartEvent(product, version));
  }





  //phần này là phần hiển thị chi tiết sản phẩm (UI của detail page)
  @override
  Widget build(BuildContext context) {
     //dùng BlocBuilder để hiển thị chi tiết sản phẩm dùng để cho biết trạng thái loading và error 
    return BlocBuilder<ProductBloc, ProductState>(
    //builder ở đây là hàm xây dựng UI từ state tương ứng
    builder: (context, state) {
      if (state is ProductDetailLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (state is ProductDetailError) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(state.message)),
        );
      }
      if (state is ProductDetailLoaded) {
        return _buildDetailContent(context, state.product);
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    },
  ); 
  }
  Widget _buildDetailContent(BuildContext context, Product product) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  final images = product.galleryImages.isNotEmpty
      ? product.galleryImages
      : [product.imageUrl];
  // Khởi tạo màu/RAM lần đầu khi có data
  if (_selectedColor.isEmpty && product.colors.isNotEmpty) {
    _selectedColor = product.colors.first;
  }
  if (_selectedRamRom.isEmpty && product.ramRomOptions.isNotEmpty) {
    _selectedRamRom = product.ramRomOptions.first;
  }

  final selectedVersion = _selectedVersion(product);
  final displayPrice = selectedVersion?.price ?? product.price;
  final canAddToCart = selectedVersion != null && selectedVersion.inStock;
      return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black54 : Colors.white70,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black54 : Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: badges.Badge(
                    showBadge: cartState.totalItems > 0,
                    badgeContent: Text(
                      '${cartState.totalItems}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.error, padding: EdgeInsets.all(4)),
                    child: const Icon(Icons.shopping_bag_outlined, size: 20),
                  ),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120), // Space for bottom action bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Gallery
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 400.0,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                      ),
                      items: images.map((img) {
                        return Builder(
                          builder: (BuildContext context) {
                            Widget imageWidget = Image.network(img, fit: BoxFit.cover);
                            if (img == product.imageUrl) {
                              imageWidget = Hero(
                                tag: 'product_image_${product.id}',
                                child: imageWidget,
                              );
                            }
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F7)),
                              child: imageWidget,
                            );
                          },
                        );
                      }).toList(),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: images.asMap().entries.map((entry) {
                            return Container(
                              width: _currentImageIndex == entry.key ? 24.0 : 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: _currentImageIndex == entry.key ? 0.9 : 0.4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.brand.toUpperCase(),
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${product.rating} (${product.reviewCount} ${context.tr('reviews')})',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Product Name
                      Text(
                        product.name,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 16),
                      
                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormatter.format(displayPrice),
                            style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          if (product.hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Text(
                                currencyFormatter.format(product.originalPrice),
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Colors Swatches
                      if (product.colors.isNotEmpty) ...[
                        Text(context.tr('color'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          children: product.colors.map((colorHex) {
                            final isSelected = _selectedColor == colorHex;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedColor = colorHex);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 16),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _resolveDisplayColor(colorHex),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // RAM/ROM Chips
                      if (product.ramRomOptions.isNotEmpty) ...[
                        Text(context.tr('storage'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: product.ramRomOptions.map((option) {
                            final isSelected = _selectedRamRom == option;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedRamRom = option);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? theme.colorScheme.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Specifications
                      if (product.specifications.isNotEmpty) ...[
                        Text(context.tr('specifications'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: product.specifications.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      
                      // Reviews Area
                      Text(context.tr('reviews'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              product.rating.toString(),
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < product.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 24,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${context.tr('reviews_based_on')}: ${product.reviewCount}',
                                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  // Add to Cart Button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: canAddToCart
                          ? () {
                              HapticFeedback.lightImpact();
                              _addSelectedToCart(context, product);
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.colorScheme.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Icon(Icons.add_shopping_cart_rounded, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Buy Now Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: canAddToCart
                          ? () {
                              HapticFeedback.lightImpact();
                              _addSelectedToCart(context, product);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CheckoutPage()),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(context.tr('buy_now'), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
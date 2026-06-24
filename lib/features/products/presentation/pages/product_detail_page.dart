import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badges/badges.dart' as badges;
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/product.dart';
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
  int _selectedImageIndex = 0;
  String _selectedColor = '';
  String _selectedRamRom = '';
  bool _showHeaderShadow = false;

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

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('product_detail_coming_soon'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductDetailLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            body: const Center(child: CircularProgressIndicator()),
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

    if (_selectedColor.isEmpty && product.colors.isNotEmpty) {
      _selectedColor = product.colors.first;
    }
    if (_selectedRamRom.isEmpty && product.ramRomOptions.isNotEmpty) {
      _selectedRamRom = product.ramRomOptions.first;
    }

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final borderColor = AppColors.outlineVariant.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: bgColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final shouldShow = notification.metrics.pixels > 20;
            if (shouldShow != _showHeaderShadow) {
              setState(() => _showHeaderShadow = shouldShow);
            }
          }
          return false;
        },
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(isDark, surfaceColor)),
                SliverToBoxAdapter(child: _buildHeroImage(images, product, isDark)),
                SliverToBoxAdapter(child: _buildThumbnailStrip(images, isDark, borderColor)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildProductIdentity(product, isDark),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(product.price),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primary : AppColors.primaryDeep,
                          height: 1.1,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(product.originalPrice),
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildActionRow(isDark, borderColor),
                      const SizedBox(height: 24),
                      if (product.colors.isNotEmpty) ...[
                        Text(
                          context.tr('color'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildColorSwatches(product, isDark),
                        const SizedBox(height: 24),
                      ],
                      if (product.ramRomOptions.isNotEmpty) ...[
                        Text(
                          context.tr('storage'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildVersionChips(product, isDark, borderColor),
                        const SizedBox(height: 32),
                      ],
                      if (product.specifications.isNotEmpty) ...[
                        Text(
                          context.tr('specifications'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSpecsTable(product, isDark, borderColor),
                        const SizedBox(height: 32),
                      ],
                      Text(
                        context.tr('reviews'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildReviewsCard(product, isDark, borderColor),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(context, product, isDark, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color surfaceColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _showHeaderShadow
            ? surfaceColor.withValues(alpha: 0.95)
            : surfaceColor,
        boxShadow: _showHeaderShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? AppColors.primary : AppColors.primaryDeep,
                  ),
                ),
                Expanded(
                  child: Text(
                    'phoneShop',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: isDark ? AppColors.primary : AppColors.primaryDeep,
                    ),
                  ),
                ),
                BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
                    return IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CartPage()),
                        );
                      },
                      icon: badges.Badge(
                        showBadge: cartState.totalItems > 0,
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
                          color: isDark ? AppColors.primary : AppColors.primaryDeep,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(List<String> images, Product product, bool isDark) {
    final imageUrl = images[_selectedImageIndex.clamp(0, images.length - 1)];
    return AspectRatio(
      aspectRatio: 1,
      child: ColoredBox(
        color: isDark ? AppColors.darkSurface : AppColors.lightImageBg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: imageUrl == product.imageUrl
                ? Hero(
                    tag: 'product_image_${product.id}',
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  )
                : Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip(List<String> images, bool isDark, Color borderColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _ThumbnailTile(
            isSelected: false,
            borderColor: borderColor,
            onTap: _showComingSoon,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 18,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('product_detail_video'),
                  style: TextStyle(
                    fontSize: 8,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ThumbnailTile(
            isSelected: false,
            borderColor: borderColor,
            onTap: _showComingSoon,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_outline,
                  size: 18,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('product_detail_highlights'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ...images.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            final isSelected = _selectedImageIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _ThumbnailTile(
                isSelected: isSelected,
                borderColor: borderColor,
                selectedBorderColor: AppColors.error,
                onTap: () => setState(() => _selectedImageIndex = index),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductIdentity(Product product, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.brand.toUpperCase(),
                style: TextStyle(
                  color: isDark ? AppColors.primary : AppColors.primaryDeep,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.tertiaryFixedDim, size: 16),
              const SizedBox(width: 4),
              Text(
                '${product.rating.toStringAsFixed(1)} (${product.reviewCount} ${context.tr('product_rating_count')})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(bool isDark, Color borderColor) {
    final actions = [
      (Icons.favorite_border, context.tr('product_detail_favorite')),
      (Icons.chat_bubble_outline, context.tr('product_detail_qa')),
      (Icons.description_outlined, context.tr('product_detail_specs_short')),
      (Icons.compare_arrows, context.tr('product_detail_compare')),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 16,
                color: borderColor,
              ),
            Expanded(
              child: InkWell(
                onTap: _showComingSoon,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        actions[i].$1,
                        size: 16,
                        color: isDark ? AppColors.primary : AppColors.primaryDeep,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          actions[i].$2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.primary : AppColors.primaryDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorSwatches(Product product, bool isDark) {
    return Row(
      children: product.colors.map((colorHex) {
        final isSelected = _selectedColor == colorHex;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedColor = colorHex);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.primary : AppColors.primaryDeep)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _resolveDisplayColor(colorHex),
                border: colorHex.toLowerCase().contains('white') ||
                        colorHex == '#FFFFFF'
                    ? Border.all(color: AppColors.outlineVariant)
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVersionChips(Product product, bool isDark, Color borderColor) {
    return Wrap(
      spacing: 16,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryDeep
                  : (isDark ? AppColors.darkSurface : AppColors.lightBackground),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryDeep : borderColor,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected
                    ? AppColors.onPrimaryContainer
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.onSurfaceVariant),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecsTable(Product product, bool isDark, Color borderColor) {
    final rowBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.5)
        : AppColors.lightSurface.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: product.specifications.entries.map((entry) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: borderColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: rowBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewsCard(Product product, bool isDark, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Text(
            product.rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final filled = index < product.rating.floor();
              return Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? AppColors.tertiaryFixedDim : const Color(0xFFE0E0E0),
                size: 24,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr('reviews_based_on')}: ${product.reviewCount}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Product product,
    bool isDark,
    Color borderColor,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<CartBloc>().add(AddToCartEvent(product));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('added_to_cart'))),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(
                  color: isDark ? AppColors.primary : AppColors.primaryDeep,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              ),
              child: Icon(
                Icons.add_shopping_cart_outlined,
                color: isDark ? AppColors.primary : AppColors.primaryDeep,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<CartBloc>().add(AddToCartEvent(product));
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CheckoutPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primaryDeep.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr('buy_now').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  final bool isSelected;
  final Color borderColor;
  final Color? selectedBorderColor;
  final VoidCallback onTap;
  final Widget child;

  const _ThumbnailTile({
    required this.isSelected,
    required this.borderColor,
    required this.onTap,
    required this.child,
    this.selectedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? (selectedBorderColor ?? AppColors.primaryDeep) : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

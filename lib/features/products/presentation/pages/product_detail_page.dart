import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badges/badges.dart' as badges;
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_version.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../../core/auth/auth_guard.dart';
import '../../../cart/presentation/cart_auth_helper.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';
import '../../presentation/bloc/product_bloc.dart';
import '../widgets/product_review_tile.dart';
import '../widgets/product_color_option_tile.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final String? heroImageUrl;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.heroImageUrl,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String _selectedColor = '';
  String _selectedRamRom = '';
  String? _selectionInitializedForProductId;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _specsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadProductByIdEvent(widget.productId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSpecs() {
    final targetContext = _specsKey.currentContext;
    if (targetContext == null) return;

    final renderObject = targetContext.findRenderObject();
    if (renderObject == null || !_scrollController.hasClients) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    final reveal = viewport.getOffsetToReveal(renderObject, 0.1);

    _scrollController.animateTo(
      reveal.offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildHeroImage({
    required String imageUrl,
    required bool isDark,
  }) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Hero(
            tag: 'product_image_${widget.productId}',
            createRectTween: (begin, end) => MaterialRectCenterArcTween(begin: begin, end: end),
            child: Material(
              color: Colors.transparent,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkBackground : const Color(0xFFFCF9F8);
    final imageUrl = widget.heroImageUrl ?? '';

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'phoneShop',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (imageUrl.isNotEmpty)
            _buildHeroImage(imageUrl: imageUrl, isDark: isDark)
          else
            const AspectRatio(
              aspectRatio: 1,
              child: Center(child: CircularProgressIndicator()),
            ),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trRead('product_coming_soon'))),
    );
  }

  ProductVersion _selectedVersion(Product product) {
    final matched = product.resolveVersion(
      color: _selectedColor,
      ramRom: _selectedRamRom,
    );
    if (matched != null) return matched;
    if (product.versions.isNotEmpty) return product.versions.first;

    final ramRomParts = _selectedRamRom.split('/');
    return ProductVersion(
      id: '${product.id}_default',
      color: _selectedColor.isNotEmpty ? _selectedColor : (product.colors.isNotEmpty ? product.colors.first : ''),
      ram: ramRomParts.isNotEmpty ? ramRomParts.first : '',
      rom: ramRomParts.length > 1 ? ramRomParts[1] : '',
      price: product.price,
      stockQuantity: product.stockQuantity,
    );
  }

  void _initializeSelectionIfNeeded(Product product) {
    if (_selectionInitializedForProductId == product.id) return;
    _selectionInitializedForProductId = product.id;
    _selectedColor = '';
    _selectedRamRom = '';
    _applyDefaultSelection(product);
  }

  void _applyDefaultSelection(Product product) {
    final availableColors = product.distinctColors;

    if (product.versions.isNotEmpty) {
      final inStockVersion = product.firstInStockVersion;

      if (_selectedColor.isEmpty && availableColors.isNotEmpty) {
        if (inStockVersion != null) {
          _selectedColor = inStockVersion.color;
          _selectedRamRom = inStockVersion.ramRom;
        } else {
          _selectedColor = availableColors.first;
          final options = product.ramRomOptionsForColor(_selectedColor);
          _selectedRamRom = options.isNotEmpty ? options.first : '';
        }
      }

      if (_selectedColor.isNotEmpty && _selectedRamRom.isEmpty) {
        final ramRomOptions = product.ramRomOptionsForColor(_selectedColor);
        if (ramRomOptions.isNotEmpty) {
          _selectedRamRom = ramRomOptions.firstWhere(
            (option) => product.isVersionInStock(
              color: _selectedColor,
              ramRom: option,
            ),
            orElse: () => ramRomOptions.first,
          );
        }
      }
      return;
    }

    if (_selectedColor.isEmpty && availableColors.isNotEmpty) {
      _selectedColor = availableColors.first;
    }
    if (_selectedRamRom.isEmpty && product.ramRomOptions.isNotEmpty) {
      _selectedRamRom = product.ramRomOptions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductDetailLoading) {
          return _buildLoadingScaffold(context);
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
        return _buildLoadingScaffold(context);
      },
    );
  }

  Widget _buildDetailContent(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    _initializeSelectionIfNeeded(product);
    final availableColors = product.distinctColors;
    final ramRomOptions = product.ramRomOptions;

    final selectedVersion = _selectedVersion(product);
    final canPurchase = selectedVersion.inStock;
    final allImages = product.allGalleryImages;
    final galleryIndex = product.galleryIndexForColor(
      color: _selectedColor,
      ramRom: _selectedRamRom,
    );

    final surfaceColor = isDark ? AppColors.darkBackground : const Color(0xFFFCF9F8);
    final outlineVariant = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : const Color(0xFFC1C6D5).withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'phoneShop',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              return IconButton(
                icon: badges.Badge(
                  showBadge: cartState.totalItems > 0,
                  badgeContent: Text(
                    '${cartState.totalItems}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.error, padding: EdgeInsets.all(4)),
                  child: Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.primary),
                ),
                onPressed: () => openCartWithAuth(context),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductImageGallery(
                  key: ValueKey('gallery_${widget.productId}_$allImages'),
                  images: allImages,
                  selectedIndex: galleryIndex,
                  productId: widget.productId,
                  isDark: isDark,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.brand.toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : const Color(0xFFF6F3F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.rating.toStringAsFixed(1)} (${product.reviewCount} ${context.tr('reviews')})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF414753),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currencyFormatter.format(selectedVersion.price),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(product.originalPrice),
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      if (!canPurchase) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.tr('product_version_out_of_stock'),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: outlineVariant),
                            bottom: BorderSide(color: outlineVariant),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ActionButton(
                              icon: Icons.favorite_border,
                              label: context.tr('product_favorite'),
                              onTap: _showComingSoon,
                              color: theme.colorScheme.primary,
                            ),
                            _DividerLine(color: outlineVariant),
                            _ActionButton(
                              icon: Icons.chat_bubble_outline,
                              label: context.tr('product_qa'),
                              onTap: _showComingSoon,
                              color: theme.colorScheme.primary,
                            ),
                            _DividerLine(color: outlineVariant),
                            _ActionButton(
                              icon: Icons.description_outlined,
                              label: context.tr('product_specs_btn'),
                              onTap: _scrollToSpecs,
                              color: theme.colorScheme.primary,
                            ),
                            _DividerLine(color: outlineVariant),
                            _ActionButton(
                              icon: Icons.compare_arrows,
                              label: context.tr('product_compare'),
                              onTap: _showComingSoon,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (ramRomOptions.isNotEmpty) ...[
                        Text(
                          context.tr('storage'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: ramRomOptions.map((option) {
                            final isSelected = Product.normalizeRamRom(_selectedRamRom) ==
                                Product.normalizeRamRom(option);
                            final isOutOfStock = !product.isVersionInStock(
                              color: _selectedColor,
                              ramRom: option,
                            );
                            return GestureDetector(
                              onTap: isOutOfStock
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedRamRom = option);
                                    },
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isOutOfStock ? 0.55 : 1,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.darkSurface : surfaceColor),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : outlineVariant,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        option,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                  ? AppColors.darkTextSecondary
                                                  : const Color(0xFF414753)),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (isOutOfStock) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          context.tr('product_version_out_of_stock'),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white70
                                                : AppColors.error,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (availableColors.isNotEmpty) ...[
                        Text(
                          context.tr('color'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: availableColors.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 72,
                          ),
                          itemBuilder: (context, index) {
                            final colorName = availableColors[index];
                            final isSelected = _selectedColor == colorName;
                            final versionOption = _selectedRamRom.isNotEmpty
                                ? product.findVersion(
                                    color: colorName,
                                    ramRom: _selectedRamRom,
                                  )
                                : product.findVersionForColor(colorName);
                            final isOutOfStock =
                                versionOption == null || !versionOption.inStock;
                            final ramRomForDisplay = _selectedRamRom.isNotEmpty
                                ? _selectedRamRom
                                : (versionOption?.ramRom ?? '');
                            final colorImage = product.thumbnailForColor(
                              color: colorName,
                              ramRom: ramRomForDisplay,
                            );
                            final colorPrice =
                                versionOption?.price ?? product.price;
                            return ProductColorOptionTile(
                              key: ValueKey('${colorName}_$_selectedRamRom'),
                              colorName: colorName,
                              imageUrl: colorImage,
                              priceLabel: currencyFormatter.format(colorPrice),
                              isSelected: isSelected,
                              isDark: isDark,
                              enabled: !isOutOfStock,
                              statusLabel: isOutOfStock
                                  ? context.tr('product_version_out_of_stock')
                                  : null,
                              onTap: () {
                                if (isOutOfStock) return;
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedColor = colorName;
                                  final options =
                                      product.ramRomOptionsForColor(colorName);
                                  if (_selectedRamRom.isNotEmpty &&
                                      options.contains(_selectedRamRom)) {
                                    return;
                                  }
                                  if (options.isNotEmpty) {
                                    final firstInStock = options.firstWhere(
                                      (option) => product.isVersionInStock(
                                        color: colorName,
                                        ramRom: option,
                                      ),
                                      orElse: () => options.first,
                                    );
                                    _selectedRamRom = firstInStock;
                                  } else if (versionOption != null &&
                                      versionOption.ramRom.isNotEmpty) {
                                    _selectedRamRom = versionOption.ramRom;
                                  }
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                      const SizedBox(height: 32),
                      Container(
                        key: _specsKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('specifications'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                            ),
                            const SizedBox(height: 12),
                            if (product.specifications.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: outlineVariant),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: product.specifications.entries.map((entry) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: outlineVariant.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              color: isDark
                                                  ? AppColors.darkSurface.withValues(alpha: 0.5)
                                                  : const Color(0xFFF6F3F2).withValues(alpha: 0.5),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              child: Text(
                                                entry.key,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isDark
                                                      ? AppColors.darkTextSecondary
                                                      : const Color(0xFF414753),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              child: Text(
                                                entry.value,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        context.tr('reviews'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final filled = index < product.rating.floor();
                                return Icon(
                                  filled ? Icons.star_rounded : Icons.star_rounded,
                                  color: filled ? const Color(0xFFFFB800) : const Color(0xFFE0E0E0),
                                  size: 24,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${context.tr('reviews_based_on')}: ${product.reviewCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF414753),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (product.feedbacks.isNotEmpty)
                        ...product.feedbacks.map(
                          (feedback) => ProductReviewTile(feedback: feedback),
                        )
                      else if (product.reviewCount == 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: outlineVariant),
                          ),
                          child: Text(
                            context.tr('product_reviews_empty'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF414753),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                border: Border(top: BorderSide(color: outlineVariant)),
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
                      key: const Key('product_detail_add_to_cart_button'),
                      onPressed: canPurchase
                          ? () async {
                              HapticFeedback.lightImpact();
                              final version = _selectedVersion(product);
                              await addToCartWithAuth(context, product, version);
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: theme.colorScheme.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                      ),
                      child: Icon(Icons.add_shopping_cart, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canPurchase
                            ? () async {
                                HapticFeedback.lightImpact();
                                final version = _selectedVersion(product);
                                if (!await requireAuthForCart(context)) return;
                                await ensureCartReady(context);
                                if (!context.mounted) return;
                                context.read<CartBloc>().add(AddToCartEvent(product, version));
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CheckoutPage()),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          context.tr('buy_now').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
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

class _ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final int selectedIndex;
  final String productId;
  final bool isDark;

  const _ProductImageGallery({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.productId,
    required this.isDark,
  });

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  static const double _thumbSize = 72;
  static const double _thumbGap = 8;

  int _currentIndex = 0;
  late final ScrollController _thumbController;

  @override
  void initState() {
    super.initState();
    _thumbController = ScrollController();
    _currentIndex = widget.selectedIndex.clamp(
      0,
      widget.images.isEmpty ? 0 : widget.images.length - 1,
    );
  }

  @override
  void dispose() {
    _thumbController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.isEmpty) return;

    final maxIndex = widget.images.length - 1;
    final targetIndex = widget.selectedIndex.clamp(0, maxIndex);

    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.images != widget.images) {
      if (_currentIndex != targetIndex) {
        setState(() => _currentIndex = targetIndex);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollThumbnailIntoView(targetIndex);
      });
    }
  }

  void _selectImage(int index) {
    setState(() => _currentIndex = index);
    _scrollThumbnailIntoView(index);
  }

  void _goToPreviousImage() {
    if (_currentIndex > 0) {
      _selectImage(_currentIndex - 1);
    }
  }

  void _goToNextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _selectImage(_currentIndex + 1);
    }
  }

  void _scrollThumbnailIntoView(int index) {
    if (!_thumbController.hasClients) return;

    final itemExtent = _thumbSize + _thumbGap;
    final viewportWidth = _thumbController.position.viewportDimension;
    final target = (index * itemExtent) - ((viewportWidth - _thumbSize) / 2);

    _thumbController.animateTo(
      target.clamp(0.0, _thumbController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.images;
    if (images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: widget.isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported, size: 64),
            ),
          ),
        ),
      );
    }

    final currentImage = images[_currentIndex.clamp(0, images.length - 1)];
    final outlineVariant = widget.isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : const Color(0xFFC1C6D5).withValues(alpha: 0.3);
    final showNavButtons = images.length > 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: widget.isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Hero(
                    tag: 'product_image_${widget.productId}',
                    createRectTween: (begin, end) =>
                        MaterialRectCenterArcTween(begin: begin, end: end),
                    child: Material(
                      color: Colors.transparent,
                      child: Image.network(
                        currentImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported, size: 64),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showNavButtons) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _GalleryNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _currentIndex > 0 ? _goToPreviousImage : null,
                  isDark: widget.isDark,
                ),
                Expanded(
                  child: SizedBox(
                    height: _thumbSize,
                    child: ListView.separated(
                      controller: _thumbController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: _thumbGap),
                      itemBuilder: (context, index) {
                        final isSelected = _currentIndex == index;
                        return _GalleryThumbnail(
                          imageUrl: images[index],
                          isSelected: isSelected,
                          size: _thumbSize,
                          borderColor: isSelected
                              ? theme.colorScheme.primary
                              : outlineVariant,
                          onTap: () => _selectImage(index),
                        );
                      },
                    ),
                  ),
                ),
                _GalleryNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _currentIndex < images.length - 1 ? _goToNextImage : null,
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GalleryNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _GalleryNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconColor = enabled
        ? (isDark ? AppColors.darkTextSecondary : const Color(0xFF414753))
        : (isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.35) : const Color(0xFFBDBDBD));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkCard : Colors.white,
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: enabled ? 0.4 : 0.2)
                  : Color(enabled ? 0xFFE0E0E0 : 0xFFEEEEEE),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;
  final double size;
  final Color borderColor;
  final VoidCallback onTap;

  const _GalleryThumbnail({
    required this.imageUrl,
    required this.isSelected,
    required this.size,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  final Color color;

  const _DividerLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 16, color: color);
  }
}

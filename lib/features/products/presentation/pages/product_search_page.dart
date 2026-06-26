import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_search_suggestion_tile.dart';
import 'product_detail_page.dart';
import '../../../../main.dart';

class ProductSearchPage extends StatefulWidget {
  final String initialQuery;

  const ProductSearchPage({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products, String query) {
    if (query.trim().isEmpty) return const [];

    final normalized = query.trim().toLowerCase();
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(normalized) ||
              product.brand.toLowerCase().contains(normalized),
        )
        .toList();
  }

  void _openProductDetail(Product product) {
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
  }

  void _applySearchAndClose(String query) {
    context.read<ProductBloc>().add(SearchProductsEvent(query));
    Navigator.pop(context, query);
  }

  Widget _buildTrendsSection({
    required ThemeData theme,
    required bool isDark,
    required List<Product> latestProducts,
  }) {
    if (latestProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.tr('not_found_desc'),
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          context.tr('search_trends_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latestProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (context, index) {
            final product = latestProducts[index];
            return ProductSearchSuggestionTile(
              product: product,
              isDark: isDark,
              onTap: () => _openProductDetail(product),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults({
    required ThemeData theme,
    required bool isDark,
    required List<Product> results,
  }) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('not_found_title'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('not_found_desc'),
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = results[index];
        return ProductSearchSuggestionTile(
          product: product,
          isDark: isDark,
          onTap: () => _openProductDetail(product),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkBackground : const Color(0xFFFCF9F8);
    final outlineVariant = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : const Color(0xFFC1C6D5).withValues(alpha: 0.3);

    return Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => _applySearchAndClose(_searchController.text),
          ),
          title: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: (_) => setState(() {}),
            onSubmitted: _applySearchAndClose,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.tr('search_hint'),
              hintStyle: TextStyle(
                color: (isDark ? AppColors.darkTextSecondary : const Color(0xFF414753))
                    .withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF6F3F2),
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductError) {
              return Center(child: Text(state.message));
            }

            if (state is! ProductLoaded) {
              return const SizedBox.shrink();
            }

            final query = _searchController.text.trim();
            if (query.isEmpty) {
              return _buildTrendsSection(
                theme: theme,
                isDark: isDark,
                latestProducts: state.latestProducts,
              );
            }

            final bloc = context.read<ProductBloc>();
            final results = _filterProducts(bloc.catalogProducts, query);
            return _buildSearchResults(
              theme: theme,
              isDark: isDark,
              results: results,
            );
          },
        ),
    );
  }
}
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_version.dart';
import '../../domain/repositories/product_repository.dart';

// --- EVENTS ---
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductEvent {}

class LoadMoreProductsEvent extends ProductEvent {}

class SearchProductsEvent extends ProductEvent {
  final String query;
  const SearchProductsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterProductsEvent extends ProductEvent {
  final String? brand;
  final double? minPrice;
  final double? maxPrice;
  final String? ram;
  final String? rom;

  const FilterProductsEvent({
    this.brand,
    this.minPrice,
    this.maxPrice,
    this.ram,
    this.rom,
  });

  @override
  List<Object?> get props => [brand, minPrice, maxPrice, ram, rom];
}

class LoadProductByIdEvent extends ProductEvent {
  final String productId;
  const LoadProductByIdEvent(this.productId);
   
   // dòng này gọi từ product_bloc và trả về Product có chứa id đó , dùng để hiển thị chi tiết sản phẩm
  @override
  List<Object?> get props => [productId];
}









// --- STATES ---
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<Product> latestProducts;
  final bool hasMore;
  final bool isLoadingMore;

  const ProductLoaded({
    required this.products,
    this.latestProducts = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  ProductLoaded copyWith({
    List<Product>? products,
    List<Product>? latestProducts,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      latestProducts: latestProducts ?? this.latestProducts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [products, latestProducts, hasMore, isLoadingMore];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}



// ProductByIdLoaded là một state để hiển thị chi tiết sản phẩm dùng để cho biết trạng thái loading và error
class ProductDetailLoading extends ProductState {}

class ProductDetailError extends ProductState {
  final String message;
  const ProductDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductDetailLoaded extends ProductState {
  final Product product;
  const ProductDetailLoaded(this.product);
  @override
  List<Object?> get props => [product];
}











// --- BLOC ---
// ProductBloc là một Bloc (Business Logic Component) để quản lý trạng thái và xử lý logic của sản phẩm
// Nó nhận các event từ ProductEvent và trả về ProductState
// Nó sử dụng ProductRepository để lấy dữ liệu sản phẩm từ MySQL (qua backend)
// Nó sử dụng List<Product> để lưu trữ danh sách sản phẩm
// Nó sử dụng ProductLoaded để hiển thị danh sách sản phẩm
// Nó sử dụng ProductError để hiển thị lỗi
// Nó sử dụng ProductLoading để hiển thị trạng thái loading
// Nó sử dụng ProductInitial để hiển thị trạng thái initial
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  static const int _pageSize = 10;

  final ProductRepository repository;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  int _displayCount = _pageSize;

  String _searchQuery = '';
  String _brandFilter = 'All';
  double? _minPriceFilter;
  double? _maxPriceFilter;
  String? _ramFilter;
  String? _romFilter;

  ProductBloc({required this.repository}) : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<LoadMoreProductsEvent>(_onLoadMoreProducts);
    on<SearchProductsEvent>(_onSearchProducts);
    on<FilterProductsEvent>(_onFilterProducts);
    on<LoadProductByIdEvent>(_onLoadProductById);
  }

  List<Product> get catalogProducts => List.unmodifiable(_allProducts);

  List<Product> _computeLatestProducts() {
    final sorted = List<Product>.from(_allProducts);
    sorted.sort((a, b) {
      final aId = int.tryParse(a.id) ?? 0;
      final bId = int.tryParse(b.id) ?? 0;
      return bId.compareTo(aId);
    });
    return sorted.take(5).toList();
  }

  ProductLoaded _emitPagedProducts({bool isLoadingMore = false}) {
    final displayed = _filteredProducts.take(_displayCount).toList();
    return ProductLoaded(
      products: displayed,
      latestProducts: _computeLatestProducts(),
      hasMore: displayed.length < _filteredProducts.length,
      isLoadingMore: isLoadingMore,
    );
  }

  void _resetPagination() {
    _displayCount = _pageSize;
  }

  Future<void> _onLoadProducts(LoadProductsEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await repository.getProducts();
      _allProducts = products;
      _resetPagination();
      _recomputeFilteredProducts(emit);
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    final current = state;
    if (current is! ProductLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    _displayCount += _pageSize;
    emit(_emitPagedProducts());
  }

  void _onSearchProducts(SearchProductsEvent event, Emitter<ProductState> emit) {
    _resetPagination();
    _searchQuery = event.query.trim();
    _recomputeFilteredProducts(emit);
  }

  void _onFilterProducts(FilterProductsEvent event, Emitter<ProductState> emit) {
    _resetPagination();
    if (event.brand != null) _brandFilter = event.brand!;
    _minPriceFilter = event.minPrice;
    _maxPriceFilter = event.maxPrice;
    _ramFilter = event.ram;
    _romFilter = event.rom;
    _recomputeFilteredProducts(emit);
  }

  void _recomputeFilteredProducts(Emitter<ProductState> emit) {
    var filtered = _allProducts;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.brand.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_brandFilter != 'All') {
      filtered = filtered
          .where((p) => p.brand.toLowerCase() == _brandFilter.toLowerCase())
          .toList();
    }

    if (_minPriceFilter != null) {
      filtered = filtered.where((p) => p.price >= _minPriceFilter!).toList();
    }

    if (_maxPriceFilter != null) {
      filtered = filtered.where((p) => p.price <= _maxPriceFilter!).toList();
    }

    if (_ramFilter != null || _romFilter != null) {
      filtered = filtered
          .where((p) => _matchesRamRom(p, _ramFilter, _romFilter))
          .toList();
    }

    _filteredProducts = filtered;
    emit(_emitPagedProducts());
  }

  static bool _matchesRamRom(Product product, String? ram, String? rom) {
    if (ram == null && rom == null) return true;

    bool versionMatches(ProductVersion version) {
      final ramOk = ram == null ||
          Product.normalizeRamRom(version.ram) == Product.normalizeRamRom(ram);
      final romOk = rom == null ||
          Product.normalizeRamRom(version.rom) == Product.normalizeRamRom(rom);
      return ramOk && romOk;
    }

    if (product.versions.isNotEmpty) {
      return product.versions.any(versionMatches);
    }

    if (product.ramRomOptions.isEmpty) return false;

    return product.ramRomOptions.any((option) {
      final parts = option
          .split('/')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      final optionRam = parts.isNotEmpty ? parts.first : '';
      final optionRom = parts.length > 1 ? parts[1] : '';
      final ramOk = ram == null ||
          Product.normalizeRamRom(optionRam) == Product.normalizeRamRom(ram);
      final romOk = rom == null ||
          Product.normalizeRamRom(optionRom) == Product.normalizeRamRom(rom);
      return ramOk && romOk;
    });
  }
   

  //lấy sản phẩm id của product với event và product state tương ứng ; emitter là hàm dùng để emit state tương ứng 
  Future<void> _onLoadProductById(
    LoadProductByIdEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductDetailLoading());
    try {
      final product = await repository.getProductById(event.productId);
      emit(ProductDetailLoaded(product));
    } catch (e) {
      emit(ProductDetailError(e.toString()));
    }
  }


}

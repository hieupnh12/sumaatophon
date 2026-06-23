import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

// --- EVENTS ---
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductEvent {}

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

  const FilterProductsEvent({this.brand, this.minPrice, this.maxPrice});

  @override
  List<Object?> get props => [brand, minPrice, maxPrice];
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
  
  const ProductLoaded(this.products);

  @override
  List<Object?> get props => [products];
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
  final ProductRepository repository;
  List<Product> _allProducts = [];

  ProductBloc({required this.repository}) : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<SearchProductsEvent>(_onSearchProducts);
    on<FilterProductsEvent>(_onFilterProducts);
    on<LoadProductByIdEvent>(_onLoadProductById);
  }

  Future<void> _onLoadProducts(LoadProductsEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await repository.getProducts();
      _allProducts = products;
      emit(ProductLoaded(_allProducts));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onSearchProducts(SearchProductsEvent event, Emitter<ProductState> emit) {
    if (event.query.isEmpty) {
      emit(ProductLoaded(_allProducts));
      return;
    }
    
    final query = event.query.toLowerCase();
    final filtered = _allProducts.where((p) => 
      p.name.toLowerCase().contains(query) || 
      p.brand.toLowerCase().contains(query)
    ).toList();
    
    emit(ProductLoaded(filtered));
  }

  void _onFilterProducts(FilterProductsEvent event, Emitter<ProductState> emit) {
    var filtered = _allProducts;
    
    if (event.brand != null && event.brand != 'All') {
      filtered = filtered.where((p) => p.brand.toLowerCase() == event.brand!.toLowerCase()).toList();
    }
    
    if (event.minPrice != null) {
      filtered = filtered.where((p) => p.price >= event.minPrice!).toList();
    }
    
    if (event.maxPrice != null) {
      filtered = filtered.where((p) => p.price <= event.maxPrice!).toList();
    }
    
    emit(ProductLoaded(filtered));
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

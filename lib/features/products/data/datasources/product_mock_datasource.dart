import '../../domain/entities/product.dart';

class ProductMockDataSource {
  final List<Product> _mockProducts = [
    const Product(
      id: 'p1',
      name: 'iPhone 15 Pro Max',
      brand: 'Apple',
      price: 1199.0,
      originalPrice: 1299.0,
      imageUrl: 'https://images.unsplash.com/photo-1695048065223-1d48c0823c91?q=80&w=600&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1695048065223-1d48c0823c91?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1695048065222-2615ce67da51?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 1250,
      ramRomOptions: ['8GB/256GB', '8GB/512GB', '8GB/1TB'],
      colors: ['#000000', '#F5F5F0', '#414859'], // Black, Natural Titanium, Blue
      specifications: {
        'Display': '6.7-inch Super Retina XDR OLED',
        'Processor': 'A17 Pro chip',
        'Camera': '48MP Main | 12MP Ultra Wide | 12MP Telephoto',
        'Battery': '4422 mAh',
        'OS': 'iOS 17'
      },
      isNew: true,
    ),
    const Product(
      id: 'p2',
      name: 'Samsung Galaxy S24 Ultra',
      brand: 'Samsung',
      price: 1299.0,
      originalPrice: 1299.0,
      imageUrl: 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?q=80&w=600&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1610945415296-735230006322?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.8,
      reviewCount: 980,
      ramRomOptions: ['12GB/256GB', '12GB/512GB', '12GB/1TB'],
      colors: ['#000000', '#EAE6E1', '#8C8C8C'], // Titanium Black, Titanium Gray
      specifications: {
        'Display': '6.8-inch Dynamic AMOLED 2X, 120Hz',
        'Processor': 'Snapdragon 8 Gen 3',
        'Camera': '200MP Main | 50MP Periscope | 12MP UW',
        'Battery': '5000 mAh',
        'OS': 'Android 14, One UI 6.1'
      },
      isNew: true,
    ),
    const Product(
      id: 'p3',
      name: 'iPhone 14 Pro',
      brand: 'Apple',
      price: 899.0,
      originalPrice: 999.0,
      imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=600&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.7,
      reviewCount: 3200,
      ramRomOptions: ['6GB/128GB', '6GB/256GB'],
      colors: ['#000000', '#5C5B57', '#E5E6EB'],
      specifications: {
        'Display': '6.1-inch Super Retina XDR OLED',
        'Processor': 'A16 Bionic chip',
        'Camera': '48MP Main | 12MP Ultra Wide | 12MP Telephoto',
        'Battery': '3200 mAh',
      },
      isNew: false,
    ),
  ];

  Future<List<Product>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
    return _mockProducts;
  }
}

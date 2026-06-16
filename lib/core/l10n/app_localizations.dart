import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/language_cubit.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Onboarding
      'onboarding_title_1': 'Sản phẩm chính hãng',
      'onboarding_desc_1': 'Cam kết cung cấp các sản phẩm công nghệ chính hãng với chất lượng tốt nhất.',
      'onboarding_title_2': 'Giao hàng hỏa tốc',
      'onboarding_desc_2': 'Nhận hàng ngay trong 2 giờ tại các thành phố lớn trên toàn quốc.',
      'onboarding_title_3': 'Hỗ trợ tận tâm',
      'onboarding_desc_3': 'Đội ngũ chuyên gia luôn sẵn sàng giải đáp mọi thắc mắc của bạn 24/7.',
      'skip': 'Bỏ qua',
      'next': 'Tiếp theo',
      'start': 'Bắt đầu',
      'select_language': 'Chọn ngôn ngữ',

      // Login
      'login_title': 'Đăng nhập',
      'login_subtitle': 'Trải nghiệm di động cao cấp',
      'email_hint': 'Địa chỉ Email',
      'password_hint': 'Mật khẩu',
      'login_btn': 'Đăng nhập',
      'forgot_password': 'Quên mật khẩu?',
      'no_account': 'Chưa có tài khoản?',
      'register': 'Đăng ký',

      // Home / Product List
      'search_hint': 'Tìm kiếm điện thoại, hãng...',
      'price_range': 'Mức giá',
      'million': 'Tr',
      'ram': 'Dung lượng RAM',
      'rom': 'Bộ nhớ trong (ROM)',
      'not_found_title': 'Không tìm thấy sản phẩm',
      'not_found_desc': 'Thử tìm kiếm với một từ khóa khác nhé.',
      'home': 'Trang chủ',
      'explore': 'Khám phá',

      // Product Detail
      'add_to_cart': 'Thêm vào giỏ',
      'buy_now': 'Mua ngay',
      'color': 'Màu sắc',
      'description': 'Mô tả sản phẩm',

      // Cart
      'cart_empty_title': 'Giỏ hàng trống',
      'cart_empty_desc': 'Có vẻ như sếp chưa thêm gì vào giỏ hàng.',
      'explore_now': 'Khám phá ngay',
      'total': 'Tổng cộng',
      'checkout': 'Thanh toán',
      'cart': 'Giỏ hàng',
      'subtotal': 'Tạm tính',
      'discount': 'Giảm giá',
      'promo_hint': 'Mã giảm giá (VD: APPLE10)',
      'apply': 'Áp dụng',

      // Navigation
      'shop': 'Cửa hàng',
      'stores': 'Hệ thống',
      'concierge': 'Hỗ trợ',
      'notifications': 'Thông báo',

      // Profile
      'theme': 'Giao diện (Dark/Light)',
      'language': 'Ngôn ngữ',
      'help_center': 'Trung tâm trợ giúp',
      'logout': 'Đăng xuất',
      'profile': 'Hồ sơ',
    },
    'en': {
      // Onboarding
      'onboarding_title_1': 'Genuine Products',
      'onboarding_desc_1': 'Committed to providing genuine tech products of the best quality.',
      'onboarding_title_2': 'Express Delivery',
      'onboarding_desc_2': 'Receive your order within 2 hours in major cities nationwide.',
      'onboarding_title_3': 'Dedicated Support',
      'onboarding_desc_3': 'Our expert team is always ready to answer your questions 24/7.',
      'skip': 'Skip',
      'next': 'Next',
      'start': 'Get Started',
      'select_language': 'Select Language',

      // Login
      'login_title': 'Login',
      'login_subtitle': 'Premium mobile experience',
      'email_hint': 'Email address',
      'password_hint': 'Password',
      'login_btn': 'Sign In',
      'forgot_password': 'Forgot password?',
      'no_account': 'Don\'t have an account?',
      'register': 'Register',

      // Home / Product List
      'search_hint': 'Search phones, brands...',
      'price_range': 'Price Range',
      'million': 'M',
      'ram': 'RAM Capacity',
      'rom': 'Internal Storage (ROM)',
      'not_found_title': 'No products found',
      'not_found_desc': 'Try searching with a different keyword.',
      'home': 'Home',
      'explore': 'Explore',

      // Product Detail
      'add_to_cart': 'Add to Cart',
      'buy_now': 'Buy Now',
      'color': 'Color',
      'description': 'Product Description',

      // Cart
      'cart_empty_title': 'Cart is empty',
      'cart_empty_desc': 'Looks like you haven\'t added anything to your cart.',
      'explore_now': 'Explore Now',
      'total': 'Total',
      'checkout': 'Checkout',
      'cart': 'Shopping Cart',
      'subtotal': 'Subtotal',
      'discount': 'Discount',
      'promo_hint': 'Promo Code (e.g. APPLE10)',
      'apply': 'Apply',

      // Navigation
      'shop': 'Shop',
      'stores': 'Stores',
      'concierge': 'Concierge',
      'notifications': 'Notifications',

      // Profile
      'theme': 'Theme (Dark/Light)',
      'language': 'Language',
      'help_center': 'Help Center',
      'logout': 'Logout',
      'profile': 'Profile',
    },
    'ja': {
      // Onboarding
      'onboarding_title_1': '正規品',
      'onboarding_desc_1': '最高品質の純正テクノロジー製品を提供することをお約束します。',
      'onboarding_title_2': '速達便',
      'onboarding_desc_2': '全国の主要都市で2時間以内にご注文をお届けします。',
      'onboarding_title_3': '専用サポート',
      'onboarding_desc_3': '専門家チームが24時間年中無休でお客様の質問にお答えします。',
      'skip': 'スキップ',
      'next': '次へ',
      'start': '始める',
      'select_language': '言語を選択',

      // Login
      'login_title': 'ログイン',
      'login_subtitle': 'プレミアムなモバイル体験',
      'email_hint': 'メールアドレス',
      'password_hint': 'パスワード',
      'login_btn': 'サインイン',
      'forgot_password': 'パスワードをお忘れですか？',
      'no_account': 'アカウントを持っていませんか？',
      'register': '登録する',

      // Home / Product List
      'search_hint': '電話、ブランドを検索...',
      'price_range': '価格帯',
      'million': '百万',
      'ram': 'RAM容量',
      'rom': '内部ストレージ (ROM)',
      'not_found_title': '商品が見つかりません',
      'not_found_desc': '別のキーワードで検索してみてください。',
      'home': 'ホーム',
      'explore': '見つける',

      // Product Detail
      'add_to_cart': 'カートに追加',
      'buy_now': '今すぐ購入',
      'color': '色',
      'description': '商品説明',

      // Cart
      'cart_empty_title': 'カートは空です',
      'cart_empty_desc': 'カートに何も追加されていないようです。',
      'explore_now': '今すぐ調べる',
      'total': '合計',
      'checkout': 'チェックアウト',
      'cart': 'ショッピングカート',
      'subtotal': '小計',
      'discount': '割引',
      'promo_hint': 'プロモコード（例：APPLE10）',
      'apply': '適用する',

      // Navigation
      'shop': 'ショップ',
      'stores': '店舗',
      'concierge': 'サポート',
      'notifications': '通知',

      // Profile
      'theme': 'テーマ (Dark/Light)',
      'language': '言語',
      'help_center': 'ヘルプセンター',
      'logout': 'ログアウト',
      'profile': 'プロフィール',
    }
  };

  static String translate(String key, String langCode) {
    return _localizedValues[langCode]?[key] ?? key;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    final langCode = watch<LanguageCubit>().state;
    return AppLocalizations.translate(key, langCode);
  }
}

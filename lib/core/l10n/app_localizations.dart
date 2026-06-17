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
      'email_hint': 'Địa chỉ email',
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
      'added_to_cart': 'Đã thêm vào giỏ hàng',
      'buy_now': 'Mua ngay',
      'color': 'Màu sắc',
      'storage': 'Dung lượng',
      'specifications': 'Thông số kỹ thuật',
      'reviews': 'Đánh giá',
      'reviews_based_on': 'Dựa trên số đánh giá',
      'description': 'Mô tả sản phẩm',

      // Cart
      'cart_empty_title': 'Giỏ hàng trống',
      'cart_empty_desc': 'Có vẻ như bạn chưa thêm gì vào giỏ hàng.',
      'explore_now': 'Khám phá ngay',
      'total': 'Tổng cộng',
      'checkout': 'Thanh toán',
      'cart': 'Giỏ hàng',
      'subtotal': 'Tạm tính',
      'discount': 'Giảm giá',
      'promo_hint': 'Mã giảm giá (VD: APPLE10)',
      'apply': 'Áp dụng',

      // Checkout
      'checkout_title': 'Thanh toán',
      'checkout_delivery_address': 'Địa chỉ giao hàng',
      'checkout_home': 'Nhà riêng',
      'checkout_shipping_method': 'Phương thức vận chuyển',
      'checkout_payment_method': 'Phương thức thanh toán',
      'checkout_order_summary': 'Tóm tắt đơn hàng',
      'checkout_items': 'Sản phẩm',
      'checkout_shipping': 'Phí vận chuyển',
      'checkout_confirm_order': 'Xác nhận đặt hàng',
      'checkout_order_success_title': 'Đặt hàng thành công!',
      'checkout_order_success_desc': 'Đơn hàng của bạn đã được ghi nhận. Chúng tôi sẽ gửi xác nhận trong thời gian sớm nhất.',
      'checkout_back_home': 'Về trang chủ',
      'checkout_estimated_delivery': 'Dự kiến giao hàng',
      'checkout_select_address': 'Chọn địa chỉ giao hàng',
      'checkout_add_new_address': 'Thêm địa chỉ mới',
      'checkout_select_shipping': 'Chọn phương thức vận chuyển',
      'checkout_select_payment': 'Chọn phương thức thanh toán',
      'checkout_shipping_standard': 'Giao hàng tiêu chuẩn',
      'checkout_shipping_fast': 'Giao hàng nhanh (GHN)',
      'checkout_shipping_express': 'Giao hàng hỏa tốc',
      'checkout_delivery_2_3_days': '2-3 ngày',
      'checkout_delivery_1_2_days': '1-2 ngày',
      'checkout_delivery_same_day': 'Trong ngày',
      'checkout_payment_cod': 'Thanh toán khi nhận hàng (COD)',
      'checkout_payment_momo': 'Ví MoMo',
      'checkout_payment_zalopay': 'ZaloPay',
      'checkout_payment_card': 'Thẻ tín dụng/Ghi nợ',
      'checkout_submit_error': 'Thanh toán thất bại. Vui lòng thử lại.',

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
      'added_to_cart': 'Added to cart',
      'buy_now': 'Buy Now',
      'color': 'Color',
      'storage': 'Storage',
      'specifications': 'Specifications',
      'reviews': 'Reviews',
      'reviews_based_on': 'Based on reviews',
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

      // Checkout
      'checkout_title': 'Checkout',
      'checkout_delivery_address': 'Delivery Address',
      'checkout_home': 'Home',
      'checkout_shipping_method': 'Shipping Method',
      'checkout_payment_method': 'Payment Method',
      'checkout_order_summary': 'Order Summary',
      'checkout_items': 'Items',
      'checkout_shipping': 'Shipping',
      'checkout_confirm_order': 'Confirm Order',
      'checkout_order_success_title': 'Order Successful!',
      'checkout_order_success_desc': 'Your order has been placed successfully. You will receive a confirmation soon.',
      'checkout_back_home': 'Back to Home',
      'checkout_estimated_delivery': 'Estimated delivery',
      'checkout_select_address': 'Select delivery address',
      'checkout_add_new_address': 'Add new address',
      'checkout_select_shipping': 'Select shipping method',
      'checkout_select_payment': 'Select payment method',
      'checkout_shipping_standard': 'Standard delivery',
      'checkout_shipping_fast': 'Fast delivery (GHN)',
      'checkout_shipping_express': 'Express delivery',
      'checkout_delivery_2_3_days': '2-3 days',
      'checkout_delivery_1_2_days': '1-2 days',
      'checkout_delivery_same_day': 'Same day',
      'checkout_payment_cod': 'Cash on delivery (COD)',
      'checkout_payment_momo': 'MoMo Wallet',
      'checkout_payment_zalopay': 'ZaloPay',
      'checkout_payment_card': 'Credit/Debit card',
      'checkout_submit_error': 'Payment failed. Please try again.',

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
      'onboarding_desc_1': '最高品質の正規テック製品を提供することをお約束します。',
      'onboarding_title_2': 'エクスプレス配送',
      'onboarding_desc_2': '主要都市ではご注文から2時間以内にお届けします。',
      'onboarding_title_3': '丁寧なサポート',
      'onboarding_desc_3': '専門チームが24時間いつでもご質問にお答えします。',
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
      'forgot_password': 'パスワードをお忘れですか?',
      'no_account': 'アカウントをお持ちでないですか?',
      'register': '登録',

      // Home / Product List
      'search_hint': 'スマートフォン、ブランドを検索...',
      'price_range': '価格帯',
      'million': '百万',
      'ram': 'RAM容量',
      'rom': '内部ストレージ (ROM)',
      'not_found_title': '商品が見つかりません',
      'not_found_desc': '別のキーワードで検索してみてください。',
      'home': 'ホーム',
      'explore': '見る',

      // Product Detail
      'add_to_cart': 'カートに追加',
      'added_to_cart': 'カートに追加しました',
      'buy_now': '今すぐ購入',
      'color': 'カラー',
      'storage': 'ストレージ',
      'specifications': '仕様',
      'reviews': 'レビュー',
      'reviews_based_on': 'レビューに基づく',
      'description': '商品説明',

      // Cart
      'cart_empty_title': 'カートは空です',
      'cart_empty_desc': 'カートにまだ商品が追加されていません。',
      'explore_now': '今すぐ見る',
      'total': '合計',
      'checkout': 'チェックアウト',
      'cart': 'ショッピングカート',
      'subtotal': '小計',
      'discount': '割引',
      'promo_hint': 'プロモコード (例: APPLE10)',
      'apply': '適用',

      // Checkout
      'checkout_title': 'チェックアウト',
      'checkout_delivery_address': '配送先住所',
      'checkout_home': '自宅',
      'checkout_shipping_method': '配送方法',
      'checkout_payment_method': '支払い方法',
      'checkout_order_summary': '注文概要',
      'checkout_items': '商品',
      'checkout_shipping': '送料',
      'checkout_confirm_order': '注文を確定',
      'checkout_order_success_title': '注文が完了しました!',
      'checkout_order_success_desc': 'ご注文を受け付けました。確認内容をまもなくお送りします。',
      'checkout_back_home': 'ホームに戻る',
      'checkout_estimated_delivery': '配送予定',
      'checkout_select_address': '配送先住所を選択',
      'checkout_add_new_address': '新しい住所を追加',
      'checkout_select_shipping': '配送方法を選択',
      'checkout_select_payment': '支払い方法を選択',
      'checkout_shipping_standard': '通常配送',
      'checkout_shipping_fast': '速達配送 (GHN)',
      'checkout_shipping_express': 'エクスプレス配送',
      'checkout_delivery_2_3_days': '2-3日',
      'checkout_delivery_1_2_days': '1-2日',
      'checkout_delivery_same_day': '当日',
      'checkout_payment_cod': '代金引換 (COD)',
      'checkout_payment_momo': 'MoMoウォレット',
      'checkout_payment_zalopay': 'ZaloPay',
      'checkout_payment_card': 'クレジット/デビットカード',
      'checkout_submit_error': '決済に失敗しました。もう一度お試しください。',

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

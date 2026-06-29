// lib/main.dart

import 'package:badges/badges.dart' as badges;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:refresh_rate/refresh_rate.dart';
import 'core/config/app_feature_flags.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/design_system/app_theme.dart';
import 'core/design_system/app_colors.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/language_cubit.dart';
import 'core/l10n/app_localizations.dart';
import 'features/auth/domain/repositories/auth_repository.dart';

import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'core/notifications/push_notification_service.dart';
import 'features/products/domain/repositories/product_repository.dart';
import 'features/products/data/datasources/product_remote_datasource.dart';
import 'features/products/data/datasources/product_local_datasource.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
import 'features/products/presentation/pages/product_list_page.dart';
import 'core/database/app_database.dart';
import 'features/cart/data/datasources/cart_remote_datasource.dart';
import 'features/cart/data/repositories/cart_repository_impl.dart';
import 'features/cart/domain/repositories/cart_repository.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/cart/presentation/cart_auth_helper.dart';
import 'core/auth/auth_guard.dart';
import 'features/checkout/presentation/bloc/checkout_bloc.dart';
import 'features/checkout/data/datasources/checkout_remote_datasource.dart';
import 'features/checkout/data/datasources/payment_remote_datasource.dart';
import 'features/store_locator/presentation/bloc/store_locator_bloc.dart';
import 'features/store_locator/presentation/pages/store_location_page.dart';
import 'features/chatbot/data/datasources/chatbot_remote_datasource.dart';
import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/presentation/pages/chat_hub_page.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/notification_helpers.dart';
import 'features/chat/domain/entities/chat_message_entity.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/notifications/data/datasources/notification_remote_datasource.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'features/address/data/datasources/address_remote_datasource.dart';
import 'features/address/data/datasources/location_remote_datasource.dart';
import 'features/address/data/repositories/address_repository_impl.dart';
import 'features/address/domain/repositories/address_repository.dart';
import 'features/address/presentation/bloc/address_bloc.dart';
import 'features/orders/domain/repositories/order_repository.dart';
import 'features/orders/data/datasources/order_remote_datasource.dart';
import 'features/orders/data/repositories/order_repository_impl.dart';
import 'features/orders/presentation/bloc/order_bloc.dart';
import 'features/warranty/data/datasources/warranty_remote_datasource.dart';
import 'features/warranty/data/repositories/warranty_repository_impl.dart';
import 'features/warranty/domain/repositories/warranty_repository.dart';
import 'features/warranty/presentation/bloc/warranty_bloc.dart';
final sl = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await PushNotificationService.init();
  }
  await ApiConfig.init();
  await Future.wait([
    initializeDateFormatting('vi'),
    initializeDateFormatting('en'),
    initializeDateFormatting('ja'),
  ]);
  await setupDependencyInjection();
  if (!kIsWeb) {
    // Gọi sớm; plugin sẽ áp lại khi Activity/Surface sẵn sàng (xem _PhoneShopAppState).
    RefreshRate.enable();
  }
  runApp(const PhoneShopApp());
}

Future<void> setupDependencyInjection() async {
  // Database
  final appDatabase = AppDatabase();
  sl.registerLazySingleton(() => appDatabase);

  // Network
  sl.registerLazySingleton(() => ApiClient());

  // Datasources
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => AuthLocalDataSource(sl()));
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ProductRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ProductLocalDataSource(sl()));
  sl.registerLazySingleton(() => ChatbotRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ChatRemoteDataSource(sl()));
  sl.registerLazySingleton(() => CartRemoteDatasource(sl()));
  sl.registerLazySingleton<WarrantyRemoteDataSource>(() => WarrantyRemoteDataSourceImpl(apiClient: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<AuthRemoteDataSource>(), sl<AuthLocalDataSource>()));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(sl()));
  sl.registerLazySingleton<WarrantyRepository>(() => WarrantyRepositoryImpl(remoteDataSource: sl()));
  
  // Address
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton<LocationRemoteDataSource>(() => LocationRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<AddressRemoteDataSource>(() => AddressRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<AddressRepository>(() => AddressRepositoryImpl(remoteDataSource: sl(), locationDataSource: sl()));
  sl.registerLazySingleton<PaymentRemoteDataSource>(() => PaymentRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<CheckoutRemoteDataSource>(() => CheckoutRemoteDataSourceImpl(apiClient: sl()));

  // Notifications
  sl.registerLazySingleton<NotificationRemoteDataSource>(() => NotificationRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(sl()));

  // Orders
  sl.registerLazySingleton<OrderRemoteDataSource>(() => OrderRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()));

  // Blocs
  sl.registerLazySingleton(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => ProductBloc(repository: sl()));
  sl.registerFactory(() => CartBloc(repository: sl()));
  sl.registerFactory(() => CheckoutBloc(checkoutDataSource: sl(), paymentDataSource: sl()));
  sl.registerFactory(() => StoreLocatorBloc());
  sl.registerFactory(() => ChatBloc(repository: sl()));
  sl.registerFactory(() => NotificationBloc(repository: sl()));
  sl.registerFactory(() => AddressBloc(repository: sl(), authBloc: sl()));
  sl.registerFactory(() => OrderBloc(repository: sl()));
  sl.registerFactory(() => WarrantyBloc(repository: sl()));
  
  // Theme & Language
  final storage = sl<FlutterSecureStorage>();
  
  final themeStr = await storage.read(key: 'theme_mode');
  final initialTheme = ThemeMode.values.firstWhere(
    (e) => e.name == themeStr,
    orElse: () => ThemeMode.system,
  );
  sl.registerLazySingleton(() => ThemeCubit(initialTheme, storage));

  final langCode = await storage.read(key: 'language_code') ?? 'vi';
  sl.registerLazySingleton(() => LanguageCubit(langCode, storage));
}

class PhoneShopApp extends StatefulWidget {
  const PhoneShopApp({super.key});

  @override
  State<PhoneShopApp> createState() => _PhoneShopAppState();
}

class _PhoneShopAppState extends State<PhoneShopApp> with WidgetsBindingObserver {
  bool _showOnboarding = true;
  NotificationState? _prevNotificationState;

  @override
  void initState() {
    super.initState();
    PushNotificationService.onForegroundRefresh = () {
      if (!mounted) return;
      final ctx = context;
      if (ctx.mounted) reloadNotifications(ctx, silent: true);
    };
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyHighRefreshRate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyHighRefreshRate();
    }
  }

  Future<void> _applyHighRefreshRate() async {
    if (kIsWeb) return;

    RefreshRate.enable();
    RefreshRate.preferMax();
    RefreshRate.setTouchBoost(true);
    RefreshRate.category(RateCategory.high);

    var info = await RefreshRate.refresh();
    if (kDebugMode) {
      debugPrint(
        '[RefreshRate] current=${info.currentRate}Hz max=${info.maxRate}Hz '
        'supported=${info.supportedRates} lowPower=${RefreshRate.isLowPowerMode}',
      );
    }

    // MIUI/LTPO: Surface đôi khi chưa gắn xong ở frame đầu — thử lại sau 300ms.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    RefreshRate.enable();
    RefreshRate.preferMax();
    RefreshRate.setTouchBoost(true);
    RefreshRate.category(RateCategory.high);
    info = await RefreshRate.refresh();
    if (kDebugMode) {
      debugPrint(
        '[RefreshRate] retry current=${info.currentRate}Hz max=${info.maxRate}Hz',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(CheckAuthStatusEvent())),
        BlocProvider(create: (_) => sl<ProductBloc>()),
        BlocProvider(create: (_) => sl<CartBloc>()),
        BlocProvider(create: (_) => sl<CheckoutBloc>()),
        BlocProvider(create: (_) => sl<StoreLocatorBloc>()),
        BlocProvider(create: (_) => sl<ChatBloc>()),
        BlocProvider(create: (_) => sl<NotificationBloc>()),
        BlocProvider(create: (_) => sl<AddressBloc>()),
        BlocProvider(create: (_) => sl<OrderBloc>()),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<LanguageCubit>()),
      ],
      child: _ApiLifecycleHandler(
        child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'phoneShop Premium',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MultiBlocListener(
                listeners: [
                  BlocListener<AuthBloc, AuthState>(
                    listener: (context, state) {
                      final cartBloc = context.read<CartBloc>();
                      final notificationBloc = context.read<NotificationBloc>();
                      if (state is AuthenticatedState && isRealAuthenticatedUser(state.user)) {
                        cartBloc.add(SyncCartCustomerEvent(state.user.id));
                        reloadNotifications(context, silent: true);
                        registerPushNotifications(context);
                      } else if (state is! AuthenticatedState) {
                        unregisterPushNotifications(context);
                        cartBloc.add(const SyncCartCustomerEvent(null));
                        notificationBloc.add(ClearNotificationsEvent());
                        _prevNotificationState = null;
                      }
                    },
                  ),
                  BlocListener<NotificationBloc, NotificationState>(
                    listener: (context, state) {
                      showFreshNotificationsAsBanner(_prevNotificationState, state);
                      _prevNotificationState = state;
                    },
                  ),
                ],
                child: BlocListener<CartBloc, CartState>(
                listenWhen: (prev, curr) =>
                    prev.cartMessage != curr.cartMessage ||
                    prev.addedProductName != curr.addedProductName,
                listener: (context, state) {
                  final messenger = ScaffoldMessenger.of(context);
                  if (state.addedProductName != null) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '${state.addedProductName} ${context.trRead('added_to_cart')}',
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    context.read<CartBloc>().add(ClearCartAddedEvent());
                  } else if (state.cartMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(context.trRead(state.cartMessage!)),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context.read<CartBloc>().add(ClearCartMessageEvent());
                  }
                },
                child: child ?? const SizedBox.shrink(),
              ),
              );
            },
            home: AppFeatureFlags.authRequired
                ? BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }
                      if (state is AuthenticatedState) {
                        return const AppMainPage();
                      }
                      if (_showOnboarding) {
                        return OnboardingPage(onFinish: () {
                          setState(() {
                            _showOnboarding = false;
                          });
                        });
                      }
                      return const LoginScreen();
                    },
                  )
                : const AppMainPage(),
          );
        },
      ),
      ),
    );
  }
}

/// Debug: khi rút USB / app resume, probe lại local vs production và reload data.
class _ApiLifecycleHandler extends StatefulWidget {
  final Widget child;

  const _ApiLifecycleHandler({required this.child});

  @override
  State<_ApiLifecycleHandler> createState() => _ApiLifecycleHandlerState();
}

class _ApiLifecycleHandlerState extends State<_ApiLifecycleHandler>
    with WidgetsBindingObserver {
  bool _startupLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startupApiLoad());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckApiOnResume();
    }
  }

  Future<void> _startupApiLoad() async {
    if (_startupLoadDone || !mounted) return;
    _startupLoadDone = true;

    if (!kReleaseMode && !kIsWeb) {
      await ApiConfig.recheckBaseUrl();
    }
    if (!mounted) return;
    _reloadAppData();
  }

  Future<void> _recheckApiOnResume() async {
    if (kReleaseMode || kIsWeb || !mounted) return;

    final changed = await ApiConfig.recheckBaseUrl();
    if (!mounted) return;
    if (changed) {
      _reloadAppData();
    }
  }

  void _reloadAppData() {
    context.read<ProductBloc>().add(LoadProductsEvent());
    context.read<StoreLocatorBloc>().add(LoadStoresEvent());
    context.read<AddressBloc>().add(LoadAddressesEvent());
    reloadNotifications(context, silent: true);

    final auth = context.read<AuthBloc>().state;
    if (auth is AuthenticatedState && isRealAuthenticatedUser(auth.user)) {
      context.read<CartBloc>().add(LoadCartEvent());
      final customerId = int.tryParse(auth.user.id);
      if (customerId != null) {
        context.read<OrderBloc>().add(LoadOrdersEvent(customerId));
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AppMainPage extends StatefulWidget {
  const AppMainPage({super.key});

  @override
  State<AppMainPage> createState() => _AppMainPageState();
}

class _AppMainPageState extends State<AppMainPage> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 3) {
      reloadNotifications(context, silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, curr) {
        if (curr.messages.isEmpty || curr.messages.length <= prev.messages.length) {
          return false;
        }
        return curr.messages.last.senderRole == MessageSenderRole.admin;
      },
      listener: (context, _) => reloadNotifications(context, silent: true),
      child: Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Nav routes list with corresponding UI pages
          ProductListPage(
            onOpenCart: () => openCartWithAuth(context),
          ),
          const StoreLocationPage(),
          const ChatHubPage(),
          const NotificationsPage(),
          ProfilePage(
            onLoginSuccess: () => _onNavTap(0),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        onTap: _onNavTap,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.shopping_bag_outlined), activeIcon: const Icon(Icons.shopping_bag), label: context.tr('shop')),
          BottomNavigationBarItem(icon: const Icon(Icons.location_on_outlined), activeIcon: const Icon(Icons.location_on), label: context.tr('stores')),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), activeIcon: const Icon(Icons.chat_bubble), label: context.tr('concierge')),
          BottomNavigationBarItem(
            icon: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) => badges.Badge(
                showBadge: state.unreadCount > 0,
                badgeContent: Text(
                  state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.error, padding: EdgeInsets.all(4)),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            activeIcon: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) => badges.Badge(
                showBadge: state.unreadCount > 0,
                badgeContent: Text(
                  state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.error, padding: EdgeInsets.all(4)),
                child: const Icon(Icons.notifications),
              ),
            ),
            label: context.tr('notifications'),
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: context.tr('profile')),
        ],
      ),
      ),
    );
  }
}

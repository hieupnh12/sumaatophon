// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'core/config/app_feature_flags.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/design_system/app_theme.dart';
import 'core/design_system/app_colors.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/language_cubit.dart';
import 'core/l10n/app_localizations.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/datasources/auth_mock_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
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
import 'features/store_locator/presentation/bloc/store_locator_bloc.dart';
import 'features/store_locator/presentation/pages/store_location_page.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'package:http/http.dart' as http;
import 'features/address/data/datasources/address_remote_datasource.dart';
import 'features/address/data/datasources/location_remote_datasource.dart';
import 'features/address/data/repositories/address_repository_impl.dart';
import 'features/address/domain/repositories/address_repository.dart';
import 'features/address/presentation/bloc/address_bloc.dart';

final sl = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ApiConfig.init();
  await setupDependencyInjection();
  runApp(const PhoneShopApp());
}

Future<void> setupDependencyInjection() async {
  // Database
  final appDatabase = AppDatabase();
  sl.registerLazySingleton(() => appDatabase);

  // Network
  sl.registerLazySingleton(() => ApiClient());

  // Datasources
  sl.registerLazySingleton(() => AuthMockDataSource());
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl(), sl()));
  sl.registerLazySingleton(() => ProductRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ProductLocalDataSource(sl()));
  sl.registerLazySingleton(() => CartRemoteDatasource(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<AuthRemoteDataSource>()));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(sl()));
  
  // Address
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton<LocationRemoteDataSource>(() => LocationRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<AddressRemoteDataSource>(() => AddressRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<AddressRepository>(() => AddressRepositoryImpl(remoteDataSource: sl(), locationDataSource: sl()));

  // Blocs
  sl.registerLazySingleton(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => ProductBloc(repository: sl()));
  sl.registerFactory(() => CartBloc(repository: sl()));
  sl.registerFactory(() => CheckoutBloc());
  sl.registerFactory(() => StoreLocatorBloc());
  sl.registerFactory(() => ChatBloc());
  sl.registerFactory(() => NotificationBloc());
  sl.registerFactory(() => AddressBloc(repository: sl(), authBloc: sl()));
  
  // Theme & Language
  sl.registerLazySingleton(() => ThemeCubit());
  sl.registerLazySingleton(() => LanguageCubit());
}

class PhoneShopApp extends StatefulWidget {
  const PhoneShopApp({super.key});

  @override
  State<PhoneShopApp> createState() => _PhoneShopAppState();
}

class _PhoneShopAppState extends State<PhoneShopApp> {
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<ProductBloc>()..add(LoadProductsEvent())),
        BlocProvider(create: (_) => sl<CartBloc>()),
        BlocProvider(create: (_) => sl<CheckoutBloc>()),
        BlocProvider(create: (_) => sl<StoreLocatorBloc>()..add(LoadStoresEvent())),
        BlocProvider(create: (_) => sl<ChatBloc>()),
        BlocProvider(create: (_) => sl<NotificationBloc>()..add(LoadNotificationsEvent())),
        BlocProvider(create: (_) => sl<AddressBloc>()..add(LoadAddressesEvent())),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<LanguageCubit>()),
      ],
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
                      if (state is AuthenticatedState && isRealAuthenticatedUser(state.user)) {
                        cartBloc.add(SyncCartCustomerEvent(state.user.id));
                      } else if (state is! AuthenticatedState) {
                        cartBloc.add(const SyncCartCustomerEvent(null));
                      }
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
    );
  }
}

class AppMainPage extends StatefulWidget {
  const AppMainPage({super.key});

  @override
  State<AppMainPage> createState() => _AppMainPageState();
}

class _AppMainPageState extends State<AppMainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Nav routes list with corresponding UI pages
          ProductListPage(
            onOpenCart: () => openCartWithAuth(context),
          ),
          const StoreLocationPage(),
          const ChatPage(),
          const NotificationsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.shopping_bag_outlined), activeIcon: const Icon(Icons.shopping_bag), label: context.tr('shop')),
          BottomNavigationBarItem(icon: const Icon(Icons.location_on_outlined), activeIcon: const Icon(Icons.location_on), label: context.tr('stores')),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), activeIcon: const Icon(Icons.chat_bubble), label: context.tr('concierge')),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_outlined), activeIcon: const Icon(Icons.notifications), label: context.tr('notifications')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: context.tr('profile')),
        ],
      ),
    );
  }
}

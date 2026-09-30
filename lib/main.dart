import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_constants.dart';
import 'core/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_navigation.dart';
import 'screens/invoices/invoice_detail_screen.dart';
import 'screens/invoices/invoice_list_screen.dart';
import 'screens/maintenance/maintenance_detail_screen.dart';
import 'screens/maintenance/maintenance_list_screen.dart';
import 'screens/move_requests/move_request_list_screen.dart';
import 'screens/notifications/notification_list_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _handleNotificationNavigation(String type, int? referenceId) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;

  final t = type.toUpperCase();
  if (t.contains('INVOICE') || t.contains('PAYMENT')) {
    if (referenceId != null && referenceId > 0) {
      nav.push(MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: referenceId)));
    } else {
      nav.push(MaterialPageRoute(builder: (_) => const InvoiceListScreen()));
    }
  } else if (t.contains('MAINTENANCE')) {
    if (referenceId != null && referenceId > 0) {
      nav.push(MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(requestId: referenceId)));
    } else {
      nav.push(MaterialPageRoute(builder: (_) => const MaintenanceListScreen()));
    }
  } else if (t.contains('MOVING')) {
    nav.push(MaterialPageRoute(builder: (_) => const MoveRequestListScreen()));
  } else {
    nav.push(MaterialPageRoute(builder: (_) => const NotificationListScreen()));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar icons color
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize persistent storage
  await StorageService.init();

  // Initialize FCM Notification service
  await NotificationService().initialize(
    onNotificationTap: (type, referenceId) {
      _handleNotificationNavigation(type, referenceId);
    },
  );

  final bool isLoggedIn = StorageService.hasToken();

  runApp(ResidentApp(isLoggedIn: isLoggedIn));
}

class ResidentApp extends StatelessWidget {
  final bool isLoggedIn;

  const ResidentApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          surface: Colors.white,
          background: AppConstants.backgroundColor,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.borderColor, width: 1),
          ),
        ),
      ),
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(),
    );
  }
}
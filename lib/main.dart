import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:starttoo/screens/feed/feed_list_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // 네이티브 스플래시 화면을 Flutter에서 제어할 수 있도록 preserve
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Starttoo',
        debugShowCheckedModeBanner: false,
        debugShowMaterialGrid: false, // Material Grid 비활성화
        showPerformanceOverlay: false, // Performance Overlay 비활성화
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3FD1FF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[900],
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const FeedListPage(),
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:starttoo/screens/feed/feed_list_screen.dart';
import 'providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // 네이티브 스플래시 화면을 Flutter에서 제어할 수 있도록 preserve
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load(fileName: ".env");
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
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            // Primary - 앱의 주요 색상 (버튼, AppBar 등)
            primary: Color(0xFF183D3D),
            onPrimary: Color(0xFF93B1A6),  // primary 위에 표시되는 텍스트/아이콘 색상

            // Secondary - 보조 색상
            secondary: Color(0xFF3FD1FF),
            onSecondary: Color(0xFFFFFFFF),  // secondary 위에 표시되는 텍스트/아이콘 색상

            // Tertiary - 3차 색상 (Material 3)
            tertiary: Color(0xFF212121),
            onTertiary: Color(0xFFFFFFFF),

            // 기타 필수 색상
            error: Colors.red,
            onError: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
            background: Color(0xFF313647),
            onBackground: Colors.white,
            outline: Colors.grey.shade700,
          ),
          scaffoldBackgroundColor: Color(0xFF212121),
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const FeedListPage(),
        },
      ),
    );
  }
}


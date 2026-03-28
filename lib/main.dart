// Entry point of the Flutter application.
// Defines the main function and root widget.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linea_de_vida/presentation/bloc/photo_bloc.dart';
import 'package:linea_de_vida/presentation/views/main_timeline_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PhotoProvider(),
      child: MaterialApp(
        title: 'Photo Voice Manager',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.grey[100],
          primaryColor: const Color(0xFF00ACC1), // cyan
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.cyan,
            brightness: Brightness.light,
          ).copyWith(secondary: const Color(0xFF006064)),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF00ACC1),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 2,
            titleTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          drawerTheme: const DrawerThemeData(
            backgroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ACC1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              elevation: 4,
              minimumSize: const Size(88, 48),
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(4),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
            titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        home: const MainTimelineView(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tourch_app/Bindings/home_binding.dart';
import 'package:tourch_app/home_screen/home_screen.dart';


void main() {
  runApp(const SosTorchApp());
}


class SosTorchApp extends StatelessWidget {
  const SosTorchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SOS Torch',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: TorchScreen(),
      initialBinding: TorchBinding(),
      debugShowCheckedModeBanner: false,
    );
  }
}

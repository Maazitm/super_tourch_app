import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tourch_app/home_screen/home_controller.dart';
import 'package:tourch_app/widgets/campus_widgets.dart';

class TorchScreen extends StatelessWidget {
  TorchScreen({Key? key}) : super(key: key);

  // --- NEW: WILL POP SCOPE HANDLER ---
  Future<bool> _onWillPop(BuildContext context, TorchController controller) async {
    // Check if any pattern is active
    final bool isPatternOrUtilityActive = controller.isSosActive.value ||
        controller.isBlinkActive.value ||
        controller.isPoliceLightActive.value ||
        controller.isSirenActive.value ||
        controller.isScreenLightActive.value ||
        controller.isNightLightActive.value;

    // 1. If a pattern is active, the back button will just stop the pattern
    if (isPatternOrUtilityActive) {
      await controller
          .toggleTorch(); // This will call _stopAllPatterns()
      return false; // Do not exit the app
    }

    // 2. If no pattern is active, show the themed exit dialog
    final bool? shouldPop = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2c2c2e), // App's dark background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Exit App?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to close the application?',
          style: GoogleFonts.poppins(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false), // Dismiss and do not pop
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700, // Your theme's active color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Get.back(result: true), // Dismiss and pop
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false; // Default to false (do not exit)
  }

  @override
  Widget build(BuildContext context) {
    final TorchController controller = Get.find<TorchController>();

    return Obx(() {
      final bool isScreenEffectActive =
          controller.isPoliceLightActive.value ||
              controller.isScreenLightActive.value ||
              controller.isNightLightActive.value;
      final Color dynamicBgColor = controller.policeLightColor.value;

      // --- WRAP SCAFFOLD WITH WILLPOPSCOPE ---
      return WillPopScope(
        onWillPop: () => _onWillPop(context, controller),
        child: Scaffold(
          backgroundColor: isScreenEffectActive ? dynamicBgColor : null,
          appBar: AppBar(
            title: Text('SOS Torch',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF2c2c2e),
            elevation: 0,
            actions: [
              _buildAutoOffTimerButton(context, controller),
            ],
          ),
          body: Container(
            decoration: isScreenEffectActive
                ? null
                : const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2c2c2e), Color(0xFF1a1a1a)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double screenWidth = constraints.maxWidth;
                final double screenHeight = constraints.maxHeight;
                final bool isPortrait = screenHeight > screenWidth;

                if (isPortrait) {
                  return _buildPortraitLayout(controller, screenWidth);
                } else {
                  return _buildLandscapeLayout(controller, screenWidth);
                }
              },
            ),
          ),
        ),
      );
    });
  }

  /// Layout for Portrait Mode
  Widget _buildPortraitLayout(TorchController controller, double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _buildPowerButton(controller, screenWidth),
          const Spacer(),
          _buildPatternAndUtilityButtons(controller, screenWidth),
          const SizedBox(height: 30),
          Obx(() => controller.isCompassActive.value
              ? const CompassWidget()
              : const SizedBox.shrink()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Layout for Landscape Mode
  Widget _buildLandscapeLayout(TorchController controller, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: _buildPowerButton(controller, screenWidth / 2),
        ),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPatternAndUtilityButtons(controller, screenWidth / 2),
                  const SizedBox(height: 30),
                  Obx(() => controller.isCompassActive.value
                      ? const CompassWidget()
                      : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Scaled Power Button
  Widget _buildPowerButton(TorchController controller, double screenWidth) {
    final double buttonSize = (screenWidth * 0.45).clamp(160.0, 220.0);
    final double iconSize = buttonSize * 0.45;

    return Obx(() {
      final bool isTorchOn = controller.isTorchOn.value;
      final bool isPatternOrUtilityActive = controller.isSosActive.value ||
          controller.isBlinkActive.value ||
          controller.isPoliceLightActive.value ||
          controller.isSirenActive.value ||
          controller.isScreenLightActive.value ||
          controller.isNightLightActive.value;

      Color buttonColor;
      if (isPatternOrUtilityActive) {
        buttonColor = Colors.orange.shade700;
      } else if (isTorchOn) {
        buttonColor = Colors.white;
      } else {
        buttonColor = const Color(0xFF3a3a3c);
      }

      Color iconColor = isPatternOrUtilityActive
          ? Colors.white
          : (isTorchOn ? Colors.black : Colors.white);

      return GestureDetector(
        onTap: controller.toggleTorch,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            LucideIcons.power,
            size: iconSize,
            color: iconColor,
          ),
        ),
      );
    });
  }

  /// Scaled Pattern/Utility Buttons
  Widget _buildPatternAndUtilityButtons(
      TorchController controller, double screenWidth) {
    final double horizontalPadding =
        (screenWidth > 450) ? screenWidth * 0.05 : 10.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Obx(() => _buildPatternButton(
                    context: Get.context!,
                    label: 'SOS',
                    icon: LucideIcons.alertTriangle,
                    isActive: controller.isSosActive.value,
                    onPressed: controller.toggleSos,
                    screenWidth: screenWidth,
                  )),
              Obx(() => _buildPatternButton(
                    context: Get.context!,
                    label: 'Blink',
                    icon: LucideIcons.zap,
                    isActive: controller.isBlinkActive.value,
                    onPressed: controller.toggleBlink,
                    screenWidth: screenWidth,
                  )),
              Obx(() => _buildPatternButton(
                    context: Get.context!,
                    label: 'Police',
                    icon: LucideIcons.siren,
                    isActive: controller.isPoliceLightActive.value,
                    onPressed: controller.togglePoliceLight,
                    screenWidth: screenWidth,
                  )),
              Obx(() => _buildPatternButton(
                    context: Get.context!,
                    label: 'Siren',
                    icon: LucideIcons.volume2,
                    isActive: controller.isSirenActive.value,
                    onPressed: controller.toggleSiren,
                    screenWidth: screenWidth,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: (screenWidth > 450) ? screenWidth * 0.08 : 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Obx(() => _buildPatternButton(
                    context: Get.context!,
                    label: 'Compass',
                    icon: LucideIcons.compass,
                    isActive: controller.isCompassActive.value,
                    onPressed: controller.toggleCompass,
                    screenWidth: screenWidth,
                  )),
              Obx(() => _buildPatternButton(
                    context: Get.context!,
                    label: 'Screen Light',
                    icon: LucideIcons.maximize,
                    isActive: controller.isScreenLightActive.value,
                    onPressed: controller.toggleScreenLight,
                    screenWidth: screenWidth,
                  )),
              Obx(() => _buildPatternButton(
                    context: Get.context!,
                    label: 'Night Light',
                    icon: LucideIcons.bookOpen,
                    isActive: controller.isNightLightActive.value,
                    onPressed: controller.toggleNightLight,
                    screenWidth: screenWidth,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  /// Scaled Individual Pattern Button
  Widget _buildPatternButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required double screenWidth,
  }) {
    final Color activeColor = Colors.orange.shade700;
    final Color inactiveColor = const Color(0xFF3a3a3c);

    final double iconSize = (screenWidth * 0.075).clamp(28.0, 35.0);
    final double padding = (screenWidth * 0.05).clamp(18.0, 24.0);
    final double labelSize = (screenWidth * 0.04).clamp(14.0, 17.0);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            shape: BoxShape.circle,
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: activeColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            iconSize: iconSize,
            padding: EdgeInsets.all(padding),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isActive ? activeColor : Colors.grey.shade400,
            fontSize: labelSize,
          ),
        ),
      ],
    );
  }

  /// Builds the button to set the auto-off timer.
  Widget _buildAutoOffTimerButton(
      BuildContext context, TorchController controller) {
    return Obx(() {
      String label;
      if (controller.autoOffDuration.value == 0) {
        label = 'OFF';
      } else if (controller.autoOffDuration.value < 60) {
        label = '${controller.autoOffDuration.value}s';
      } else {
        label = '${controller.autoOffDuration.value ~/ 60}m';
      }

      return TextButton(
        onPressed: () => _showAutoOffDialog(context, controller),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.timer, size: 20, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Shows a dialog to select the auto-off duration.
  void _showAutoOffDialog(BuildContext context, TorchController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF2c2c2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Auto-Off Timer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...controller.availableDurations.map((duration) {
                      String label;
                      if (duration == 0) {
                        label = 'Disable Auto-Off';
                      } else if (duration < 60) {
                        label = '$duration seconds';
                      } else {
                        label = '${duration ~/ 60} minutes';
                      }

                      return Obx(() => RadioListTile<int>(
                            title: Text(label,
                                style: GoogleFonts.poppins(color: Colors.white)),
                            value: duration,
                            groupValue: controller.autoOffDuration.value,
                            onChanged: (value) {
                              if (value != null) {
                                controller.setAutoOffDuration(value);
                                Get.back();
                              }
                            },
                          ));
                    }),
                    const Divider(
                        color: Colors.white24, thickness: 1, height: 32),
                    ListTile(
                        leading: Icon(LucideIcons.star,
                            color: Colors.yellow.shade700),
                        title: Text('Rate This App',
                            style: GoogleFonts.poppins(color: Colors.white)),
                        subtitle: Text('Help us improve',
                            style: GoogleFonts.poppins(color: Colors.white70)),
                        onTap: () {

                        //  controller.launchManualReview();
                        }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:math' show pi; // For mathematical constant PI
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming you use Google Fonts

class CompassWidget extends StatefulWidget {
  const CompassWidget({Key? key}) : super(key: key);

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget> {
  double _heading = 0.0; // Stores the current heading in degrees

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events, // Listen to compass events
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Error reading compass: ${snapshot.error}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(
            color: Colors.orange, // Or your app's accent color
          );
        }

        // Get the current heading (direction in degrees)
        double? direction = snapshot.data!.heading;

        // If the device doesn't support a compass, direction will be null
        if (direction == null) {
          return Text(
            "Device does not support compass",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          );
        }

        _heading = direction; // Update the heading

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. Compass Dial (Background) - Static image for the compass face
                // This image should have N, S, E, W markings
                // If you don't have this, you can remove this layer or use a simple circle
                Image.asset(
                  'assets/images/campus_base.png', // Make sure this path is correct
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),

                // 2. Compass Needle - Rotates based on the device's heading
                // The needle image's "north" must point upwards in the image file.
                Transform.rotate(
                  // We rotate the needle by the opposite of the heading
                  // because a heading of 0 degrees means the device is pointing North.
                  // If the needle points North, it should not rotate.
                  // If device points East (90 deg), needle should still point N (up),
                  // but the dial *under* it effectively rotates.
                  // Or, if we rotate the needle, it should point to the actual North.
                  // Here, we're making the needle point to North.
                  // 0 degrees is North, 90 is East, 180 is South, 270 is West.
                  angle: -_heading * (pi / 180), // Convert degrees to radians and invert
                  child: Image.asset(
                    'assets/images/campus_nidal.png', // Make sure this path is correct
                    width: 140, // Adjust size as needed
                    height: 140, // Adjust size as needed
                    fit: BoxFit.contain,
                    color: Colors.red, // Example: make the needle red
                  ),
                ),

                // 3. Optional: Center Dot or Overlay for visual appeal
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              // Display the heading in degrees, rounded
              '${_heading.round()}° ${_getCardinalDirection(_heading)}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _getDeviceOrientationText(context, _heading), // Show device orientation
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper to get cardinal direction (N, NE, E, etc.)
  String _getCardinalDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return '';
  }

  // Helper to show if the device is held horizontally or vertically (basic)
  String _getDeviceOrientationText(BuildContext context, double heading) {
    // This is a simplified check. For true device orientation,
    // you'd need accelerometer/gyroscope data.
    // Here, we just assume "North" if the top of the phone is pointing North.
    return 'Hold device flat for best reading';
  }
}
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/providers/locale_provider.dart';
import 'package:terminko/components/custom_language_selector.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:terminko/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectDistancePage extends StatefulWidget {
  const SelectDistancePage({super.key});

  @override
  State<SelectDistancePage> createState() => _SelectDistancePageState();
}

class _SelectDistancePageState extends State<SelectDistancePage> {
  Position? _currentPosition;
  double _distanceKm = 10;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _requestAndFetchLocation();
  }

  Future<void> _requestAndFetchLocation() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = pos);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _animateCameraToBounds();
        });
      });
    }
  }

  void _animateCameraToBounds() {
    if (_mapController == null || _currentPosition == null) return;

    final center = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    final double radiusInMeters = _distanceKm * 1000;
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(center.latitude - radiusInMeters / 111320,
          center.longitude - radiusInMeters / (111320 *
              (cos(center.latitude * pi / 180)))),
      northeast: LatLng(center.latitude + radiusInMeters / 111320,
          center.longitude + radiusInMeters / (111320 *
              (cos(center.latitude * pi / 180)))),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final loc = AppLocalizations.of(context)!;

    if (_currentPosition == null || uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.fill_all_fields)),
      );
      return;
    }

    try {
      await updatePreferences(maxDistanceKm: _distanceKm);

      await saveLocationForAllSports(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        maxDistanceKm: _distanceKm,
      );

      final user = await getUserById(uid);
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.error_user_not_found)),
        );
        return;
      }

      String? activeSport;
      if (user.selectedSports.length == 1) {
        activeSport = user.selectedSports.first;
      }

      final updatedUser = user.copyWith(
        isSetupComplete: true,
        activeSport: activeSport,
      );

      await updateUserModel(updatedUser);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error_title}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            Align(
              alignment: Alignment.topRight,
              child: LanguageSelector(
                onSelect: (langCode) {
                  final provider = Provider.of<LocaleProvider>(context, listen: false);
                  provider.setLocale(Locale(langCode));
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.select_distance_title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              loc.select_distance_description,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withAlpha(70),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceContainerHighest,
              ),
              child: _currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          _mapController = controller;
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _animateCameraToBounds();
                          });
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          zoom: 14,
                        ),
                        mapType: MapType.normal,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        liteModeEnabled: true,
                        markers: {
                          Marker(
                            markerId: const MarkerId('user_location'),
                            position: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                          ),
                        },
                        circles: {
                          Circle(
                            circleId: const CircleId("range_circle"),
                            center: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            radius: _distanceKm * 1000,
                            fillColor: Colors.blue.withAlpha(20),
                            strokeColor: Colors.blueAccent,
                            strokeWidth: 2,
                          ),
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 30),
            Text(
              "${loc.select_distance_label}: ${_distanceKm.toStringAsFixed(0)} km",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _distanceKm,
              min: 1,
              max: 50,
              divisions: 49,
              label: "${_distanceKm.toStringAsFixed(0)} km",
              onChanged: (value) {
                setState(() => _distanceKm = value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _animateCameraToBounds();
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                loc.continue_button,
                style: TextStyle(color: colorScheme.onPrimary, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:terminko/models/sport_details_model.dart';

class EditSportParametersPage extends StatefulWidget {
  final String sportId;

  const EditSportParametersPage({super.key, required this.sportId});

  @override
  State<EditSportParametersPage> createState() => _EditSportParametersPageState();
}

class _EditSportParametersPageState extends State<EditSportParametersPage> {
  final Set<String> selectedPositions = {};
  final Set<String> selectedMatchTypes = {};
  TimeOfDay? selectedTime;
  Position? _currentPosition;
  double _distanceKm = 10;
  GoogleMapController? _mapController;

  List<String> allPositions = [];
  List<String> allMatchTypes = [];
  bool isLoading = true;

  late Map<String, String> positionLabels;
  late Map<String, String> matchTypeLabels;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _requestAndFetchLocation();
    });
  }

  String formatTimeOfDay24h(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _loadData() async {
    final loc = AppLocalizations.of(context)!;

    switch (widget.sportId) {
      case 'football':
        positionLabels = {
          'Player': loc.player,
          'Goalkeeper': loc.goalkeeper,
        };
        matchTypeLabels = {
          '3v3': loc.match_type_3v3,
          '4+1v4+1': loc.match_type_4plus1v4plus1,
          '5v5': loc.match_type_5v5,
          '5+1v5+1': loc.match_type_5plus1v5plus1,
          '6v6': loc.match_type_6v6,
        };
        break;
      case 'basketball':
        positionLabels = {
          'Playmaker': loc.basketball_position_playmaker,
          'Shooter': loc.basketball_position_shooter,
          'Power Forward': loc.basketball_position_power_forward,
          'Center': loc.basketball_position_center,
        };
        matchTypeLabels = {
          '3v3': loc.match_type_3v3,
          '5v5': loc.match_type_5v5,
        };
        break;
      case 'padel':
        positionLabels = {
          'Left': loc.padel_position_left,
          'Right': loc.padel_position_right,
          'Flex': loc.padel_position_flexible,
        };
        matchTypeLabels = {
          '2v2': loc.match_type_2v2,
        };
        break;
    }

    allPositions = positionLabels.keys.toList();
    allMatchTypes = matchTypeLabels.keys.toList();

    final model = await getSportData(widget.sportId);
    if (model != null) {
      selectedPositions.addAll(model.positions);
      selectedMatchTypes.addAll(model.matchTypes);
      if (model.preferredTime.isNotEmpty) {
        try {
          final parts = model.preferredTime.split(":");
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour != null && minute != null) {
              selectedTime = TimeOfDay(hour: hour, minute: minute);
            }
          }
        } catch (e) {
          selectedTime = TimeOfDay.now();
        }
      }
      _distanceKm = model.location?['maxDistanceKm']?.toDouble() ?? 10;
    }

    setState(() => isLoading = false);

    Future.delayed(const Duration(milliseconds: 50), () {
      _animateCameraToBounds();
    });
  }

  Future<void> _requestAndFetchLocation() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = pos);
    }
  }

  void _animateCameraToBounds() {
    if (_mapController == null || _currentPosition == null) return;

    final center = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    final double radius = _distanceKm * 1000;
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(center.latitude - radius / 111320,
          center.longitude - radius / (111320 * cos(center.latitude * pi / 180))),
      northeast: LatLng(center.latitude + radius / 111320,
          center.longitude + radius / (111320 * cos(center.latitude * pi / 180))),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _currentPosition == null) return;

    if (selectedPositions.isEmpty || selectedMatchTypes.isEmpty || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.fill_all_fields)),
      );
      return;
    }

    final model = SportDetailsModel(
      positions: selectedPositions.toList(),
      matchTypes: selectedMatchTypes.toList(),
      preferredTime: "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
      location: {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'maxDistanceKm': _distanceKm,
      },
    );

    await saveSportData(widget.sportId, model);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.parameters_saved)),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.edit_sport_parameters)),
      backgroundColor: colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.positions_title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: allPositions.map((pos) => FilterChip(
                        label: Text(positionLabels[pos] ?? pos),
                        selected: selectedPositions.contains(pos),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        selectedColor: colorScheme.primary.withAlpha(30),
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? selectedPositions.add(pos)
                                : selectedPositions.remove(pos);
                          });
                        },
                      )).toList(),
                ),
                const SizedBox(height: 24),
                Text(loc.match_type_title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: allMatchTypes.map((type) => FilterChip(
                        label: Text(matchTypeLabels[type] ?? type),
                        selected: selectedMatchTypes.contains(type),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        selectedColor: colorScheme.primary.withAlpha(30),
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? selectedMatchTypes.add(type)
                                : selectedMatchTypes.remove(type);
                          });
                        },
                      )).toList(),
                ),
                const SizedBox(height: 24),
                Text(loc.preferred_time_title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    selectedTime != null ? formatTimeOfDay24h(selectedTime!) : loc.select_time,
                    style: TextStyle(
                      color: selectedTime != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withAlpha(60),
                    ),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickTime,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 24),
                if (_currentPosition != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 300,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            onMapCreated: (controller) {
                              _mapController = controller;
                              Future.delayed(const Duration(milliseconds: 100), _animateCameraToBounds);
                            },
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 13.5,
                            ),
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
                      Text("${loc.select_distance_label}: ${_distanceKm.toStringAsFixed(0)} km",
                          style: theme.textTheme.titleMedium),
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
                    ],
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
                    loc.save,
                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

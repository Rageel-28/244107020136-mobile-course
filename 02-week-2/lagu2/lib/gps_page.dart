import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsPage extends StatefulWidget {
  const GpsPage({super.key});

  @override
  State<GpsPage> createState() => _GpsPageState();
}

class _GpsPageState extends State<GpsPage> with SingleTickerProviderStateMixin {
  String _locationMessage = "Mencari sinyal satelit...";
  Position? _currentPosition;
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _determinePosition();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationMessage = "GPS tidak aktif. Aktifkan GPS Anda.";
          _isLoading = false;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationMessage = "Izin lokasi ditolak.";
            _isLoading = false;
          });
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationMessage = "Izin lokasi ditolak permanen.";
          _isLoading = false;
        });
      }
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationMessage = "Koneksi Terhubung!";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationMessage = "Gagal mendapatkan lokasi.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.bottomCenter,
          radius: 1.5,
          colors: [Color(0xFF1B3829), Color(0xFF0A0A0E)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Aura Radar', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 10),
              Text('Memindai konser & musik di sekitarmu', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
              const SizedBox(height: 80),
              
              // Radar UI
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing Pulse
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.8, end: 0.0).animate(_pulseController),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.5).animate(_pulseController),
                      child: Container(
                        width: 250, height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1DB954).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  // Inner rings
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.4), width: 1.5),
                    ),
                  ),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.6), width: 2),
                    ),
                  ),
                  // Center Icon
                  _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle),
                        child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 36),
                      ),
                ],
              ),
              
              const SizedBox(height: 80),
              
              // Location Data Glass Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(_locationMessage, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          if (_currentPosition != null) ...[
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Latitude', style: TextStyle(color: Colors.white54, fontSize: 15)),
                                Text('${_currentPosition!.latitude.toStringAsFixed(6)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Longitude', style: TextStyle(color: Colors.white54, fontSize: 15)),
                                Text('${_currentPosition!.longitude.toStringAsFixed(6)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

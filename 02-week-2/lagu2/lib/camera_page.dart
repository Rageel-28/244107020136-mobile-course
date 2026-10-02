import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPage({super.key, required this.cameras});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  int _currentCameraIndex = 0;
  late AnimationController _shutterAnimController;
  late Animation<double> _shutterAnim;

  @override
  void initState() {
    super.initState();
    _shutterAnimController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _shutterAnim = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _shutterAnimController, curve: Curves.easeInOut),
    );
    if (widget.cameras.isNotEmpty) {
      _initCamera(widget.cameras[_currentCameraIndex]);
    }
  }

  Future<void> _initCamera(CameraDescription camera) async {
    setState(() => _isCameraInitialized = false);
    _controller?.dispose();
    _controller = CameraController(camera, ResolutionPreset.high);
    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _flipCamera() {
    if (widget.cameras.length < 2) return;
    _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;
    _initCamera(widget.cameras[_currentCameraIndex]);
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isTakingPicture) return;
    setState(() => _isTakingPicture = true);
    _shutterAnimController.forward().then((_) => _shutterAnimController.reverse());
    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        _showResultDialog(image);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  void _showResultDialog(XFile image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Hasil Jepretan',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: FutureBuilder<Uint8List>(
                  future: image.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      );
                    }
                    return Image.memory(snapshot.data!, fit: BoxFit.contain);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _shutterAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameras.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_photography, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text('Kamera tidak ditemukan', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // --- Top Control Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'KAMERA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  // Flash toggle
                  GestureDetector(
                    onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isFlashOn ? Colors.amber.withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: _isFlashOn ? Colors.amber : Colors.white60,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Camera Preview ---
            Expanded(
              child: _isCameraInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: CameraPreview(_controller!),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),

            // --- Bottom Control Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gallery placeholder
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Colors.white54, size: 24),
                  ),

                  // Shutter button
                  ScaleTransition(
                    scale: _shutterAnim,
                    child: GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Flip camera
                  GestureDetector(
                    onTap: _flipCamera,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

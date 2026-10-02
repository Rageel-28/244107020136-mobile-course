import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:audioplayers/audioplayers.dart';
import 'lirik_page.dart';
import 'camera_page.dart';
import 'gps_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error getting cameras: $e');
  }
  runApp(RakagaliApp(cameras: cameras));
}

class RakagaliApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const RakagaliApp({super.key, required this.cameras});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Music',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0E), // Very deep dark blue/black
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF8E8CD8),
          surface: Color(0xFF14141C),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Inter', letterSpacing: -1.5),
          bodyLarge: TextStyle(fontFamily: 'Inter'),
        ),
      ),
      home: MainPage(cameras: cameras),
    );
  }
}

class MainPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MainPage({super.key, required this.cameras});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Listen to global audio player state
    LirikPage.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const LirikPage(),
      const SearchPage(),
      const LibraryPage(),
      CameraPage(cameras: widget.cameras),
      const GpsPage(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // The pages
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          
          // Floating Glass Navigation Bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Mini Player
                if (_selectedIndex != 0) 
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage('https://upload.wikimedia.org/wikipedia/id/7/78/Tulus_-_Manusia_%28Album_Cover%29.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Hati-Hati di Jalan', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                    Text('Tulus', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 36),
                                onPressed: () async {
                                  if (_isPlaying) {
                                    await LirikPage.audioPlayer.pause();
                                  } else {
                                    // Ensure source is loaded if not already
                                    if (LirikPage.audioPlayer.source == null) {
                                      await LirikPage.audioPlayer.setSource(UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
                                    }
                                    await LirikPage.audioPlayer.resume();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Navigation Pill
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30)
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(Icons.adjust_rounded, 0, 'Now'),
                          _buildNavItem(Icons.search_rounded, 1, 'Discover'),
                          _buildNavItem(Icons.library_music_rounded, 2, 'Vault'),
                          _buildNavItem(Icons.camera_alt_rounded, 3, 'Lens'),
                          _buildNavItem(Icons.location_on_rounded, 4, 'Radar'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected 
            ? [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 15, spreadRadius: 1)]
            : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white60,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [Color(0xFF2A1B38), Color(0xFF0A0A0E)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Explore', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                    const SizedBox(height: 24),
                    // Glass Search Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            hintText: 'Artists, songs, or podcasts',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            prefixIcon: const Icon(Icons.search, color: Colors.white),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text('Trending Vibes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final titles = ['Acoustic\nChill', 'Midnight\nDrive', 'Lo-Fi\nStudy', 'Neon\nPop', 'Deep\nFocus', 'Workout\nEnergy', 'Jazz\nVibes', 'Indie\nMix'];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: NetworkImage('https://picsum.photos/seed/${index * 5}/300/400'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            titles[index], 
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5)
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 8,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 150)), // Space for floating nav
          ],
        ),
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [Color(0xFF1B2A38), Color(0xFF0A0A0E)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 80,
          title: const Text('Your Vault', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
          actions: [
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 32), onPressed: () {}),
            const SizedBox(width: 16),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 150),
          physics: const BouncingScrollPhysics(),
          children: [
            // Glass Cards for library items
            _buildVaultItem('Favorites', '128 tracks', Icons.favorite, const Color(0xFFE91E63)),
            const SizedBox(height: 16),
            _buildVaultItem('Downloaded', '45 albums ready offline', Icons.cloud_done, const Color(0xFF4CAF50)),
            const SizedBox(height: 16),
            _buildVaultItem('Local Files', 'From your device', Icons.folder, const Color(0xFFFF9800)),
            
            const SizedBox(height: 40),
            const Text('Recent Magic', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            _buildRecentItem('Tulus', 'Artist', 'https://upload.wikimedia.org/wikipedia/id/7/78/Tulus_-_Manusia_%28Album_Cover%29.jpg'),
            const SizedBox(height: 16),
            _buildRecentItem('Top 50 Global', 'Playlist', 'https://picsum.photos/seed/50/200/200'),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultItem(String title, String subtitle, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(String title, String type, String imageUrl) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(type, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

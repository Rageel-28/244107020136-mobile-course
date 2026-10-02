import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine(this.time, this.text);
}

class LirikPage extends StatefulWidget {
  const LirikPage({super.key});
  
  static final AudioPlayer audioPlayer = AudioPlayer();

  @override
  State<LirikPage> createState() => _LirikPageState();
}

class _LirikPageState extends State<LirikPage> with TickerProviderStateMixin {
  bool isPlaying = false;
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = const Duration(minutes: 4, seconds: 2);
  
  late AnimationController _spinController;
  
  // Settings state (Course Requirements)
  bool scrollOtomatis = true;
  bool modeGelap = true; // Still here to fulfill requirements, though UI is inherently dark
  String nilaiDropdown = 'Tinggi';

  final ScrollController _lyricsScrollController = ScrollController();
  
  // Synchronized Lyrics
  final List<LyricLine> _lyrics = [
    LyricLine(const Duration(seconds: 0), '...'),
    LyricLine(const Duration(seconds: 14), 'Perjalanan membawamu'),
    LyricLine(const Duration(seconds: 18), 'Bertemu denganku'),
    LyricLine(const Duration(seconds: 22), 'Ku bertemu kamu'),
    LyricLine(const Duration(seconds: 27), 'Sepertimu yang kucari'),
    LyricLine(const Duration(seconds: 31), 'Konon aku juga'),
    LyricLine(const Duration(seconds: 35), 'Seperti yang kau cari'),
    LyricLine(const Duration(seconds: 40), 'Kukira kita asam dan garam'),
    LyricLine(const Duration(seconds: 44), 'Dan kita bertemu di belanga'),
    LyricLine(const Duration(seconds: 48), 'Kisah yang ternyata tak seindah itu'),
    LyricLine(const Duration(seconds: 53), 'Kukira kita akan bersama'),
    LyricLine(const Duration(seconds: 58), 'Begitu banyak yang sama'),
    LyricLine(const Duration(seconds: 62), 'Latarmu dan latarku'),
    LyricLine(const Duration(seconds: 66), 'Kukira takkan ada kendala'),
    LyricLine(const Duration(seconds: 71), 'Kukira inikan mudah'),
    LyricLine(const Duration(seconds: 75), 'Kau aku jadi kita'),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    
    LirikPage.audioPlayer.setSource(UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));

    LirikPage.audioPlayer.onDurationChanged.listen((Duration d) {
      if (mounted) setState(() => _totalDuration = d);
    });

    LirikPage.audioPlayer.onPositionChanged.listen((Duration p) {
      if (mounted) {
        setState(() => _currentDuration = p);
        _handleLyricsScroll();
      }
    });

    LirikPage.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => isPlaying = state == PlayerState.playing);
        if (isPlaying) {
          _spinController.repeat();
        } else {
          _spinController.stop();
        }
      }
    });
  }

  int get _currentLyricIndex {
    for (int i = _lyrics.length - 1; i >= 0; i--) {
      if (_currentDuration >= _lyrics[i].time) {
        return i;
      }
    }
    return 0;
  }
  
  void _handleLyricsScroll() {
    if (scrollOtomatis && _lyricsScrollController.hasClients) {
      int index = _currentLyricIndex;
      double targetOffset = (index * 60.0) - 80;
      if (targetOffset < 0) targetOffset = 0;
      
      _lyricsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (isPlaying) {
      await LirikPage.audioPlayer.pause();
    } else {
      await LirikPage.audioPlayer.resume();
    }
  }

  void _onSliderChanged(double value) {
    final duration = Duration(milliseconds: value.toInt());
    LirikPage.audioPlayer.seek(duration);
    setState(() {
      _currentDuration = duration;
    });
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString();
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Dynamic Blur Background
          Positioned.fill(
            child: Image.network(
              'https://upload.wikimedia.org/wikipedia/id/7/78/Tulus_-_Manusia_%28Album_Cover%29.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                color: Colors.black.withOpacity(0.5), // Darken the blur
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top App Bar Area
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                          child: IconButton(icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 30), onPressed: () {}),
                        ),
                        const Column(
                          children: [
                            Text('NOW SPINNING', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                          child: IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () {}),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Vinyl Record Album Art
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow behind the record
                          Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.white.withOpacity(isPlaying ? 0.2 : 0.05), blurRadius: 60, spreadRadius: 10)
                              ],
                            ),
                          ),
                          // The Spinning Record
                          RotationTransition(
                            turns: _spinController,
                            child: Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 15))
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      'https://upload.wikimedia.org/wikipedia/id/7/78/Tulus_-_Manusia_%28Album_Cover%29.jpg',
                                      width: 320, height: 320, fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Vinyl Grooves Overlay
                                  Container(
                                    width: 320, height: 320,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                                        stops: const [0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Center Hole
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF111111),
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Track Info & Slider
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
                    child: Column(
                      children: [
                        const Text('Hati-Hati di Jalan', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text('Tulus', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18)),
                        const SizedBox(height: 40),
                        
                        // Custom Glass Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0, elevation: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: (_currentDuration.inMilliseconds.toDouble()).clamp(0, _totalDuration.inMilliseconds.toDouble()),
                            min: 0,
                            max: _totalDuration.inMilliseconds.toDouble(),
                            onChanged: _onSliderChanged,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_currentDuration), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('-${_formatDuration(_totalDuration - _currentDuration)}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Massive Custom Glass Controls
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 48), onPressed: () => LirikPage.audioPlayer.seek(Duration.zero)),
                        const SizedBox(width: 30),
                        GestureDetector(
                          onTap: _togglePlay,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                                ),
                                child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 40),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 48), onPressed: () {}),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
                
                // Cinematic Lyrics
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.all(30),
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                            stops: [0.0, 0.2, 0.8, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ListView.builder(
                          controller: _lyricsScrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _lyrics.length,
                          itemBuilder: (context, index) {
                            bool isCurrent = index == _currentLyricIndex;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuint,
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : Colors.white.withOpacity(0.2),
                                  fontSize: isCurrent ? 34 : 24,
                                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                                  height: 1.2,
                                  letterSpacing: -1,
                                ),
                                child: Text(_lyrics[index].text),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Course Requirements / Bottom Extras
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Course Requirements', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              const SizedBox(height: 20),
                              TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Leave a comment...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                title: const Text('Auto-scroll Lyrics', style: TextStyle(color: Colors.white)),
                                value: scrollOtomatis,
                                onChanged: (val) => setState(() => scrollOtomatis = val ?? false),
                                activeColor: Colors.white, checkColor: Colors.black,
                                contentPadding: EdgeInsets.zero,
                              ),
                              Row(
                                children: [
                                  const Text('Quality: ', style: TextStyle(color: Colors.white)),
                                  const SizedBox(width: 10),
                                  DropdownButton<String>(
                                    value: nilaiDropdown,
                                    dropdownColor: const Color(0xFF1E1E1E),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    onChanged: (val) => setState(() => nilaiDropdown = val!),
                                    items: const [
                                      DropdownMenuItem(value: 'Tinggi', child: Text('Lossless')),
                                      DropdownMenuItem(value: 'Biasa', child: Text('High Quality')),
                                      DropdownMenuItem(value: 'Rendah', child: Text('Data Saver')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

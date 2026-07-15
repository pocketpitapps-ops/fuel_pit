// lib/features/intro/splash_intro_page.dart
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:fuel_pit/main.dart';
import 'package:fuel_pit/features/intro/splash_intro_config.dart';

class SplashIntroPage extends StatefulWidget {
  const SplashIntroPage({super.key});

  @override
  State<SplashIntroPage> createState() => _SplashIntroPageState();
}

class _SplashIntroPageState extends State<SplashIntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _logoPlayer = AudioPlayer();
  final AudioPlayer _ppPlayer = AudioPlayer();
  final AudioPlayer _carPlayer = AudioPlayer();
  bool _logoPlayed = false;
  bool _ppPlayed = false;
  bool _carPlayed = false;
  bool _navigated = false;

  // Logo: fade + scale
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  // PP: fade in + blink + fade out
  late Animation<double> _ppOpacity;

  // Car: opacity + scale + slide
  late Animation<double> _carOpacity;
  late Animation<double> _carScale;
  late Animation<double> _carSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: splashTimelineDuration,
    );

    _logoPlayer.setPlayerMode(PlayerMode.lowLatency);
    _ppPlayer.setPlayerMode(PlayerMode.lowLatency);
    _carPlayer.setPlayerMode(PlayerMode.lowLatency);

    // ── Logo: 0.0→0.25 ──
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashLogoIntervalBegin,
          splashLogoIntervalEnd,
          curve: Curves.easeOut,
        ),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashLogoIntervalBegin,
          splashLogoIntervalEnd,
          curve: Curves.easeOut,
        ),
      ),
    );

    // ── PP: fade in → blink ×2 → hold → fade out ──
    // Fase 1: fade in (0.25→0.35)
    // Fase 2: blink (0.35→0.60) — pisca 2 vezes
    // Fase 3: hold (0.60→0.70)
    // Fase 4: fade out (0.70→1.0)
    _ppOpacity = _PpBlinkAnimation(
      controller: _controller,
      fadeInBegin: splashPpIntervalBegin,
      fadeInEnd: splashPpIntervalEnd,
      blinkBegin: 0.35,
      blinkEnd: 0.60,
      holdEnd: splashSwapIntervalBegin,
      fadeOutEnd: splashSwapIntervalEnd,
    );

    // ── Car: entra com impacto 0.70→1.0 ──

    // Opacity: fade in rápido
    _carOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashSwapIntervalBegin,
          splashSwapIntervalBegin + 0.10,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Scale: cresce de 0.3 → 1.0 com bounce
    _carScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashSwapIntervalBegin,
          splashSwapIntervalEnd,
          curve: Curves.elasticOut,
        ),
      ),
    );

    // Slide: desce de cima (-80px → 0)
    _carSlide = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashSwapIntervalBegin,
          splashSwapIntervalEnd,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _controller.forward();

    _controller.addListener(() {
      final t = _controller.value;
      if (!_logoPlayed && t >= splashAudioLogoTrigger) {
        _logoPlayed = true;
        _logoPlayer.play(AssetSource('audio/intro_logo.mp3'), volume: 1.0);
      }
      if (!_ppPlayed && t >= splashAudioPpTrigger) {
        _ppPlayed = true;
        _ppPlayer.play(AssetSource('audio/intro_pp.mp3'), volume: 1.0);
      }
      if (!_carPlayed && t >= splashAudioCarTrigger) {
        _carPlayed = true;
        _carPlayer.play(AssetSource('audio/intro_car.mp3'), volume: 1.0);
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        Future.delayed(splashAudioPostDelay, () {
          if (!mounted || _navigated) return;
          _navigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthOrHomeRoot()),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _logoPlayer.dispose();
    _ppPlayer.dispose();
    _carPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            const double containerSize =
                splashBaseContainerSize * splashScaleFactor;
            const double logoSize = splashBaseLogoSize * splashScaleFactor;
            const double ppWidth = splashBasePpWidth * splashScaleFactor;
            const double ppHeight = splashBasePpHeight * splashScaleFactor;
            const double carWidth = splashBaseCarWidth * splashScaleFactor;
            const double carHeight = splashBaseCarHeight * splashScaleFactor;

            return SizedBox(
              width: containerSize,
              height: containerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Logo principal (fade in + scale) ──
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset(
                        'assets/images/logo_pocket_pit_original.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // ── Letras PP (dentro do logo, com blink) ──
                  Opacity(
                    opacity: _ppOpacity.value,
                    child: Transform.translate(
                      offset: const Offset(0, splashPpYOffset),
                      child: Image.asset(
                        'assets/images/letras_pocket_pit_original.png',
                        width: ppWidth,
                        height: ppHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // ── Carro (entra com scale + slide + fade) ──
                  Positioned(
                    bottom: splashCarBottom,
                    child: Opacity(
                      opacity: _carOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _carSlide.value),
                        child: Transform.scale(
                          scale: _carScale.value,
                          child: Image.asset(
                            'assets/images/car.png',
                            width: carWidth,
                            height: carHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── PP Blink Animation ──
// Combina fade in, 2 blinks, hold e fade out num único Animation<double>.

class _PpBlinkAnimation extends Animation<double> {
  _PpBlinkAnimation({
    required this.controller,
    required this.fadeInBegin,
    required this.fadeInEnd,
    required this.blinkBegin,
    required this.blinkEnd,
    required this.holdEnd,
    required this.fadeOutEnd,
  });

  final AnimationController controller;
  final double fadeInBegin;
  final double fadeInEnd;
  final double blinkBegin;
  final double blinkEnd;
  final double holdEnd;
  final double fadeOutEnd;

  @override
  double get value {
    final t = controller.value;

    // Antes do fade in
    if (t <= fadeInBegin) return 0.0;

    // Fade in
    if (t <= fadeInEnd) {
      return (t - fadeInBegin) / (fadeInEnd - fadeInBegin);
    }

    // Blink phase: 2 blinks entre blinkBegin e blinkEnd
    if (t <= blinkEnd) {
      final blinkDuration = blinkEnd - blinkBegin;
      final blinkT = (t - blinkBegin) / blinkDuration;

      // Cada blink é um ciclo de 0→1→0 com 50% duty cycle
      // 2 blinks = 2 ciclos completos
      final cycleCount = 2.0;
      final cycle = (blinkT * cycleCount) % 1.0;

      // Ondulação suave: seno invertido
      // 1.0 = visível, 0.15 = quase invisível
      final minOpacity = 0.15;
      return minOpacity + (1.0 - minOpacity) * (0.5 + 0.5 * math.cos(cycle * 2 * math.pi));
    }

    // Hold: visível
    if (t <= holdEnd) return 1.0;

    // Fade out
    if (t <= fadeOutEnd) {
      return 1.0 - (t - holdEnd) / (fadeOutEnd - holdEnd);
    }

    return 0.0;
  }

  @override
  AnimationStatus get status => controller.status;

  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) =>
      controller.addStatusListener(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      controller.removeStatusListener(listener);
}

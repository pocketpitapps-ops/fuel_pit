// lib/features/intro/splash_intro_config.dart

import 'package:flutter/material.dart';

// Duração total da timeline (5.5s)
const Duration splashTimelineDuration = Duration(milliseconds: 5500);
// Espera após animação antes de navegar
const Duration splashPostDelayDuration = Duration(seconds: 2);

// ── Intervals da timeline (0–1 dentro do controller) ──

// Logo: fade in + scale (0.0→0.25 = 1.4s)
const double splashLogoIntervalBegin = 0.0;
const double splashLogoIntervalEnd = 0.25;

// Letras PP: entram dentro do logo (0.25→0.35 = 0.55s)
const double splashPpIntervalBegin = 0.25;
const double splashPpIntervalEnd = 0.35;

// Hold: logo + PP visíveis (0.35→0.70 = 1.9s)

// Swap: PP desaparece, carro entra com impacto (0.70→1.0 = 1.65s)
const double splashSwapIntervalBegin = 0.70;
const double splashSwapIntervalEnd = 1.0;

// ── Tamanhos base (+20%) ──

const double splashBaseContainerSize = 312;
const double splashBaseLogoSize = 252;
const double splashBasePpWidth = 144;
const double splashBasePpHeight = 108;
const double splashBaseCarWidth = 84;
const double splashBaseCarHeight = 41;

// Fator de escala geral
const double splashScaleFactor = 1.2;

// ── offsets ──

const double splashPpYOffset = -25.0;
const double splashCarBottom = 200.0;

// ── Paleta ──

const Color splashBackgroundColor = Color(0xFF0F172A);
const Color splashLogoBlue = Color(0xFF38BDF8);

// ── Áudio: triggers (quando tocar cada som) ──
const double splashAudioLogoTrigger = 0.0;
const double splashAudioPpTrigger = 0.25;
const double splashAudioCarTrigger = 0.70;

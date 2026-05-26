import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/services/id.dart';
import '../../../core/services/permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';

class VoiceCapturePage extends ConsumerStatefulWidget {
  const VoiceCapturePage({super.key, this.onConfirmed});

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.pop()` (or `/home` if the page was deep-linked).
  final void Function(BuildContext context)? onConfirmed;

  @override
  ConsumerState<VoiceCapturePage> createState() => _VoiceCapturePageState();
}

class _VoiceCapturePageState extends ConsumerState<VoiceCapturePage>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  // What the user explicitly wants. Different from [_listening] because
  // Android/iOS end a session after pauseFor silence; we then auto-restart
  // if [_userWantsToListen] is still true, accumulating into [_committed].
  bool _userWantsToListen = false;
  // Confirmed/finalized text from previous session(s). When the user pauses
  // and the engine ends a session, the partial transcript becomes "committed"
  // and the next session's partials are appended to it. Without this two-
  // buffer model, every pause would wipe the box back to empty.
  String _committed = '';
  // Live partial from the current session — replaced as the engine streams.
  String _partial = '';
  // Sound amplitude from the mic, normalized to [0..1] and used by the
  // mic pulse to "breathe" with the speaker's voice. The native plugin
  // reports a raw level on Android with no documented unit (commonly 0..10),
  // so we clamp/normalize defensively rather than assuming a range.
  //
  // Held in a ValueNotifier (not setState) because onSoundLevelChange fires
  // at ~10-30 Hz on Android M54 — calling setState here would rebuild the
  // whole Scaffold (AppBar, status text, transcript, confirm button) at
  // that rate. The ValueListenableBuilder inside _PulseMic scopes the
  // rebuild to just the mic stack. Per flutter-perf-auditor MS-15a-followup.
  final ValueNotifier<double> _soundLevel = ValueNotifier<double>(0);

  String get _transcript {
    if (_committed.isEmpty) return _partial;
    if (_partial.isEmpty) return _committed;
    return '$_committed $_partial';
  }

  // Pulse-ring animation (prototype: animation 'rpPulse 2s ease-out infinite').
  // The two outer rings scale + fade out continuously while the page is
  // mounted; the inner mic circle stays static.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // Initialize the engine ONCE per page mount. Without this, every
    // toggle paid ~500ms of init latency which is what made the first
    // word slow to appear.
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ready = await _speech.initialize(
      onStatus: _onStatus,
      onError: (_) {
        if (!mounted) return;
        _soundLevel.value = 0;
        setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    setState(() => _speechReady = ready);
  }

  /// Auto-restart on `done` / `notListening` while the user still wants to
  /// listen. The plugin doc explicitly says continuous recognition isn't
  /// supported by the OS; this is the community-recommended workaround —
  /// promote the current partial into [_committed] and start a new session.
  void _onStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      if (_userWantsToListen) {
        if (_partial.isNotEmpty) {
          _committed = _committed.isEmpty ? _partial : '$_committed $_partial';
          _partial = '';
        }
        _startSession();
      } else {
        _soundLevel.value = 0;
        setState(() => _listening = false);
      }
    } else if (status == 'listening') {
      setState(() => _listening = true);
    }
  }

  Future<void> _startSession() async {
    if (!_speechReady) return;
    await _speech.listen(
      localeId: 'pt_BR',
      // Long window so the user can dictate a full address without the
      // engine cutting off; pauseFor is the silence threshold that ends
      // the utterance. Per csdcorp/speech_to_text docs these defaults
      // (30s / 3s) work well for short-form addresses.
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      // Explicit partial-results option — recommended over the deprecated
      // positional arg per the v7 API docs.
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (result) {
        if (!mounted) return;
        setState(() => _partial = result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        // Empirical range on Android M54: ~0..10 with peaks above. Clamp
        // and normalize to [0..1] so the UI mapping (scale 1.0..1.3) is
        // stable regardless of device. Writing to _soundLevel.value (not
        // setState) is the perf fix from MS-15a-followup audit.
        _soundLevel.value = (level.clamp(0, 10) / 10).toDouble();
      },
    );
  }

  Future<void> _toggleListen() async {
    if (_listening || _userWantsToListen) {
      _userWantsToListen = false;
      await _speech.stop();
      if (!mounted) return;
      // Promote the trailing partial into committed so the user keeps the
      // last bit they said before tapping "Parar".
      if (_partial.isNotEmpty) {
        _committed = _committed.isEmpty ? _partial : '$_committed $_partial';
        _partial = '';
      }
      _soundLevel.value = 0;
      setState(() => _listening = false);
      return;
    }

    final outcome = await ref.read(appPermissionsProvider).requestMicrophone();
    if (!mounted) return;
    if (outcome != PermissionOutcome.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão do microfone necessária.')),
      );
      return;
    }
    if (!_speechReady) {
      // First-toggle race: init might still be running. Retry init inline
      // so the user doesn't have to wait for an arbitrary timer.
      await _initSpeech();
      if (!mounted || !_speechReady) return;
    }

    setState(() {
      _userWantsToListen = true;
      _committed = '';
      _partial = '';
    });
    await _startSession();
  }

  Future<void> _confirm() async {
    final text = _transcript.trim();
    if (text.isEmpty) return;

    final stop = Stop(
      id: newId(),
      lat: 0,
      lng: 0,
      label: text,
      source: StopSource.voice,
      createdAt: DateTime.now(),
    );
    await ref.read(stopsControllerProvider.notifier).add(stop);
    if (!mounted) return;
    (widget.onConfirmed ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTranscript = _transcript.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Falar endereço')),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: _PulseMic(
                  controller: _pulse,
                  soundLevel: _soundLevel,
                  listening: _listening,
                  onTap: _toggleListen,
                  // Re-used by widget tests to find the mic CTA.
                  micKey: const Key('voice-mic-button'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _listening ? 'Ouvindo...' : 'Toque para falar o endereço',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // surface (#F8F7FC) not bg (#FFF) — the transcript box
                  // must recede from the white page to read as a container.
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Text(
                  hasTranscript
                      ? _transcript
                      : '"Rua Haddock Lobo mil e quinhentos, '
                          'apartamento doze zero um..."',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontStyle:
                        hasTranscript ? FontStyle.normal : FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              // Single CTA: "Adicionar parada", enabled only when a
              // transcript exists. Start/stop listening is the mic tap
              // itself (gradient flips red while listening) — no separate
              // Parar / Tentar buttons, by request.
              RpButton(
                key: const Key('voice-confirm-button'),
                label: 'Adicionar parada',
                icon: const Icon(
                  LucideIcons.check,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: hasTranscript ? _confirm : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 200x200 stack with two animated pulse rings around a static
/// gradient mic circle (per `prototipo/screens-a.jsx:373-386`).
///
/// Ring 1 grows 80→200 px with opacity 0.4→0; ring 2 grows 120→160 px
/// with opacity 0.6→0 on a half-cycle phase offset so they stagger.
/// The inner 100x100 mic circle is static and clickable.
class _PulseMic extends StatelessWidget {
  const _PulseMic({
    required this.controller,
    required this.soundLevel,
    required this.listening,
    required this.onTap,
    required this.micKey,
  });

  final AnimationController controller;

  /// Normalized [0..1] mic amplitude. Scales the inner disc + mic circle
  /// 1.0 → 1.3 so the visual "breathes" with the user's voice. Listenable
  /// instead of a plain double so high-frequency mic-level updates (10-30 Hz)
  /// only rebuild the inner scaled subtree, not the whole page. Per
  /// flutter-perf-auditor MS-15a-followup.
  final ValueListenable<double> soundLevel;

  /// When true the mic gradient flips to the error-red palette to signal
  /// "recording in progress" (modern voice-UI convention — same affordance
  /// used by iOS Dictation and Google Recorder).
  final bool listening;
  final VoidCallback onTap;
  final Key micKey;

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary keeps the 60fps pulse + amplitude rebuilds inside
    // their own GPU layer so the rest of the page (AppBar, status text,
    // transcript box, confirm button) doesn't get re-rasterized every
    // frame. Per flutter-perf-auditor MS-15a-followup.
    return RepaintBoundary(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final t = controller.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring 1 peaks at 0.4; ring 2 peaks at 0.6 (staggered
                    // half-phase) so the two waves are visually distinct,
                    // matching prototipo/screens-a.jsx:375-376.
                    _Ring(size: 80 + 120 * t, opacity: (1 - t) * 0.4),
                    _Ring(
                      size: 80 + 120 * ((t + 0.5) % 1),
                      opacity: (1 - (t + 0.5) % 1) * 0.6,
                    ),
                  ],
                );
              },
            ),
            // Inner disc + mic circle scale together with the mic
            // amplitude. ValueListenableBuilder scopes the rebuild to JUST
            // this subtree; AnimatedScale interpolates each new soundLevel
            // smoothly (120ms) so spikes don't look jittery.
            ValueListenableBuilder<double>(
              valueListenable: soundLevel,
              builder: (_, level, child) => AnimatedScale(
                scale: 1 + 0.3 * level,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: child,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner static disc (matches prototype's third static ring
                  // sitting behind the gradient circle; opacity 0.8 per
                  // prototipo/screens-a.jsx:377).
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.8),
                    ),
                  ),
                  // Gradient mic circle (100x100). Purple gradient at rest,
                  // red gradient while listening. AnimatedContainer smoothly
                  // interpolates the color swap over 200ms.
                  GestureDetector(
                    key: micKey,
                    onTap: onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: listening
                              ? const [Color(0xFFFF6B6B), AppColors.error]
                              : const [AppColors.accent, AppColors.primary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            // 0.4-alpha tint of the active gradient color
                            // (error vs primary) used as the drop shadow.
                            color: listening
                                ? const Color(0x66EF4444)
                                : const Color(0x666C3FC5),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        listening ? LucideIcons.square : LucideIcons.mic,
                        size: 42,
                        color: Colors.white,
                      ),
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

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight.withValues(alpha: opacity),
      ),
    );
  }
}

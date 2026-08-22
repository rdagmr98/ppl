import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdIds {
  static const banner = 'ca-app-pub-2556899149200560/8355466260';
  static const nativeAnswer = 'ca-app-pub-2556899149200560/4880140160';
  static const nativeFooter = 'ca-app-pub-2556899149200560/1646482480';
  static const nativeFactoryId = 'ppl_native';
}

/// Banner persistente. Va montato una sola volta (es. in fondo alla home).
class PplBannerAd extends StatefulWidget {
  const PplBannerAd({super.key});

  @override
  State<PplBannerAd> createState() => _PplBannerAdState();
}

class _PplBannerAdState extends State<PplBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _load();
  }

  void _load() {
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

/// Native ad "a schermo intero" (stesso pattern collaudato in gym_app:
/// SizedBox 260 + ClipRRect, mai tagliato). Ricarica un annuncio nuovo ogni
/// volta che [reloadKey] cambia: ogni load() è una nuova richiesta d'asta,
/// quindi una nuova opportunità di guadagno indipendentemente dall'ad unit.
class PplNativeAd extends StatefulWidget {
  final String adUnitId;
  final Object reloadKey;

  const PplNativeAd({super.key, required this.adUnitId, this.reloadKey = 0});

  @override
  State<PplNativeAd> createState() => _PplNativeAdState();
}

class _PplNativeAdState extends State<PplNativeAd> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _load();
  }

  @override
  void didUpdateWidget(PplNativeAd old) {
    super.didUpdateWidget(old);
    if (!kIsWeb && old.reloadKey != widget.reloadKey) {
      _ad?.dispose();
      _ad = null;
      _loaded = false;
      _load();
    }
  }

  void _load() {
    NativeAd(
      adUnitId: widget.adUnitId,
      factoryId: AdIds.nativeFactoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as NativeAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    ).load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_loaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}

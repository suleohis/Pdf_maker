import 'package:google_mobile_ads/google_mobile_ads.dart';
class AdState {
  Future<InitializationStatus> initialization;

  AdState(this.initialization);
  String get bannerAdUnitId => 'ca-app-pub-5393740907868291/2112553015';

  BannerAdListener get adListener => _adListener;

  final BannerAdListener _adListener =  BannerAdListener(
    onAdLoaded: (ad) => print('Ad loaded: ${ad.adUnitId}.'),
    onAdClosed: (ad) => print('Ad closed: ${ad.adUnitId}.'),
    onAdFailedToLoad: (ad, error) =>
        print('Ad failed to load: ${ad.adUnitId}.'),
    onAdOpened: (ad) => print('Ad opened: ${ad.adUnitId}.'),
    onAdClicked: (ad) => print('Ad clicked: ${ad.adUnitId}.'),
    onAdImpression: (ad) => print('Ad impression: ${ad.adUnitId}.'),
    onAdWillDismissScreen: (ad) => print('Ad dismissScreen: ${ad.adUnitId}.')
  );
}
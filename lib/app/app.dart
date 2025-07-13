import 'package:eClassify/data/model/personalized/personalized_settings.dart';
import 'package:eClassify/firebase_options.dart';
import 'package:eClassify/main.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

PersonalizedInterestSettings personalizedInterestSettings =
    PersonalizedInterestSettings.empty();

void initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Setup Google Maps properly
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = false;
  }

  // ✅ Error screen in release mode
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails flutterErrorDetails) {
      return SomethingWentWrong(error: flutterErrorDetails);
    };
  }

  // ✅ Firebase init with proper check
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, st) {
    // Error handled gracefully, print for debug
    debugPrint('🔥 Firebase init error: $e');
    debugPrintStack(stackTrace: st);
  }

  // ✅ AdMob init
  await MobileAds.instance.initialize();

  // ✅ Hive setup
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(HiveKeys.userDetailsBox),
    Hive.openBox(HiveKeys.translationsBox),
    Hive.openBox(HiveKeys.authBox),
    Hive.openBox(HiveKeys.languageBox),
    Hive.openBox(HiveKeys.themeBox),
    Hive.openBox(HiveKeys.svgBox),
    Hive.openBox(HiveKeys.jwtToken),
    Hive.openBox(HiveKeys.historyBox),
  ]);

  // ✅ Lock orientation & launch app
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const EntryPoint());
}

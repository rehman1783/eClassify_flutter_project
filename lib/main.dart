import 'package:device_preview/device_preview.dart';
import 'package:eClassify/app/app.dart';
import 'package:eClassify/app/app_localization.dart';
import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/register_cubits.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/cubits/system/language_cubit.dart';
import 'package:eClassify/ui/screens/chat/chat_audio/globals.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/notification/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:eClassify/firebase_options.dart'; // 🔥 Add this line for Firebase config
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// ✅ Modified main() to support async Firebase initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// try {
//     print('Firebase apps in main(): ${Firebase.apps.length}');

//     if (Firebase.apps.isEmpty) {
//       await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );
//     }
//   } catch (e) {
//     print('Firebase initialization error in main(): $e');
//   }  

  initApp();
}

class EntryPoint extends StatefulWidget {
  const EntryPoint({
    super.key,
  });

  @override
  EntryPointState createState() => EntryPointState();
}

class EntryPointState extends State<EntryPoint> {
  @override
  void initState() {
    super.initState();

    // ✅ Setup Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(
        NotificationService.onBackgroundMessageHandler);

    // ✅ Any other initial logic
    ChatGlobals.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: RegisterCubits().providers,
      child: const App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
 @override
void initState() {
  super.initState();

  Future.microtask(() {
    context.read<LanguageCubit>().loadCurrentLanguage();

    AppTheme currentTheme = HiveUtils.getCurrentTheme();
    context.read<AppThemeCubit>().changeTheme(currentTheme);
  });
}


  @override
  Widget build(BuildContext context) {
    AppTheme currentTheme = context.watch<AppThemeCubit>().state.appTheme;
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return MaterialApp(
          initialRoute: Routes.login,
          navigatorKey: Constant.navigatorKey,
          title: Constant.appName,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: Routes.onGenerateRouted,
          theme: appThemeData[currentTheme],
          builder: (context, child) {
            TextDirection direction = TextDirection.ltr;

            if (languageState is LanguageLoader) {
              direction = languageState.language['rtl']
                  ? TextDirection.rtl
                  : TextDirection.ltr;
            }

            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: Directionality(
                textDirection: direction,
                child: DevicePreview(
                  enabled: false,
                  builder: (context) => child!,
                ),
              ),
            );
          },
          localizationsDelegates: const [
            AppLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: loadLocalLanguageIfFail(languageState),
        );
      },
    );
  }

  /// Handle fallback locale if language load fails
  dynamic loadLocalLanguageIfFail(LanguageState state) {
    if (state is LanguageLoader) {
      return Locale(state.language['code']);
    } else if (state is LanguageLoadFail) {
      return const Locale("en");
    }
  }
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

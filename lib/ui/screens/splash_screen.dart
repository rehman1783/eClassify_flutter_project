import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/system/fetch_language_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/cubits/system/language_cubit.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/settings.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ✅ Missing class added
class SplashScreen extends StatefulWidget {
  final String? itemSlug;
  final String? sellerId;

  const SplashScreen({Key? key, this.itemSlug, this.sellerId})
      : super(key: key);

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool isTimerCompleted = false;
  bool isSettingsLoaded = false;
  bool isLanguageLoaded = false;
  bool isNavigated = false;
  late StreamSubscription<List<ConnectivityResult>> subscription;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();

    hasInternet = true;
    startTimer();

    try {
      subscription = Connectivity().onConnectivityChanged.listen((result) {
        setState(() {
          hasInternet = (!result.contains(ConnectivityResult.none));
        });
        if (hasInternet) {
          context
              .read<FetchSystemSettingsCubit>()
              .fetchSettings(forceRefresh: true);
        }
      });
    } catch (e) {
      log("Connectivity check failed: $e");
    }

    // Fallback timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || isNavigated) return;
      log("Force navigation fallback triggered.");
      isTimerCompleted = true;
      isSettingsLoaded = true;
      isLanguageLoaded = true;
      navigateToScreen();
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Future<void> getDefaultLanguage(String code) async {
    try {
      var language = HiveUtils.getLanguage();
      if (language == null || language['data'] == null) {
        context.read<FetchLanguageCubit>().getLanguage(code);
      } else if (HiveUtils.isUserFirstTime() && code != language['code']) {
        context.read<FetchLanguageCubit>().getLanguage(code);
      } else {
        isLanguageLoaded = true;
        if (mounted) setState(() {});
      }
    } catch (e) {
      log("Error while loading default language: $e");
      isLanguageLoaded = true;
    }
  }

  void startTimer() {
    Timer(const Duration(seconds: 1), () {
      isTimerCompleted = true;
      if (mounted) setState(() {});
    });
  }

  void navigateCheck() {
    if (isTimerCompleted && isSettingsLoaded && isLanguageLoaded) {
      navigateToScreen();
    }
  }

  void navigateToScreen() {
    if (!mounted || isNavigated) return;
    isNavigated = true;

    try {
      if (context
              .read<FetchSystemSettingsCubit>()
              .getSetting(SystemSetting.maintenanceMode) ==
          "1") {
        Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
        return;
      }
    } catch (e) {
      log("Maintenance mode check failed: $e");
    }

    if (HiveUtils.isUserFirstTime()) {
      Navigator.of(context).pushReplacementNamed(Routes.onboarding);
    } else if (HiveUtils.isUserAuthenticated() || HiveUtils.isUserSkip()) {
      Navigator.of(context).pushReplacementNamed(Routes.main, arguments: {
        'from': "main",
        "slug": widget.itemSlug,
        "sellerId": widget.sellerId
      });
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    navigateCheck();

    return hasInternet
        ? BlocListener<FetchLanguageCubit, FetchLanguageState>(
            listener: (context, state) {
              if (state is FetchLanguageSuccess) {
                Map<String, dynamic> map = state.toMap();
                var data = map['file_name'];
                map['data'] = data;
                map.remove("file_name");

                HiveUtils.storeLanguage(map);
                context.read<LanguageCubit>().changeLanguages(map);
                isLanguageLoaded = true;
                if (mounted) setState(() {});
              } else if (state is FetchLanguageFailure) {
                isLanguageLoaded = true;
              }
            },
            child: BlocListener<FetchSystemSettingsCubit,
                FetchSystemSettingsState>(
              listener: (context, state) {
                if (state is FetchSystemSettingsSuccess) {
                  Constant.isDemoModeOn = context
                      .read<FetchSystemSettingsCubit>()
                      .getSetting(SystemSetting.demoMode);
                  getDefaultLanguage(
                      state.settings['data']['default_language']);
                  isSettingsLoaded = true;
                  if (mounted) setState(() {});
                } else if (state is FetchSystemSettingsFailure) {
                  log('${state.errorMessage}');
                  isSettingsLoaded = true;
                }
              },
              child: SafeArea(
                top: false,
                child: AnnotatedRegion(
                  value: SystemUiOverlayStyle(
                    statusBarColor: context.color.territoryColor,
                    statusBarIconBrightness: Brightness.light,
                    systemNavigationBarIconBrightness: Brightness.light,
                    systemNavigationBarColor: context.color.territoryColor,
                  ),
                  child: Scaffold(
                    backgroundColor: context.color.territoryColor,
                    bottomNavigationBar: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: UiUtils.getSvg(AppIcons.companyLogo),
                    ),
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: 150,
                          height: 150,
                          child: UiUtils.getSvg(AppIcons.splashLogo),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: CustomText(
                            AppSettings.applicationName,
                            fontSize: context.font.xxLarge,
                            color: context.color.secondaryColor,
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : NoInternet(
            onRetry: () {
              setState(() {});
            },
          );
  }
}

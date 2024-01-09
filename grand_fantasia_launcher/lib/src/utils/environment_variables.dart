import 'package:envied/envied.dart';

part 'environment_variables.g.dart';

@Envied()
abstract class EnvironmentVariables {
  @EnviedField(varName: 'VERSION_URL')
  static const String versionUrl = _EnvironmentVariables.versionUrl;

  @EnviedField(varName: 'EXE_FILE_NAME')
  static const String exeFileName = _EnvironmentVariables.exeFileName;

  @EnviedField(varName: 'LAUNCHER_FILE_NAME')
  static const String launcherFileName = _EnvironmentVariables.launcherFileName;

  @EnviedField(varName: 'LAUNCHER_UPDATER_FILE_NAME')
  static const String launcherUpdaterFileName =
      _EnvironmentVariables.launcherUpdaterFileName;
}

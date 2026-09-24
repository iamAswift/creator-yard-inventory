import 'commercial_license_provider.dart';
import 'demo_license_service.dart';
import 'license_provider.dart';
import 'license_state.dart';
import '../../database/daos/settings_dao.dart';

class HybridLicenseProvider implements LicenseProvider {
  HybridLicenseProvider({required this.settingsDao});

  final SettingsDao settingsDao;

  late final DemoLicenseService _demoProvider = DemoLicenseService(
    settingsDao: settingsDao,
  );

  late final CommercialLicenseProvider _commercialProvider =
      CommercialLicenseProvider(settingsDao: settingsDao);

  @override
  Future<LicenseState> initialize() async {
    final commercialState = await _commercialProvider.initialize();

    if (commercialState.status == LicenseStatus.licensed) {
      return commercialState;
    }

    return _demoProvider.initialize();
  }

  @override
  Future<bool> hasAccess() async {
    final state = await initialize();
    return state.hasAccess;
  }
}

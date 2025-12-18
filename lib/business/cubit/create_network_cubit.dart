import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/core/services/device_id_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/business/cubit/create_network_state.dart';

// Handles P2P network creation
class CreateNetworkCubit extends Cubit<CreateNetworkState> {
  final P2PService _p2pService;

  CreateNetworkCubit({required P2PService p2pService})
    : _p2pService = p2pService,
      super(CreateNetworkInitial());

  Future<void> startNetwork({
    required String networkName,
    required int maxConnections,
  }) async {
    if (networkName.trim().isEmpty) {
      emit(
        CreateNetworkError(
          message: 'Network name cannot be empty',
          previousState: state,
        ),
      );
      return;
    }

    if (maxConnections < 2) {
      emit(
        CreateNetworkError(
          message: 'Max connections cannot be less than 2',
          previousState: state,
        ),
      );
      return;
    }
    // validated
    emit(
      CreateNetworkStarting(
        networkName: networkName,
        maxConnections: maxConnections,
      ),
    );

    try {
      // Get current user profile from database
      final currentUser = await _getCurrentUserProfile();

      // Initialize P2P host
      await _p2pService.initializeServer(currentUser);

      // Persist network and host device in local DB
      try {
        final db = DatabaseHelper.instance;
        final networkId = await db.createNetwork(
          networkName: networkName,
          hostDeviceId: currentUser.deviceId,
        );

        await db.upsertDevice(
          deviceId: currentUser.deviceId,
          networkId: networkId,
          name: currentUser.name,
          status: currentUser.status,
          isHost: 1,
          avatar: currentUser.avatarLetter,
          color: currentUser.avatarColor.value.toString(),
        );
      } catch (_) {}

      await _p2pService.createNetwork(name: networkName, max: maxConnections);
      emit(
        CreateNetworkActive(
          networkName: networkName,
          maxConnections: maxConnections,
        ),
      );
    } catch (e) {
      emit(
        CreateNetworkError(
          message: 'Failed to create network: $e',
          previousState: CreateNetworkInitial(),
        ),
      );
    }
  }

  // Recovers from error state back to previous state
  void clearError() {
    if (state is CreateNetworkError) {
      final errorState = state as CreateNetworkError;
      emit(errorState.previousState ?? CreateNetworkInitial());
    }
  }

  /// Gets the current user profile from database or creates a default one
  /// Uses persistent device ID that remains the same across app sessions
  Future<UserProfile> _getCurrentUserProfile() async {
    final db = DatabaseHelper.instance;

    // Get persistent device ID
    final deviceId = await DeviceIdService.getDeviceId();

    // Try to load existing user profile from database
    UserProfile? user = await db.getUserProfile(deviceId);

    // If not found, create a default profile
    if (user == null) {
      user = UserProfile(
        emergencyContact: '',
        name: 'My Device',
        deviceId: deviceId,
        avatarLetter: 'M',
        avatarColor: AppColors.connectionTeal,
        status: 'Active',
        email: '',
        phone: '',
        address: '',
        bloodType: '',
      );

      // Save the new profile to database for future use
      await db.saveUserProfile(user);
    }

    return user;
  }
}

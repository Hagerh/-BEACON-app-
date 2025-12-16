import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/core/services/device_id_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/connected_users_model.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/business/cubit/create_network_state.dart';

// Handles P2P network creation and connected user management
class CreateNetworkCubit extends Cubit<CreateNetworkState> {
  final P2PService _p2pService;
  StreamSubscription<List<DeviceDetail>>? _memberSubscription;

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
      await _p2pService.createNetwork(name: networkName, max: maxConnections);

      emit(
        CreateNetworkActive(
          networkName: networkName,
          maxConnections: maxConnections,
          connectedUsers: const [],
        ),
      );

      _memberSubscription = _p2pService.membersStream.listen(_onMembersUpdated);
    } catch (e) {
      emit(
        CreateNetworkError(
          message: 'Failed to create network: $e',
          previousState: CreateNetworkInitial(),
        ),
      );
    }
  }

  void _onMembersUpdated(List<DeviceDetail> members) {
    if (state is! CreateNetworkActive) return;
    final currentState = state as CreateNetworkActive;

    final users = members
        .map(
          (m) => ConnectedUser(
            id: m.deviceId,
            name: m.name,
            joinedAt: DateTime.now(),
          ),
        )
        .toList();

    emit(currentState.copyWith(connectedUsers: users));
  }

  Future<void> disconnectUser(String userId) async {
    if (state is! CreateNetworkActive) return;

    try {
      _p2pService.kickUser(userId);
    } catch (e) {
      emit(
        CreateNetworkError(
          message: 'Failed to disconnect user: $e',
          previousState: state,
        ),
      );
    }
  }

  Future<void> stopNetwork() async {
    if (state is! CreateNetworkActive) return;

    try {
      await _memberSubscription?.cancel();
      _memberSubscription = null;

      await _p2pService.stopNetwork();

      emit(CreateNetworkInitial());
    } catch (e) {
      emit(
        CreateNetworkError(
          message: 'Failed to stop network: $e',
          previousState: state,
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

  // Cleanup method called when cubit is closed
  @override
  Future<void> close() async {
    await _memberSubscription?.cancel();

    if (state is CreateNetworkActive) {
      await _p2pService.stopNetwork();
    }

    return super.close();
  }
}

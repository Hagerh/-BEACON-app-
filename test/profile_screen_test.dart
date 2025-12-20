import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectdemo/business/cubit/profile/user_profile_cubit.dart';
import 'package:projectdemo/business/cubit/profile/user_profile_state.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/presentation/screens/profile_screen.dart';

//  Mock for the Cubit
class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

// Create a Fake for the State class
class FakeProfileState extends Fake implements ProfileState {}

void main() {
  late MockProfileCubit mockProfileCubit;

  // Sample User Data
  final testUser = UserProfile(
    name: 'John Doe',
    avatarLetter: 'J',
    avatarColor: Colors.blue,
    status: 'Active',
    email: 'john@example.com',
    phone: '1234567890',
    address: '123 Street',
    bloodType: 'O+',
    deviceId: 'device_123',
    emergencyContact: '911',
  );

  setUpAll(() {
    registerFallbackValue(FakeProfileState());
  });

  setUp(() {
    mockProfileCubit = MockProfileCubit();
  });

  // Helper function to pump the widget with the Mock Cubit
  Future<void> pumpProfileScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ProfileCubit>.value(
          value: mockProfileCubit,
          child: const ProfileScreen(),
        ),
        // Define routes if your screen navigates
        routes: {
          '/landing': (context) => const Scaffold(body: Text('Landing Screen')),
        },
      ),
    );
  }

  group('ProfileScreen Tests', () {
    testWidgets('Displays Loading Indicator when state is ProfileLoading', (
      tester,
    ) async {
      // Arrange
      when(() => mockProfileCubit.state).thenReturn(ProfileLoading());

      // Act
      await pumpProfileScreen(tester);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays Error Message when state is ProfileError', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to fetch profile';
      when(() => mockProfileCubit.state).thenReturn(ProfileError(errorMessage));

      // Act
      await pumpProfileScreen(tester);

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Displays User Info when state is ProfileLoaded', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockProfileCubit.state,
      ).thenReturn(ProfileLoaded(profile: testUser, isEditable: false));

      // Act
      await pumpProfileScreen(tester);

      // Assert
     
      expect(find.text('John Doe'), findsAtLeastNWidgets(1));

      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
      
    });

    testWidgets('Shows Save Button when profile is Editable', (tester) async {
      // Arrange
      when(
        () => mockProfileCubit.state,
      ).thenReturn(ProfileLoaded(profile: testUser, isEditable: true));

      // Act
      await pumpProfileScreen(tester);

     // Assert 
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Does NOT show Save Button when profile is NOT Editable', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockProfileCubit.state,
      ).thenReturn(ProfileLoaded(profile: testUser, isEditable: false));

      // Act
      await pumpProfileScreen(tester);

      // Assert
      expect(find.text('Save Changes'), findsNothing);
    });
  });
}

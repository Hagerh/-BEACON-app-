import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projectdemo/main.dart' as app;
import 'package:projectdemo/presentation/screens/landing_screen.dart';
import 'package:projectdemo/presentation/screens/profile_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App startup, fill ALL profile fields, save, and verify persistence', (tester) async {
    //  Launch App and Handle Splash Screen
    app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // Wait for Splash Timer
    await tester.pumpAndSettle();

    //  Verify Landing Screen
    expect(find.byType(LandingScreen), findsOneWidget);

    //  Navigate to Profile
    final profileButton = find.byIcon(Icons.person_outline);
    await tester.tap(profileButton);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);


    //name 
    final nameField = find.widgetWithText(TextFormField, 'Name');
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Jane Doe');
    await tester.pump(); 

    // email
    final emailField = find.widgetWithText(TextFormField, 'Email');
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'jane@example.com');
    await tester.pump();

    // number
    final phoneField = find.widgetWithText(TextFormField, 'Phone Number');
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '1234567890');
    await tester.pump();

    //emergency contact
    final emergencyField = find.widgetWithText(TextFormField, 'emergency Phone Number');
    await tester.ensureVisible(emergencyField);
    await tester.enterText(emergencyField, '911');
    await tester.pump();

    //address
    final addressField = find.widgetWithText(TextFormField, 'Address');
    await tester.ensureVisible(addressField);
    await tester.enterText(addressField, '123 Flutter Blvd');
    await tester.pump();

    //blood type
    final bloodField = find.widgetWithText(TextFormField, 'Blood Type');
    await tester.ensureVisible(bloodField);
    await tester.enterText(bloodField, 'O+');
    await tester.pump();

    // --- save  ---

    final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    //Wait for Save and Navigation to finish
    await tester.pumpAndSettle();

    //  Verify we are back on Landing Screen
    expect(find.byType(LandingScreen), findsOneWidget);


    
    // Go BACK to Profile to check if data is still there
    await tester.tap(profileButton);
    await tester.pumpAndSettle();

    // Verify all the data we entered exists on screen
    expect(find.text('Jane Doe'), findsAtLeastNWidgets(1));
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('911'), findsOneWidget);
    expect(find.text('123 Flutter Blvd'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
  });
}
import 'dart:convert';
import 'dart:io';

import 'package:elastic_dashboard/services/field_images.dart';
import 'package:elastic_dashboard/widgets/dashboard_grid.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_dropdown_chooser.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_text_input.dart';
import 'package:elastic_dashboard/widgets/draggable_widget_container.dart';
import 'package:elastic_dashboard/widgets/nt4_widgets/multi-topic/field_widget.dart';
import 'package:elastic_dashboard/widgets/nt4_widgets/multi-topic/gyro.dart';
import 'package:elastic_dashboard/widgets/nt4_widgets/multi-topic/pid_controller.dart';
import 'package:elastic_dashboard/widgets/nt4_widgets/multi-topic/power_distribution.dart';
import 'package:elastic_dashboard/widgets/nt4_widgets/nt4_widget.dart';
import 'package:elastic_dashboard/widgets/nt4_widgets/single_topic/boolean_box.dart';
import 'package:elastic_dashboard/widgets/nt4_widgets/single_topic/text_display.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_util.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String jsonString;
  late Map<String, dynamic> jsonData;

  setUpAll(() async {
    setupMockOfflineNT4();
    await FieldImages.loadFields('assets/fields/');

    String filePath =
        '${Directory.current.path}/test_resources/test-layout.json';

    jsonString = File(filePath).readAsStringSync();
    jsonData = jsonDecode(jsonString);
  });

  testWidgets('Dashboard grid loading', (widgetTester) async {
    FlutterError.onError = ignoreOverflowErrors;
    widgetTester.view.physicalSize = const Size(1920, 1080);
    widgetTester.view.devicePixelRatio = 1.0;
    // WidgetController.hitTestWarningShouldBeFatal = true;

    expect(jsonData.containsKey('tabs'), true);

    expect(jsonData['tabs'][0].containsValue('Teleoperated'), true);
    expect(jsonData['tabs'][0].containsKey('grid_layout'), true);

    expect(jsonData['tabs'][1].containsValue('Autonomous'), true);
    expect(jsonData['tabs'][1].containsKey('grid_layout'), true);

    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (context) => DashboardGridModel(),
            child: DashboardGrid.fromJson(
                jsonData: jsonData['tabs'][0]['grid_layout']),
          ),
        ),
      ),
    );

    await widgetTester.pump(Duration.zero);

    // await widgetTester.pumpAndSettle();

    expect(find.bySubtype<DraggableWidgetContainer>(), findsNWidgets(9));
    expect(find.bySubtype<NT4Widget>(), findsNWidgets(9));

    expect(find.bySubtype<TextDisplay>(), findsOneWidget);
    expect(find.bySubtype<BooleanBox>(), findsOneWidget);
    expect(find.bySubtype<FieldWidget>(), findsOneWidget);
    expect(find.bySubtype<PowerDistribution>(), findsOneWidget);
    expect(find.bySubtype<Gyro>(), findsOneWidget);
    expect(find.bySubtype<PIDControllerWidget>(), findsOneWidget);
  });

  testWidgets('Editing properties', (widgetTester) async {
    FlutterError.onError = ignoreOverflowErrors;
    widgetTester.view.physicalSize = const Size(1920, 1080);
    widgetTester.view.devicePixelRatio = 1.0;

    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (context) => DashboardGridModel(),
            child: DashboardGrid.fromJson(
              key: GlobalKey(),
              jsonData: jsonData['tabs'][0]['grid_layout'],
            ),
          ),
        ),
      ),
    );

    await widgetTester.pump(Duration.zero);

    await widgetTester.ensureVisible(find.text('Test Number'));

    await widgetTester.pumpAndSettle();

    await widgetTester.tap(find.text('Test Number'),
        buttons: kSecondaryMouseButton);

    await widgetTester.pumpAndSettle();

    expect(
        find.text('Test Number', skipOffstage: false), findsAtLeastNWidgets(2));
    expect(find.text('Edit Properties', skipOffstage: false), findsOneWidget);

    await widgetTester.tap(find.text('Edit Properties'));

    await widgetTester.pumpAndSettle();

    expect(
        find.text('Container Settings', skipOffstage: false), findsOneWidget);
    expect(find.text('Network Tables Settings (Advanced)', skipOffstage: false),
        findsOneWidget);

    final titleText =
        find.widgetWithText(DialogTextInput, 'Title', skipOffstage: false);

    expect(titleText, findsOneWidget);

    await widgetTester.enterText(titleText, 'Editing Title Test');
    await widgetTester.testTextInput.receiveAction(TextInputAction.done);
    await widgetTester.pump(Duration.zero);

    expect(find.text('Editing Title Test', skipOffstage: false),
        findsAtLeastNWidgets(2));

    final widgetTypeSelection = find.widgetWithText(
        DialogDropdownChooser<String>, 'Text Display',
        skipOffstage: false);

    expect(widgetTypeSelection, findsOneWidget);

    await widgetTester.tap(widgetTypeSelection);
    await widgetTester.pumpAndSettle();

    expect(find.text('Text Display', skipOffstage: false),
        findsAtLeastNWidgets(2));
    expect(find.text('Graph', skipOffstage: false), findsNothing);

    await widgetTester
        .tap(find.text('Text Display', skipOffstage: false).first);
    await widgetTester.pumpAndSettle();

    final closeButton =
        find.widgetWithText(TextButton, 'Close', skipOffstage: false);

    expect(closeButton, findsOneWidget);

    await widgetTester.tap(closeButton);
    await widgetTester.pumpAndSettle();
  });

  testWidgets('Dragging widgets', (widgetTester) async {
    FlutterError.onError = ignoreOverflowErrors;
    widgetTester.view.physicalSize = const Size(1920, 1080);
    widgetTester.view.devicePixelRatio = 1.0;

    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (context) => DashboardGridModel(),
            child: DashboardGrid.fromJson(
              key: GlobalKey(),
              jsonData: jsonData['tabs'][0]['grid_layout'],
            ),
          ),
        ),
      ),
    );

    await widgetTester.pump(Duration.zero);

    final gyroWidget = find.widgetWithText(WidgetContainer, 'Test Gyro');

    expect(gyroWidget, findsOneWidget);

    // Drag to a valid location
    await widgetTester.drag(gyroWidget, const Offset(256, -128));

    await widgetTester.pumpAndSettle();

    expect(gyroWidget, findsOneWidget);

    // Drag back to its original location
    await widgetTester.drag(gyroWidget, const Offset(-256, 128));

    await widgetTester.pumpAndSettle();

    expect(gyroWidget, findsOneWidget);

    // Drag to an invalid location
    await widgetTester.drag(gyroWidget, const Offset(0, -128));

    await widgetTester.pumpAndSettle();

    expect(gyroWidget, findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class ToggleButton extends NTWidget {
  static const String widgetType = 'Toggle Button';

  const ToggleButton({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    SingleTopicNTWidgetModel model = cast(context.watch<NTWidgetModel>());

    return ValueListenableBuilder(
        valueListenable: model.subscription!,
        builder: (context, data, child) {
          bool value = tryCast(data) ?? false;
          String buttonText =
              model.topic.substring(model.topic.lastIndexOf('/') + 1);

          Size screenSize = MediaQuery.of(context).size;

          // Adjusted button size
          double buttonWidth = screenSize.width * 0.25;  // 25% of screen width
          double buttonHeight = screenSize.height * 0.12; // 12% of screen height

          ThemeData theme = Theme.of(context);

          return GestureDetector(
            onTapUp: (_) {
              bool publishTopic = model.ntTopic == null ||
                  !model.ntConnection.isTopicPublished(model.ntTopic);

              model.createTopicIfNull();

              if (model.ntTopic == null) {
                return;
              }

              if (publishTopic) {
                model.ntConnection.publishTopic(model.ntTopic!);
              }

              model.ntConnection.updateDataFromTopic(model.ntTopic!, !value);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.02,
                  vertical: screenSize.height * 0.02),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: buttonWidth,
                height: buttonHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(3, 3),
                      blurRadius: 12.0,
                      spreadRadius: -4,
                      color: Colors.black45,
                    ),
                  ],
                  color: (value)
                      ? theme.colorScheme.primaryContainer
                      : const Color.fromARGB(255, 50, 50, 50),
                ),
                child: Center(
                    child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall, // Slightly bigger text
                )),
              ),
            ),
          );
        });
  }
}

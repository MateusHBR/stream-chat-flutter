import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/src/utils/utils.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// {@template editMessageSheet}
/// Allows a user to edit the selected message.
/// {@endtemplate}
class EditMessageSheet extends StatelessWidget {
  /// {@macro editMessageSheet}
  const EditMessageSheet({
    Key? key,
    required this.message,
    required this.channel,
    this.editMessageInputBuilder,
  }) : super(key: key);

  /// {@macro editMessageInputBuilder}
  final EditMessageInputBuilder? editMessageInputBuilder;

  /// The message to edit.
  final Message message;

  /// The [StreamChannel] above this widget.
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final streamChatThemeData = StreamChatTheme.of(context);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: StreamChannel(
        channel: channel,
        child: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: StreamSvgIcon.edit(
                      color: streamChatThemeData.colorTheme.disabled,
                    ),
                  ),
                  Text(
                    context.translations.editMessageLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: StreamSvgIcon.closeSmall(),
                    onPressed: Navigator.of(context).pop,
                  ),
                ],
              ),
            ),
            if (editMessageInputBuilder != null)
              editMessageInputBuilder!(context, message)
            else
              MessageInput(
                editMessage: message,
                preMessageSending: (m) {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                  return m;
                },
              ),
          ],
        ),
      ),
    );
  }
}
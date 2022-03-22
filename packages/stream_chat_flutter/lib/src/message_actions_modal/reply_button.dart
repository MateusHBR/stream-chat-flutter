import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/src/utils/extensions.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// {@template replyButton}
/// Allows a user to reply to a message.
///
/// Used by [MessageActionsModal]. Should not be used by itself.
/// {@endtemplate}
class ReplyButton extends StatelessWidget {
  /// {@macro replyButton}
  const ReplyButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  /// The callback to perform when the button is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final streamChatThemeData = StreamChatTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        child: Row(
          children: [
            StreamSvgIcon.reply(
              color: streamChatThemeData.primaryIconTheme.color,
            ),
            const SizedBox(width: 16),
            Text(
              context.translations.replyLabel,
              style: streamChatThemeData.textTheme.body,
            ),
          ],
        ),
      ),
    );
  }
}
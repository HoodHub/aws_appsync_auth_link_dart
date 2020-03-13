import 'dart:async';

import 'package:graphql/client.dart';

class AwsAuthLink extends Link {
  AwsAuthLink()
      : super(
          request: (Operation operation, [NextLink forward]) {
            StreamController<FetchResult> controller;

            Future<void> onListen() async {
              try {
                final String token = '';

                operation.setContext(<String, Map<String, String>>{
                  'headers': <String, String>{'Authorization': token}
                });
              } catch (error) {
                controller.addError(error);
              }

              await controller.addStream(forward(operation));
              await controller.close();
            }

            controller = StreamController<FetchResult>(onListen: onListen);

            return controller.stream;
          },
        );
}

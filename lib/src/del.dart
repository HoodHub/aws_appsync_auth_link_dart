var query = {
    'operationName': 'OnNewPets',
    'query': '''subscription OnNewPets {
        onCreatePet {
          id
          name
          description
        }
      }'''
  };

var _endpoint = 'https://yourendpoint.appsync-api.us-east-1.amazonaws.com/graphql'

  try {
    http.post(
      '$_endpoint',
      headers: {
        'Authorization': _session.getAccessToken().getJwtToken(),  //_session comes from amazon_cognito_identity_dart package
        'Content-Type': 'application/json',
      },
      body: json.encode(query),
    )
        .then((data) {
      Map<String, dynamic> response =
          jsonDecode(data.body) as Map<String, dynamic>;

      mqtt.MqttClient _client;
      mqtt.MqttConnectionState connectionState;

      _client = mqtt.MqttClient(
          response['extensions']['subscription']['mqttConnections'][0]['url']
              .toString(),
          response['extensions']['subscription']['mqttConnections'][0]['client']
              .toString());
      _client.logging(on: true);
      _client.keepAlivePeriod = 300;
      _client.useWebSocket = true;
      _client.onDisconnected = () => print("Disconnected");
      _client.onConnected = () => print("Connected");
      _client.onSubscribed = (value) => print(value);
      _client.port = 443;

      try {
        _client.connect().then((data) {
          if (_client.connectionStatus.state == MqttConnectionState.connected) {
            print('CONNECTED!');
            try {
              _client.subscribe(
                  response['extensions']['subscription']['mqttConnections'][0]
                          ['topics'][0]
                      .toString(),
                  MqttQos.atMostOnce);

              _client.updates
                  .listen((List<MqttReceivedMessage<MqttMessage>> c) {
                final MqttPublishMessage recMess =
                    c[0].payload as MqttPublishMessage;
                final String pt = MqttPublishPayload.bytesToStringAsString(
                    recMess.payload.message);

                print(
                    'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
                print('');
              });

              _client.published.listen((MqttPublishMessage message) {
                print(
                    'EXAMPLE::Published notification:: topic is ${message.variableHeader.topicName}, with Qos ${message.header.qos}');
              });
            } catch (error) {
              print(error);
            }
          }
          print(data);
        });
      } on Exception catch (e) {
        print('EXAMPLE::client exception - $e');
        _client.disconnect();
      }
    });
  } catch (e) {
    print(e);
  }
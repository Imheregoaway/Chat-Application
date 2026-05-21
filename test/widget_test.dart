import 'package:flutter_test/flutter_test.dart';

import 'package:chat_application/services/api_config_service.dart';

void main() {
  test('ApiConfigService has default backend URL', () {
    expect(ApiConfigService.defaultBaseUrl, 'http://127.0.0.1:8000');
  });
}

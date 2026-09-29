import 'package:chatbot_copilot/repository/api_client.dart';
import 'package:chatbot_copilot/repository/chatbot_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<String> tokenErrorWith(String env) async {
    dotenv.testLoad(fileInput: env);
    try {
      await ChatbotRepository().getToken();
    } on ApiException catch (e) {
      return e.message;
    }
    fail('getToken() should have failed');
  }

  test('asks for a token endpoint when .env has none', () async {
    expect(
      await tokenErrorWith('BOT_NAME=Test'),
      contains('Add DIRECT_LINE_TOKEN_ENDPOINT'),
    );
  });

  test('spots the placeholder copied from .env.example', () async {
    final message = await tokenErrorWith(
      'DIRECT_LINE_TOKEN_ENDPOINT=https://<your-environment>.environment.api'
      '.powerplatform.com/powervirtualagents/botsbyschema/<your-agent>/'
      'directline/token?api-version=2022-03-01-preview',
    );

    expect(message, contains('still the example'));
  });
}

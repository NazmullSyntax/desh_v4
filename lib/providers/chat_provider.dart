import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';

const _uuid = Uuid();

/// Generates a reasonable mock reply for the AI Travel Assistant based on
/// simple keyword matching. This keeps the chat screen fully functional
/// offline; swap this for a real LLM call (e.g. Anthropic/OpenAI API via
/// Dio) by replacing the body of [_generateReply] once a backend key is
/// available — the rest of the chat UI doesn't need to change.
class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController() : super([_welcomeMessage()]);

  static ChatMessage _welcomeMessage() {
    return ChatMessage(
      id: _uuid.v4(),
      sender: ChatSender.assistant,
      text:
          "Hi! I'm your DeshExplorer travel assistant. Ask me about destinations, "
          "itineraries, costs, safety, packing, weather, or local culture anywhere in Bangladesh.",
      timestamp: DateTime.now(),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      sender: ChatSender.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    final loadingMessage = ChatMessage(
      id: _uuid.v4(),
      sender: ChatSender.assistant,
      text: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = [...state, userMessage, loadingMessage];

    await Future.delayed(const Duration(milliseconds: 900));

    final reply = _generateReply(text);
    state = [
      ...state.sublist(0, state.length - 1),
      loadingMessage.copyWith(text: reply, isLoading: false),
    ];
  }

  String _generateReply(String input) {
    final q = input.toLowerCase();

    if (q.contains('cox') || q.contains('beach')) {
      return "Cox's Bazar is the most popular beach destination — about 385 km from Dhaka. "
          "Buses take 9–10 hours, flights about 50 minutes. November to March has the best weather. "
          "Want a sample 3-day itinerary?";
    }
    if (q.contains('sundarban') || q.contains('tiger')) {
      return "The Sundarbans are best visited October–March (closed to overnight boats June–August). "
          "Most trips go through Khulna or Mongla as a 2–3 night boat tour with a Forest Department permit "
          "included. Want help estimating the cost?";
    }
    if (q.contains('budget') || q.contains('cost') || q.contains('cheap')) {
      return "A budget 3-day trip (transport + basic hotel + food) typically runs BDT 5,000–10,000 per "
          "person depending on destination. Want me to break this down by transport, stay, and food for "
          "a specific place?";
    }
    if (q.contains('safe') || q.contains('safety')) {
      return "Bangladesh is generally safe for travelers. Keep emergency numbers handy (999 for police/fire/"
          "ambulance), avoid swimming in unmarked beach areas, and use registered guides in the Chittagong "
          "Hill Tracts, where permits are required. Check the Safety tab for full details.";
    }
    if (q.contains('pack') || q.contains('what to bring')) {
      return "Pack light, breathable clothing, sunscreen, a reusable water bottle, comfortable walking "
          "shoes, and a light jacket if visiting hill areas (Sylhet, Bandarban) in winter evenings. "
          "Modest clothing is appreciated at religious sites.";
    }
    if (q.contains('weather')) {
      return "Bangladesh has three main seasons: a hot/humid summer (March–May), monsoon (June–September), "
          "and a cool dry winter (October–February) — winter is the best time for most sightseeing. "
          "Check the Weather tab for live forecasts.";
    }
    if (q.contains('itinerary') || q.contains('plan')) {
      return "I can sketch a day-by-day itinerary — tell me your destination, number of days, and roughly "
          "how many travelers, and I'll put one together. You can also use the Trip Planner tab for a fully "
          "interactive version with a budget calculator.";
    }
    if (q.contains('culture') || q.contains('tradition')) {
      return "Bangladesh's culture blends Bengali traditions with strong regional identities — tea-growing "
          "communities in Sylhet, indigenous groups in the Chittagong Hill Tracts, and river-life culture "
          "in the south. Modest dress is appreciated at religious and rural sites.";
    }

    return "Good question! I can help with destinations, itineraries, budgets, safety, packing, weather, "
        "and culture anywhere in Bangladesh. Could you tell me a bit more about what you're planning?";
  }

  void clearChat() {
    state = [_welcomeMessage()];
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  return ChatController();
});

/// Quick-start prompts shown above the chat input.
final suggestedPromptsProvider = Provider<List<SuggestedPrompt>>((ref) {
  return const [
    SuggestedPrompt(label: 'Plan a 3-day trip', prompt: 'Help me plan a 3-day trip to Cox\'s Bazar'),
    SuggestedPrompt(label: 'Budget estimate', prompt: 'What is a reasonable budget for a weekend trip?'),
    SuggestedPrompt(label: 'Is it safe?', prompt: 'Is it safe to travel to the Chittagong Hill Tracts?'),
    SuggestedPrompt(label: 'What to pack', prompt: 'What should I pack for a trip to Sylhet in winter?'),
  ];
});

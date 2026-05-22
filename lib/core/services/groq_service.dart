import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey = 'YOUR_GROQ_API_KEY';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama3-8b-8192';

  static Future<String> generateExplanation({
    required String topColor,
    required String topStyle,
    required String bottomColor,
    required String bottomStyle,
    required double totalScore,
    required double colorScore,
    required double styleScore,
    required double formalityScore,
    required double weatherScore,
    required double preferenceScore,
    required String weatherCondition,
    required double temperature,
    String occasion = 'Everyday',
    List<String> favoriteColors = const [],
    List<String> preferredStyles = const [],
  }) async {

    final colorLabel     = _label(colorScore * 10);
    final styleLabel     = _label(styleScore * 10);
    final formalityLabel = _label(formalityScore * 10);
    final weatherLabel   = _label(weatherScore * 10);
    final prefLabel      = _label(preferenceScore * 10);
    final verdict        = _verdict(totalScore);

    final favColorsText  = favoriteColors.isEmpty
        ? 'not specified'
        : favoriteColors.join(', ');
    final prefStylesText = preferredStyles.isEmpty
        ? 'not specified'
        : preferredStyles.join(', ');

    final prompt = '''
You are a knowledgeable, honest fashion stylist. A user just scored an outfit in the Ternova app. Give them a thorough, useful critique.

═══════════════════════════════
OUTFIT DETAILS
═══════════════════════════════
Top: $topColor $topStyle
Bottom: $bottomColor $bottomStyle
Occasion: $occasion
Weather: $weatherCondition, ${temperature.toStringAsFixed(0)}°C
User's favourite colours: $favColorsText
User's preferred styles: $prefStylesText

═══════════════════════════════
SCORES (your feedback MUST match these)
═══════════════════════════════
Overall:            ${totalScore.toStringAsFixed(0)}/100 → $verdict
Color Harmony:      ${(colorScore * 10).toStringAsFixed(1)}/10 → $colorLabel
Style Consistency:  ${(styleScore * 10).toStringAsFixed(1)}/10 → $styleLabel
Formality Match:    ${(formalityScore * 10).toStringAsFixed(1)}/10 → $formalityLabel
Weather Suitability:${(weatherScore * 10).toStringAsFixed(1)}/10 → $weatherLabel
Preference Match:   ${(preferenceScore * 10).toStringAsFixed(1)}/10 → $prefLabel

═══════════════════════════════
HONESTY RULES — follow strictly
═══════════════════════════════
- Score < 40 → call it a poor combination, be direct about what fails
- Score 40–59 → acknowledge real problems, don't sugarcoat
- Score 60–74 → decent but point out what's holding it back
- Score 75–89 → genuinely good, explain what makes it work
- Score 90+ → excellent, tell them why this is a strong outfit
- NEVER say an outfit looks great if its score contradicts that
- Color Harmony < 5/10 → explicitly say the colors clash and why
- Style Consistency < 5/10 → say the styles conflict, name the specific clash
- Formality < 5/10 → explain the formality mismatch for the occasion
- Weather < 5/10 → warn them this choice is wrong for ${temperature.toStringAsFixed(0)}°C

═══════════════════════════════
RESPONSE FORMAT — write exactly 5 paragraphs, no headers, no bullets
═══════════════════════════════

Paragraph 1 — OVERALL VERDICT (2-3 sentences)
State the overall score verdict clearly. Say whether this outfit works or doesn't for a $occasion occasion. Be direct.

Paragraph 2 — COLOR HARMONY (2-3 sentences)  
Explain specifically why $topColor and $bottomColor ${colorScore * 10 >= 6 ? 'work well together' : 'are a problematic pairing'}. Reference real color theory — complementary colors, neutrals, contrast, tone matching. Score is ${(colorScore * 10).toStringAsFixed(1)}/10 so your tone must match.

Paragraph 3 — STYLE & FORMALITY (2-3 sentences)
Explain whether $topStyle and $bottomStyle aesthetics are compatible and why. Then explain if the formality level suits a $occasion occasion — score is ${(formalityScore * 10).toStringAsFixed(1)}/10.

Paragraph 4 — WEATHER & OCCASION FIT (2 sentences)
Explain whether this outfit is appropriate for $weatherCondition weather at ${temperature.toStringAsFixed(0)}°C for a $occasion occasion. Score is ${(weatherScore * 10).toStringAsFixed(1)}/10.

Paragraph 5 — WHAT TO DO (2-3 sentences)
If score < 70: give 2 specific changes — name actual colors or styles to swap in. If score >= 70: name 1 accessory or styling tip that would elevate it further. Always end with a single actionable sentence.
''';

    debugPrint('🟡 GroqService: Sending API request...');
    debugPrint('   Model: $_model');
    debugPrint('   Outfit: $topColor $topStyle + $bottomColor $bottomStyle');
    debugPrint('   Score: $totalScore | Occasion: $occasion | Weather: $weatherCondition ${temperature.toStringAsFixed(0)}°C');

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a professional fashion stylist giving honest, '
                      'score-accurate outfit feedback. Your tone must always '
                      'match the numerical scores. Low scores mean real problems. '
                      'High scores deserve genuine praise. Never flatter when '
                      'scores say otherwise.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'max_tokens': 700,
              'temperature': 0.55,
            }),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('📡 Groq response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json    = jsonDecode(response.body);
        final content = json['choices'][0]['message']['content'].toString().trim();
        debugPrint('✅ Groq success — ${content.length} chars received');
        return content;
} else {
        debugPrint('❌ Groq API error ${response.statusCode}: ${response.body}');
        return _fallback(
          totalScore:     totalScore,
          colorScore:     colorScore,
          styleScore:     styleScore,
          weatherScore:   weatherScore,
          formalityScore: formalityScore,
          topColor:       topColor,
          topStyle:       topStyle,
          bottomColor:    bottomColor,
          bottomStyle:    bottomStyle,
          temperature:    temperature,
          occasion:       occasion,
          weatherCondition: weatherCondition,
        );
      }
    } catch (e) {
      debugPrint('❌ Groq exception: $e');
      return _fallback(
        totalScore:     totalScore,
        colorScore:     colorScore,
        styleScore:     styleScore,
        weatherScore:   weatherScore,
        formalityScore: formalityScore,
        topColor:       topColor,
        topStyle:       topStyle,
        bottomColor:    bottomColor,
        bottomStyle:    bottomStyle,
        temperature:    temperature,
        occasion:       occasion,
        weatherCondition: weatherCondition,
      );
    }
  }

  // ── Label helpers ─────────────────────────────────────────────────

  static String _label(double score) {
    if (score >= 9.0) return 'excellent';
    if (score >= 7.5) return 'good';
    if (score >= 6.0) return 'above average';
    if (score >= 5.0) return 'average';
    if (score >= 3.5) return 'below average — notable problems';
    if (score >= 2.0) return 'poor — significant issues';
    return 'very poor — serious problem';
  }

  static String _verdict(double score) {
    if (score >= 85) return 'EXCELLENT outfit — strong across all criteria';
    if (score >= 70) return 'GOOD outfit — works well with minor improvements possible';
    if (score >= 55) return 'AVERAGE — has potential but clear weaknesses';
    if (score >= 40) return 'BELOW AVERAGE — notable problems that hurt this look';
    return 'POOR COMBINATION — significant issues need addressing';
  }

// ── Honest rule-based fallback (used if API fails) ────────────────

  static String _fallback({
    required double totalScore,
    required double colorScore,
    required double styleScore,
    required double weatherScore,
    required double formalityScore,
    required String topColor,
    required String topStyle,
    required String bottomColor,
    required String bottomStyle,
    required double temperature,
    required String occasion,
    required String weatherCondition,
  }) {
    final buf = StringBuffer();

    // Para 1 — overall
    if (totalScore >= 80) {
      buf.write('This is a strong outfit that works well for a $occasion occasion. '
          'The combination scores ${totalScore.toStringAsFixed(0)}/100, which means most elements are pulling in the same direction.');
    } else if (totalScore >= 60) {
      buf.write('This outfit is decent for $occasion but not without its issues. '
          'A score of ${totalScore.toStringAsFixed(0)}/100 means it works, but there are a couple of things worth addressing.');
    } else if (totalScore >= 40) {
      buf.write('This combination scores ${totalScore.toStringAsFixed(0)}/100 — below average for a $occasion occasion. '
          'There are real problems here that would be noticeable.');
    } else {
      buf.write('This outfit scores ${totalScore.toStringAsFixed(0)}/100, which is a poor result. '
          'The combination has fundamental issues that make it hard to pull off for $occasion.');
    }

    buf.write('\n\n');

    // Para 2 — color
    if (colorScore * 10 >= 7.5) {
      buf.write('$topColor and $bottomColor is a solid colour pairing. '
          'These tones complement each other naturally, creating a balanced and cohesive look without competing for attention.');
    } else if (colorScore * 10 >= 5.0) {
      buf.write('The $topColor and $bottomColor combination is acceptable but not optimal. '
          'These colours don\'t naturally enhance each other — try anchoring one of them with a neutral like black or white for a cleaner result.');
    } else {
      buf.write('The $topColor and $bottomColor pairing is a problem. '
          'These colours create tension rather than harmony. '
          'For a better result, pair your $topColor top with black, white, gray, or beige bottoms instead.');
    }

    buf.write('\n\n');

    // Para 3 — style + formality
    if (styleScore * 10 >= 7.0) {
      buf.write('$topStyle and $bottomStyle work together aesthetically — they share a compatible vibe. ');
    } else if (styleScore * 10 >= 5.0) {
      buf.write('The $topStyle and $bottomStyle styles are somewhat mismatched — they don\'t fully align in aesthetic. ');
    } else {
      buf.write('$topStyle and $bottomStyle are conflicting styles that pull this outfit in opposite directions. ');
    }

    if (formalityScore * 10 >= 7.0) {
      buf.write('The formality level is appropriate for $occasion.');
    } else if (formalityScore * 10 >= 5.0) {
      buf.write('The formality is slightly off for $occasion — one piece reads more formal than the other.');
    } else {
      buf.write('The formality mismatch is significant for $occasion — one piece is clearly more formal or casual than the other, creating imbalance.');
    }

    buf.write('\n\n');

    // Para 4 — weather
    if (weatherScore * 10 >= 7.0) {
      buf.write('For $weatherCondition weather at ${temperature.toStringAsFixed(0)}°C, this outfit is a suitable choice. '
          'The style and weight of these pieces align well with the conditions.');
    } else if (weatherScore * 10 >= 5.0) {
      buf.write('This outfit is borderline for ${temperature.toStringAsFixed(0)}°C $weatherCondition weather. '
          'It will work but may feel slightly off — consider a light layer.');
    } else {
      buf.write('This outfit is not well-suited for $weatherCondition at ${temperature.toStringAsFixed(0)}°C. '
          'The style or weight of these pieces doesn\'t match the conditions well at all.');
    }

    buf.write('\n\n');

    // Para 5 — action
    if (totalScore < 70) {
      if (colorScore * 10 < styleScore * 10) {
        buf.write('The quickest fix is changing the $bottomColor bottom — try a white, black, or beige option instead. '
            'That alone would significantly improve the colour harmony score. '
            'Keep the style in mind for $occasion and aim for both pieces to share the same aesthetic.');
      } else {
        buf.write('The main issue is style consistency — try pairing your $topStyle top with a $topStyle bottom instead of $bottomStyle. '
            'That one change would bring the score up considerably for $occasion.');
      }
    } else {
      buf.write('To elevate this further for $occasion, consider adding a simple accessory — '
          'a minimal watch or a structured bag would refine the look without overcomplicating it. '
          'This outfit already works well, so keep additions subtle.');
    }

    return buf.toString();
  }
}

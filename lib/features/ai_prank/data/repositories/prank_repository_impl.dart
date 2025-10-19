import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/entities/family_member.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../domain/services/ai_context_provider.dart';
import 'prank_repository.dart';

/// Implementace PrankRepository
///
/// Používá OpenRouter API pro generování prank tipů.
/// Využívá AI Split model (chytřejší + bezpečnostní filtr).
class PrankRepositoryImpl implements PrankRepository {
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final DatabaseHelper _db;

  PrankRepositoryImpl(this._db);

  @override
  Future<String> generatePrank({
    required Todo completedTodo,
  }) async {
    // ✅ Fail Fast: validace
    if (completedTodo.task.trim().isEmpty) {
      throw ArgumentError('Completed todo nesmí být prázdný');
    }

    // Načíst nastavení z databáze
    final settings = await _db.getSettings();
    final apiKey = settings['openrouter_api_key'] as String?;
    final model = settings['ai_reward_model'] as String;
    final temperature = settings['ai_reward_temperature'] as double;
    final maxTokens = settings['ai_reward_max_tokens'] as int;

    // ✅ Fail Fast: kontrola API klíče
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('API klíč není nastaven. Přejděte do nastavení.');
    }

    // Načíst profil uživatele + rodinu z DB (pro context)
    final UserProfile? userProfile = await _loadUserProfile();
    final List<FamilyMember> familyMembers = await _loadFamilyMembers();

    // Vytvořit AI context provider
    final contextProvider = AIContextProvider(
      userProfile: userProfile,
      familyMembers: familyMembers,
    );

    // Vygenerovat prank prompt
    final prompt = contextProvider.generatePrankPrompt(completedTodo);

    // System prompt pro prank AI s BEZPEČNOSTNÍMI PRAVIDLY
    const systemPrompt = '''
Jsi vtipný kamarád dítěte, který navrhuje BEZPEČNÉ a NEŠKODNÉ pranky a aktivity s rodinou.

⚠️ KRITICKÉ: NIKDY neopakuj stejný typ pranku! Buď MAXIMÁLNĚ KREATIVNÍ a různorodý!

KRITICKÁ BEZPEČNOSTNÍ PRAVIDLA - NIKDY NEPORUŠUJ:
❌ NIKDY nenavrhuj pranky, které:
  - Zahrnují ničení majetku (malování na zeď, ničení věcí, atd.)
  - Používají nebezpečné látky (chemikálie, barvy, fixu na kůži/obličej, atd.)
  - Mohou někoho vyděsit nebo rozrušit
  - Zahrnují manipulaci s jídlem (kromě lehkých neškodných záměn)
  - Mohou někoho fyzicky zranit

✅ POUZE navrhuj pranky, které:
  - Jsou lehké, vtipné a ORIGINÁLNÍ
  - Vyvolají úsměv a smích u VŠECH
  - Jsou snadno vratné (můžeš to rychle napravit)
  - Jsou vhodné pro věk dítěte

🎨 KATEGORIE PRANKŮ (střídej je!):
1. SKRÝVAČKY & HÁDANKY: Schovat věci, vytvořit hádankovou cestu, tajné vzkazy
2. ILUZE & KOUZLA: Falešné věci, optické klamy, "kouzelnické" triky
3. ZVUKOVÉ EFEKTY: Neobvyklé zvuky, falešné hovory, hlasové imitace
4. PŘEKVAPENÍ: Nečekané situace, změny v prostředí, "divné" objevy
5. SLOVNÍ HŘÍČKY: Záměny slov, vtipné nápisy, falešné zprávy
6. KOSTÝMY & PŘEVLEKY: Maskování, převlékání věcí, tematické scény
7. PAPÍROVÉ PRANKY: Falešné dokumenty, vtipné certifikáty, kresby
8. TECHNOLOGICKÉ: SMS pranky (s dovolením rodičů), timer-based surprises

PŘÍKLADY PRO INSPIRACI (NIKDY je neopakuj přímo!):
- Vytvořit "archeologický nález" na zahradě
- Udělat falešnou zprávu od "starosty města"
- Připravit "kouzelné" zmizení předmětu s kouzelnou hůlkou
- Nainstalovat "detektiv" hru s indiciemi po celém bytě
- Vytvořit "muzeum" z běžných věcí doma s vtipnými popisky
- Udělat "televizní vysílání" s rodinnými zprávami
- Připravit "vědecký experiment" s neškodnými ingrediencemi


FORMÁT ODPOVĚDI:
Odpovídej POUZE v markdown formátu s touto strukturou:

# 🎉 [Krátká pochvala]

[1-2 věty uznání za dokončení úkolu]

## 🎭 Tip na prank

[Konkrétní vtipný nápad s kontextem rodiny/zájmů - AŽ 13 VĚT]
[Můžeš popsat detailní kroky, co potřebuješ, jak to provést, co říct]
[Používej odrážky nebo číslované seznamy pro kroky]

STYL:
- Používej **bold** pro důležité části
- Používej *italic* pro emočně zabarvená slova
- Používej emoji (ale ne přehnaně)
- Můžeš použít odrážky (- krok 1, - krok 2) nebo číslované seznamy (1. krok, 2. krok)
- Max 15 vět celkem (1-2 pochvala + až 13 detailní prank tip)
- Hravý a povzbuzující tón
- Zaměř se na zábavu a společné chvíle s rodinou
- Buď konkrétní a detailní - ať dítě ví PŘESNĚ co má dělat
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://github.com/your-repo',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['choices'][0]['message']['content'] as String;
        return message.trim();
      } else {
        AppLogger.error('❌ OpenRouter API error: ${response.statusCode}');
        AppLogger.error('Response: ${response.body}');
        throw Exception(
            'API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Exception při volání AI Prank', error: e);
      rethrow; // Propagovat chybu nahoru
    }
  }

  @override
  Future<String> generateGoodDeed({
    required Todo completedTodo,
  }) async {
    // ✅ Fail Fast: validace
    if (completedTodo.task.trim().isEmpty) {
      throw ArgumentError('Completed todo nesmí být prázdný');
    }

    // Načíst nastavení z databáze
    final settings = await _db.getSettings();
    final apiKey = settings['openrouter_api_key'] as String?;
    final model = settings['ai_reward_model'] as String;
    final temperature = settings['ai_reward_temperature'] as double;
    final maxTokens = settings['ai_reward_max_tokens'] as int;

    // ✅ Fail Fast: kontrola API klíče
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('API klíč není nastaven. Přejděte do nastavení.');
    }

    // Načíst profil uživatele + rodinu z DB (pro context)
    final UserProfile? userProfile = await _loadUserProfile();
    final List<FamilyMember> familyMembers = await _loadFamilyMembers();

    // Vytvořit AI context provider
    final contextProvider = AIContextProvider(
      userProfile: userProfile,
      familyMembers: familyMembers,
    );

    // Vygenerovat good deed prompt
    final prompt = contextProvider.generateGoodDeedPrompt(completedTodo);

    // System prompt pro good deed AI
    const systemPrompt = '''
Jsi laskavý kamarád dítěte, který navrhuje DOBRÉ SKUTKY a pomoc rodině/přátelům.

⚠️ KRITICKÉ: NIKDY neopakuj stejný typ dobrého skutku! Buď MAXIMÁLNĚ KREATIVNÍ a různorodý!

💚 KATEGORIE DOBRÝCH SKUTKŮ (střídej je!):
1. POMOC V DOMÁCNOSTI: Úklid, vaření, zahrádka, péče o věci
2. EMOČNÍ PODPORA: Pochvala, povzbuzení, naslouchání, objetí
3. KREATIVNÍ DÁRKY: Kresby, básničky, vyrobené věci, dekorace
4. SLUŽBY PRO DRUHÉ: Donést něco, pomoci s nákupem, vyvenčit psa
5. PŘEKVAPENÍ & RADOST: Nečekané milé gesto, tajná pomoc, pozornost
6. UČENÍ & SDÍLENÍ: Naučit něco, pomoct s úkolem, sdílet dovednost
7. ČAS & POZORNOST: Trávit čas s někým, poslouchat příběhy, hrát hru
8. PÉČE O PROSTŘEDÍ: Uklidit parčík, nakrmit ptáčky, vysadit květinu

PŘÍKLADY PRO INSPIRACI (NIKDY je neopakuj přímo!):
- Vytvořit "kuponovou knihu" s nabídkami pomoci pro rodiče
- Uspořádat mini koncert nebo divadelní představení pro rodinu
- Udělat "den bez stížností" a být extra pozitivní
- Vytvořit rodinný časopis s vtipnými zprávami
- Připravit "spa den" pro sourozence (manikúra, masáž rukou)
- Vytvořit "wall of fame" s fotkami a pochvalami členů rodiny
- Udělat "tajnou misi" vylepšit něco doma bez řeči
- Napsat dopisy budoucímu já a členům rodiny
- Vytvořit "rodinný strom" s kresbami a vzpomínkami
- Uspořádat piknik na terase/v obýváku pro rodiče

FORMÁT ODPOVĚDI:
Odpovídej POUZE v markdown formátu s touto strukturou:

# 💚 [Krátká pochvala]

[1-2 věty uznání za dokončení úkolu]

## 🌟 Tip na dobrý skutek

[Konkrétní laskavý nápad s kontextem rodiny/zájmů - AŽ 13 VĚT]
[Můžeš popsat detailní kroky, co potřebuješ, jak to provést, co říct]
[Používej odrážky nebo číslované seznamy pro kroky]

STYL:
- Používej **bold** pro důležité části
- Používej *italic* pro emočně zabarvená slova
- Používej emoji (ale ne přehnaně)
- Můžeš použít odrážky (- krok 1, - krok 2) nebo číslované seznamy (1. krok, 2. krok)
- Max 15 vět celkem (1-2 pochvala + až 13 detailní tip na dobrý skutek)
- Laskavý a povzbuzující tón
- Zaměř se na radost a hrdost z pomoci druhým
- Buď konkrétní a detailní - ať dítě ví PŘESNĚ co má dělat
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://github.com/your-repo',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['choices'][0]['message']['content'] as String;
        return message.trim();
      } else {
        AppLogger.error('❌ OpenRouter API error: ${response.statusCode}');
        AppLogger.error('Response: ${response.body}');
        throw Exception(
            'API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Exception při volání AI Good Deed', error: e);
      rethrow; // Propagovat chybu nahoru
    }
  }

  /// Načíst user profile z DB
  Future<UserProfile?> _loadUserProfile() async {
    try {
      // Předpokládáme, že DatabaseHelper má metodu pro načtení profilu
      // Pokud neexistuje, vrátíme null
      final db = await _db.database;
      final results = await db.query(
        'user_profile',
        where: 'user_id = ?',
        whereArgs: ['default'],
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return UserProfile.fromMap(results.first);
    } catch (e) {
      AppLogger.error('❌ Chyba při načítání user profile', error: e);
      return null;
    }
  }

  /// Načíst family members z DB
  Future<List<FamilyMember>> _loadFamilyMembers() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'family_members',
        where: 'user_id = ?',
        whereArgs: ['default'],
        orderBy: 'created_at ASC',
      );

      return results.map((map) => FamilyMember.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('❌ Chyba při načítání family members', error: e);
      return [];
    }
  }
}

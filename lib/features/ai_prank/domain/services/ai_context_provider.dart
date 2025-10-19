import 'package:intl/intl.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/entities/family_member.dart';
import '../../../todo_list/domain/entities/todo.dart';

/// Service pro generování AI kontextu s profilem uživatele + rodinou
///
/// Poskytuje personalizovaný kontext pro AI včetně:
/// - Informací o uživateli (dítě)
/// - Členů rodiny
/// - Nadcházejících událostí
/// - Aktuálního data
class AIContextProvider {
  final UserProfile? userProfile;
  final List<FamilyMember> familyMembers;

  AIContextProvider({
    required this.userProfile,
    required this.familyMembers,
  });

  /// Vygeneruje základní system prompt s profilem uživatele
  String generateSystemPrompt() {
    final sb = StringBuffer();
    final now = DateTime.now();

    sb.writeln('=== AKTUÁLNÍ DATUM ===');
    sb.writeln(
        'Dnes je: ${DateFormat('d. M. yyyy, EEEE', 'cs_CZ').format(now)}');
    sb.writeln();

    if (userProfile != null) {
      sb.writeln('=== KONTEXT O UŽIVATELI (DÍTĚ) ===');
      sb.writeln('Jméno: ${userProfile!.firstName} ${userProfile!.lastName}');
      sb.writeln('Věk: ${userProfile!.age} let');
      sb.writeln(
          'Datum narození: ${DateFormat('d. M. yyyy').format(userProfile!.birthDate)}');

      if (userProfile!.nameDay != null && userProfile!.nameDay!.isNotEmpty) {
        sb.writeln('Jméno pro svátek: ${userProfile!.nameDay}');
      }

      if (userProfile!.gender != null) {
        sb.writeln('Pohlaví: ${userProfile!.gender.displayName}');
      }

      sb.writeln('Styl komunikace: ${_getCommunicationStyle()}');
      sb.writeln();

      if (userProfile!.hobbies.isNotEmpty) {
        sb.writeln('Koníčky: ${userProfile!.hobbies.join(", ")}');
        sb.writeln();
      }

      if (userProfile!.aboutMe.isNotEmpty) {
        sb.writeln('O mně (vlastními slovy):');
        sb.writeln(userProfile!.aboutMe);
        sb.writeln();
      }

      if (userProfile!.silneStranky != null &&
          userProfile!.silneStranky!.isNotEmpty) {
        sb.writeln('💪 Silné stránky: ${userProfile!.silneStranky}');
      }

      if (userProfile!.slabeStranky != null &&
          userProfile!.slabeStranky!.isNotEmpty) {
        sb.writeln('🎯 Co chci zlepšit: ${userProfile!.slabeStranky}');
      }
    }

    if (familyMembers.isNotEmpty) {
      sb.writeln();
      sb.writeln('=== RODINA ===');
      for (final member in familyMembers) {
        sb.write(
            '${member.firstName} ${member.lastName} (${member.role.displayName}, ${member.age} let)');

        if (member.relationshipDescription != null &&
            member.relationshipDescription!.isNotEmpty) {
          sb.write(' - ${member.relationshipDescription}');
        }

        sb.writeln();

        if (member.personalityTraits != null &&
            member.personalityTraits!.isNotEmpty) {
          sb.writeln('  Vlastnosti: ${member.personalityTraits}');
        }

        if (member.hobbies != null && member.hobbies!.isNotEmpty) {
          sb.writeln('  Koníčky: ${member.hobbies}');
        }

        if (member.occupation != null && member.occupation!.isNotEmpty) {
          sb.writeln('  Zaměstnání: ${member.occupation}');
        }

        if (member.silneStranky != null && member.silneStranky!.isNotEmpty) {
          sb.writeln('  💪 Silné stránky: ${member.silneStranky}');
        }

        if (member.slabeStranky != null && member.slabeStranky!.isNotEmpty) {
          sb.writeln('  🎯 Co zlepšit: ${member.slabeStranky}');
        }
      }
    }

    return sb.toString();
  }

  /// Vygeneruje prompt pro AI prank po dokončení úkolu
  ///
  /// **FÁZE 1:** Jen pochvala + prank tip (bez vytváření úkolu)
  String generatePrankPrompt(Todo completedTodo) {
    final context = generateSystemPrompt();

    final userName = userProfile?.firstName ?? 'kamaráde';
    final userAge = userProfile?.age ?? 0;
    final userGender = userProfile?.gender?.displayName ?? 'neznámé';
    final communicationStyle = _getCommunicationStyle();

    // Sestavit info o rodině (věk + role)
    final familyInfo = StringBuffer();
    if (familyMembers.isNotEmpty) {
      familyInfo.writeln('Rodina:');
      for (final member in familyMembers) {
        familyInfo.writeln('  - ${member.firstName} (${member.role.displayName}, ${member.age} let)');
      }
    } else {
      familyInfo.writeln('Rodina: žádní členové rodiny nejsou zadáni');
    }

    return '''
$context

=== DOKONČENÝ ÚKOL ===
Uživatel právě dokončil tento úkol:
"${completedTodo.task}"

=== TVŮJ ÚKOL ===
1. **POCHVÁLIT** uživatele za dokončení úkolu (1-2 věty)
2. **NAVRHNOUT VTIPNÝ PRANK** nebo tip na aktivitu s rodinou (až 13 vět s detaily)

=== KLÍČOVÉ INFORMACE ===
- Jméno: $userName
- Věk: $userAge let (DŮLEŽITÉ: přizpůsob prank věku dítěte!)
- Pohlaví: $userGender
- Styl komunikace: $communicationStyle
$familyInfo

=== PRAVIDLA ===
- Prank MUSÍ být vhodný pro věk $userAge let!
- Používej kontext o rodině a zájmech výše
- Prank musí být jednoduchý, realizovatelný, BEZPEČNÝ
- Pokud v rodině není nikdo, navrhni obecný tip
- Max 15 vět celkem (1-2 pochvala + až 13 prank tip s detailními kroky)

=== PŘÍKLAD PRO INSPIRACI ===
Uživatel: Tomáš (9 let), hobby: fotbal, sourozenec: Honza (12 let)

# 🎉 Úžasně, Tomáši!

Splnil jsi úkol jako **profík**! 💪 Tohle si zaslouží odměnu.

## 🎭 Tip na prank

Co takhle *schovat Honzovi* jeho fotbalový míč a připravit mu vtipnou **hádankovou cestu**?

**Jak na to:**
1. Schovej míč na bezpečné místo (třeba pod postelí v obýváku)
2. Napiš na lístek: "Ahoj Honzo! Tvůj míč odpočívá tam, kde se odpočívá celá rodina 🛋️"
3. Ten lístek dej na jeho stůl
4. Když ho najde, řekni: "Hádej, kde je!" a směj se s ním

Honza se určitě bude smát a možná ti to **vrátí** stejným způsobem! ⚽😄
''';
  }

  /// Vygeneruje prompt pro AI good deed po dokončení úkolu
  ///
  /// **FÁZE 1:** Pochvala + tip na dobrý skutek/pomoc rodině
  String generateGoodDeedPrompt(Todo completedTodo) {
    final context = generateSystemPrompt();

    final userName = userProfile?.firstName ?? 'kamaráde';
    final userAge = userProfile?.age ?? 0;
    final userGender = userProfile?.gender?.displayName ?? 'neznámé';
    final communicationStyle = _getCommunicationStyle();

    // Sestavit info o rodině (věk + role)
    final familyInfo = StringBuffer();
    if (familyMembers.isNotEmpty) {
      familyInfo.writeln('Rodina:');
      for (final member in familyMembers) {
        familyInfo.writeln('  - ${member.firstName} (${member.role.displayName}, ${member.age} let)');
      }
    } else {
      familyInfo.writeln('Rodina: žádní členové rodiny nejsou zadáni');
    }

    return '''
$context

=== DOKONČENÝ ÚKOL ===
Uživatel právě dokončil tento úkol:
"${completedTodo.task}"

=== TVŮJ ÚKOL ===
1. **POCHVÁLIT** uživatele za dokončení úkolu (1-2 věty)
2. **NAVRHNOUT DOBRÝ SKUTEK** nebo tip na pomoc rodině/kamarádům (až 13 vět s detaily)

=== KLÍČOVÉ INFORMACE ===
- Jméno: $userName
- Věk: $userAge let (DŮLEŽITÉ: přizpůsob skutek věku dítěte!)
- Pohlaví: $userGender
- Styl komunikace: $communicationStyle
$familyInfo

=== PRAVIDLA ===
- Skutek MUSÍ být vhodný pro věk $userAge let!
- Používej kontext o rodině a zájmech výše
- Skutek musí být jednoduchý, realizovatelný, LASKAVÝ
- Pokud v rodině není nikdo, navrhni obecný tip (pomoc sousedům, kamarádům)
- Max 15 vět celkem (1-2 pochvala + až 13 detailní tip)

=== PŘÍKLAD PRO INSPIRACI ===
Uživatel: Tomáš (9 let), hobby: kreslení, rodina: maminka Jana (35 let), brácha Honza (12 let)

# 💚 Úžasně, Tomáši!

Splnil jsi úkol jako **šampion**! 💪 Tohle si zaslouží odměnu.

## 🌟 Tip na dobrý skutek

Co takhle *udělat mamce překvapení* a nakreslit jí **krásný obrázek** s poděkováním?

**Jak na to:**
1. Vezmi si papír a pastelky/fixy
2. Nakresli něco, co má mamka ráda (třeba kytičky, nebo celou rodinu)
3. Napiš nahoře: "Děkuji ti, maminko, za vše! ❤️"
4. Polož jí obrázek na polštář nebo na stůl jako překvapení
5. Uvidíš, jak se rozesměje! 😊

Maminka se určitě potěší a bude **hrdá** na tvou laskavost! 🌈
''';
  }

  /// Určí styl komunikace podle věku uživatele
  String _getCommunicationStyle() {
    if (userProfile == null) {
      return 'Přátelský';
    }

    switch (userProfile!.ageBriefingStyle) {
      case 'playful':
        return 'Hravý, jednoduché věty, emoji, nadšení';
      case 'encouraging':
        return 'Povzbuzující, více informací, kamarádský tón';
      case 'teen':
        return 'Cool tón, respekt, jako kamarád';
      default:
        return 'Přátelský';
    }
  }
}

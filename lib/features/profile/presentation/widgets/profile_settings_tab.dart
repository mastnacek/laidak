import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';



import '../../domain/entities/family_role.dart';
import '../../domain/entities/gender.dart';

/// Tab "O mně" v Settings
class ProfileSettingsTab extends ConsumerWidget {
  const ProfileSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (state) {
        if (state is ProfileLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === UŽIVATEL ===
                _buildHeader('👤 O TOBĚ (UŽIVATEL APLIKACE)', highlighted: true),
                const SizedBox(height: 12),
                _UserProfileCard(profile: state.userProfile),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                // === RODINA ===
                _buildHeader('👨‍👩‍👧‍👦 ČLENOVÉ RODINY'),
                const SizedBox(height: 12),
                _FamilyMembersList(members: state.familyMembers),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddFamilyMemberDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat člena rodiny'),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('Neznámý stav profilu'));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Chyba: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(profileProvider.notifier).loadProfile();
              },
              child: const Text('Zkusit znovu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: highlighted
          ? BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 2),
            )
          : null,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: highlighted ? Colors.blue : null,
        ),
      ),
    );
  }

  void _showAddFamilyMemberDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final nameDayController = TextEditingController();
    final nicknameController = TextEditingController();
    final relationshipDescController = TextEditingController();
    final personalityController = TextEditingController();
    final hobbiesController = TextEditingController();
    final occupationController = TextEditingController();
    final otherNotesController = TextEditingController();
    final silneStrankyController = TextEditingController();
    final slabeStrankyController = TextEditingController();
    DateTime? birthDate;
    Gender selectedGender = Gender.other;
    FamilyRole selectedRole = FamilyRole.mother;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Přidat člena rodiny'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Křestní jméno *'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Povinné' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Příjmení *'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Povinné' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(birthDate != null
                      ? DateFormat('d. M. yyyy').format(birthDate!)
                      : 'Datum narození *'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate:
                          DateTime.now().subtract(const Duration(days: 365 * 30)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      birthDate = picked;
                      (dialogContext as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameDayController,
                  decoration: const InputDecoration(
                    labelText: 'Jméno pro svátek (volitelné)',
                    prefixIcon: Icon(Icons.celebration),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: '😊 Přezdívka (volitelné)',
                    hintText: 'Jak mu/jí říkáte?',
                    prefixIcon: Icon(Icons.tag_faces),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Gender>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Pohlaví *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: Gender.values.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedGender = value;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FamilyRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                  items: FamilyRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedRole = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: relationshipDescController,
                  decoration: const InputDecoration(
                    labelText: 'Slovní popis vztahu (volitelné)',
                    hintText: '"Můj starší brácha", "Maminka"...',
                    prefixIcon: Icon(Icons.favorite),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: personalityController,
                  decoration: const InputDecoration(
                    labelText: 'Popis vlastností (volitelné)',
                    hintText: 'Jaký je? Např: "Má rád hokej, je vtipný"',
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hobbiesController,
                  decoration: const InputDecoration(
                    labelText: 'Koníčky (volitelné)',
                    hintText: 'Např: hokej, kreslení...',
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: occupationController,
                  decoration: const InputDecoration(
                    labelText: 'Zaměstnání (volitelné)',
                    hintText: 'Pro rodiče: "učitelka", "programátor"...',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: otherNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Ostatní poznámky (volitelné)',
                    hintText: 'Cokoliv dalšího...',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: silneStrankyController,
                  decoration: const InputDecoration(
                    labelText: '💪 Silné stránky (volitelné)',
                    hintText: 'Co daný člověk umí dobře? V čem je dobrý?',
                    prefixIcon: Icon(Icons.star),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: slabeStrankyController,
                  decoration: const InputDecoration(
                    labelText: '🎯 Slabé stránky (volitelné)',
                    hintText: 'Co by mohl zlepšit? Co mu dělá problémy?',
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() && birthDate != null) {
                ref.read(profileProvider.notifier).addFamilyMember(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  birthDate: birthDate!,
                  nameDay: nameDayController.text.trim().isEmpty
                      ? null
                      : nameDayController.text.trim(),
                  nickname: nicknameController.text.trim().isEmpty
                      ? null
                      : nicknameController.text.trim(),
                  gender: selectedGender,
                  role: selectedRole,
                  relationshipDescription: relationshipDescController.text.trim().isEmpty
                      ? null
                      : relationshipDescController.text.trim(),
                  personalityTraits: personalityController.text.trim().isEmpty
                      ? null
                      : personalityController.text.trim(),
                  hobbies: hobbiesController.text.trim().isEmpty
                      ? null
                      : hobbiesController.text.trim(),
                  occupation: occupationController.text.trim().isEmpty
                      ? null
                      : occupationController.text.trim(),
                  otherNotes: otherNotesController.text.trim().isEmpty
                      ? null
                      : otherNotesController.text.trim(),
                  silneStranky: silneStrankyController.text.trim().isEmpty
                      ? null
                      : silneStrankyController.text.trim(),
                  slabeStranky: slabeStrankyController.text.trim().isEmpty
                      ? null
                      : slabeStrankyController.text.trim(),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Přidat'),
          ),
        ],
      ),
    );
  }
}

/// Karta UserProfile
class _UserProfileCard extends ConsumerWidget {
  final dynamic profile;

  const _UserProfileCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Profil ještě není vyplněn'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showEditProfileDialog(context, ref, null),
                child: const Text('Vytvořit profil'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        title: Text('${profile.firstName} ${profile.lastName}'),
        subtitle: Text(
          'Věk: ${profile.age} let\n'
          'Kategorie: ${profile.ageCategory.emoji} ${profile.ageCategory.czechName}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditProfileDialog(context, ref, profile),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, dynamic existingProfile) {
    final formKey = GlobalKey<FormState>();
    final firstNameController =
        TextEditingController(text: existingProfile?.firstName ?? '');
    final lastNameController =
        TextEditingController(text: existingProfile?.lastName ?? '');
    final nameDayController =
        TextEditingController(text: existingProfile?.nameDay ?? '');
    final nicknameController =
        TextEditingController(text: existingProfile?.nickname ?? '');
    final hobbiesController =
        TextEditingController(text: existingProfile?.hobbies?.join(', ') ?? '');
    final aboutMeController =
        TextEditingController(text: existingProfile?.aboutMe ?? '');
    final silneStrankyController =
        TextEditingController(text: existingProfile?.silneStranky ?? '');
    final slabeStrankyController =
        TextEditingController(text: existingProfile?.slabeStranky ?? '');
    DateTime birthDate =
        existingProfile?.birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 10));
    Gender selectedGender = existingProfile?.gender ?? Gender.other;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existingProfile == null ? 'Vytvořit profil' : 'Upravit profil'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Křestní jméno *'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Povinné' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Příjmení *'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Povinné' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(DateFormat('d. M. yyyy').format(birthDate)),
                  subtitle: const Text('Datum narození *'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: birthDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      birthDate = picked;
                      (dialogContext as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Gender>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Pohlaví *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: Gender.values.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedGender = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameDayController,
                  decoration: const InputDecoration(
                    labelText: 'Jméno pro svátek (volitelné)',
                    hintText: 'Např. Tomáš, Marie...',
                    prefixIcon: Icon(Icons.celebration),
                    helperText: 'Použijeme pro připomínání svátku',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: '😊 Přezdívka (volitelné)',
                    hintText: 'Jak tě říkají kamarádi nebo rodina?',
                    prefixIcon: Icon(Icons.tag_faces),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hobbiesController,
                  decoration: const InputDecoration(
                    labelText: 'Koníčky (volitelné)',
                    hintText: 'fotbal, Minecraft, kreslení...',
                    prefixIcon: Icon(Icons.sports_soccer),
                    helperText: 'Odděl čárkou',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: aboutMeController,
                  decoration: const InputDecoration(
                    labelText: 'O mně (co by AI měla vědět?)',
                    hintText: 'Např: "Mám rád Star Wars, nemám rád brambory..."',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: silneStrankyController,
                  decoration: const InputDecoration(
                    labelText: '💪 Silné stránky (volitelné)',
                    hintText: 'Např: "Jsem rychlý v matematice, umím dobře kreslit, pomáhám ostatním"',
                    prefixIcon: Icon(Icons.star),
                    helperText: 'Co ti jde dobře? Co o sobě víš pozitivního?',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: slabeStrankyController,
                  decoration: const InputDecoration(
                    labelText: '🎯 Slabé stránky (volitelné)',
                    hintText: 'Např: "Zapomínám na domácí úkoly, těžko vstávám ráno, nesoustředím se"',
                    prefixIcon: Icon(Icons.psychology),
                    helperText: 'Co bys rád zlepšil? Co ti dělá problémy?',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // Parse hobbies (oddělit čárkou a trimovat)
                final hobbies = hobbiesController.text
                    .split(',')
                    .map((h) => h.trim())
                    .where((h) => h.isNotEmpty)
                    .toList();

                ref.read(profileProvider.notifier).saveUserProfile(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  birthDate: birthDate,
                  nameDay: nameDayController.text.trim().isEmpty
                      ? null
                      : nameDayController.text.trim(),
                  nickname: nicknameController.text.trim().isEmpty
                      ? null
                      : nicknameController.text.trim(),
                  gender: selectedGender,
                  hobbies: hobbies,
                  aboutMe: aboutMeController.text.trim(),
                  silneStranky: silneStrankyController.text.trim().isEmpty
                      ? null
                      : silneStrankyController.text.trim(),
                  slabeStranky: slabeStrankyController.text.trim().isEmpty
                      ? null
                      : slabeStrankyController.text.trim(),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
  }
}

/// Seznam členů rodiny
class _FamilyMembersList extends ConsumerWidget {
  final List<dynamic> members;

  const _FamilyMembersList({required this.members});

  void _showEditFamilyMemberDialog(BuildContext context, WidgetRef ref, dynamic existingMember) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: existingMember.firstName);
    final lastNameController = TextEditingController(text: existingMember.lastName);
    final nameDayController = TextEditingController(text: existingMember.nameDay ?? '');
    final nicknameController = TextEditingController(text: existingMember.nickname ?? '');
    final relationshipDescController = TextEditingController(text: existingMember.relationshipDescription ?? '');
    final personalityController = TextEditingController(text: existingMember.personalityTraits ?? '');
    final hobbiesController = TextEditingController(text: existingMember.hobbies ?? '');
    final occupationController = TextEditingController(text: existingMember.occupation ?? '');
    final otherNotesController = TextEditingController(text: existingMember.otherNotes ?? '');
    final silneStrankyController = TextEditingController(text: existingMember.silneStranky ?? '');
    final slabeStrankyController = TextEditingController(text: existingMember.slabeStranky ?? '');
    DateTime birthDate = existingMember.birthDate;
    Gender selectedGender = existingMember.gender;
    FamilyRole selectedRole = existingMember.role;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upravit člena rodiny'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Křestní jméno *'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Povinné' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Příjmení *'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Povinné' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(DateFormat('d. M. yyyy').format(birthDate)),
                  subtitle: const Text('Datum narození *'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: birthDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      birthDate = picked;
                      (dialogContext as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameDayController,
                  decoration: const InputDecoration(
                    labelText: 'Jméno pro svátek (volitelné)',
                    prefixIcon: Icon(Icons.celebration),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: '😊 Přezdívka (volitelné)',
                    hintText: 'Jak mu/jí říkáte?',
                    prefixIcon: Icon(Icons.tag_faces),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Gender>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Pohlaví *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: Gender.values.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedGender = value;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FamilyRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                  items: FamilyRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedRole = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: relationshipDescController,
                  decoration: const InputDecoration(
                    labelText: 'Slovní popis vztahu (volitelné)',
                    hintText: '"Můj starší brácha", "Maminka"...',
                    prefixIcon: Icon(Icons.favorite),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: personalityController,
                  decoration: const InputDecoration(
                    labelText: 'Popis vlastností (volitelné)',
                    hintText: 'Jaký je? Např: "Má rád hokej, je vtipný"',
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hobbiesController,
                  decoration: const InputDecoration(
                    labelText: 'Koníčky (volitelné)',
                    hintText: 'Např: hokej, kreslení...',
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: occupationController,
                  decoration: const InputDecoration(
                    labelText: 'Zaměstnání (volitelné)',
                    hintText: 'Pro rodiče: "učitelka", "programátor"...',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: otherNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Ostatní poznámky (volitelné)',
                    hintText: 'Cokoliv dalšího...',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: silneStrankyController,
                  decoration: const InputDecoration(
                    labelText: '💪 Silné stránky (volitelné)',
                    hintText: 'Co daný člověk umí dobře? V čem je dobrý?',
                    prefixIcon: Icon(Icons.star),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: slabeStrankyController,
                  decoration: const InputDecoration(
                    labelText: '🎯 Slabé stránky (volitelné)',
                    hintText: 'Co by mohl zlepšit? Co mu dělá problémy?',
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(profileProvider.notifier).updateFamilyMember(
                  id: existingMember.id!,
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  birthDate: birthDate,
                  nameDay: nameDayController.text.trim().isEmpty
                      ? null
                      : nameDayController.text.trim(),
                  nickname: nicknameController.text.trim().isEmpty
                      ? null
                      : nicknameController.text.trim(),
                  gender: selectedGender,
                  role: selectedRole,
                  relationshipDescription: relationshipDescController.text.trim().isEmpty
                      ? null
                      : relationshipDescController.text.trim(),
                  personalityTraits: personalityController.text.trim().isEmpty
                      ? null
                      : personalityController.text.trim(),
                  hobbies: hobbiesController.text.trim().isEmpty
                      ? null
                      : hobbiesController.text.trim(),
                  occupation: occupationController.text.trim().isEmpty
                      ? null
                      : occupationController.text.trim(),
                  otherNotes: otherNotesController.text.trim().isEmpty
                      ? null
                      : otherNotesController.text.trim(),
                  silneStranky: silneStrankyController.text.trim().isEmpty
                      ? null
                      : silneStrankyController.text.trim(),
                  slabeStranky: slabeStrankyController.text.trim().isEmpty
                      ? null
                      : slabeStrankyController.text.trim(),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (members.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Žádní členové rodiny'),
        ),
      );
    }

    return Column(
      children: members.map((member) {
        return Card(
          child: ListTile(
            title: Text('${member.firstName} ${member.lastName}'),
            subtitle: Text(
              '${member.role.displayName}, ${member.age} let\n'
              '${member.ageCategory.emoji} ${member.ageCategory.czechName}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditFamilyMemberDialog(context, ref, member),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(profileProvider.notifier).deleteFamilyMember(member.id!);
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

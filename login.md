# 🔐 LOGIN.md - Firebase Authentication Implementation Plan

**Datum vytvoření**: 2025-10-13
**Status**: Naplánováno (čeká na implementaci)
**Platforma**: Windows, Android, Web
**Architektura**: Feature-First + BLoC

---

## 📋 OBSAH

1. [Přehled](#přehled)
2. [Architektura](#architektura)
3. [Firebase Setup](#firebase-setup)
4. [Implementace - Krok za krokem](#implementace)
5. [Security Rules](#security-rules)
6. [Migrace dat](#migrace-dat)
7. [Testing](#testing)
8. [Deployment](#deployment)

---

## 🎯 PŘEHLED

### Co implementujeme:
- ✅ Email/Password autentifikace přes Firebase Auth
- ✅ Real-time sync úkolů mezi zařízeními (Firestore)
- ✅ Offline persistence (automatická)
- ✅ Multi-platform (Windows, Android, Web)

### Proč Firebase?
1. **Minimální práce** - Auth ready za 1 den
2. **Real-time sync** - změny se propagují automaticky
3. **Free tier** - stačí pro 500+ úkolů/den
4. **Bezpečnost** - HTTPS/SSL built-in
5. **Škálovatelnost** - zvládne růst

### Časový odhad:
- **Firebase Setup**: 2-3 hodiny
- **Authentication**: 1 den (Login/Register pages + AuthBloc)
- **Firestore migrace**: 2-3 dny (TodoRepository refactoring)
- **Security Rules**: 1 den
- **Testing**: 1 den
- **Celkem**: 5-6 dnů full implementace

---

## 🏗️ ARCHITEKTURA

### Feature-First struktura:

```
lib/features/auth/
├── data/
│   ├── datasources/
│   │   └── firebase_auth_datasource.dart       # FirebaseAuth SDK wrapper
│   ├── models/
│   │   └── user_model.dart                     # User DTO (Firestore mapping)
│   └── repositories/
│       └── auth_repository_impl.dart           # Repository implementation
├── domain/
│   ├── entities/
│   │   └── user.dart                           # Pure Dart User entity
│   └── repositories/
│       └── auth_repository.dart                # Repository interface
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart                      # BLoC orchestrace
    │   ├── auth_event.dart                     # Events: LoginRequested, LogoutRequested
    │   └── auth_state.dart                     # States: Authenticated, Unauthenticated, Loading
    └── pages/
        ├── login_page.dart                     # Login screen
        └── register_page.dart                  # Registration screen
```

### Firestore databázová struktura:

```
users/{userId}/
├── profile/                                    # User profile document
│   ├── email: "user@example.com"
│   ├── displayName: "Jarda"
│   ├── createdAt: Timestamp
│   └── lastLoginAt: Timestamp
│
└── todos/                                      # Subcollection s úkoly
    ├── {todoId}/
    │   ├── task: "Koupit mléko"
    │   ├── priority: "a"
    │   ├── dueDate: Timestamp
    │   ├── tags: ["rodina"]
    │   ├── isCompleted: false
    │   ├── createdAt: Timestamp
    │   ├── subtasks: [...]
    │   ├── aiRecommendations: "..."
    │   └── aiDeadlineAnalysis: "..."
    └── {todoId2}/
        └── ...
```

---

## 🔥 FIREBASE SETUP

### Krok 1: Vytvoření Firebase projektu (15 min)

1. Otevři [Firebase Console](https://console.firebase.google.com/)
2. Klikni **"Add project"**
3. Název: `todo-app-jarda` (nebo vlastní)
4. Enable Google Analytics: **Ano** (optional, ale užitečné)
5. Počkej na provisioning (~2 min)

### Krok 2: Přidání aplikací (30 min)

#### **A) Android App**
1. V Firebase Console → Project Overview → **Add app** → **Android**
2. **Android package name**: `com.jarda.todo` (musí odpovídat `applicationId` v `android/app/build.gradle`)
3. **App nickname**: `TODO Android`
4. **SHA-1 certificate** (optional pro Google Sign-In):
   ```bash
   # Debug SHA-1 (pro development)
   cd android
   ./gradlew signingReport
   # Zkopíruj SHA-1 z výstupu
   ```
5. Stáhnout `google-services.json` → umístit do `android/app/`
6. Následuj pokyny pro přidání Firebase SDK do `build.gradle`

#### **B) Web App**
1. V Firebase Console → Project Overview → **Add app** → **Web**
2. **App nickname**: `TODO Web`
3. **Firebase Hosting**: Zatím **Ne** (můžeš přidat později)
4. Zkopíruj Firebase config (SDK snippet)

#### **C) Windows**
- Windows používá **Web konfiguraci** (Flutter Web build)
- Žádné extra kroky potřeba

### Krok 3: FlutterFire CLI setup (20 min)

```bash
# Instalace FlutterFire CLI (globálně)
dart pub global activate flutterfire_cli

# Přidej do PATH (pokud ještě není)
# Windows: Přidej C:\Users\{user}\AppData\Local\Pub\Cache\bin do PATH

# Login do Firebase
firebase login

# Konfigurace Firebase pro Flutter projekt
cd D:\01_programovani\flutter-todo\todo
flutterfire configure

# Vyber projekt: todo-app-jarda
# Vyber platformy: Android, iOS (skip), Web, Windows
# Automaticky vytvoří: lib/firebase_options.dart
```

### Krok 4: Instalace dependencies (10 min)

Přidej do `pubspec.yaml`:

```yaml
dependencies:
  # Firebase Core
  firebase_core: ^3.6.0

  # Firebase Authentication
  firebase_auth: ^5.3.1

  # Cloud Firestore (pro sync úkolů)
  cloud_firestore: ^5.4.4

  # Optional: Firebase Analytics
  firebase_analytics: ^11.3.3

# Poznámka: Verze mohou být novější - použij flutter pub outdated
```

Pak spusť:
```bash
flutter pub get
```

### Krok 5: Inicializace Firebase v `main.dart` (10 min)

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializovat Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializovat TagService (existující kód)
  await TagService().init();

  runApp(const MyApp());
}
```

---

## 💻 IMPLEMENTACE - Krok za krokem

### **FÁZE 1: Domain Layer** (1 hodina)

#### 1.1 User Entity

Vytvoř: `lib/features/auth/domain/entities/user.dart`

```dart
import 'package:equatable/equatable.dart';

/// Pure Dart User entity (domain layer)
class User extends Equatable {
  final String id;              // Firebase UID
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.lastLoginAt,
  });

  @override
  List<Object?> get props => [id, email, displayName, createdAt, lastLoginAt];

  @override
  String toString() => 'User(id: $id, email: $email, displayName: $displayName)';
}
```

#### 1.2 Auth Repository Interface

Vytvoř: `lib/features/auth/domain/repositories/auth_repository.dart`

```dart
import '../entities/user.dart';

/// Repository interface (domain layer)
///
/// Definuje kontrakt pro autentifikaci bez závislosti na Firebase
abstract class AuthRepository {
  /// Aktuálně přihlášený user (null pokud není přihlášen)
  User? get currentUser;

  /// Stream změn autentifikace (pro BLoC listener)
  Stream<User?> get authStateChanges;

  /// Přihlásit se emailem a heslem
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registrovat nového uživatele
  Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Odhlásit se
  Future<void> signOut();

  /// Resetovat heslo (poslat email)
  Future<void> sendPasswordResetEmail(String email);
}
```

---

### **FÁZE 2: Data Layer** (2 hodiny)

#### 2.1 User Model (DTO)

Vytvoř: `lib/features/auth/data/models/user_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

/// Data Transfer Object pro User (Firestore mapping)
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    required super.createdAt,
    super.lastLoginAt,
  });

  /// Vytvořit z Firebase User
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  /// Vytvořit z Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Konvertovat na Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  /// Vytvořit doménovou entitu
  User toEntity() => User(
        id: id,
        email: email,
        displayName: displayName,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt,
      );
}
```

#### 2.2 Firebase Auth Datasource

Vytvoř: `lib/features/auth/data/datasources/firebase_auth_datasource.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Firebase Authentication datasource
///
/// Wrapper kolem Firebase Auth SDK
class FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthDataSource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Aktuálně přihlášený user
  UserModel? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? UserModel.fromFirebaseUser(firebaseUser) : null;
  }

  /// Stream změn autentifikace
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? UserModel.fromFirebaseUser(firebaseUser) : null;
    });
  }

  /// Sign in s emailem a heslem
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed - user is null');
      }

      // Update lastLoginAt v Firestore
      await _updateLastLogin(credential.user!.uid);

      return UserModel.fromFirebaseUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Registrovat nového uživatele
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Registration failed - user is null');
      }

      // Update display name
      if (displayName != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Vytvořit user profile v Firestore
      final userModel = UserModel.fromFirebaseUser(credential.user!);
      await _createUserProfile(userModel);

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Poslat reset password email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Vytvořit user profile v Firestore
  Future<void> _createUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  /// Update lastLoginAt timestamp
  Future<void> _updateLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  /// Konvertovat Firebase Auth exceptions na user-friendly zprávy
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Uživatel s tímto emailem neexistuje');
      case 'wrong-password':
        return Exception('Nesprávné heslo');
      case 'email-already-in-use':
        return Exception('Email je již používán');
      case 'invalid-email':
        return Exception('Neplatný email');
      case 'weak-password':
        return Exception('Heslo je příliš slabé (min. 6 znaků)');
      case 'network-request-failed':
        return Exception('Chyba sítě - zkontroluj připojení');
      default:
        return Exception('Autentifikace selhala: ${e.message}');
    }
  }
}
```

#### 2.3 Auth Repository Implementation

Vytvoř: `lib/features/auth/data/repositories/auth_repository_impl.dart`

```dart
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Implementation AuthRepository s Firebase datasource
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  User? get currentUser => _dataSource.currentUser?.toEntity();

  @override
  Stream<User?> get authStateChanges {
    return _dataSource.authStateChanges.map((userModel) => userModel?.toEntity());
  }

  @override
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userModel = await _dataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final userModel = await _dataSource.registerWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    return userModel.toEntity();
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _dataSource.sendPasswordResetEmail(email);
}
```

---

### **FÁZE 3: Presentation Layer - BLoC** (2 hodiny)

#### 3.1 Auth Events

Vytvoř: `lib/features/auth/presentation/bloc/auth_event.dart`

```dart
import 'package:equatable/equatable.dart';

/// Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App started - zkontroluj auth state
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User klikl na login button
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// User klikl na register button
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const RegisterRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// User klikl na logout button
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// User klikl na "forgot password"
class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}
```

#### 3.2 Auth States

Vytvoř: `lib/features/auth/presentation/bloc/auth_state.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Auth States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking auth
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// User je přihlášen
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User není přihlášen
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Loading (během login/register)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Error
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
```

#### 3.3 Auth BLoC

Vytvoř: `lib/features/auth/presentation/bloc/auth_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC - orchestrace autentifikace
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthInitial()) {
    // Poslouchat změny auth state
    _repository.authStateChanges.listen((user) {
      if (user != null) {
        add(const AuthCheckRequested());
      } else {
        emit(const Unauthenticated());
      }
    });

    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  /// Check aktuální auth state
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _repository.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  /// Login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Register
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.registerWithEmailAndPassword(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const Unauthenticated());
  }

  /// Reset password
  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.sendPasswordResetEmail(event.email);
      // Úspěch - můžeš přidat PasswordResetEmailSent state
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
```

---

### **FÁZE 4: Presentation Layer - UI** (3 hodiny)

#### 4.1 Login Page

Vytvoř: `lib/features/auth/presentation/pages/login_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_page.dart';

/// Login Page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.appColors.red,
              ),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: theme.appColors.cyan,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'TODO APP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.appColors.fg,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Přihlaste se do svého účtu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.appColors.base5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.appColors.fg),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: theme.appColors.base5),
                        prefixIcon: Icon(Icons.email, color: theme.appColors.cyan),
                        filled: true,
                        fillColor: theme.appColors.bgAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.appColors.base3),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Zadejte email';
                        }
                        if (!value.contains('@')) {
                          return 'Zadejte platný email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: theme.appColors.fg),
                      decoration: InputDecoration(
                        labelText: 'Heslo',
                        labelStyle: TextStyle(color: theme.appColors.base5),
                        prefixIcon: Icon(Icons.lock, color: theme.appColors.cyan),
                        filled: true,
                        fillColor: theme.appColors.bgAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.appColors.base3),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Zadejte heslo';
                        }
                        if (value.length < 6) {
                          return 'Heslo musí mít alespoň 6 znaků';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;

                        return ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.appColors.cyan,
                            foregroundColor: theme.appColors.bg,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.appColors.bg,
                                  ),
                                )
                              : const Text(
                                  'PŘIHLÁSIT SE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Register link
                    TextButton(
                      onPressed: _goToRegister,
                      child: Text(
                        'Nemáte účet? Zaregistrujte se',
                        style: TextStyle(color: theme.appColors.cyan),
                      ),
                    ),

                    // Forgot password link
                    TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password dialog
                      },
                      child: Text(
                        'Zapomenuté heslo?',
                        style: TextStyle(color: theme.appColors.base5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 4.2 Register Page

Vytvoř: `lib/features/auth/presentation/pages/register_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Register Page
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _displayNameController.text.trim().isEmpty
                  ? null
                  : _displayNameController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('REGISTRACE'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.appColors.red,
              ),
            );
          } else if (state is Authenticated) {
            // Úspěšná registrace - vrátit se na hlavní obrazovku
            Navigator.of(context).pop();
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Display name field
                    TextFormField(
                      controller: _displayNameController,
                      style: TextStyle(color: theme.appColors.fg),
                      decoration: InputDecoration(
                        labelText: 'Jméno (volitelné)',
                        labelStyle: TextStyle(color: theme.appColors.base5),
                        prefixIcon: Icon(Icons.person, color: theme.appColors.cyan),
                        filled: true,
                        fillColor: theme.appColors.bgAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.appColors.fg),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: theme.appColors.base5),
                        prefixIcon: Icon(Icons.email, color: theme.appColors.cyan),
                        filled: true,
                        fillColor: theme.appColors.bgAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Zadejte email';
                        }
                        if (!value.contains('@')) {
                          return 'Zadejte platný email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: theme.appColors.fg),
                      decoration: InputDecoration(
                        labelText: 'Heslo',
                        labelStyle: TextStyle(color: theme.appColors.base5),
                        prefixIcon: Icon(Icons.lock, color: theme.appColors.cyan),
                        filled: true,
                        fillColor: theme.appColors.bgAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Zadejte heslo';
                        }
                        if (value.length < 6) {
                          return 'Heslo musí mít alespoň 6 znaků';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: TextStyle(color: theme.appColors.fg),
                      decoration: InputDecoration(
                        labelText: 'Potvrdit heslo',
                        labelStyle: TextStyle(color: theme.appColors.base5),
                        prefixIcon: Icon(Icons.lock_outline, color: theme.appColors.cyan),
                        filled: true,
                        fillColor: theme.appColors.bgAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Hesla se neshodují';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;

                        return ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.appColors.green,
                            foregroundColor: theme.appColors.bg,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.appColors.bg,
                                  ),
                                )
                              : const Text(
                                  'REGISTROVAT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### **FÁZE 5: Integrace do Main App** (1 hodina)

#### 5.1 Upravit `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Auth feature
import 'features/auth/data/datasources/firebase_auth_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';

// Existující imports...
import 'services/tag_service.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializovat Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializovat TagService
  await TagService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC
        BlocProvider(
          create: (context) {
            final authBloc = AuthBloc(
              AuthRepositoryImpl(FirebaseAuthDataSource()),
            );
            authBloc.add(const AuthCheckRequested());
            return authBloc;
          },
        ),

        // Další BLoC providers (TodoListBloc, atd.)...
      ],
      child: MaterialApp(
        title: 'TODO App',
        theme: ThemeData.dark(), // Tvůj theme
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial || state is AuthLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is Authenticated) {
              return const HomePage(); // Existující hlavní obrazovka
            }

            return const LoginPage();
          },
        ),
      ),
    );
  }
}
```

---

## 🔒 SECURITY RULES

### Firestore Security Rules

V Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      // User profile
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false; // Nikdy nemažeme profily

      // User's todos subcollection
      match /todos/{todoId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId);
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
    }
  }
}
```

**Co tato pravidla dělají:**
- ✅ User může číst/zapisovat **jen svoje data**
- ✅ Ostatní uživatelé **nemohou vidět** tvoje úkoly
- ✅ Anonymní přístup **zakázán**

---

## 🔄 MIGRACE DAT (SQLite → Firestore)

### Krok 1: Vytvořit Firestore TodoDataSource

Vytvoř: `lib/features/todo_list/data/datasources/firestore_todo_datasource.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_model.dart';

class FirestoreTodoDataSource {
  final FirebaseFirestore _firestore;
  final String _userId;

  FirestoreTodoDataSource({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference pro user's todos
  CollectionReference<Map<String, dynamic>> get _todosCollection =>
      _firestore.collection('users').doc(_userId).collection('todos');

  /// Stream všech úkolů (real-time)
  Stream<List<TodoModel>> watchAllTodos() {
    return _todosCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TodoModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Získat všechny úkoly (one-time)
  Future<List<TodoModel>> getAllTodos() async {
    final snapshot = await _todosCollection.get();
    return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
  }

  /// Přidat nový úkol
  Future<String> addTodo(TodoModel todo) async {
    final docRef = await _todosCollection.add(todo.toFirestore());
    return docRef.id;
  }

  /// Update úkol
  Future<void> updateTodo(TodoModel todo) async {
    await _todosCollection.doc(todo.firestoreId).update(todo.toFirestore());
  }

  /// Smazat úkol
  Future<void> deleteTodo(String firestoreId) async {
    await _todosCollection.doc(firestoreId).delete();
  }
}
```

### Krok 2: Upravit TodoModel

Přidej Firestore mapping do `TodoModel`:

```dart
// lib/features/todo_list/data/models/todo_model.dart

// Přidej field pro Firestore ID
final String? firestoreId;

// Factory constructor z Firestore
factory TodoModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return TodoModel(
    id: data['localId'] as int?,  // Lokální SQLite ID (optional)
    firestoreId: doc.id,
    task: data['task'] as String,
    priority: data['priority'] as String?,
    dueDate: data['dueDate'] != null
        ? (data['dueDate'] as Timestamp).toDate()
        : null,
    tags: List<String>.from(data['tags'] ?? []),
    isCompleted: data['isCompleted'] as bool,
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    // ... další fields
  );
}

// Konverze na Firestore map
Map<String, dynamic> toFirestore() {
  return {
    'localId': id,  // Zachovat pro zpětnou kompatibilitu
    'task': task,
    'priority': priority,
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'tags': tags,
    'isCompleted': isCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
    // ... další fields
  };
}
```

### Krok 3: Migrace existujících dat

Vytvoř utility script pro migraci:

```dart
// lib/utils/migrate_to_firestore.dart

import '../core/services/database_helper.dart';
import '../features/todo_list/data/datasources/firestore_todo_datasource.dart';
import '../features/todo_list/data/models/todo_model.dart';

Future<void> migrateToFirestore(String userId) async {
  final db = DatabaseHelper();
  final firestoreDs = FirestoreTodoDataSource(userId: userId);

  // Načíst všechny úkoly z SQLite
  final sqliteTodos = await db.getAllTodos();

  print('🔄 Migrace ${sqliteTodos.length} úkolů...');

  for (final todo in sqliteTodos) {
    try {
      await firestoreDs.addTodo(TodoModel.fromMap(todo));
      print('✅ Migrován: ${todo['task']}');
    } catch (e) {
      print('❌ Chyba při migraci: ${todo['task']}, error: $e');
    }
  }

  print('🎉 Migrace dokončena!');
}
```

Spustit při prvním přihlášení:

```dart
// V AuthBloc po úspěšném login:
if (isFirstLogin) {
  await migrateToFirestore(user.id);
}
```

---

## 🧪 TESTING

### Unit Tests - AuthBloc

Vytvoř: `test/features/auth/presentation/bloc/auth_bloc_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock repository
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(mockRepository);
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when login succeeds',
      build: () {
        when(() => mockRepository.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const User(
              id: '123',
              email: 'test@example.com',
              createdAt: DateTime(2025, 1, 1),
            ));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(),
        isA<Authenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError, Unauthenticated] when login fails',
      build: () {
        when(() => mockRepository.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(Exception('Nesprávné heslo'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'test@example.com',
        password: 'wrong',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
        const Unauthenticated(),
      ],
    );
  });
}
```

---

## 🚀 DEPLOYMENT

### Build pro jednotlivé platformy:

#### **Windows:**
```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/
```

#### **Android:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Nebo AAB pro Google Play:
flutter build appbundle --release
```

#### **Web:**
```bash
flutter build web --release
# Output: build/web/

# Deploy na Firebase Hosting:
firebase init hosting
firebase deploy --only hosting
```

---

## 📚 ZÁVĚREČNÉ POZNÁMKY

### Co jsme dosáhli:
- ✅ Email/Password autentifikace
- ✅ Real-time sync mezi zařízeními
- ✅ Offline persistence
- ✅ Multi-platform (Windows, Android, Web)
- ✅ Feature-First + BLoC architektura
- ✅ Secure (Firestore Security Rules)

### Další vylepšení (optional):
- 🔹 Google Sign-In
- 🔹 Apple Sign-In
- 🔹 Biometric authentication (fingerprint/Face ID)
- 🔹 Email verification
- 🔹 Password strength indicator
- 🔹 Remember me checkbox
- 🔹 Dark/Light theme toggle na login screen

### Performance tips:
- 📊 Firestore indexy pro rychlejší queries
- 🔄 Pagination pro velké seznamy úkolů
- 💾 Aggressive caching
- ⚡ Lazy loading subtasks

---

## 📞 SUPPORT

**Otázky během implementace?**
- Firebase Docs: https://firebase.google.com/docs
- FlutterFire: https://firebase.flutter.dev/
- BLoC pattern: https://bloclibrary.dev/

**Common issues:**
1. **Firebase init error** → Zkontroluj `firebase_options.dart`
2. **Android build error** → Zkontroluj `google-services.json` v `android/app/`
3. **Firestore permission denied** → Zkontroluj Security Rules

---

🎉 **Hodně štěstí s implementací!** 🎉

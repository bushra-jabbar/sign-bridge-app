enum ClipKind { sign, fingerspell }

class Clip {
  const Clip({required this.clip, required this.label, required this.kind});

  final String clip;
  final String label;
  final ClipKind kind;
}

class SignEntry {
  const SignEntry({
    required this.gloss,
    required this.displayText,
    required this.category,
    required this.clipName,
  });

  final String gloss;
  final String displayText;
  final String category;
  final String clipName;
}

class PhraseEntry {
  const PhraseEntry({required this.phraseNorm, required this.glossSequence});

  final String phraseNorm;
  final String glossSequence;
}

abstract class GlossEngine {
  Future<List<Clip>> translate(String text, {String language = 'asl'});
}

abstract class SignLexicon {
  Future<SignEntry?> findWord(String lemma, String lang);
  Future<PhraseEntry?> findPhrase(String normalised, String lang);
  Future<String?> findSynonym(String variant, String lang);
  Future<String?> findIrregularVerb(String form, String lang);
  Future<String?> findAlphabetClip(String letter, String lang);
  Future<List<SignEntry>> browse({String? category, String? query});
}

abstract class SpeechInput {
  Future<bool> isAvailable();
  Stream<String> listen();
  Future<void> stop();
}

abstract class SignRecognizer {
  Stream<Map<String, dynamic>> recognize();
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.password,
  });

  final String id;
  final String email;
  final String displayName;
  final String password;

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'password': password,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: (map['id'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? 'User',
      password: (map['password'] as String?) ?? '',
    );
  }
}

abstract class AuthRepository {
  Stream<AppUser?> get user;
  Future<void> signIn(String email, String password);
  Future<void> register({
    required String email,
    required String password,
    String displayName,
  });
  Future<void> resetPassword(String email, String newPassword);
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> updateProfile({String? displayName, String? email});
  Future<void> changePassword(String oldPassword, String newPassword);
}

abstract class HistoryRepository {
  Future<void> add(HistoryEntry entry);
  Future<List<HistoryEntry>> recent({int limit = 50});
}

class HistoryEntry {
  const HistoryEntry({
    required this.inputText,
    required this.clips,
    required this.createdAt,
    this.language = 'asl',
    this.mode = 'text_to_sign',
  });

  final String inputText;
  final List<Clip> clips;
  final DateTime createdAt;
  final String language;
  final String mode;
}

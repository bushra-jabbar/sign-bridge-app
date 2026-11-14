import 'package:flutter_test/flutter_test.dart';
import 'package:sign_bridge_app/core/interfaces/gloss_engine.dart';
import 'package:sign_bridge_app/features/gloss/normaliser.dart';
import 'package:sign_bridge_app/features/gloss/rule_gloss_engine.dart';

void main() {
  late RuleGlossEngine engine;

  setUp(() {
    engine = RuleGlossEngine(_TestLexicon());
  });

  test('normalises punctuation and expands contractions', () {
    expect(Normaliser.normalise("I don't understand!"), [
      'i',
      'do',
      'not',
      'understand',
    ]);
  });

  test('uses the longest phrase match', () async {
    final clips = await engine.translate('Good morning');
    expect(_labels(clips), ['GOOD-MORNING']);
  });

  test('uses suffix rules only when the resulting lemma exists', () async {
    expect(_labels(await engine.translate('I am running')), ['me', 'run']);
    expect(_labels(await engine.translate('She goes to school')), [
      'she',
      'go',
      'school',
    ]);
  });

  test('drops be forms and maps first-person pronouns', () async {
    final clips = await engine.translate('I am hungry');
    expect(_labels(clips), ['me', 'hungry']);
  });

  test('matches the common how-are-you phrase', () async {
    final clips = await engine.translate('How are you?');
    expect(_labels(clips), ['HOW', 'YOU']);
  });

  test(
    'uses phrase entries before translating their individual words',
    () async {
      expect(_labels(await engine.translate('Thank you')), ['THANK-YOU']);
      expect(_labels(await engine.translate('I love you')), ['I-LOVE-YOU']);
    },
  );

  test('moves wh-words to the end', () async {
    expect(_labels(await engine.translate('What is your name?')), [
      'your',
      'name',
      'what',
    ]);
    expect(_labels(await engine.translate('Where is the bathroom?')), [
      'bathroom',
      'where',
    ]);
  });

  test(
    'expands contractions and drops the auxiliary do in a negation',
    () async {
      expect(_labels(await engine.translate("I don't understand")), [
        'me',
        'not',
        'understand',
      ]);
    },
  );

  test(
    'lemmatises verbs, drops infinitive to, and fronts time words',
    () async {
      expect(
        _labels(await engine.translate('She is going to school tomorrow')),
        ['tomorrow', 'she', 'go', 'school'],
      );
    },
  );

  test('fingerspells an unknown word in order', () async {
    final clips = await engine.translate('COMSATS');
    expect(_labels(clips), ['C', 'O', 'M', 'S', 'A', 'T', 'S']);
    expect(clips.every((clip) => clip.kind == ClipKind.fingerspell), isTrue);
    expect(clips.map((clip) => clip.clip).toList(), [
      'FS_C',
      'FS_O',
      'FS_M',
      'FS_S',
      'FS_A',
      'FS_T',
      'FS_S',
    ]);
  });
}

List<String> _labels(List<Clip> clips) =>
    clips.map((clip) => clip.label).toList();

class _TestLexicon implements SignLexicon {
  static const _entries = {
    'hello': SignEntry(
      gloss: 'HELLO',
      displayText: 'hello',
      category: 'greetings',
      clipName: 'HELLO',
    ),
    'thank you': SignEntry(
      gloss: 'THANK-YOU',
      displayText: 'thank you',
      category: 'greetings',
      clipName: 'THANK-YOU',
    ),
    'good': SignEntry(
      gloss: 'GOOD',
      displayText: 'good',
      category: 'emotions',
      clipName: 'GOOD',
    ),
    'yes': SignEntry(
      gloss: 'YES',
      displayText: 'yes',
      category: 'responses',
      clipName: 'YES',
    ),
    'no': SignEntry(
      gloss: 'NO',
      displayText: 'no',
      category: 'responses',
      clipName: 'NO',
    ),
    'i': SignEntry(
      gloss: 'I',
      displayText: 'I',
      category: 'pronouns',
      clipName: 'I',
    ),
    'you': SignEntry(
      gloss: 'YOU',
      displayText: 'you',
      category: 'pronouns',
      clipName: 'YOU',
    ),
    'she': SignEntry(
      gloss: 'SHE',
      displayText: 'she',
      category: 'pronouns',
      clipName: 'SHE',
    ),
    'me': SignEntry(
      gloss: 'ME',
      displayText: 'me',
      category: 'pronouns',
      clipName: 'ME',
    ),
    'your': SignEntry(
      gloss: 'YOUR',
      displayText: 'your',
      category: 'pronouns',
      clipName: 'YOUR',
    ),
    'school': SignEntry(
      gloss: 'SCHOOL',
      displayText: 'school',
      category: 'places',
      clipName: 'SCHOOL',
    ),
    'hungry': SignEntry(
      gloss: 'HUNGRY',
      displayText: 'hungry',
      category: 'health',
      clipName: 'HUNGRY',
    ),
    'understand': SignEntry(
      gloss: 'UNDERSTAND',
      displayText: 'understand',
      category: 'communication',
      clipName: 'UNDERSTAND',
    ),
    'not': SignEntry(
      gloss: 'NOT',
      displayText: 'not',
      category: 'communication',
      clipName: 'NOT',
    ),
    'bathroom': SignEntry(
      gloss: 'BATHROOM',
      displayText: 'bathroom',
      category: 'places',
      clipName: 'BATHROOM',
    ),
    'name': SignEntry(
      gloss: 'NAME',
      displayText: 'name',
      category: 'communication',
      clipName: 'NAME',
    ),
    'where': SignEntry(
      gloss: 'WHERE',
      displayText: 'where',
      category: 'questions',
      clipName: 'WHERE',
    ),
    'what': SignEntry(
      gloss: 'WHAT',
      displayText: 'what',
      category: 'questions',
      clipName: 'WHAT',
    ),
    'how': SignEntry(
      gloss: 'HOW',
      displayText: 'how',
      category: 'questions',
      clipName: 'HOW',
    ),
    'go': SignEntry(
      gloss: 'GO',
      displayText: 'go',
      category: 'actions',
      clipName: 'GO',
    ),
    'run': SignEntry(
      gloss: 'RUN',
      displayText: 'run',
      category: 'actions',
      clipName: 'RUN',
    ),
    'tomorrow': SignEntry(
      gloss: 'TOMORROW',
      displayText: 'tomorrow',
      category: 'time',
      clipName: 'TOMORROW',
    ),
    'love': SignEntry(
      gloss: 'LOVE',
      displayText: 'love',
      category: 'emotions',
      clipName: 'LOVE',
    ),
  };

  static const _phrases = {
    'good morning': PhraseEntry(
      phraseNorm: 'good morning',
      glossSequence: 'GOOD-MORNING',
    ),
    'thank you': PhraseEntry(
      phraseNorm: 'thank you',
      glossSequence: 'THANK-YOU',
    ),
    'how are you': PhraseEntry(
      phraseNorm: 'how are you',
      glossSequence: 'HOW YOU',
    ),
    'i love you': PhraseEntry(
      phraseNorm: 'i love you',
      glossSequence: 'I-LOVE-YOU',
    ),
  };

  static const _synonyms = {'hi': 'hello', 'hey': 'hello'};
  static const _irregularVerbs = {'went': 'go', 'gone': 'go'};

  @override
  Future<SignEntry?> findWord(String lemma, String lang) async =>
      _entries[lemma.toLowerCase()];

  @override
  Future<PhraseEntry?> findPhrase(String normalised, String lang) async =>
      _phrases[normalised];

  @override
  Future<String?> findSynonym(String variant, String lang) async =>
      _synonyms[variant.toLowerCase()];

  @override
  Future<String?> findIrregularVerb(String form, String lang) async =>
      _irregularVerbs[form.toLowerCase()];

  @override
  Future<String?> findAlphabetClip(String letter, String lang) async =>
      'FS_${letter.toUpperCase()}';

  @override
  Future<List<SignEntry>> browse({String? category, String? query}) async =>
      _entries.values.toList();
}

import '../../core/interfaces/gloss_engine.dart';
import 'normaliser.dart';

class RuleGlossEngine implements GlossEngine {
  RuleGlossEngine(this._lexicon);

  final SignLexicon _lexicon;

  static const _articles = {'a', 'an', 'the'};
  static const _beForms = {'am', 'is', 'are', 'was', 'were', 'be', 'been'};
  static const _pronouns = {'i': 'me'};
  static const _timeWords = {'today', 'tomorrow', 'yesterday', 'now'};
  static const _whWords = {'what', 'where', 'when', 'who', 'why'};

  @override
  Future<List<Clip>> translate(String text, {String language = 'asl'}) async {
    final words = Normaliser.normalise(text);
    final clips = <Clip>[];
    final timeClips = <Clip>[];
    final whClips = <Clip>[];

    for (var index = 0; index < words.length;) {
      final phrase = await _longestPhraseAt(words, index, language);
      if (phrase != null) {
        clips.addAll(_phraseClips(phrase));
        index += phrase.wordCount;
        continue;
      }

      final word = words[index];
      if (_articles.contains(word) || _beForms.contains(word)) {
        index++;
        continue;
      }

      if (word == 'do' &&
          index + 1 < words.length &&
          words[index + 1] == 'not') {
        index++;
        continue;
      }

      if (word == 'to' && await _shouldDropTo(words, index, language)) {
        index++;
        continue;
      }

      final synonym = await _lexicon.findSynonym(word, language);
      final resolved = await _resolveLemma(synonym ?? word, language);
      final gloss = _pronouns[resolved] ?? resolved;

      if (_timeWords.contains(gloss)) {
        timeClips.addAll(await _clipsForWord(gloss, language));
      } else if (_whWords.contains(gloss)) {
        whClips.addAll(await _clipsForWord(gloss, language));
      } else {
        clips.addAll(await _clipsForWord(gloss, language));
      }
      index++;
    }

    return [...timeClips, ...clips, ...whClips];
  }

  Future<_PhraseMatch?> _longestPhraseAt(
    List<String> words,
    int start,
    String language,
  ) async {
    for (var end = words.length; end > start + 1; end--) {
      final phraseNorm = words.sublist(start, end).join(' ');
      final phrase = await _lexicon.findPhrase(phraseNorm, language);
      if (phrase != null) {
        return _PhraseMatch(
          glossSequence: phrase.glossSequence,
          wordCount: end - start,
        );
      }
    }
    return null;
  }

  List<Clip> _phraseClips(_PhraseMatch phrase) {
    return phrase.glossSequence
        .split(RegExp(r'\s+'))
        .where((gloss) => gloss.isNotEmpty)
        .map((gloss) => Clip(clip: gloss, label: gloss, kind: ClipKind.sign))
        .toList();
  }

  Future<bool> _shouldDropTo(
    List<String> words,
    int index,
    String language,
  ) async {
    if (index + 1 < words.length && await _isVerb(words[index + 1], language)) {
      return true;
    }
    if (index > 0 && await _isVerb(words[index - 1], language)) {
      return true;
    }
    return false;
  }

  Future<bool> _isVerb(String word, String language) async {
    final synonym = await _lexicon.findSynonym(word, language);
    final lemma = await _resolveLemma(synonym ?? word, language);
    final entry = await _lexicon.findWord(lemma, language);
    return entry?.category == 'actions';
  }

  Future<String> _resolveLemma(String word, String language) async {
    final irregular = await _lexicon.findIrregularVerb(word, language);
    if (irregular != null) {
      return irregular;
    }

    final candidates = <String>[];
    if (word.endsWith('ies') && word.length > 4) {
      candidates.add('${word.substring(0, word.length - 3)}y');
    }
    if (word.endsWith('ing') && word.length > 4) {
      final stem = word.substring(0, word.length - 3);
      candidates
        ..add(stem)
        ..add('${stem}e');
      if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
        candidates.add(stem.substring(0, stem.length - 1));
      }
    }
    if (word.endsWith('ed') && word.length > 3) {
      final stem = word.substring(0, word.length - 2);
      candidates
        ..add(stem)
        ..add('${stem}e');
      if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
        candidates.add(stem.substring(0, stem.length - 1));
      }
    }
    if (word.endsWith('es') && word.length > 3) {
      candidates.add(word.substring(0, word.length - 2));
    }
    if (word.endsWith('s') && !word.endsWith('ss') && word.length > 3) {
      candidates.add(word.substring(0, word.length - 1));
    }

    for (final candidate in candidates) {
      if (await _lexicon.findWord(candidate, language) != null) {
        return candidate;
      }
    }
    return word;
  }

  Future<List<Clip>> _clipsForWord(String word, String language) async {
    final entry = await _lexicon.findWord(word, language);
    if (entry != null) {
      return [
        Clip(
          clip: entry.clipName,
          label: entry.displayText,
          kind: ClipKind.sign,
        ),
      ];
    }

    final clips = <Clip>[];
    for (final character in word.toUpperCase().split('')) {
      final clipName = RegExp(r'[A-Z]').hasMatch(character)
          ? await _lexicon.findAlphabetClip(character, language) ??
                'FS_$character'
          : 'FS_$character';
      clips.add(
        Clip(clip: clipName, label: character, kind: ClipKind.fingerspell),
      );
    }
    return clips;
  }
}

class _PhraseMatch {
  const _PhraseMatch({required this.glossSequence, required this.wordCount});

  final String glossSequence;
  final int wordCount;
}

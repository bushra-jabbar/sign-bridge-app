class Normaliser {
  Normaliser._();

  static const Map<String, String> _contractions = {
    "can't": 'can not',
    "couldn't": 'could not',
    "didn't": 'did not',
    "doesn't": 'does not',
    "don't": 'do not',
    "hadn't": 'had not',
    "hasn't": 'has not',
    "haven't": 'have not',
    "he's": 'he is',
    "i'm": 'i am',
    "isn't": 'is not',
    "it's": 'it is',
    "she's": 'she is',
    "shouldn't": 'should not',
    "they're": 'they are',
    "wasn't": 'was not',
    "we're": 'we are',
    "weren't": 'were not',
    "won't": 'will not',
    "wouldn't": 'would not',
    "you're": 'you are',
  };

  static List<String> normalise(String text) {
    var normalised = text.toLowerCase().replaceAll('’', "'");

    for (final contraction in _contractions.entries) {
      normalised = normalised.replaceAll(
        RegExp('\\b${RegExp.escape(contraction.key)}\\b'),
        contraction.value,
      );
    }

    return RegExp(r'[a-z0-9]+')
        .allMatches(normalised)
        .map((match) => match.group(0)!)
        .toList();
  }
}

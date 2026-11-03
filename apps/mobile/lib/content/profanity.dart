/// A small, conservative word filter for questions people write themselves (BUILD_PROMPT §7).
/// It blocks common English and Hindi/Hinglish swear words and slurs, with simple look-alike
/// spellings ("sh1t", "f*ck"). It is a guard rail for a party game played in person, not
/// moderation: custom questions never leave the phone.
library;

const _blocked = <String>{
  // English
  'fuck', 'fucker', 'fucking', 'motherfucker', 'shit', 'bullshit', 'bitch', 'bastard', 'asshole',
  'arsehole', 'dick', 'dickhead', 'cock', 'cunt', 'pussy', 'slut', 'whore', 'wanker', 'twat',
  'prick', 'bollocks', 'jackass', 'douchebag', 'porn', 'nude', 'nudes', 'rape', 'rapist',
  // Slurs
  'nigger', 'nigga', 'faggot', 'fag', 'retard', 'retarded', 'tranny', 'chink', 'spic', 'kike',
  'paki',
  // Hindi / Hinglish
  'chutiya', 'chutiye', 'madarchod', 'behenchod', 'bhenchod', 'bhosdike', 'bhosdi', 'gaand',
  'gandu', 'randi', 'lund', 'lauda', 'loda', 'harami', 'kutta', 'kutti', 'kamina', 'kamine',
  'chod', 'jhatu', 'tatti',
};

const _lookAlikes = {
  '0': 'o',
  '1': 'i',
  '!': 'i',
  '3': 'e',
  '4': 'a',
  '@': 'a',
  '5': 's',
  r'$': 's',
  '7': 't',
  '*': 'u',
};

String _normalise(String word) {
  final b = StringBuffer();
  for (final ch in word.toLowerCase().split('')) {
    b.write(_lookAlikes[ch] ?? ch);
  }
  // "fuuuck" → "fuck": collapse letters repeated three or more times.
  return b.toString().replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m[1]!);
}

/// True when [text] contains a blocked word (whole words only, so "Scunthorpe" is fine).
bool containsProfanity(String text) {
  for (final raw in text.split(RegExp(r"[^\p{L}\p{N}@$!*']+", unicode: true))) {
    if (raw.isEmpty) continue;
    final w = _normalise(raw.replaceAll("'", ''));
    if (_blocked.contains(w)) return true;
    // Common endings: "shits", "bitches", "fucked".
    for (final suffix in ['s', 'es', 'ed', 'ing', 'er', 'y']) {
      if (w.length > suffix.length + 2 &&
          w.endsWith(suffix) &&
          _blocked.contains(w.substring(0, w.length - suffix.length))) {
        return true;
      }
    }
  }
  return false;
}

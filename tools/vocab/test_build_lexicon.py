import csv
import json
import tempfile
import unittest
from pathlib import Path

from build_lexicon import (
    build_rows,
    load_glosses,
    load_sentence_counts,
    load_word_frequencies,
    normalise_gloss,
    write_outputs,
)


class BuildLexiconTest(unittest.TestCase):
    def test_normalises_multiword_glosses_for_clip_names(self):
        self.assertEqual(normalise_gloss("good morning"), "good-morning")

    def test_ranks_only_glosses_found_in_sentences_and_assigns_tiers(self):
        rows = build_rows(
            {"hello", "good-morning", "unused"},
            {"hello": 3, "good morning": 7},
            {"hello": 100, "good-morning": 1},
        )

        self.assertEqual([row["gloss"] for row in rows], ["GOOD-MORNING", "HELLO"])
        self.assertEqual(rows[0]["tier"], "tier1")
        self.assertEqual(rows[0]["category"], "greetings")
        self.assertEqual(rows[0]["clip_name"], "GOOD-MORNING")

    def test_reads_text_inputs_and_writes_the_expected_output_files(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            gloss_path = root / "glosses.json"
            sentences_path = root / "sentences.csv"
            frequency_path = root / "frequency.txt"
            output_path = root / "output"
            gloss_path.write_text(
                json.dumps([{"gloss": "hello"}, {"gloss": "good morning"}]),
                encoding="utf-8",
            )
            sentences_path.write_text(
                'sentence\n"Hello, good morning."\n',
                encoding="utf-8",
            )
            frequency_path.write_text(
                "good-morning 10\nhello 5\n",
                encoding="utf-8",
            )

            glosses = load_glosses(gloss_path)
            sentence_counts = load_sentence_counts(sentences_path)
            word_frequencies = load_word_frequencies(frequency_path)
            rows = build_rows(glosses, sentence_counts, word_frequencies)
            lexicon_path, clips_path = write_outputs(rows, output_path)

            with lexicon_path.open(encoding="utf-8", newline="") as source:
                written_rows = list(csv.DictReader(source))
            self.assertEqual(
                [row["gloss"] for row in written_rows],
                ["GOOD-MORNING", "HELLO"],
            )
            self.assertEqual(
                clips_path.read_text(encoding="utf-8").splitlines(),
                ["GOOD-MORNING", "HELLO"],
            )


if __name__ == "__main__":
    unittest.main()

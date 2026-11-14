#!/usr/bin/env python3
"""Build an offline sign lexicon from text-only dataset metadata."""

import argparse
import csv
import json
import re
from collections import Counter
from pathlib import Path

TOKEN_PATTERN = re.compile(r"[a-z0-9]+")

CATEGORY_WORDS = {
    "actions": {
        "eat", "drink", "sleep", "go", "know", "tell", "read", "write",
        "work", "help", "understand", "want", "need", "come", "make",
    },
    "emotions": {"good", "bad", "happy", "sad", "angry", "love", "worried"},
    "greetings": {"hello", "hi", "good-morning", "goodbye", "thank-you"},
    "people": {"mother", "father", "sister", "brother", "friend", "family"},
    "places": {"home", "house", "school", "hospital", "bathroom", "store"},
    "questions": {"what", "where", "when", "who", "why", "how"},
    "responses": {"yes", "no", "maybe"},
    "time": {"today", "tomorrow", "yesterday", "now"},
}


def normalise_gloss(value):
    words = TOKEN_PATTERN.findall(value.lower().replace("_", " "))
    return "-".join(words)


def load_glosses(path):
    with path.open(encoding="utf-8-sig") as source:
        data = json.load(source)

    glosses = set()

    def visit(value):
        if isinstance(value, dict):
            gloss = value.get("gloss")
            if isinstance(gloss, str):
                normalised = normalise_gloss(gloss)
                if normalised:
                    glosses.add(normalised)
            else:
                for child in value.values():
                    visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)
        elif isinstance(value, str):
            normalised = normalise_gloss(value)
            if normalised:
                glosses.add(normalised)

    visit(data)
    if not glosses:
        raise ValueError(f"No glosses found in {path}")
    return glosses


def _choose_text_column(fieldnames, requested):
    if not fieldnames:
        raise ValueError("The sentence CSV has no header row")
    if requested:
        if requested not in fieldnames:
            raise ValueError(
                f"Text column {requested!r} is missing; found: {fieldnames}"
            )
        return requested

    preferred = ("sentence", "text", "english", "translation")
    lowered = {name.lower(): name for name in fieldnames}
    for candidate in preferred:
        if candidate in lowered:
            return lowered[candidate]
    for name in fieldnames:
        if any(candidate in name.lower() for candidate in preferred):
            return name
    raise ValueError(
        "Could not identify the English sentence column; pass --text-column"
    )


def load_sentence_counts(path, text_column=None):
    counts = Counter()
    with path.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        column = _choose_text_column(reader.fieldnames, text_column)
        for row in reader:
            tokens = TOKEN_PATTERN.findall((row.get(column) or "").lower())
            for start in range(len(tokens)):
                for width in range(1, min(3, len(tokens) - start) + 1):
                    counts[" ".join(tokens[start : start + width])] += 1
    return counts


def load_word_frequencies(path):
    frequencies = {}
    with path.open(encoding="utf-8-sig") as source:
        for line in source:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = re.split(r"[\s,;]+", line)
            if len(parts) < 2:
                continue
            try:
                frequency = int(parts[1])
                word = normalise_gloss(parts[0])
            except ValueError:
                continue
            if word:
                frequencies[word] = frequency
    return frequencies


def _category_for(gloss):
    for category, words in CATEGORY_WORDS.items():
        if gloss in words:
            return category
    return "common"


def build_rows(glosses, sentence_counts, word_frequencies, limit=500):
    ranked = []
    for gloss in glosses:
        sentence_frequency = sentence_counts.get(gloss.replace("-", " "), 0)
        if sentence_frequency:
            ranked.append(
                (
                    gloss,
                    sentence_frequency,
                    word_frequencies.get(gloss, 0),
                )
            )

    ranked.sort(key=lambda item: (-item[1], -item[2], item[0]))
    rows = []
    for rank, (gloss, frequency, _) in enumerate(ranked[:limit], start=1):
        tier = "tier1" if rank <= 100 else "tier2" if rank <= 250 else "tier3"
        rows.append(
            {
                "language": "asl",
                "gloss": gloss.upper(),
                "display_text": gloss.replace("-", " "),
                "category": _category_for(gloss),
                "tier": tier,
                "frequency": frequency,
                "clip_name": gloss.upper(),
            }
        )
    return rows


def write_outputs(rows, output_dir):
    output_dir.mkdir(parents=True, exist_ok=True)
    lexicon_path = output_dir / "lexicon_seed.csv"
    fields = [
        "language",
        "gloss",
        "display_text",
        "category",
        "tier",
        "frequency",
        "clip_name",
    ]
    with lexicon_path.open("w", encoding="utf-8", newline="") as target:
        writer = csv.DictWriter(target, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)

    clips_path = output_dir / "clips_needed.txt"
    with clips_path.open("w", encoding="utf-8", newline="\n") as target:
        for row in rows:
            target.write(f"{row['clip_name']}\n")
    return lexicon_path, clips_path


def main():
    parser = argparse.ArgumentParser(
        description="Build the ASL seed CSV using text and gloss metadata only."
    )
    parser.add_argument("--wlasl", required=True, type=Path, help="WLASL gloss JSON")
    parser.add_argument(
        "--sentences", required=True, type=Path, help="How2Sign sentence CSV"
    )
    parser.add_argument(
        "--word-frequency",
        required=True,
        type=Path,
        help="Text file with word and frequency columns",
    )
    parser.add_argument(
        "--text-column",
        help="Sentence text column name (auto-detected when omitted)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("assets/packs/asl"),
        help="Output folder (default: assets/packs/asl)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=500,
        help="Maximum number of ranked glosses to write (default: 500)",
    )
    args = parser.parse_args()

    if args.limit < 1:
        parser.error("--limit must be at least 1")
    glosses = load_glosses(args.wlasl)
    sentence_counts = load_sentence_counts(args.sentences, args.text_column)
    word_frequencies = load_word_frequencies(args.word_frequency)
    rows = build_rows(glosses, sentence_counts, word_frequencies, args.limit)
    if not rows:
        parser.error("No WLASL glosses appeared in the sentence dataset")

    lexicon_path, clips_path = write_outputs(rows, args.output_dir)
    print(f"Wrote {len(rows)} signs to {lexicon_path}")
    print(f"Wrote the matching clip list to {clips_path}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Builds the app's reading_plan.json and docs/STUDY_PLAN.md from plan_source.txt.

Usage: python3 tools/build_plan.py
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "tools" / "plan_source.txt"
JSON_OUT = ROOT / "LeadershipPathway" / "Resources" / "reading_plan.json"
MD_OUT = ROOT / "docs" / "STUDY_PLAN.md"

BOOKS = {
    "Mark": "Mark", "Acts": "Acts", "Rom": "Romans", "Luke": "Luke",
    "1 Cor": "1 Corinthians", "2 Cor": "2 Corinthians", "Gal": "Galatians",
    "Eph": "Ephesians", "Phil": "Philippians", "Col": "Colossians",
    "Matt": "Matthew", "Heb": "Hebrews", "James": "James", "John": "John",
    "1 Thess": "1 Thessalonians", "2 Thess": "2 Thessalonians",
    "1 Tim": "1 Timothy", "2 Tim": "2 Timothy", "Titus": "Titus",
    "Philemon": "Philemon", "1 Pet": "1 Peter", "2 Pet": "2 Peter",
    "1 John": "1 John", "2 John": "2 John", "3 John": "3 John",
    "Jude": "Jude", "Rev": "Revelation", "Ps": "Psalms", "Prov": "Proverbs",
}
CONTINUATION = re.compile(r"^\d+(:\d+)?(–\d+(:\d+)?)?$")
SEGMENT = re.compile(r"^(?P<book>(?:[123] )?[A-Za-z]+)(?: (?P<ref>.+))?$")


def category(book):
    if book == "Ps":
        return "psalms"
    if book == "Prov":
        return "proverbs"
    return "newTestament"


def parse_passages(text):
    passages, prev_book = [], None
    for seg in (s.strip() for s in text.split(";")):
        if CONTINUATION.match(seg):
            if prev_book is None:
                raise ValueError(f"continuation without book: {text!r}")
            book, ref = prev_book, seg
        else:
            m = SEGMENT.match(seg)
            if not m or m.group("book") not in BOOKS:
                raise ValueError(f"unknown book in segment {seg!r} ({text!r})")
            book, ref = m.group("book"), m.group("ref") or ""
        prev_book = book
        passages.append({
            "book": BOOKS[book],
            "abbreviation": book,
            "reference": ref,
            "category": category(book),
        })
    return passages


def parse():
    weeks = []
    for line in SOURCE.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        tag, text = (p.strip() for p in line.split("|", 1))
        if tag.startswith("W"):
            weeks.append({"number": int(tag[1:]), "summary": text, "days": []})
        elif tag == "D":
            week = weeks[-1]
            week["days"].append({
                "number": len(week["days"]) + 1,
                "reading": text,
                "passages": parse_passages(text),
            })
        else:
            raise ValueError(f"bad line: {line!r}")
    validate(weeks)
    return weeks


def validate(weeks):
    assert [w["number"] for w in weeks] == list(range(1, 35)), "expected weeks 1–34"
    for w in weeks:
        assert len(w["days"]) == 5, f"week {w['number']} has {len(w['days'])} days"
        parse_passages(w["summary"])  # summary must parse too


def write_markdown(weeks):
    lines = [
        "# Leadership Pathway — 34-Week Reading Plan",
        "",
        "Generated from `tools/plan_source.txt` by `tools/build_plan.py`. Do not edit by hand.",
        "",
        "## Structure",
        "",
        "- **34 weeks × 5 reading days = 170 sessions.**",
        "- Three parallel tracks run through every week:",
        "  - **New Testament** — Mark → Acts → Romans → Luke → 1–2 Corinthians → Galatians → Ephesians →",
        "    Philippians → Colossians → Matthew → Hebrews → James → John → 1–2 Thessalonians → 1–2 Timothy →",
        "    Titus → Philemon → 1–2 Peter → 1–3 John → Jude → Revelation.",
        "  - **Psalms** — Psalms 1–150 in order.",
        "  - **Proverbs** — Proverbs 1–31 in order.",
        "- Days 1, 3 and 5 typically pair the New Testament with Psalms; days 2 and 4 pair it with Proverbs.",
        "",
    ]
    for w in weeks:
        lines += [f"## Week {w['number']}", "", f"_Weekly assignment:_ {w['summary']}", "",
                  "| Day | Reading |", "| --- | --- |"]
        lines += [f"| {d['number']} | {d['reading']} |" for d in w["days"]]
        lines.append("")
    MD_OUT.write_text("\n".join(lines), encoding="utf-8")


def main():
    weeks = parse()
    JSON_OUT.write_text(json.dumps({
        "title": "Leadership Pathway",
        "subtitle": "34-week reading plan",
        "weeks": weeks,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_markdown(weeks)
    days = sum(len(w["days"]) for w in weeks)
    passages = sum(len(d["passages"]) for w in weeks for d in w["days"])
    print(f"{len(weeks)} weeks, {days} days, {passages} passages")


if __name__ == "__main__":
    main()

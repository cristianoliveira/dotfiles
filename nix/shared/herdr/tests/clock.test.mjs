import assert from "node:assert/strict";
import test from "node:test";
import { formatStatusTime } from "../mods/tmux-status/clock.js";

test("status clock matches tmux's local 24-hour time and English date format", () => {
  assert.equal(formatStatusTime(new Date(2026, 10, 7, 19, 5)), "19:05 Sat 07-Nov-26");
});

test("status clock pads midnight and handles a leap day", () => {
  assert.equal(formatStatusTime(new Date(2024, 1, 29, 0, 3)), "00:03 Thu 29-Feb-24");
});

test("status clock rolls over the date and year", () => {
  assert.equal(formatStatusTime(new Date(2026, 11, 31, 23, 59)), "23:59 Thu 31-Dec-26");
  assert.equal(formatStatusTime(new Date(2027, 0, 1, 0, 0)), "00:00 Fri 01-Jan-27");
});

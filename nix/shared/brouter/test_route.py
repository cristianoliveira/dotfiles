import unittest
from datetime import datetime
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))
from route import choose_target  # noqa: E402


class RouteTargetTests(unittest.TestCase):
    def test_work_url_is_personal_before_workday_window(self):
        self.assertEqual(
            choose_target(b"https://meet.google.com/x", datetime(2026, 9, 14, 6, 59)),
            b"personal",
        )

    def test_work_url_is_work_at_window_start(self):
        self.assertEqual(
            choose_target(b"https://meet.google.com/x", datetime(2026, 9, 14, 7, 0)),
            b"work",
        )

    def test_drive_wire_url_is_work_at_window_start(self):
        self.assertEqual(
            choose_target(
                b"https://drive.wire.com/pub/default/15bac305f241",
                datetime(2026, 9, 16, 7, 0),
            ),
            b"work",
        )

    def test_jumpcloud_and_wire_patterns_are_separate(self):
        self.assertEqual(
            choose_target(b"https://jumpcloud.com", datetime(2026, 9, 16, 7, 0)),
            b"work",
        )
        self.assertEqual(
            choose_target(b"https://wire.com", datetime(2026, 9, 16, 7, 0)),
            b"work",
        )

    def test_work_url_is_work_until_window_end(self):
        self.assertEqual(
            choose_target(b"https://github.com/x", datetime(2026, 9, 18, 17, 59)),
            b"work",
        )

    def test_work_url_is_personal_at_window_end(self):
        self.assertEqual(
            choose_target(b"https://github.com/x", datetime(2026, 9, 18, 18, 0)),
            b"personal",
        )

    def test_work_url_is_personal_on_weekend(self):
        self.assertEqual(
            choose_target(b"https://github.com/x", datetime(2026, 9, 19, 10, 0)),
            b"personal",
        )

    def test_development_url_is_unchanged_outside_work_hours(self):
        self.assertEqual(
            choose_target(b"http://localhost:3000", datetime(2026, 9, 19, 10, 0)),
            b"dev",
        )

    def test_work_wins_overlap_during_work_hours(self):
        self.assertEqual(
            choose_target(
                b"https://github.com/localhost", datetime(2026, 9, 14, 9, 0)
            ),
            b"work",
        )

    def test_development_wins_overlap_outside_work_hours(self):
        self.assertEqual(
            choose_target(
                b"https://github.com/localhost", datetime(2026, 9, 14, 6, 59)
            ),
            b"dev",
        )

    def test_unmatched_url_defers_to_static_rules(self):
        self.assertEqual(
            choose_target(b"https://example.org", datetime(2026, 9, 14, 10, 0)),
            b"@default",
        )


if __name__ == "__main__":
    unittest.main()

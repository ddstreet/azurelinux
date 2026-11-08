import unittest
import sys
import subprocess

class TestFoma(unittest.TestCase):

    def test_dummy(self):
        self.assertEqual(True, True)

    @unittest.expectedFailure
    def test_expected_failure(self):
        self.assertEqual(False, True)

    def test_foma(self):
        cp  = subprocess.run(['foma -f foma-input.txt'], encoding='UTF-8', text=True, shell=True, capture_output=True)
        self.assertEqual(
            'defined Animals: 455 bytes. 6 states, 6 arcs, 2 paths.\n'
            '471 bytes. 6 states, 8 arcs, Cyclic.\n'
            'Animals\t455 bytes. 6 states, 6 arcs, 2 paths.\n',
            cp.stdout)
        self.assertEqual('', cp.stderr)
        self.assertEqual(0, cp.returncode)

if __name__ == "__main__":
    unittest.main()

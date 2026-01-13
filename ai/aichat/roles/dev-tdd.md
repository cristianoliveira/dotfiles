You are senior developer that is working on a large codebase.
You like to practice TDD (Test Driven Development) and you are working on a new feature.
I ask you to write a test for the new feature and you write the test.

DO NOT EXPLAIN THE CODE.

Request:
Write a test for fizzbuzz function in python

Response:
import unittest
from fizzbuzz import fizzbuzz

class TestFizzBuzz(unittest.TestCase):
    def test_fizzbuzz(self):
        # Test for multiples of 3
        self.assertEqual(fizzbuzz(3), "Fizz")
        self.assertEqual(fizzbuzz(6), "Fizz")
        self.assertEqual(fizzbuzz(9), "Fizz")

        # Test for multiples of 5
        self.assertEqual(fizzbuzz(5), "Buzz")
        self.assertEqual(fizzbuzz(10), "Buzz")
        self.assertEqual(fizzbuzz(20), "Buzz")

        # Test for multiples of both 3 and 5
        self.assertEqual(fizzbuzz(15), "FizzBuzz")
        self.assertEqual(fizzbuzz(30), "FizzBuzz")

        # Test for numbers that are not multiples of 3 or 5
        self.assertEqual(fizzbuzz(1), 1)
        self.assertEqual(fizzbuzz(2), 2)
        self.assertEqual(fizzbuzz(4), 4)
        self.assertEqual(fizzbuzz(7), 7)
        self.assertEqual(fizzbuzz(8), 8)

if __name__ == '__main__':
    unittest.main()

Request:
Write a test for fizzbuzz function in javascript

Response:
import assert from 'assert';
import { fizzbuzz } from './fizzbuzz.js';
import { describe, it } from 'vitest';

describe('FizzBuzz', function() {
    it('should return "Fizz" for multiples of 3', function() {
        assert.strictEqual(fizzbuzz(3), 'Fizz');
        assert.strictEqual(fizzbuzz(6), 'Fizz');
        assert.strictEqual(fizzbuzz(9), 'Fizz');
    });

    it('should return "Buzz" for multiples of 5', function() {
        assert.strictEqual(fizzbuzz(5), 'Buzz');
        assert.strictEqual(fizzbuzz(10), 'Buzz');
        assert.strictEqual(fizzbuzz(20), 'Buzz');
    });

    it('should return "FizzBuzz" for multiples of both 3 and 5', function() {
        assert.strictEqual(fizzbuzz(15), 'FizzBuzz');
        assert.strictEqual(fizzbuzz(30), 'FizzBuzz');
    });

    it('should return the number for non-multiples of 3 or 5', function() {
        assert.strictEqual(fizzbuzz(1), 1);
        assert.strictEqual(fizzbuzz(2), 2);
        assert.strictEqual(fizzbuzz(4), 4);
        assert.strictEqual(fizzbuzz(7), 7);
        assert.strictEqual(fizzbuzz(8), 8);
    });
});

Request: 
__INPUT__

Response: 

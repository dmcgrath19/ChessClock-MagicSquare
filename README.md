# Magic Square Checker

This project implements a subroutine in Assembly to determine whether a given square matrix qualifies as a magic square — a matrix in which the sums of all rows, columns, and both diagonals are equal.

## Problem Description

A magic square is a two-dimensional n x n matrix where:

- The sum of each row is equal.
- The sum of each column is equal.
- The sums of the two main diagonals are also equal.

A 1x1 matrix is considered a valid magic square by definition.

## Approach

The main subroutine `isMagicSquare` takes:

- A pointer to the start of the array representing the matrix.
- The size of the matrix (its width and height, since it is square).

It returns a boolean indicating whether the matrix is a magic square.

To improve modularity and clarity, the logic is broken down into three key subroutines:

### `isDiagonalEqual`

- Calculates the sum of both diagonals in a single loop.
- Compares them and returns true only if they match.
- Designed for efficiency by avoiding repeated loops.

### `isHorizontalEqual`

- Iterates through each row.
- Compares each row's sum to the first row.
- Returns false immediately if any row does not match.

### `isColumnEqual`

- Iterates through each column using index calculations.
- Compares each column’s sum to the first column’s total.
- Slightly more computationally intensive due to address arithmetic.

Each subroutine:

- Returns a boolean indicating success or failure.
- Provides the sum of the direction it evaluated, allowing `isMagicSquare` to compare results consistently.

The order of subroutine calls is optimized for efficiency, checking diagonals first (fixed number of checks), then rows, and finally columns.

## Testing

The subroutines were tested individually to ensure correctness. The main `isMagicSquare` routine was tested using various matrix sizes and both valid and invalid magic squares. Results were pushed to the stack and verified by popping and matching expected outcomes.

## Efficiency Considerations

- Early exit strategy: The program returns false as soon as any mismatch is found.
- Modular subroutine design promotes maintainability and testing.
- Redundant memory movement is avoided where possible.
- Diagonal sums are computed simultaneously in a single loop.

## Potential Improvements

- Subroutines could be merged into a single routine to reduce overhead and improve register reuse.
- Combining checks may also reduce memory movement and branching, improving overall efficiency at the cost of modularity and readability.

## Summary

This implementation is structured for efficiency and clarity. By checking conditions in a performance-conscious order and using a modular subroutine design, it balances execution speed with ease of understanding and testing.

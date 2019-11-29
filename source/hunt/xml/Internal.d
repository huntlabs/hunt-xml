/*
 * Hunt - A xml library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.xml.Internal;

import hunt.xml.Common;

// dfmt off

ubyte[256] lookup_whitespace = [
 // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  0,  0,  1,  0,  0,  // 0
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
    1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 2
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 3
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 4
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 5
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 6
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 7
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 8
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 9
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // A
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // B
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // C
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // D
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // E
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0   // F
];              // Whitespace table

ubyte[256] lookup_node_name = [
// 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];           // Node name table

ubyte[256] lookup_element_name = [
// 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  0,  0,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];          // Element name table

ubyte[256] lookup_text =  [
// 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];
                    // Text table
ubyte[256] lookup_text_pure_no_ws =  [
// 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];
         // Text table
ubyte[256] lookup_text_pure_with_ws =  [
// 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    0,  1,  1,  1,  1,  1,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];

// Text table
ubyte[256] lookup_attribute_name  = [
  // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  0,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];

// Attribute name table
ubyte[256] lookup_attribute_data_1 = [
// 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  1,  1,  1,  1,  1,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];

// Attribute data table with single quote
ubyte[256] lookup_attribute_data_1_pure =  [
 // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];

// Attribute data table with single quote
ubyte[256] lookup_attribute_data_2 =  [
 // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    1,  1,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];

// Attribute data table with double quotes
ubyte[256] lookup_attribute_data_2_pure = [
 // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 0
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
    1,  1,  0,  1,  1,  1,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 2
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 3
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
];

// Attribute data table with double quotes

ubyte[256] lookup_digits =  [
 // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // 0
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // 1
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // 2
    0,  1,  2,  3,  4,  5,  6,  7,  8,  9,255,255,255,255,255,255,  // 3
    255, 10, 11, 12, 13, 14, 15,255,255,255,255,255,255,255,255,255,  // 4
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // 5
    255, 10, 11, 12, 13, 14, 15,255,255,255,255,255,255,255,255,255,  // 6
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // 7
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // 8
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // 9
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // A
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // B
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // C
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // D
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,  // E
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255   // F
];

// Digits

ubyte[256] lookup_upcase =  [
 // 0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  A   B   C   D   E   F
    0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15,   // 0
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,   // 1
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,   // 2
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,   // 3
    64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,   // 4
    80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,   // 5
    96, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,   // 6
    80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 123,124,125,126,127,  // 7
    128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,  // 8
    144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,  // 9
    160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,  // A
    176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,  // B
    192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,  // C
    208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,  // D
    224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,  // E
    240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255   // F
]; 

// dfmt on

void insertCodedCharacter(int Flags)(ref char[] text,  ulong code)
{
    if (Flags & ParsingFlags.NoUtf8)
    {
        // Insert 8-bit ASCII character
        // Todo: possibly verify that code is less than 256 and use replacement char otherwise?
        text[0] = (code);
        text = text[ 1 .. $ - 1];
    }
    else
    {
        // Insert UTF8 sequence
        if (code < 0x80)    // 1 byte sequence
        {
            text[0] = (code);
            text = text[1 .. $ - 1];
        }
        else if (code < 0x800)  // 2 byte sequence
        {
            text[1] = ((code | 0x80) & 0xBF); code >>= 6;
            text[0] = (code | 0xC0);
            text = text[ 2 .. $ - 1];
        }
        else if (code < 0x10000)    // 3 byte sequence
        {
            text[2] = ((code | 0x80) & 0xBF); code >>= 6;
            text[1] = ((code | 0x80) & 0xBF); code >>= 6;
            text[0] = (code | 0xE0);
            text = text[3 .. $ - 1];
        }
        else if (code < 0x110000)   // 4 byte sequence
        {
            text[3] = ((code | 0x80) & 0xBF); code >>= 6;
            text[2] = ((code | 0x80) & 0xBF); code >>= 6;
            text[1] = ((code | 0x80) & 0xBF); code >>= 6;
            text[0] = (code | 0xF0);
            text = text[4 .. $ - 1];
        }
        else    // Invalid, only codes up to 0x10FFFF are allowed in Unicode
        {
            throw new XmlParsingException("invalid numeric character entity", text);
        }
    }
}

// Skip characters until predicate evaluates to true while doing the following:
// - replacing XML character entity references with proper characters (&apos; &amp; &quot; &lt; &gt; &#...;)
// - condensing whitespace sequences to single space character

static  char[] skipAndExpandCharacterRefs(T , TP , int Flags)(ref char[] text)
{
    // If entity translation, whitespace condense and whitespace trimming is disabled, use plain skip
    if (Flags & ParsingFlags.EntityTranslation &&
        !(Flags & ParsingFlags.NormalizeWhitespace) &&
        !(Flags & ParsingFlags.TrimWhitespace))
    {
        skip!(T)(text);
        return text;
    }

    // Use simple skip until first modification is detected
    skip!(TP)(text);
    // Use translation skip
    char[] src = text;
    char[] dest = src.dup;
    long index = 0;
    while (T.test(src[0]))
    {
        // If entity translation is enabled
        if (!(Flags & ParsingFlags.EntityTranslation))
        {
            // Test if replacement is needed
            if (src[0] == ('&'))
            {
                switch (src[1])
                {

                // &amp; &apos;
                case ('a'):
                    if (src[2] == ('m') && src[3] == ('p') && src[4] == (';'))
                    {
                        dest[index] = ('&');
                        ++index;
                        src=src[5..$-1];
                        continue;
                    }
                    if (src[2] == ('p') && src[3] == ('o') && src[4] == ('s') && src[5] == (';'))
                    {
                        dest[index] = ('\'');
                        ++index;
                        src = src[6 .. $-1];
                        continue;
                    }
                    break;

                // &quot;
                case ('q'):
                    if (src[2] == ('u') && src[3] == ('o') && src[4] == ('t') && src[5] == (';'))
                    {
                        dest[index] = ('"');
                        ++index;
                        src = src[6 .. $ - 1];
                        continue;
                    }
                    break;

                // &gt;
                case ('g'):
                    if (src[2] == ('t') && src[3] == (';'))
                    {
                        dest[index] = ('>');
                        ++index;
                        src = src[4 .. $ - 1];
                        continue;
                    }
                    break;

                // &lt;
                case ('l'):
                    if (src[2] == ('t') && src[3] == (';'))
                    {
                        dest[index] = ('<');
                        ++index;
                        src = src[ 4 .. $ - 1];
                        continue;
                    }
                    break;

                // &#...; - assumes ASCII
                case ('#'):
                    if (src[2] == ('x'))
                    {
                            ulong code = 0;
                        src = src[3 .. $ - 1];   // Skip &#x
                        while (1)
                        {
                            ubyte digit = lookup_digits[src[0]];
                            if (digit == 0xFF)
                                break;
                            code = code * 16 + digit;
                            src = src[1 .. $ - 1];
                        }
                        //   insertCodedCharacter!Flags(dest, code);    // Put character in output
                    }
                    else
                    {
                        ulong code = 0;
                        src = src[2 .. $ - 1];   // Skip &#
                        while (1)
                        {
                            ubyte digit = lookup_digits[src[0]];
                            if (digit == 0xFF)
                                break;
                            code = code * 10 + digit;
                            src=src[1 .. $ - 1];
                        }
                    //      insertCodedCharacter!Flags(dest, code);    // Put character in output
                    }
                    if (src[0] == (';'))
                        src=src[1..$ - 1];
                    else
                        throw new XmlParsingException("expected ;", src);
                    continue;

                // Something else
                default:
                    // Ignore, just copy '&' verbatim
                    break;

                }
            }
        }

        // If whitespace condensing is enabled
        if (Flags & ParsingFlags.NormalizeWhitespace)
        {
            // Test if condensing is needed
            if (WhitespacePred.test(src[0]))
            {
                dest[index] = (' '); ++index;    // Put single space in dest
                src = src[1 .. $ - 1];                      // Skip first whitespace char
                // Skip remaining whitespace chars
                while (WhitespacePred.test(src[0]))
                    src = src[1 .. $ - 1];
                continue;
            }
        }

        // No replacement, only copy character
        dest[index] = src[0];
        ++index;
        src = src[1 .. $ - 1];

    }

    // Return new end
    text = src;
    return dest;

}

    // private static void skip(T )(ref char[] text)
    // {

    //     char[] tmp = text;
    //     while(tmp.length > 0 && T.test(tmp[0]))
    //     {
    //         tmp = tmp[1 .. $];    
    //     }
    //     text = tmp;
    // }


void skip(T)(ref char[] text)
{
    int index = 0;
    int length = cast(int)text.length;
    while(index < text.length && T.test(text[index]))
        index++;
    text = text[index .. $];
}

struct WhitespacePred
{
    static ubyte test(ubyte ch)
    {
        return lookup_whitespace[ch];
    }
}

// Detect node name character
struct NodeNamePred
{
    static ubyte test(ubyte ch)
    {
        return lookup_node_name[ch];
    }
}

// Detect element name character
struct ElementNamePred
{
    static ubyte test(ubyte ch)
    {
        return lookup_element_name[ch];
    }
}

// Detect attribute name character
struct AttributeNamePred
{
    static ubyte test(ubyte ch)
    {
        return lookup_attribute_name[ch];
    }
}

// Detect text character (PCDATA)
struct TextPred
{
    static ubyte test(ubyte ch)
    {
        return lookup_text[ch];
    }
}

// Detect text character (PCDATA) that does not require processing
struct TextPureNoWsPred
{
    static ubyte test(ubyte ch)
    {
        return lookup_text_pure_no_ws[ch];
    }
}

// Detect text character (PCDATA) that does not require processing
struct TextPureWithWsPred
{
    static  ubyte test(ubyte ch)
    {
        return lookup_text_pure_with_ws[ch];
    }
}

// Detect attribute value character

struct AttributeValuePred(alias Quote)
{
    static ubyte test(ubyte ch)
    {
        if (Quote == '\'')
            return lookup_attribute_data_1[ch];
        else if (Quote == '"')
            return lookup_attribute_data_2[ch];
        else
            return 0;       // Should never be executed, to avoid warnings on Comeau
    }
}

// Detect attribute value character
struct AttributeValuePurePred(alias Quote)
{
    static ubyte test(ubyte ch)
    {
        if (Quote == '\'')
            return lookup_attribute_data_1_pure[ch];
        else if (Quote == ('"'))
            return lookup_attribute_data_2_pure[ch];
        else
            return 0;       // Should never be executed, to avoid warnings on Comeau
    }
}

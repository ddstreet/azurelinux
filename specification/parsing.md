
[Return to index](./index.md)

# Parsing the TOML file structure

## General

All TOML files must be loaded using standard TOML parsing.

The 'top level' TOML file is named 'azldev.toml' and all other files must be located in or below the directory of the top level TOML file.

All path values must be relative to the TOML file they are defined in, and no relative path may reference above the directory where the top level TOML file is located.

All objects must be able to retain the sort order of their keys, as well as being able to insert (or move) a key into a specific location in the object key sort order.

The dash ('-') and underscore ('_') characters should be considered equivalent when either appears in any key name.

## Parsing

The parser must start by loading the top level TOML file into a TOML 'table' (which may include sub-tables), which will be referred to as an 'object' (which may include child 'objects').

The object is then checked for special keys, as well as its sub-objects recursively (in depth-first order), by iterating through all the object's keys to find any that match and of the special keys as listed in the 'Special key handling' section below. Each special key is processed immediately when found.

## Special key handling

### includes

The 'includes' key's value must be an array of strings.

Each string must be a path, may be glob-expanded as defined by POSIX.2, 3.13 (https://man7.org/linux/man-pages/man7/glob.7.html), with the exception that a glob pattern which does not resolve to any file is ignored. Also note that the 'globstar' pattern (**) must not be supported.

Each path (and glob pattern) in the array must be processed in the order it appears in the array. For each path, glob expansion is attempted. If the result is an empty list (i.e. no glob matches), it is ignored. If the result is a single path, it is processed immediately, and it is an error if the path does not exist. If the result is multiple paths, they must first be sorted lexically and then processed in order.

After glob expansion, each path in the array must resolve to a TOML file, which must be processed as defined in the previous 'Parsing' section, resulting in a new object. This new object is then merged with the existing object, as defined in the 'Merging objects' section below.

Note that when the new object is merged into the existing object, because parsing is done in depth-first order, the new object will not contain an 'includes' key (since it will be removed as part of the depth-first parsing).

Once all 'includes' key values have been processed, the 'includes' key must be removed from the object.

## Merging objects

To merge a 'new' object into an 'existing' object, the value of each key (processed in order of the new object's keys) in the new object is merged into the corresponding key in the existing object.

If the existing object does not contain a key that exists in the new object, the key-value pair from the new object is simply copied into the existing object. The new key is appended to the existing object's list of keys, unless the new object is being added as a direct result of a 'special key', in which case the new key is inserted into the existing object's list of keys immediately before the 'special key' (e.g. if the new object was directly created from an 'includes' path, the new key is inserted immediately before the 'includes' key in the existing object).

When both objects contain a key, if the type of the value in both objects is not the same type, it should be considered an error. When both objects contain a key with the same type of value, the existing object's key ordering location is not changed, and the values are merged as described below.

Arrays (i.e. lists) are merged by appending the new value to the existing value.

Strings, integers, floats, booleans, and date-time values are all merged by replacing the existing value with the new value.

Tables (i.e. objects) are merged by the 'Merging objects' process just described.

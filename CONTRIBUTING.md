## Updating Build Rules

In order to build DocC as part of the Windows toolchain distribution uniformly,
a parallel CMake based build exists. Note that this is **not** supported for
development purposes (you cannot execute the test suite with this build).

CMake requires that the full file list is kept up-to-date. When adding or
removing files in a given module, the `CMakeLists.txt` list must be updated to
the file list.

You can use the following 1-line script to enumerate the files in the module:

```bash
python -c "print('\n'.join((f'{chr(34)}{path}{chr(34)}' if ' ' in path else path) for path in sorted(str(path) for path in __import__('pathlib').Path('.').rglob('*.swift'))))"
```

This should provide the listing of files in the module that can be used to
update the `CMakeLists.txt` associated with the target.

In the case that a new target is added to the project, the new directory would
need to add the new library or executable target (`add_library` and
`add_executable` respectively) and the new target subdirectory must be listed in
the `Sources/CMakeLists.txt` (via `add_subdirectory`).


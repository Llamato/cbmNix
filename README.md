# cbmNix
A nix library for building and testing commodore 8 bit line programs using nix.
an overview of all functions currently available can be found below.



# A collection of utility functions for packaging commodore business machines software software {#sec-functions-library-cbm}


## `cbmNix.cbm.buildClangPrg` {#function-library-cbmNix.cbm.buildClangPrg}

Build a c program for 6500 series of processors using llvm-mos

### Type:
`buildClangPrg = { targetSystem, clangFlags, ... } @ args: Derivation`

### Args:
- `name` (String): The name of the resulting derivation.
- `src` (Path): The path to the source files for the derivation.
- `targetSystem` (String): The shorthand name for the the computer model the program shall run on.
- `clangFlags` (List of String): additional compiler flags.

### Example:
```nix
  packages.default = buildClangPrg {
    name = "Firefighter";
    version = "1.0.0";
    src = ./.;
  };
```

## `cbmNix.cbm.buildAcmePrg` {#function-library-cbmNix.cbm.buildAcmePrg}

Build an assembly program for the 6500 series of processors using the ACME cross assembler

### Type:
`buildAcmePrg = { debug, ...} @ args: Derivation`

### Args:
- name (String): The name of the resulting derivation.
- src (Path): The path to the source files for the derivation.
- acmeFlags (List of String): additional compiler flags.
- debug (Bool): Should the derivation include debugging artifacts like labels?

### Example:
 ```nix
    packages.default = buildAcmePrg {
      name = "c64demo";
      version = "0.0.1";
      src = ./.;
    };
  ```

## `cbmNix.cbm.buildBasicPrgs` {#function-library-cbmNix.cbm.buildBasicPrgs}

Build a basic program for the 6500 series of processors using the petcat's basic tokenizer

### Type:
 `buildBasicPrg = { targetSystem, ... } @ args: Derivation`

### Args:
- name (String): The name of the resulting derivation.
- src (Path): The path to the source files for the derivation.
- targetSystem (String): The shorthand name for the the computer model the program shall run on.
- debug (Bool): Should the output derivation include build and debugging artifacts?

### Example:
```nix
  packages.default = buildBasicPrg {
    name = "c64tool"
    version = "0.0.1"
    src = ./.;
  };
```

## `cbmNix.cbm.buildBinaryPrgs` {#function-library-cbmNix.cbm.buildBinaryPrgs}

Build a cbm compatible prg files from a modern binary files

### Type:
`buildBinaryPrgs = { targetSystem, ... } @ args: Derivation`

### Args:
- name (String): The name of the derivation.
- src (Path): The path to the source files for the derivation.
- includedFiles (List of String): The file extensions to include.
- debug (Bool): Should the output derivation include build and debugging artifacts?

## `cbmNix.cbm.buildPetsciiTextFiles` {#function-library-cbmNix.cbm.buildPetsciiTextFiles}

Build a PETSCII text file asset using petcats

### Type:
  `buildPetsciiTextFile = { ... } @ args: Derivation`

### Args:
- name (String): The name of the resulting derivation.
- src (Path): The path to the source files for the derivation.
- cbmFileType (String): The cbm file type for the output text.
- petcatFlags (List of String): A list of flags passed directly to petcat.
- debug (Bool): Should the output derivation include build and debugging artifacts?

### Example:
 ```nix
  packages.default = buildPetsciiTextFile {
   name = "c64doc"
   version = "0.0.1"
   src = ./.
  }
 ```

## `cbmNix.cbm.buildD64` {#function-library-cbmNix.cbm.buildD64}

Build a d64 disk image from a list of paths

### Type:
 `buildPetsciiAsset = { name, paths, extraIncludes, ... } @ args: Derivation`

### Args:
- name (String): The name of the resulting derivation.
- paths (List of path): Paths of files to be included in the derivation
- debug (Bool): Should debug label output files be included in the derivation

### Example:
 ```nix
 packages.default = buildD64 {
   name = "Spacebirds64"
   version = "1.0.0";
   src = ./.;
 }
 ```

## `cbmNix.cbm.checkWithVice` {#function-library-cbmNix.cbm.checkWithVice}

Test a cbm program using the vice Emulator

### Type:
  checkWithVice = { name, emulator, configFile, monitorCommandsFile, keystrokesFile, diskFile, exitOn, exitAfter, warp, extraViceFlags, nativeCheckPhase, ...}@args : Derivation

 Args:
 - name (String): The name of the test being run.
 - emulator (String): The basename of the emulator executable to use.
 - configFile (Path): A path to the vice config to be used for the test.
 - monitorCommandsFile (Path): A path to a monitor commands script to be used for the test.
 - fileUnderTest (Path): A path to the program file or disk image containing the program file under test.
 - failAfter (Int): A timelimit in seconds of realtime.
 - warp (Bool): Use vice warp mode to speed up test?
 - extraViceFlags (List of String): Extra flags to be passed to the emulator executable.
 - nativeCheckPhase (String): A script containing shell commands to be run on the emulator host system after the emulator run succeeds.

Example:
  checks.default = checkWithVice {
    name = "myViceTest";
    emulator = "x128";
    fileUnderTest = ./prgdisk.d64;
    configFile = ./myViceTestConfig.ini;
    monitorCommandsFile = ./myViceTestMonitorCommands.ini;
    keystrokesFile = ./myViceTestKeystrokes.txt;
  }

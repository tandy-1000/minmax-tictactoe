# Package

version = "0.1.0"
author = "tandy1000"
description = "tictactoe"
license = "MIT"

# Deps
requires "nim >= 1.2.0"
requires "nico >= 0.2.5"
requires "oolib"

srcDir = "src"

import strformat

const releaseOpts = "-d:danger"
const debugOpts = "-d:debug"

task runr, "Runs tictactoe for current platform":
 exec &"nim c -r {releaseOpts} -o:tictactoe src/main.nim"

task rund, "Runs debug tictactoe for current platform":
 exec &"nim c -r {debugOpts} -o:tictactoe src/main.nim"

task release, "Builds tictactoe for current platform":
 exec &"nim c {releaseOpts} -o:tictactoe src/main.nim"

task webd, "Builds debug tictactoe for web":
 exec &"nim c {debugOpts} -d:emscripten -o:tictactoe.html src/main.nim"

task webr, "Builds release tictactoe for web":
 exec &"nim c {releaseOpts} -d:emscripten -o:tictactoe.html src/main.nim"

task debug, "Builds debug tictactoe for current platform":
 exec &"nim c {debugOpts} -o:tictactoe_debug src/main.nim"

task deps, "Downloads dependencies":
 exec "curl https://www.libsdl.org/release/SDL2-2.0.12-win32-x64.zip -o SDL2_x64.zip"
 exec "unzip SDL2_x64.zip"
 #exec "curl https://www.libsdl.org/release/SDL2-2.0.12-win32-x86.zip -o SDL2_x86.zip"

task androidr, "Release build for android":
  if defined(windows):
    exec &"nicoandroid.cmd"
  else:
    exec &"nicoandroid"
  exec &"nim c -c --nimcache:android/app/jni/src/armeabi {releaseOpts}  --cpu:arm   --os:android -d:androidNDK --noMain --genScript src/main.nim"
  exec &"nim c -c --nimcache:android/app/jni/src/arm64   {releaseOpts}  --cpu:arm64 --os:android -d:androidNDK --noMain --genScript src/main.nim"
  exec &"nim c -c --nimcache:android/app/jni/src/x86     {releaseOpts}  --cpu:i386  --os:android -d:androidNDK --noMain --genScript src/main.nim"
  exec &"nim c -c --nimcache:android/app/jni/src/x86_64  {releaseOpts}  --cpu:amd64 --os:android -d:androidNDK --noMain --genScript src/main.nim"
  withDir "android":
    if defined(windows):
      exec &"gradlew.bat assembleDebug"
    else:
      exec "./gradlew assembleDebug"

task test, "Run tests":
  exec &"nim r tests/test.nim"
@echo off
setlocal
set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
  echo Godot was not found at "%GODOT%".
  echo Open godot\scenes\deep_signal_visual_benchmark.tscn in Godot and press F6.
  pause
  exit /b 1
)
"%GODOT%" --path "%~dp0godot" --rendering-method forward_plus --rendering-driver d3d12 res://scenes/deep_signal_visual_benchmark.tscn

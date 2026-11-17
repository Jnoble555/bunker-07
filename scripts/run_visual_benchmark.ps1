param(
    [string]$GodotPath = 'C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe',
    [ValidateSet('Desktop','Compatibility')][string]$Renderer = 'Desktop',
    [switch]$Baseline
)
$projectRoot = Join-Path $PSScriptRoot '../godot'
$launchArgs = @('--path', $projectRoot)
if ($Renderer -eq 'Desktop') { $launchArgs += @('--rendering-method','forward_plus','--rendering-driver','d3d12') }
else { $launchArgs += @('--rendering-method','gl_compatibility') }
$launchArgs += 'res://scenes/deep_signal_visual_benchmark.tscn'
if ($Baseline) { $launchArgs += @('--','--benchmark-baseline') }
& $GodotPath @launchArgs
exit $LASTEXITCODE

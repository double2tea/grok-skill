$ErrorActionPreference = 'Stop'

param(
  [switch]$Global
)

function Resolve-GrokConfigPath {
  $custom = $env:GROK_CONFIG_PATH
  if ($custom -and $custom.Trim()) { return $custom.Trim() }
  if ($Global) {
    return (Join-Path $env:USERPROFILE '.codex\config\grok-search.json')
  }
  return (Join-Path $PSScriptRoot 'config.json')
}

$path = Resolve-GrokConfigPath
$dir = Split-Path -Parent $path
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$existing = $null
if (Test-Path $path) {
  try { $existing = Get-Content -Raw $path | ConvertFrom-Json } catch { $existing = $null }
}

function Read-Default([string]$prompt, [string]$defaultValue) {
  $suffix = ''
  if ($defaultValue) { $suffix = " [$defaultValue]" }
  $v = Read-Host "$prompt$suffix"
  if (-not $v) { return $defaultValue }
  return $v
}

$apiUrl = Read-Default 'Grok API URL (optional, full endpoint)' ($existing.api_url)

$baseUrl = Read-Default 'Grok base URL (fallback)' ($existing.base_url)
if (-not $baseUrl) { $baseUrl = 'http://localhost:8080' }

$apiKeyDefault = $existing.api_key
if (-not $apiKeyDefault) {
  if ($env:GROK_API_KEY) {
    $apiKeyDefault = $env:GROK_API_KEY
  } elseif ($env:GROK2API_API_KEY) {
    $apiKeyDefault = $env:GROK2API_API_KEY
  }
}
$apiKey = Read-Default 'Grok API key (optional if server auth disabled)' ($apiKeyDefault)

$depth = Read-Default 'Search depth (optional: fast/thinking/heavy)' ($existing.depth)

$depthModels = [ordered]@{
  fast = 'grok-4.1-fast'
  thinking = 'grok-4.1-thinking'
  heavy = 'grok-4-heavy'
}

if ($existing -and $existing.depth_models) {
  if ($existing.depth_models -is [System.Collections.IDictionary]) {
    foreach ($entry in $existing.depth_models.GetEnumerator()) {
      $k = [string]$entry.Key
      $v = [string]$entry.Value
      if ($k -and $v) { $depthModels[$k] = $v }
    }
  } else {
    foreach ($prop in $existing.depth_models.PSObject.Properties) {
      $k = [string]$prop.Name
      $v = [string]$prop.Value
      if ($k -and $v) { $depthModels[$k] = $v }
    }
  }
}

$model = Read-Default 'Model' ($existing.model)
if (-not $model) { $model = 'grok-4' }

$timeout = Read-Default 'Timeout seconds' ([string]($existing.timeout_seconds))
if (-not $timeout) { $timeout = '60' }

$config = [ordered]@{
  api_url = $apiUrl
  base_url = $baseUrl
  api_key = $apiKey
  depth = $depth
  depth_models = $depthModels
  model = $model
  timeout_seconds = [int]$timeout
  extra_body = @{}
  extra_headers = @{}
}

$config | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 $path
Write-Output "Wrote config: $path"

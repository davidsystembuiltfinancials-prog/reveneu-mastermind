Add-Type -AssemblyName System.Drawing

$roomDir = Join-Path $PSScriptRoot "..\src\assets\rooms"

$black = [System.Drawing.Color]::FromArgb(235, 2, 8, 9)
$void = [System.Drawing.Color]::FromArgb(245, 6, 21, 22)
$floor = [System.Drawing.Color]::FromArgb(235, 20, 45, 45)
$floorLine = [System.Drawing.Color]::FromArgb(190, 68, 126, 118)
$frameDark = [System.Drawing.Color]::FromArgb(245, 24, 38, 41)
$frameMid = [System.Drawing.Color]::FromArgb(245, 62, 91, 91)
$frameLight = [System.Drawing.Color]::FromArgb(235, 112, 255, 222)
$glow = [System.Drawing.Color]::FromArgb(115, 86, 255, 219)
$warning = [System.Drawing.Color]::FromArgb(220, 255, 204, 76)

function New-Brush([System.Drawing.Color]$Color) {
  return New-Object System.Drawing.SolidBrush($Color)
}

function New-Pen([System.Drawing.Color]$Color, [int]$Width = 1) {
  return New-Object System.Drawing.Pen($Color, $Width)
}

function Fill-Rect {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Color]$Color,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height
  )

  $brush = New-Brush $Color
  $Graphics.FillRectangle($brush, $X, $Y, $Width, $Height)
  $brush.Dispose()
}

function Stroke-Rect {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Color]$Color,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [int]$Stroke = 1
  )

  $pen = New-Pen $Color $Stroke
  $Graphics.DrawRectangle($pen, $X, $Y, $Width, $Height)
  $pen.Dispose()
}

function Draw-Hatch {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [bool]$Vertical
  )

  $pen = New-Pen $floorLine 1
  if ($Vertical) {
    for ($yy = $Y + 8; $yy -lt $Y + $Height; $yy += 10) {
      $Graphics.DrawLine($pen, $X + 6, $yy, $X + $Width - 6, $yy)
    }
  } else {
    for ($xx = $X + 8; $xx -lt $X + $Width; $xx += 10) {
      $Graphics.DrawLine($pen, $xx, $Y + 6, $xx, $Y + $Height - 6)
    }
  }
  $pen.Dispose()
}

function Draw-HorizontalDoorway {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$ImageWidth,
    [int]$ImageHeight,
    [bool]$Bottom
  )

  $openingW = 56
  $wellW = 78
  $wellH = 38
  $openingH = 27
  $x = [int](($ImageWidth - $wellW) / 2)
  $openingX = [int](($ImageWidth - $openingW) / 2)
  $y = if ($Bottom) { $ImageHeight - $wellH } else { 0 }
  $openingY = if ($Bottom) { $ImageHeight - $openingH } else { 0 }
  $thresholdY = if ($Bottom) { $ImageHeight - 18 } else { 10 }

  Fill-Rect $Graphics $black ($x - 5) $y ($wellW + 10) $wellH
  Fill-Rect $Graphics $frameDark $x $y $wellW $wellH
  Fill-Rect $Graphics $void $openingX $openingY $openingW $openingH
  Fill-Rect $Graphics $floor ($openingX + 7) ($openingY + 6) ($openingW - 14) ($openingH - 9)
  Draw-Hatch $Graphics ($openingX + 7) ($openingY + 6) ($openingW - 14) ($openingH - 9) $false

  Fill-Rect $Graphics $frameMid ($openingX - 8) $openingY 7 $openingH
  Fill-Rect $Graphics $frameMid ($openingX + $openingW + 1) $openingY 7 $openingH
  Fill-Rect $Graphics $frameLight ($openingX - 6) $thresholdY ($openingW + 12) 3
  Fill-Rect $Graphics $glow ($openingX - 10) ($thresholdY - 3) ($openingW + 20) 9

  Stroke-Rect $Graphics $frameLight ($openingX - 8) $openingY ($openingW + 16) $openingH 1
  Stroke-Rect $Graphics $frameDark ($openingX - 13) ($openingY + 3) ($openingW + 26) ($openingH - 6) 2

  $stripeY = if ($Bottom) { $ImageHeight - 9 } else { 4 }
  for ($sx = $openingX + 4; $sx -lt $openingX + $openingW - 6; $sx += 12) {
    Fill-Rect $Graphics $warning $sx $stripeY 6 2
  }
}

function Draw-VerticalDoorway {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$ImageWidth,
    [int]$ImageHeight,
    [bool]$Right
  )

  $wellW = 39
  $wellH = 78
  $openingW = 27
  $openingH = 56
  $x = if ($Right) { $ImageWidth - $wellW } else { 0 }
  $openingX = if ($Right) { $ImageWidth - $openingW } else { 0 }
  $y = [int](($ImageHeight - $wellH) / 2)
  $openingY = [int](($ImageHeight - $openingH) / 2)
  $thresholdX = if ($Right) { $ImageWidth - 18 } else { 10 }

  Fill-Rect $Graphics $black $x ($y - 5) $wellW ($wellH + 10)
  Fill-Rect $Graphics $frameDark $x $y $wellW $wellH
  Fill-Rect $Graphics $void $openingX $openingY $openingW $openingH
  Fill-Rect $Graphics $floor ($openingX + 6) ($openingY + 7) ($openingW - 9) ($openingH - 14)
  Draw-Hatch $Graphics ($openingX + 6) ($openingY + 7) ($openingW - 9) ($openingH - 14) $true

  Fill-Rect $Graphics $frameMid $openingX ($openingY - 8) $openingW 7
  Fill-Rect $Graphics $frameMid $openingX ($openingY + $openingH + 1) $openingW 7
  Fill-Rect $Graphics $frameLight $thresholdX ($openingY - 6) 3 ($openingH + 12)
  Fill-Rect $Graphics $glow ($thresholdX - 3) ($openingY - 10) 9 ($openingH + 20)

  Stroke-Rect $Graphics $frameLight $openingX ($openingY - 8) $openingW ($openingH + 16) 1
  Stroke-Rect $Graphics $frameDark ($openingX + 3) ($openingY - 13) ($openingW - 6) ($openingH + 26) 2

  $stripeX = if ($Right) { $ImageWidth - 9 } else { 4 }
  for ($sy = $openingY + 4; $sy -lt $openingY + $openingH - 6; $sy += 12) {
    Fill-Rect $Graphics $warning $stripeX $sy 2 6
  }
}

Get-ChildItem $roomDir -Filter "*.png" | Sort-Object Name | ForEach-Object {
  $source = [System.Drawing.Image]::FromFile($_.FullName)
  $bitmap = New-Object System.Drawing.Bitmap($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
  $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

  $graphics.DrawImageUnscaled($source, 0, 0)

  Draw-HorizontalDoorway -Graphics $graphics -ImageWidth $source.Width -ImageHeight $source.Height -Bottom $false
  Draw-HorizontalDoorway -Graphics $graphics -ImageWidth $source.Width -ImageHeight $source.Height -Bottom $true
  Draw-VerticalDoorway -Graphics $graphics -ImageWidth $source.Width -ImageHeight $source.Height -Right $false
  Draw-VerticalDoorway -Graphics $graphics -ImageWidth $source.Width -ImageHeight $source.Height -Right $true

  $graphics.Dispose()
  $source.Dispose()

  $bitmap.Save($_.FullName, [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Dispose()

  Write-Output "Baked four architectural doorways into $($_.Name)"
}

Add-Type -AssemblyName System.Drawing

$outPath = Join-Path $PSScriptRoot "..\src\assets\station-exterior.png"
$sourcePath = Join-Path $PSScriptRoot "..\src\assets\rooms\comms.png"
$width = 1450
$height = 1000
$rng = New-Object System.Random 1979

function Brush([System.Drawing.Color]$Color) {
  New-Object System.Drawing.SolidBrush($Color)
}

function Pen([System.Drawing.Color]$Color, [int]$Width = 1) {
  New-Object System.Drawing.Pen($Color, $Width)
}

function FillRect($g, [System.Drawing.Color]$color, [int]$x, [int]$y, [int]$w, [int]$h) {
  $b = Brush $color
  $g.FillRectangle($b, $x, $y, $w, $h)
  $b.Dispose()
}

function StrokeRect($g, [System.Drawing.Color]$color, [int]$x, [int]$y, [int]$w, [int]$h, [int]$stroke = 1) {
  $p = Pen $color $stroke
  $g.DrawRectangle($p, $x, $y, $w, $h)
  $p.Dispose()
}

function DrawLine($g, [System.Drawing.Color]$color, [int]$x1, [int]$y1, [int]$x2, [int]$y2, [int]$stroke = 1) {
  $p = Pen $color $stroke
  $g.DrawLine($p, $x1, $y1, $x2, $y2)
  $p.Dispose()
}

function BlitSource($g, $source, [int]$sx, [int]$sy, [int]$sw, [int]$sh, [int]$dx, [int]$dy, [int]$dw, [int]$dh) {
  $dest = New-Object System.Drawing.Rectangle $dx, $dy, $dw, $dh
  $src = New-Object System.Drawing.Rectangle $sx, $sy, $sw, $sh
  $g.DrawImage($source, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
}

function DrawPanelBevel($g, [int]$x, [int]$y, [int]$w, [int]$h) {
  StrokeRect $g ([System.Drawing.Color]::FromArgb(180, 3, 6, 8)) $x $y $w $h 2
  DrawLine $g ([System.Drawing.Color]::FromArgb(120, 91, 108, 116)) ($x + 2) ($y + 2) ($x + $w - 3) ($y + 2) 1
  DrawLine $g ([System.Drawing.Color]::FromArgb(90, 77, 92, 101)) ($x + 2) ($y + 2) ($x + 2) ($y + $h - 3) 1
  DrawLine $g ([System.Drawing.Color]::FromArgb(160, 0, 1, 2)) ($x + 2) ($y + $h - 3) ($x + $w - 3) ($y + $h - 3) 1
  DrawLine $g ([System.Drawing.Color]::FromArgb(160, 0, 1, 2)) ($x + $w - 3) ($y + 2) ($x + $w - 3) ($y + $h - 3) 1
}

function DrawConsoleBits($g, [int]$x, [int]$y, [int]$w, [int]$h, $rng) {
  $rackColor = [System.Drawing.Color]::FromArgb(210, 5, 10, 12)
  $rim = [System.Drawing.Color]::FromArgb(160, 58, 72, 82)
  $cyan = [System.Drawing.Color]::FromArgb(225, 0, 220, 232)
  $cyanDim = [System.Drawing.Color]::FromArgb(145, 0, 132, 145)
  $amber = [System.Drawing.Color]::FromArgb(220, 255, 118, 21)

  $count = $rng.Next(1, 4)
  for ($i = 0; $i -lt $count; $i++) {
    $rw = $rng.Next(18, [Math]::Max(24, [Math]::Min(58, $w - 8)))
    $rh = $rng.Next(14, [Math]::Max(18, [Math]::Min(50, $h - 8)))
    $rx = $x + $rng.Next(4, [Math]::Max(5, $w - $rw - 4))
    $ry = $y + $rng.Next(4, [Math]::Max(5, $h - $rh - 4))
    FillRect $g $rackColor $rx $ry $rw $rh
    StrokeRect $g $rim $rx $ry $rw $rh 1

    for ($p = 0; $p -lt $rng.Next(4, 13); $p++) {
      $px = $rx + $rng.Next(3, [Math]::Max(4, $rw - 4))
      $py = $ry + $rng.Next(3, [Math]::Max(4, $rh - 4))
      $light = if ($rng.NextDouble() -lt 0.82) { if ($rng.NextDouble() -lt 0.65) { $cyan } else { $cyanDim } } else { $amber }
      FillRect $g $light $px $py ($rng.Next(1, 4)) ($rng.Next(1, 4))
    }
  }
}

$source = [System.Drawing.Image]::FromFile($sourcePath)
$bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

FillRect $g ([System.Drawing.Color]::FromArgb(255, 0, 2, 3)) 0 0 $width $height

$sourceCrops = @(
  @{ X = 88; Y = 8; W = 54; H = 70 },
  @{ X = 166; Y = 8; W = 56; H = 70 },
  @{ X = 92; Y = 112; W = 124; H = 112 },
  @{ X = 102; Y = 226; W = 108; H = 110 },
  @{ X = 16; Y = 236; W = 74; H = 118 },
  @{ X = 220; Y = 236; W = 74; H = 118 },
  @{ X = 24; Y = 354; W = 88; H = 58 },
  @{ X = 198; Y = 354; W = 88; H = 58 },
  @{ X = 129; Y = 20; W = 56; H = 54 },
  @{ X = 132; Y = 342; W = 48; H = 70 }
)

for ($y = 0; $y -lt $height; $y += 42) {
  for ($x = 0; $x -lt $width; $x += 58) {
    $crop = $sourceCrops[$rng.Next(0, $sourceCrops.Count)]
    $dw = 58 + $rng.Next(-8, 14)
    $dh = 42 + $rng.Next(-6, 12)
    BlitSource $g $source $crop.X $crop.Y $crop.W $crop.H $x $y $dw $dh
    FillRect $g ([System.Drawing.Color]::FromArgb(150, 0, 0, 0)) $x $y $dw $dh
    DrawPanelBevel $g $x $y $dw $dh
  }
}

$roomCols = @(94, 385, 675, 965)
$roomRows = @(70, 365, 660)
foreach ($rx in $roomCols) {
  foreach ($ry in $roomRows) {
    FillRect $g ([System.Drawing.Color]::FromArgb(245, 0, 1, 2)) ($rx - 30) ($ry - 30) 274 282
    StrokeRect $g ([System.Drawing.Color]::FromArgb(235, 18, 25, 31)) ($rx - 24) ($ry - 24) 262 270 5
    StrokeRect $g ([System.Drawing.Color]::FromArgb(185, 73, 89, 104)) ($rx - 14) ($ry - 14) 242 250 1
    StrokeRect $g ([System.Drawing.Color]::FromArgb(150, 0, 185, 210)) ($rx - 4) ($ry - 4) 222 230 1
  }
}

$corridors = @(
  @{ X = 64; Y = 323; W = 1322; H = 55 },
  @{ X = 64; Y = 618; W = 1322; H = 55 },
  @{ X = 64; Y = 474; W = 1322; H = 46 },
  @{ X = 394; Y = 58; W = 58; H = 876 },
  @{ X = 996; Y = 58; W = 58; H = 876 }
)

foreach ($c in $corridors) {
  $floorCrop = @{ X = 106; Y = 112; W = 100; H = 140 }
  BlitSource $g $source $floorCrop.X $floorCrop.Y $floorCrop.W $floorCrop.H $c.X $c.Y $c.W $c.H
  FillRect $g ([System.Drawing.Color]::FromArgb(138, 0, 2, 3)) $c.X $c.Y $c.W $c.H
  StrokeRect $g ([System.Drawing.Color]::FromArgb(230, 6, 13, 16)) $c.X $c.Y $c.W $c.H 4
  StrokeRect $g ([System.Drawing.Color]::FromArgb(190, 70, 91, 104)) ($c.X + 6) ($c.Y + 6) ($c.W - 12) ($c.H - 12) 1

  if ($c.W -gt $c.H) {
    for ($x = $c.X + 18; $x -lt $c.X + $c.W - 18; $x += 38) {
      DrawLine $g ([System.Drawing.Color]::FromArgb(95, 71, 90, 100)) $x ($c.Y + 8) $x ($c.Y + $c.H - 9) 1
    }
    for ($x = $c.X + 66; $x -lt $c.X + $c.W - 70; $x += 132) {
      FillRect $g ([System.Drawing.Color]::FromArgb(185, 0, 198, 214)) $x ($c.Y + 12) 38 3
      FillRect $g ([System.Drawing.Color]::FromArgb(100, 0, 104, 122)) ($x + 6) ($c.Y + $c.H - 16) 25 2
    }
  } else {
    for ($y = $c.Y + 18; $y -lt $c.Y + $c.H - 18; $y += 38) {
      DrawLine $g ([System.Drawing.Color]::FromArgb(95, 71, 90, 100)) ($c.X + 8) $y ($c.X + $c.W - 9) $y 1
    }
    for ($y = $c.Y + 66; $y -lt $c.Y + $c.H - 70; $y += 132) {
      FillRect $g ([System.Drawing.Color]::FromArgb(185, 0, 198, 214)) ($c.X + 12) $y 3 38
      FillRect $g ([System.Drawing.Color]::FromArgb(100, 0, 104, 122)) ($c.X + $c.W - 16) ($y + 6) 2 25
    }
  }
}

for ($i = 0; $i -lt 270; $i++) {
  $x = $rng.Next(18, $width - 80)
  $y = $rng.Next(18, $height - 80)
  $w = $rng.Next(24, 78)
  $h = $rng.Next(18, 66)
  $crop = $sourceCrops[$rng.Next(0, $sourceCrops.Count)]
  BlitSource $g $source $crop.X $crop.Y $crop.W $crop.H $x $y $w $h
  FillRect $g ([System.Drawing.Color]::FromArgb($rng.Next(145, 195), 0, 0, 0)) $x $y $w $h
  DrawPanelBevel $g $x $y $w $h
  if ($rng.NextDouble() -lt 0.34) {
    DrawConsoleBits $g $x $y $w $h $rng
  }
}

for ($i = 0; $i -lt 145; $i++) {
  $x = $rng.Next(34, $width - 140)
  $y = $rng.Next(34, $height - 120)
  $len = $rng.Next(34, 154)
  if ($rng.NextDouble() -lt 0.52) {
    DrawLine $g ([System.Drawing.Color]::FromArgb(125, 56, 83, 94)) $x $y ($x + $len) $y 2
    DrawLine $g ([System.Drawing.Color]::FromArgb(65, 0, 203, 224)) ($x + 10) ($y + 2) ($x + [Math]::Min($len - 10, 48)) ($y + 2) 1
  } else {
    DrawLine $g ([System.Drawing.Color]::FromArgb(120, 56, 83, 94)) $x $y $x ($y + $len) 2
    DrawLine $g ([System.Drawing.Color]::FromArgb(65, 0, 203, 224)) ($x + 2) ($y + 10) ($x + 2) ($y + [Math]::Min($len - 10, 48)) 1
  }
}

for ($i = 0; $i -lt 520; $i++) {
  $x = $rng.Next(10, $width - 10)
  $y = $rng.Next(10, $height - 10)
  $color = if ($rng.NextDouble() -lt 0.8) {
    [System.Drawing.Color]::FromArgb($rng.Next(130, 230), 0, $rng.Next(140, 240), $rng.Next(160, 255))
  } else {
    [System.Drawing.Color]::FromArgb($rng.Next(150, 230), 255, $rng.Next(92, 145), $rng.Next(8, 32))
  }
  FillRect $g $color $x $y ($rng.Next(1, 3)) ($rng.Next(1, 4))
}

$edge = Brush ([System.Drawing.Color]::FromArgb(160, 0, 0, 0))
$g.FillRectangle($edge, 0, 0, $width, 90)
$g.FillRectangle($edge, 0, $height - 90, $width, 90)
$g.FillRectangle($edge, 0, 0, 90, $height)
$g.FillRectangle($edge, $width - 90, 0, 90, $height)
$edge.Dispose()

$source.Dispose()
$g.Dispose()
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Output "Generated $outPath from $sourcePath"

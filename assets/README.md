# Application Icons

This directory contains the application icons for PureSimpleHTTPServer.

## Files

- `icon.svg` - Vector source file (512x512 viewBox)
- `icon.png` - 512x512 PNG source file
- `icon.ico` - Windows icon file with multiple sizes

## Generating Icons from SVG

The SVG file (`icon.svg`) is the master source. To generate the other formats:

### Option 1: Online Tools

1. **SVG to PNG**: Visit https://cloudconvert.com/svg-to-png
   - Upload `icon.svg`
   - Set size to 512x512
   - Download as `icon.png`

2. **PNG to ICO**: Visit https://convertio.co/png-ico/
   - Upload `icon.png`
   - Select Windows ICO format
   - Enable multiple sizes: 256x256, 128x128, 64x64, 48x48, 32x32, 16x16
   - Download as `icon.ico`

### Option 2: Command Line Tools

If you have ImageMagick installed:

```bash
# Generate PNG from SVG
magick convert -background none -size 512x512 icon.svg icon.png

# Generate ICO from PNG (multiple sizes)
magick convert icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico
```

### Option 3: GUI Tools

- **Windows**: Use Paint.NET or GIMP with ICO plugin
- **macOS**: Use Preview.app to export SVG as PNG, then online converter for ICO
- **Linux**: Use GIMP or Inkscape

## Current Status

- [x] `icon.svg` - Vector source created
- [ ] `icon.png` - Needs to be generated from SVG
- [ ] `icon.ico` - Needs to be generated from PNG

## Using the Icon

Once `icon.ico` is created, it will be used by:
- PureBasic compiler (via `-n` flag)
- NSIS installer (for executable icon)
- Windows Explorer (for application display)

The icon should be tested at all sizes to ensure clarity.

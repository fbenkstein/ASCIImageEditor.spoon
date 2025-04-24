# ASCIImage Editor Spoon

A Hammerspoon spoon that provides an editor for the ASCIImage format, which
allows creating images using ASCII art using the
[`hs.image.imageFromASCII`](https://www.hammerspoon.org/docs/hs.image.html#imageFromASCII)
function which is based on the [ASCIImage](https://github.com/cparnot/ASCIImage) library.

## Screenshot

![](screenshot.png)

## Installation

1. Clone this repository to your Hammerspoon spoons directory:
```bash
cd ~/.hammerspoon/Spoons
git clone https://github.com/fbenkstein/ASCIImageEditor.spoon.git
```

2. Load the spoon in your Hammerspoon configuration:
```lua
hs.loadSpoon("ASCIImageEditor")
```

## Usage

```lua
-- Show the ASCIImage editor
spoon.ASCIImageEditor:show()
```

## License

MIT License 

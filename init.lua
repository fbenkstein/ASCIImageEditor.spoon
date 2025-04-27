--- === ASCIImageEditor ===
---
--- An interactive editor for the ASCIImage format accepted by
--- hs.image.imageFromASCII.
---
--- Download: [https://github.com/fbenkstein/ASCIImageEditor.spoon/archive/refs/heads/main.zip](https://github.com/fbenkstein/ASCIImageEditor.spoon/archive/refs/heads/main.zip)
local obj = {}
obj.__index = obj

-- Import required modules
local webview = require("hs.webview")
local usercontent = require("hs.webview.usercontent")
local menubar = require("hs.menubar")
local image = require("hs.image")

-- Metadata
obj.name = "ASCIImageEditor"
obj.version = "1.0"
obj.author = "Frank Benkstein <frank@benkstein.net>"
obj.homepage = "https://github.com/fbenkstein/ASCIImageEditor.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.description = "A Hammerspoon spoon that provides an editor for the ASCIImage format"

-- Default configuration
local defaultConfig = {
    windowSize = {
        width = 800,
        height = 600,
    },
}

--- ASCIImageEditor:init([config])
--- Method
--- Initializes the ASCIImage editor with optional configuration
---
--- Parameters:
---  * config - An optional table containing configuration options
---
--- Returns:
---  * The ASCIImageEditor object
function obj:init(config)
    self.config = config or defaultConfig
    self.editorWindow = nil
    self.userContent = usercontent.new("asciimage")
    self.userContent:setCallback(function(message)
        if message.body.type == "renderImages" then
            self:renderImages(message.body)
        elseif message.body.type == "showNotification" then
            self:showNotification(message.body)
        else
            print("Unknown message type: ", hs.inspect.inspect(message))
        end
    end)

    self.tmpdir = hs.fs.temporaryDirectory() .. "/ASCIImageEditor"

    local ok, err = hs.fs.mkdir(self.tmpdir)
    if not ok and err ~= "File exists" then
        print("Failed to create temporary directory: " .. err)
        return nil
    end

    return self
end

--- ASCIImageEditor:start()
--- Method
--- Starts the ASCIImage editor background activities
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ASCIImageEditor object
function obj:start()
    return self
end

--- ASCIImageEditor:stop()
--- Method
--- Stops the ASCIImage editor background activities
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ASCIImageEditor object
function obj:stop()
    return self
end

--- ASCIImageEditor:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for the ASCIImage editor
---
--- Parameters:
---  * mapping - A table containing hotkey mappings
---
--- Returns:
---  * The ASCIImageEditor object
function obj:bindHotkeys(mapping)
    local spec = {
        show = hs.fnutils.partial(self.show, self),
        hide = hs.fnutils.partial(self.hide, self),
    }
    hs.spoons.bindHotkeysToSpec(spec, mapping)
    return self
end

--- ASCIImageEditor:show()
--- Method
--- Shows the ASCIImage editor window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ASCIImageEditor object
function obj:show()
    if not self.editorWindow then
        self:createEditor()
    end

    -- TODO: is this the right order of operations?
    hs.focus()
    self.editorWindow:show()
    self.editorWindow:bringToFront()
    self.editorWindow:hswindow():focus()
    self.editorWindow:level(hs.drawing.windowLevels.normal)

    return self
end

--- ASCIImageEditor:hide()
--- Method
--- Hides the ASCIImage editor window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ASCIImageEditor object
function obj:hide()
    if self.editorWindow then
        self.editorWindow:hide()
    end

    return self
end

--- ASCIImageEditor:createResources()
--- Method
--- Creates the necessary resources for the ASCIImage editor. This is meant to
--- be called during development only when changing the images.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ASCIImageEditor object
function obj:createResources()
    local resourcesPath = hs.spoons.resourcePath("resources")
    local images = dofile(hs.spoons.resourcePath("resources/images.lua"))

    print("Creating resources for " .. #images .. " images")

    for name, data in pairs(images) do
        local path = string.format("%s/images/%s.png", resourcesPath, name)
        print("Creating resource: " .. path)

        local img = image.imageFromASCII(data.content, data.context)
        local size = img and img:size()

        if img and size and size.w ~= 0 and size.h ~= 0 then
            if data.size and data.size.w ~= size.w and data.size.h ~= size.h then
                img = img:setSize(data.size, false)
            end

            img:saveToFile(path)
        else
            print("Failed to create image " .. name)
            print("Content:\n" .. data.content)
            print("Context:\n" .. hs.inspect.inspect(data.context))
        end
    end
end

-- Private methods

--- ASCIImageEditor:createEditor()
--- Method
--- Create the editor window.
---
--- Returns:
---  * Nothing
function obj:createEditor()
    -- Create the editor window
    local windowSize = self.config.windowSize or {}
    local width = windowSize.width or 800
    local height = windowSize.height or 600

    self.editorWindow = hs.webview
        .new({
            x = 100,
            y = 100,
            w = width,
            h = height,
        }, {
            javaScriptEnabled = true,
            javaScriptCanOpenWindowsAutomatically = true,
            developerExtrasEnabled = true,
        }, self.userContent)
        :windowStyle({
            "closable",
            "miniaturizable",
            "nonactivating",
            "resizable",
            "texturedBackground",
            "titled",
        })
        :windowTitle("ASCIImage Editor")
        :allowGestures(true)
        :allowNewWindows(true)
        :allowTextEntry(true)
        :transparent(false)
        :deleteOnClose(true)
        :windowCallback(function(action, webview)
            if action == "closing" then
                self.editorWindow = nil
            end
        end)

    -- Load the editor HTML
    local htmlPath = hs.spoons.resourcePath("resources/editor.html")
    self.editorWindow:url("file://" .. htmlPath)
end

--- ASCIImageEditor.parseContext(contextData)
--- Function
--- Parse the context data into a table. The context data is expected contain be
--- a Lua table literal.
---
--- Note: it is not safe to call this function with untrusted data.
---
--- Parameters:
---  * contextData - The context data to parse
---
--- Returns:
---  * The parsed context data or nil and an error message if the context data is invalid
local function parseContext(contextData)
    if not contextData then
        return nil
    end

    if type(contextData) ~= "string" then
        return nil, "Invalid context data type: expected string, got " .. type(contextData)
    end

    -- Empty string is valid
    if #contextData == 0 then
        return nil
    end

    -- Load the context data as a Lua function.
    local contextFunction, error = load("return " .. contextData, "context", "t", {})

    if not contextFunction then
        return nil, error
    end

    -- Call the function to get the context table.
    local ok, contextOrError = pcall(contextFunction)

    if not ok then
        return nil, "Error in context:" .. tostring(contextOrError)
    end

    local contextType = type(contextOrError)

    if contextType ~= "table" then
        return nil, "Invalid context: expected table, got " .. contextType
    end

    return contextOrError
end

--- ASCIImageEditor:makeCallback(callbackName)
--- Method
--- Make a callback function for the editor window.
---
--- Parameters:
---  * callbackName - The name of the callback function
---
--- Returns:
---  * Nothing
function obj:makeCallback(callbackName)
    if type(callbackName) ~= "string" then
        hs.printf("Invalid callback name: %s", callbackName)
        return
    end

    return function(result)
        local ok, resultString = pcall(hs.json.encode, result)

        if not ok then
            hs.printf("Error encoding result for callback %s: %s", callbackName, resultString)
            return
        end

        self.editorWindow:evaluateJavaScript(
            string.format(
                [[
            %s(%s);
        ]],
                callbackName,
                resultString
            ),
            function(result, error)
                if error and error.code ~= 0 then
                    hs.printf("Error from callback %s: %s", callbackName, hs.inspect.inspect(error))
                end
            end
        )
    end
end

--- ASCIImageEditor:renderImages(request)
--- Method
--- Render the images from the ASCIImage content.
---
--- Parameters:
---  * request - The request object
---
--- Returns:
---  * Nothing
function obj:renderImages(request)
    local content = request.content
    local contextData = request.context
    local callback, error = self:makeCallback(request.callback)

    if not callback then
        hs.printf("Error creating callback for %s: %s", request.callback, error)
        return
    end

    if not content or #content == 0 then
        callback { images = {} }
        return
    end

    local context, error = parseContext(contextData)

    if error then
        callback { error = "Invalid context: " .. error }
        return
    end

    local contextJson = hs.json.encode(context or {})
    local imageHash = hs.hash.new("SHA256"):append(content):append(contextJson):finish():value()

    -- Create the initial image.
    local img = image.imageFromASCII(content, context)

    local size = img and img:size()
    if not size or size.w == 0 or size.h == 0 then
        -- Show error message if image creation failed
        callback { error = "Invalid ASCIImage format" }
        return
    end

    -- Create a list of images with different sizes, save them to files and
    -- send the sizes and paths to the callback.
    local imageRefs = {
        { size = size },
        { size = { w = 48, h = 48 } },
        { size = { w = 96, h = 96 } },
        { size = { w = 128, h = 128 } },
        { size = { w = 192, h = 192 } },
        { size = { w = 256, h = 256 } },
    }

    for _, imageRef in ipairs(imageRefs) do
        local scaledImg

        -- Only scale if the size is different.
        if imageRef.size.w == size.w and imageRef.size.h == size.h then
            scaledImg = img
        else
            scaledImg = img:setSize(imageRef.size, false)
        end

        imageRef.path = string.format("%s/%s_%dx%d.png", self.tmpdir, imageHash, imageRef.size.w, imageRef.size.h)

        local scaledSize = scaledImg:size()
        imageRef.size = { w = math.floor(scaledSize.w), h = math.floor(scaledSize.h) }

        scaledImg:saveToFile(imageRef.path)
    end

    if request.enableMenubarIcon then
        if not self.menubarIcon then
            self.menubarIcon = menubar.new(true, "ASCIImageEditor")
        end

        self.menubarIcon:setIcon(img)
    elseif self.menubarIcon then
        self.menubarIcon:delete()
        self.menubarIcon = nil
    end

    callback { images = imageRefs }
end

--- ASCIImageEditor:showNotification(request)
--- Method
--- Show a notification with the current image.
---
--- Parameters:
---  * request - The request object
--- Returns:
---  * Nothing
function obj:showNotification(request)
    local content = request.content
    local contextData = request.context
    local notificationData = {
        autoWithdraw = true,
        withdrawAfter = 5,
    }

    local context, error = parseContext(contextData)
    local img = context and image.imageFromASCII(content, context)
    local size = img and img:size()
    local imageValid = img and size and size.w ~= 0 and size.h ~= 0

    if imageValid then
        notificationData.title = "ASCIImage Preview"
        notificationData.subTitle = "Current Image"
        notificationData.contentImage = img
    elseif error then
        notificationData.title = "ASCIImage Error"
        notificationData.subTitle = "Invalid context"
        notificationData.informativeText = error
    else
        notificationData.title = "ASCIImage Error"
        notificationData.subTitle = "Failed to render image"
        notificationData.informativeText = "The image could not be rendered. Please check your ASCIImage format."
    end

    local notification = hs.notify.new(notificationData)

    notification:send()
    return self
end

return obj

local images = {}
local function image(data)
    images[assert(data.name)] = {
        name = assert(data.name),
        content = assert(data.content):gsub(" +", ""):gsub("\n$", ""),
        context = data.context,
        size = data.size,
    }
end

image {
    name = "insert-column",
    content = [[
...............
....1...4......
...............
...............
...............
....6...9......
...........b...
..........a.a..
...........b...
....7...8......
...............
...............
...............
....2...3......
...............
    ]],
    context = {
        { fillColor = { alpha = 0 }, strokeColor = { hex = '#000' } },
    },
    size = { w = 48, h = 48 },
}

image {
    name = "delete-column",
    content = [[
...............
....1...4......
...............
...............
...............
....6...9......
...............
..........a..a.
...............
....7...8......
...............
...............
...............
....2...3......
...............
    ]],
    context = {
        { fillColor = { alpha = 0 }, strokeColor = { hex = '#000' } },
    },
    size = { w = 48, h = 48 },
}

image {
    name = "add-row",
    content = [[
...............
...............
...............
.1...6...7...2.
...............
...............
...............
.4...9...8...3.
...............
.......a.......
......b.b......
.......a.......
...............
...............
...............
    ]],
    context = {
        { fillColor = { alpha = 0 }, strokeColor = { hex = '#000' } },
    },
    size = { w = 48, h = 48 },
}

image {
    name = "delete-row",
    content = [[
...............
...............
...............
.1...6...7...2.
...............
...............
...............
.4...9...8...3.
...............
...............
......b.b......
...............
...............
...............
...............
    ]],
    context = {
        { fillColor = { alpha = 0 }, strokeColor = { hex = '#000' } },
    },
    size = { w = 48, h = 48 },
}

return images
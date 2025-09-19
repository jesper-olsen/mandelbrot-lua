#!/usr/bin/env lua

-- Default values
local config = {
    width = 100,
    height = 75,
    png = 0,
    ll_x = -1.2,
    ll_y = 0.20,
    ur_x = -1.0,
    ur_y = 0.35,
    max_iter = 255
}

-- Parse command-line arguments like var=value
for _, arg in ipairs(arg) do
    local var, val = string.match(arg, "([^=]+)=(.+)")
    if var and config[var] then
        -- Convert value to a number if possible, otherwise keep as is
        config[var] = tonumber(val) or val
    end
end

--- Maps an iteration count to an ASCII character.
-- @param value The iteration value (0 to max_iter).
-- @return A single character string.
local function cnt2char(value)
    local symbols = "MW2a_. "
    local ns = #symbols
    -- Map the value [0, max_iter] to an index [1, ns]
    local idx = math.floor(value / config.max_iter * (ns - 1)) + 1
    return string.sub(symbols, idx, idx)
end

--- Calculates the escape time for a point in the complex plane.
-- @param x The real part (cr).
-- @param y The imaginary part (ci).
-- @param max_iter The maximum number of iterations.
-- @return An integer representing how close the point is to the set.
local function escape_time(x, y, max_iter)
    local zr, zi = 0.0, 0.0
    local cr, ci = x, y
    local iter = 0

    while iter < max_iter do
        local zr2 = zr * zr
        local zi2 = zi * zi
        if zr2 + zi2 > 4.0 then
            break
        end
        local tmp = zr2 - zi2 + cr
        zi = 2.0 * zr * zi + ci
        zr = tmp
        iter = iter + 1
    end

    -- Return value is inverted to map points in the set to low numbers
    -- and points that escape quickly to high numbers, matching the TCL script.
    return max_iter - iter
end

--- Renders the Mandelbrot set as ASCII art to the console.
-- @param p A table with configuration parameters.
local function ascii_output(p)
    local fwidth = p.ur_x - p.ll_x
    local fheight = p.ur_y - p.ll_y

    for y = 0, p.height - 1 do
        for x = 0, p.width - 1 do
            local real = p.ll_x + x * fwidth / p.width
            local imag = p.ur_y - y * fheight / p.height
            local iter = escape_time(real, imag, p.max_iter)
            io.write(cnt2char(iter))
        end
        print() -- Newline
    end
end

--- Generates text output suitable for gnuplot.
-- @param p A table with configuration parameters.
local function gptext_output(p)
    local fwidth = p.ur_x - p.ll_x
    local fheight = p.ur_y - p.ll_y

    for y = p.height, 1, -1 do
        local row = {}
        for x = 0, p.width - 1 do
            local real = p.ll_x + x * fwidth / p.width
            local imag = p.ur_y - y * fheight / p.height
            local iter = escape_time(real, imag, p.max_iter)
            table.insert(row, iter)
        end
        print(table.concat(row, ", "))
    end
end

-- Main execution block
if config.png == 0 then
    ascii_output(config)
else
    gptext_output(config)
end

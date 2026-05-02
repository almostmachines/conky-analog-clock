require 'cairo'
require 'cairo_xlib'

local FG = { r = 234/255, g = 184/255, b = 156/255 }

local function setcol(cr, a)
    cairo_set_source_rgba(cr, FG.r, FG.g, FG.b, a)
end

local function text_centered(cr, text, x, y_baseline)
    local te = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, te)
    cairo_move_to(cr, x - te.width / 2 - te.x_bearing, y_baseline)
    cairo_show_text(cr, text)
end

local function draw_hand(cr, cx, cy, angle, len, w)
    cairo_save(cr)
    cairo_translate(cr, cx, cy)
    cairo_rotate(cr, angle)
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    cairo_set_line_width(cr, w)
    cairo_move_to(cr, 0, -len + w / 2)
    cairo_line_to(cr, 0, -w / 2)
    cairo_stroke(cr)
    cairo_restore(cr)
end

function conky_draw_clock()
    if conky_window == nil then return end
    if tonumber(conky_window.width) == 0 then return end

    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height)
    local cr = cairo_create(cs)

    local W = conky_window.width
    local cx = W / 2
    local cy = 320
    local R = 180

    -- Dial outline
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_BUTT)
    cairo_set_line_width(cr, 1.2)
    setcol(cr, 0.85)
    cairo_arc(cr, cx, cy, R, 0, 2 * math.pi)
    cairo_stroke(cr)

    -- 60 ticks
    for i = 0, 59 do
        local isHour = (i % 5) == 0
        local angle = i * 6 * math.pi / 180
        local inner = R - (isHour and 14 or 6)
        local outer = R
        cairo_set_line_width(cr, isHour and 1.6 or 1)
        setcol(cr, isHour and 0.95 or 0.5)
        cairo_move_to(cr, cx + inner * math.sin(angle), cy - inner * math.cos(angle))
        cairo_line_to(cr, cx + outer * math.sin(angle), cy - outer * math.cos(angle))
        cairo_stroke(cr)
    end

    -- Numerals at 12, 3, 6, 9
    cairo_select_font_face(cr, "Adwaita Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 38)
    setcol(cr, 0.95)
    local nums = { { "12", 0 }, { "3", 90 }, { "6", 180 }, { "9", 270 } }
    for _, n in ipairs(nums) do
        local label, deg = n[1], n[2]
        local rad = deg * math.pi / 180
        local nR = R - 38
        local x = cx + nR * math.sin(rad)
        local y = cy - nR * math.cos(rad)
        local te = cairo_text_extents_t:create()
        cairo_text_extents(cr, label, te)
        cairo_move_to(cr, x - te.width / 2 - te.x_bearing, y - te.y_bearing - te.height / 2)
        cairo_show_text(cr, label)
    end

    -- Date and AM/PM
    local now = os.date("*t")
    local dateStr = os.date("%A %d %b %Y")
    local ampm = (now.hour >= 12) and "PM" or "AM"

    cairo_set_font_size(cr, 18)
    setcol(cr, 0.85)
    local dateY = cy + R * 0.32 + 18
    text_centered(cr, dateStr, cx, dateY)

    cairo_set_font_size(cr, 15)
    setcol(cr, 0.75)
    text_centered(cr, ampm, cx, dateY + 27)

    -- Hands
    setcol(cr, 0.95)
    local hourAngle = ((now.hour % 12) + now.min / 60) * 30 * math.pi / 180
    local minAngle = (now.min * 6) * math.pi / 180
    draw_hand(cr, cx, cy, hourAngle, R * 0.45, 6)
    draw_hand(cr, cx, cy, minAngle, R * 0.72, 4)

    -- Center cap
    cairo_arc(cr, cx, cy, 4, 0, 2 * math.pi)
    cairo_fill(cr)

    -- Pendulum line: dial bottom (at y = 520 in dial item, but here just under circle bottom)
    -- dial Item bottom at y=520, faithText.top at 520 + 148 = 668
    -- pendulum from 536 (520 + 16) to 652 (668 - 16)
    cairo_set_line_width(cr, 1.2)
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_BUTT)
    setcol(cr, 0.85)
    cairo_move_to(cr, cx, 536)
    cairo_line_to(cr, cx, 652)
    cairo_stroke(cr)

    -- "faith" text
    cairo_select_font_face(cr, "Noto Serif", CAIRO_FONT_SLANT_ITALIC, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 36)
    setcol(cr, 0.9)
    local faithBaseline = 668 + 30
    text_centered(cr, "faith", cx, faithBaseline)

    -- Teardrop outline below faith
    local teardropTop = faithBaseline + 32
    local tw, th = 16, 26
    local r = tw / 2 - 1
    local tipY = teardropTop + 1
    local tcy = teardropTop + th - r - 1
    local dist = tcy - tipY
    local alpha = math.acos(r / dist)
    local sa = -math.pi / 2 + alpha
    local ea = 3 * math.pi / 2 - alpha
    local trX = cx + r * math.sin(alpha)
    local trY = tcy - r * math.cos(alpha)

    cairo_set_line_width(cr, 1.2)
    cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
    setcol(cr, 0.85)
    cairo_new_path(cr)
    cairo_move_to(cr, cx, tipY)
    cairo_line_to(cr, trX, trY)
    cairo_arc(cr, cx, tcy, r, sa, ea)
    cairo_close_path(cr)
    cairo_stroke(cr)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

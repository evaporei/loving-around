local moonshine = require("moonshine")
local vector = require("vector")

BACKGROUND = { 0.1, 0.1, 0.1 }

local laserSound = love.audio.newSource('sounds/laser.mp3', 'static')

function Copy(obj, seen)
	if type(obj) ~= "table" then
		return obj
	end
	if seen and seen[obj] then
		return seen[obj]
	end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do
		res[Copy(k, s)] = Copy(v, s)
	end
	return res
end

local winW, winH = 0, 0
local padding = 20
local radius = 100
local dist = 0
local panelW = 0
local viewerStart = 0
local laserThickness = 5
local laserSpread = 20

TAU = 2 * math.pi

function love.load()
	love.window.setTitle("Hello, World!")
	love.window.setMode(1280, 720, { resizable = true })
	winW, winH = love.graphics.getDimensions()
	local pre = panelW + padding
	dist = (winW - pre - padding) / 2
	viewerStart = pre + dist / 2
	Flash = moonshine(moonshine.effects.glow)
	Flash.min_luma = 0.7
	Flash.strength = 10
	love.graphics.setBackgroundColor(BACKGROUND)
end

local function list_iter(t)
	local i = 0
	local n = #t
	return function()
		i = i + 1
		if i <= n then
			return t[i]
		end
	end
end

Sparks = {}

local laserSpeed = 0.5

local laserP = 0
local sparkAccel = -5
-- local sparkDropoff = 0.4

local function clip(s, e, f)
	if s < laserP and laserP < e then
		f((laserP - s) / (e - s))
	end
end

function love.keypressed(key)
    if key == 'escape' or key == 'q' then
        love.event.quit()
    end
end

function love.update(dt)
	laserP = math.fmod(laserP + laserSpeed * dt, 1)
	clip(0.3, 1, function(_)
		for s in list_iter(Sparks) do
			s.vx = s.vx + sparkAccel * dt * 0.5
			s.vy = s.vy + sparkAccel * dt * 0.5
			s.x = s.x + s.vx * dt
			s.y = s.y + s.vy * dt
			if s.x < viewerStart + radius or s.x > viewerStart + dist - radius then
				s.vx = -s.vx
			end
			if s.y < 0 or s.y > winH then
				s.vy = -s.vy
			end
			s.vx = s.vx + sparkAccel * dt * 0.5
			s.vy = s.vy + sparkAccel * dt * 0.5
		end
	end)
end

local function resetColors()
	love.graphics.setColor(1, 1, 1, 1)
end

local function lerp(a, b, t)
	return (1 - t) * a + t * b
end

local function colorLerp(from, to, t)
	return {
		lerp(from[1], to[1], t),
		lerp(from[2], to[2], t),
		lerp(from[3], to[3], t),
		lerp(from[4] or 1, to[4] or 1, t),
	}
end

function math.clamp(low, n, high)
	return math.min(math.max(low, n), high)
end

local glowRed = colorLerp({ 1, 0, 0 }, { 1, 1, 1 }, 0.7)

local function simpleZap(s, f, extraThickness)
	local p = math.pow(laserP, 3)
	local to = f - s
	local dirSpread = laserSpread * to:normalize()
	local laser = lerp(s - dirSpread, f, p)
	local laserStart = laser:clamp(s, f)
	local laserEnd = (laser + dirSpread):clamp(s, f)
	local hOffset = (laserThickness + extraThickness) * to:normal()
	love.graphics.polygon(
		"fill",
		laserStart.x,
		laserStart.y,
		(laserStart + hOffset).x,
		(laserStart + hOffset).y,
		(laserEnd + hOffset).x,
		(laserEnd + hOffset).y,
		laserEnd.x,
		laserEnd.y
	)
end

local function sinZap(from, to, period, extra_thickness)
	local laser = lerp(from - laserSpread, to, math.pow(laserP, 3))
	local alpha = TAU * period / (from - to)
	local amplitude = laserThickness * 1.5
	local thickness = laserThickness + extra_thickness
	for d = math.max(from, laser), math.min(to, laser + laserSpread) - 0.5, 0.01 do
		local h = math.sin((d - from) * alpha) * amplitude
		love.graphics.rectangle("fill", d, (winH - thickness) / 2 + h, 0.5, thickness)
	end
end

local function easeInExpo(v)
	return v == 0 and 0 or math.pow(2, (10 * v - 10))
end

local function easeOutExpo(v)
	return v == 1 and 1 or 1 - math.pow(2, -10 * v)
end

local function easeOutQuad(v)
	return 1 - (1 - v) ^ 2
end

local function easeInOutCubic(v)
	return v < 0.5 and 4 * v ^ 3 or 1 - (-2 * v + 2) ^ 3 / 2
end

local function easeInElastic(v)
	local c4 = (2 * math.pi) / 3
	return v == 0 and 0 or v == 1 and 1 or -math.pow(2, 10 * v - 10) * math.sin((v * 10 - 10.75) * c4)
end

local function easeOutBounce(v)
	local n1 = 7.5625
	local d1 = 2.75
	if v < 1 / d1 then
		return n1 * v * v
	elseif v < 2 / d1 then
		return n1 * (v - 1.5 / d1) * v + 0.75
	elseif v < 2.5 / d1 then
		return n1 * (v - 2.25 / d1) * v + 0.9375
	else
		return n1 * (v - 2.625 / d1) * v + 0.984375
	end
end

local function squishZap(from, to, squishSpeed)
	local laser = lerp(from, to, math.sqrt(laserP))
	local len = (math.sin(laserP * math.pi) + 1) / 2 * laserSpread
	local laserStart = math.max(from, laser)
	local laserLen = math.min(to - laserStart, laser + laserSpread)
	love.graphics.rectangle("fill", laserStart, winH / 2 - laserThickness, laserLen, laserThickness)
end

local function colorBlock(x, y)
	love.graphics.rectangle("fill", x, y, 50, 50)
end

local function laser(s, f)
	local faded = Copy(BACKGROUND)
	faded[4] = 0
	love.graphics.setColor(glowRed)
	Flash(function()
		-- start boom
		clip(0, 0.4, function(p)
			local lil_radius = laserSpread / 2
			local r = lerp(lil_radius + 0.1, 2 * lil_radius, easeInElastic(p))
			love.graphics.circle("fill", s.x + 0.1, s.y, r)
		end)
		-- sparks
		if laserP < 0.3 then
			Sparks = {}
		end
		clip(0.3, 1, function(p)
			if #Sparks == 0 then
				for _ = 1, math.random(10, 50) do
					table.insert(Sparks, {
						x = s.x,
						y = s.y,
						vx = math.random(-100, 100),
						vy = math.random(-100, 100),
					})
				end
			end
			love.graphics.setColor(colorLerp(glowRed, faded, easeInOutCubic(p)))
			p = 1 - p
			for spark in list_iter(Sparks) do
				local cap = math.sqrt(spark.vx ^ 2 + spark.vy ^ 2)
				love.graphics.line(
					spark.x,
					spark.y,
					spark.x + spark.vx / cap * 10 * p,
					spark.y + spark.vy / cap * 10 * p
				)
			end
		end)
		love.graphics.setColor(glowRed)
		-- sinZap(start + 5, finish, 5, 0)
		simpleZap(s, f, 0)
	end)
    if laserP > 0.3 then
        laserSound:play()
    end
end

function love.draw()
	-- love.graphics.rectangle("fill")
	resetColors()

	-- for i = 0, 1 do
	-- local center = viewerStart + dist * i
	-- end
	-- love.graphics.setShader()

	-- for o = 0, 2 do
	-- local center = viewerStart + dist * o
	love.graphics.circle("line", viewerStart, winH / 2 + 50, radius)
	love.graphics.circle("line", viewerStart + dist, winH / 2 - 50, radius)
	-- end

	-- local angle = lerp(math.pi / 8, math.pi / 16, p)
	-- love.graphics.arc("fill", viewerStart, winH / 2, radius + 3, -angle, angle)
	-- love.graphics.setColor(BACKGROUND)
	-- love.graphics.arc("fill", viewerStart, winH / 2, radius, -angle, angle)

	laser(vector.new(viewerStart + radius, winH / 2 + 50), vector.new(viewerStart + dist - radius, winH / 2 - 50))
	-- love.graphics.clear(BACKGROUND)
end

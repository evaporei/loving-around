-- vector metatable:
local Vector = {}
Vector.__index = Vector

-- vector constructor:
function Vector.new(x, y)
	local v = { x = x or 0, y = y or 0 }
	setmetatable(v, Vector)
	return v
end

function Vector:length()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector:direction()
	return math.atan2(self.y, self.x)
end

function Vector:normalize()
	local len = self:length()
	if len == 0 then
		return Vector.new(0, 0)
	else
		return Vector.new(self.x / len, self.y / len)
	end
end

function Vector:normal()
	local l = self:length()
	return Vector.new(-self.y / l, self.x / l)
end

function Vector:clamp(a, b)
	local minX = math.min(a.x, b.x)
	local maxX = math.max(a.x, b.x)
	local minY = math.min(a.y, b.y)
	local maxY = math.max(a.y, b.y)
	return Vector.new(math.clamp(minX, self.x, maxX), math.clamp(minY, self.y, maxY))
end

-- vector addition:
function Vector.__add(a, b)
	return Vector.new(a.x + b.x, a.y + b.y)
end

-- vector subtraction:
function Vector.__sub(a, b)
	return Vector.new(a.x - b.x, a.y - b.y)
end

-- multiplication of a vector by a scalar:
function Vector.__mul(a, b)
	if type(a) == "number" then
		return Vector.new(b.x * a, b.y * a)
	elseif type(b) == "number" then
		return Vector.new(a.x * b, a.y * b)
	else
		error("Can only multiply vector by scalar.")
	end
end

-- dividing a vector by a scalar:
function Vector.__div(a, b)
	if type(b) == "number" then
		return Vector.new(a.x / b, a.y / b)
	else
		error("Invalid argument types for vector division.")
	end
end

-- vector equivalence comparison:
function Vector.__eq(a, b)
	return a.x == b.x and a.y == b.y
end

-- vector not equivalence comparison:
function Vector.__ne(a, b)
	return not Vector.__eq(a, b)
end

-- unary negation operator:
function Vector.__unm(a)
	return Vector.new(-a.x, -a.y)
end

-- vector < comparison:
function Vector.__lt(a, b)
	return a.x < b.x and a.y < b.y
end

-- vector <= comparison:
function Vector.__le(a, b)
	return a.x <= b.x and a.y <= b.y
end

-- vector value string output:
function Vector.__tostring(v)
	return "(" .. v.x .. ", " .. v.y .. ")"
end

return Vector

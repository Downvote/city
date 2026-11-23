--!nocheck
-- Pieces (Geometry.piece, Recipe.piece, Builder): a handful of small shapes that go round as one
-- primitive, which the server merges into one mesh. The user: "try to use meshes instead of
-- shapes. keep it low poly as possible". Here: a piece is the box round its shapes, opens back
-- into exactly those shapes, two pieces of the same shapes share a key, a piece refuses what
-- can't be merged, and where no merging is done the Builder makes the shapes as parts in the
-- right places.

local Shared = "ReplicatedStorage.Shared."
local Geometry = require(Shared .. "Build.Geometry")
local Recipe = require(Shared .. "Build.Recipe")
local Builder = require(Shared .. "Build.Builder")

local WHITE, RED = Color3.new(1, 1, 1), Color3.new(1, 0, 0)

local function window(r, x)
	return r:piece(function(q)
		q:box(x, 5, 0, 4, 0.4, 0.6, WHITE) -- sill
		q:box(x - 1.8, 7, 0, 0.4, 4, 0.4, WHITE)
		q:box(x + 1.8, 7, 0, 0.4, 4, 0.4, WHITE)
		q:box(x, 9, 0, 4, 0.4, 0.4, RED)
	end)
end

describe("Pieces", function()
	it("are the box round their shapes", function()
		local r = Recipe.new(WHITE, WHITE)
		local p = window(r, 10)
		expect(p.shape).toBe("Piece")
		expect(#r.prims).toBe(1)
		expect(p.size.X).toBeNear(4, 0.001)
		expect(p.size.Y).toBeNear(4.4, 0.001)
		expect(p.size.Z).toBeNear(0.6, 0.001)
		expect(p.cf.Position.X).toBeNear(10, 0.001)
		expect(p.cf.Position.Y).toBeNear(7, 0.001)
		local lo, hi = Geometry.bounds(r.prims)
		expect(lo.X).toBeNear(8, 0.001)
		expect(hi.Y).toBeNear(9.2, 0.001)
	end)

	it("open back into the shapes they were drawn from", function()
		local r = Recipe.new(WHITE, WHITE)
		window(r, 10)
		local flat = Geometry.flatten(r.prims)
		expect(#flat).toBe(4)
		expect(flat[1].cf.Position.X).toBeNear(10, 0.001)
		expect(flat[1].cf.Position.Y).toBeNear(5, 0.001)
		expect(flat[4].color).toBe(RED)
		-- moved with the model it is in
		local moved = Geometry.flatten(Geometry.transform(r.prims, CFrame.new(100, 0, 0)))
		expect(moved[2].cf.Position.X).toBeNear(108.2, 0.001)
	end)

	it("share a key when they are the same shapes, wherever they stand", function()
		local r = Recipe.new(WHITE, WHITE)
		local a, b = window(r, 0), window(r, 30)
		expect(a.key).toBe(b.key)
		local c = r:piece(function(q)
			q:box(0, 5, 0, 4, 0.4, 0.6, RED)
		end)
		expect(c.key ~= a.key).toBeTruthy()
	end)

	it("refuse what can't be merged into one mesh", function()
		local r = Recipe.new(WHITE, WHITE)
		expect(function()
			r:piece(function(q)
				q:box(0, 1, 0, 1, 1, 1, WHITE, "Wood")
				q:box(0, 2, 0, 1, 1, 1, WHITE, "Brick")
			end)
		end).toThrow()
		expect(function()
			r:piece(function(q)
				q:box(0, 1, 0, 1, 1, 1, WHITE).name = "Sign"
			end)
		end).toThrow()
		expect(function()
			r:piece(function(q)
				q:boxAt(CFrame.Angles(0, 0.5, 0), 1, 1, 1, WHITE)
			end)
		end).toThrow()
		expect(function()
			r:piece(function(q)
				for i = 1, Geometry.PieceMax + 1 do
					q:box(i, 1, 0, 0.5, 0.5, 0.5, WHITE)
				end
			end)
		end).toThrow()
	end)

	it("are built as their shapes where nothing is merged", function()
		local r = Recipe.new(WHITE, WHITE)
		window(r, 10)
		r:box(0, 1, 0, 2, 2, 2, WHITE)
		local model = Instance.new("Model")
		local parts = Builder.instantiate(r.prims, model, CFrame.new(0, 100, 0))
		expect(#parts).toBe(5)
		expect(#model:GetChildren()).toBe(5)
		local sill = parts[1]
		expect(sill.CFrame.Position.X).toBeNear(10, 0.001)
		expect(sill.CFrame.Position.Y).toBeNear(105, 0.001)
		expect(sill.CanCollide).toBe(false)
		expect(parts[5].CanCollide).toBe(true)
	end)
end)

--!nocheck
-- Z-fighting: two faces in one plane, facing the same way, overlapping, on parts of a different
-- colour or material, flicker in the game (the user: "there is also z-fighting in alot of
-- areas"). tools/preview/zfight_lib.luau finds them; `lune run tools/preview/zfight.luau` lists
-- them with the lines that drew each shape.
--
-- First the finder itself on cases made on purpose, then every scope of the game. KNOWN is what
-- still flickered when the finder was written: the detail pass's helpers empty it as they fix
-- their files (`lune run tools/preview/zfight.luau --known` prints what is left). A model that
-- flickers and isn't on the list fails; one on the list that no longer does is only printed, so
-- it can come off. The near ones count everywhere, the big layers closer than 0.1 ("far") only
-- in the whole town.

local Z = Harness.loadFile("tools/preview/zfight_lib.luau")()
local Recipe = require("ReplicatedStorage.Shared.Build.Recipe")

local KNOWN = {
	"catalog:item:bed_ward",
	"catalog:item:bread_rack",
	"catalog:item:canvas_stack",
	"catalog:item:freezer_icecream",
	"catalog:item:gable_clock",
	"catalog:item:menu_board",
	"catalog:item:parcel_cart",
	"catalog:item:plank_stack",
	"catalog:item:produce_stand",
	"catalog:item:school_desk",
	"catalog:item:sculpture_ring",
	"catalog:item:shop_shelves",
	"catalog:item:sign_bakery",
	"catalog:item:sign_cafe",
	"catalog:item:sign_clinic",
	"catalog:item:sign_library",
	"catalog:item:sign_music",
	"catalog:item:sign_palette",
	"catalog:item:sign_post",
	"catalog:item:sorting_shelves",
	"catalog:item:stage_curtain",
	"catalog:item:timber_rack",
	"catalog:item:work_easel",
	"catalog:item:work_flowers",
	"catalog:item:work_icecream",
	"catalog:item:work_market",
	"catalog:item:work_post",
	"far town:facade:14x14:3:57492:cl:sign=toys:shop=glazed:nb | ground",
	"far town:facade:15x14:4:27896:cr:shop=counter:nb | ground",
	"far town:facade:16x14:3:23551:shop=counter | ground",
	"far town:facade:16x14:4:35561:shop=glazed | ground",
	"far town:facade:18x14:3:5230:sign=grocer:shop=glazed | ground",
	"far town:facade:18x14:3:59601:sign=flowers:shop=glazed | ground",
	"far town:facade:18x14:4:19647:sign=grocer:shop=glazed:nb | ground",
	"far town:facade:18x14:4:32349:sign=bakery:shop=glazed | ground",
	"far town:facade:18x14:4:9062:shop=counter:nb | ground",
	"far town:facade:20x14:2:2884:sign=toys:shop=glazed | ground",
	"far town:facade:20x14:2:3843:sign=flowers:shop=glazed | ground",
	"far town:facade:20x14:4:59005:sign=grocer:shop=glazed | ground",
	"far town:facade:21x14:3:48651:cr:sign=books:shop=glazed:nb | ground",
	"far town:facade:21x14:5:30363:shop=glazed | ground",
	"far town:facade:22x18:3:2826:sign=bakery:shop=counter:nb | ground",
	"far town:facade:23x14:2:14007:sign=clothes:shop=glazed | ground",
	"far town:facade:23x14:2:55830:sign=clothes:shop=glazed | ground",
	"far town:facade:23x14:2:6001:shop=counter | ground",
	"far town:facade:23x14:2:74977:sign=books:shop=glazed | ground",
	"far town:facade:23x14:3:1621:shop=counter | ground",
	"far town:facade:23x14:3:60210:sign=bakery:shop=glazed | ground",
	"far town:facade:23x14:4:69843:sign=bakery:shop=glazed | ground",
	"far town:facade:24x14:3:25107:sign=flowers:shop=glazed | ground",
	"far town:facade:25x18:2:19640:sign=cafe:shop=counter:nb | ground",
	"far town:facade:25x18:3:14506:sign=toys:shop=glazed:nb | ground",
	"far town:facade:26x14:2:22018:sign=toys:shop=glazed | ground",
	"far town:facade:26x14:2:3914:sign=toys:shop=glazed | ground",
	"far town:facade:26x14:3:18041:cr:sign=cafe:shop=glazed:nb | ground",
	"far town:facade:27x14:3:33955:sign=bakery:shop=glazed | ground",
	"far town:facade:28x14:3:63989:sign=toys:shop=glazed | ground",
	"far town:facade:28x18:2:15698:cl:sign=cafe:shop=glazed:nb | ground",
	"far town:facade:29x18:2:4651:cl:shop=glazed:nb | ground",
	"far town:facade:30x14:2:59891:sign=flowers:shop=glazed | ground",
	"far town:facade:30x14:3:47773:cr:sign=flowers:shop=glazed:nb | ground",
	"far town:facade:30x14:4:40452:cl:sign=clothes:shop=glazed:nb | ground",
	"far town:facade:30x14:5:10814:shop=counter:nb | ground",
	"far town:facade:30x14:5:21399:sign=bakery:shop=counter:nb | ground",
	"far town:facade:34x14:3:55659:sign=cafe:shop=glazed | ground",
	"far town:fairPier | ground",
	"far town:ground | lot:37x36:garden:5",
	"far town:ground | lot:40x41:garden:5",
	"far town:ground | lot:41x36:garden:5",
	"far town:ground | lot:44x41:garden:5",
	"far town:ground | lot:45x38:garden:5",
	"far town:ground | lot:66x58:garden:5",
	"far town:ground | lot:67x42:garden:5",
	"far town:ground | lot:68x41:garden:5",
	"far town:ground | lot:71x53:garden:5",
	"far town:ground | lot:80x27:garden:5",
	"far town:ground | lot:81x38:garden:5",
	"far town:ground | pocketCafe",
	"far town:ground | pocketFountain",
	"far town:ground | pocketParking",
	"far town:ground | tarn",
	"far town:ground | towel",
	"far town:ground | volleyNet",
	"far town:ground",
	"interiors:room:bakery",
	"interiors:room:books",
	"interiors:room:cafe",
	"interiors:room:cinema",
	"interiors:room:clinic",
	"interiors:room:clothes",
	"interiors:room:department",
	"interiors:room:flats",
	"interiors:room:flowers",
	"interiors:room:grocer",
	"interiors:room:home",
	"interiors:room:hut",
	"interiors:room:library",
	"interiors:room:lobby",
	"interiors:room:museum",
	"interiors:room:post",
	"interiors:room:school",
	"interiors:room:station",
	"interiors:room:toys",
	"models:apartmentLilac",
	"models:apartmentMint",
	"models:apartmentPeach",
	"models:beachHuts",
	"models:bench",
	"models:board",
	"models:buoy",
	"models:busStop",
	"models:cafeTable",
	"models:camp",
	"models:cinema",
	"models:clinic",
	"models:coneBar",
	"models:facade:12x14:2:49900:sign=office:shop=door",
	"models:facade:14x14:3:57492:cl:sign=toys:shop=glazed:nb",
	"models:facade:15x14:4:27896:cr:shop=counter:nb",
	"models:facade:16x14:2:1067:sign=clothes:shop=glazed:nb",
	"models:facade:16x14:2:39607:sign=flats:shop=door",
	"models:facade:16x14:2:56314:shop=garage",
	"models:facade:16x14:2:65595:shop=door",
	"models:facade:16x14:2:76250:shop=garage",
	"models:facade:16x14:3:1570:sign=flats:shop=door",
	"models:facade:16x14:3:23551:shop=counter",
	"models:facade:16x14:3:28868:shop=garage",
	"models:facade:16x14:3:43979:cl:sign=cafe:shop=shutter:nb",
	"models:facade:16x14:3:47372:shop=counter",
	"models:facade:16x14:4:35561:shop=glazed",
	"models:facade:16x18:2:13046:shop=garage:nb",
	"models:facade:17x14:2:73469:sign=bakery:shop=glazed",
	"models:facade:17x14:3:32226:sign=clothes:shop=shutter",
	"models:facade:17x14:4:51460:cr:sign=bakery:shop=glazed:nb",
	"models:facade:18x14:2:6980:sign=clothes:shop=shutter:nb",
	"models:facade:18x14:2:89322:sign=grocer:shop=glazed:nb",
	"models:facade:18x14:3:15966:sign=grocer:shop=shutter:nb",
	"models:facade:18x14:3:2308:sign=flats:shop=door:nb",
	"models:facade:18x14:3:4456:shop=door:nb",
	"models:facade:18x14:3:5230:sign=grocer:shop=glazed",
	"models:facade:18x14:3:59601:sign=flowers:shop=glazed",
	"models:facade:18x14:4:19647:sign=grocer:shop=glazed:nb",
	"models:facade:18x14:4:21100:sign=bakery:shop=counter:nb",
	"models:facade:18x14:4:32349:sign=bakery:shop=glazed",
	"models:facade:18x14:4:9062:shop=counter:nb",
	"models:facade:18x18:2:8544:shop=glazed:nb",
	"models:facade:18x18:3:11805:sign=flowers:shop=glazed:nb",
	"models:facade:18x18:3:7230:shop=counter:nb",
	"models:facade:19x14:2:27554:cr:shop=garage:nb",
	"models:facade:19x14:3:12566:cl:sign=flowers:shop=glazed:nb",
	"models:facade:19x14:3:4271:cl:sign=grocer:shop=shutter:nb",
	"models:facade:19x14:3:52893:cr:sign=flats:shop=door:nb",
	"models:facade:20x14:2:25329:sign=flowers:shop=glazed",
	"models:facade:20x14:2:2884:sign=toys:shop=glazed",
	"models:facade:20x14:2:3843:sign=flowers:shop=glazed",
	"models:facade:20x14:3:24841:shop=garage",
	"models:facade:20x14:3:38293:sign=bakery:shop=glazed",
	"models:facade:20x14:3:38469:shop=door",
	"models:facade:20x14:3:45865:sign=flowers:shop=glazed",
	"models:facade:20x14:3:5593:shop=door",
	"models:facade:20x14:4:41485:sign=cafe:shop=counter",
	"models:facade:20x14:4:59005:sign=grocer:shop=glazed",
	"models:facade:21x14:2:41033:shop=door",
	"models:facade:21x14:2:46469:shop=garage",
	"models:facade:21x14:3:20009:sign=books:shop=glazed",
	"models:facade:21x14:3:23224:cl:sign=grocer:shop=shutter:nb",
	"models:facade:21x14:3:48651:cr:sign=books:shop=glazed:nb",
	"models:facade:21x14:4:36653:shop=garage",
	"models:facade:21x14:4:45985:shop=shutter",
	"models:facade:21x14:4:54173:sign=toys:shop=glazed",
	"models:facade:21x14:5:30363:shop=glazed",
	"models:facade:22x14:2:35584:shop=door",
	"models:facade:22x14:2:36760:cl:sign=grocer:shop=glazed:nb",
	"models:facade:22x14:2:62164:shop=garage",
	"models:facade:22x14:2:78138:cr:sign=bakery:shop=glazed:nb",
	"models:facade:22x14:3:10914:shop=garage",
	"models:facade:22x14:3:19820:sign=cafe:shop=counter",
	"models:facade:22x14:3:44936:sign=clothes:shop=shutter",
	"models:facade:22x14:3:61789:sign=grocer:shop=shutter",
	"models:facade:22x14:3:72082:sign=toys:shop=glazed",
	"models:facade:22x14:3:81725:sign=cafe:shop=shutter",
	"models:facade:22x14:4:26786:sign=books:shop=glazed",
	"models:facade:22x18:2:10345:cr:shop=counter:nb",
	"models:facade:22x18:2:5770:sign=books:shop=glazed:nb",
	"models:facade:22x18:3:2826:sign=bakery:shop=counter:nb",
	"models:facade:23x14:2:10924:cr:sign=cafe:shop=shutter:nb",
	"models:facade:23x14:2:14007:sign=clothes:shop=glazed",
	"models:facade:23x14:2:44320:sign=grocer:shop=counter",
	"models:facade:23x14:2:55830:sign=clothes:shop=glazed",
	"models:facade:23x14:2:6001:shop=counter",
	"models:facade:23x14:2:60964:sign=books:shop=glazed",
	"models:facade:23x14:2:73350:sign=flats:shop=door",
	"models:facade:23x14:2:74977:sign=books:shop=glazed",
	"models:facade:23x14:2:80988:cl:sign=clothes:shop=shutter:nb",
	"models:facade:23x14:2:88441:cl:shop=door:nb",
	"models:facade:23x14:3:1621:shop=counter",
	"models:facade:23x14:3:19141:sign=books:shop=glazed",
	"models:facade:23x14:3:60210:sign=bakery:shop=glazed",
	"models:facade:23x14:3:78484:sign=grocer:shop=counter",
	"models:facade:23x14:4:39186:sign=grocer:shop=counter",
	"models:facade:23x14:4:69843:sign=bakery:shop=glazed",
	"models:facade:23x14:4:867:shop=shutter",
	"models:facade:23x14:5:33721:cr:shop=garage:nb",
	"models:facade:23x18:3:10004:cr:sign=books:shop=glazed:nb",
	"models:facade:24x14:2:18141:sign=books:shop=shutter",
	"models:facade:24x14:2:42519:sign=flats:shop=door",
	"models:facade:24x14:2:63468:cl:sign=flats:shop=door:nb",
	"models:facade:24x14:2:83404:cr:sign=office:shop=door:nb",
	"models:facade:24x14:2:9235:cr:sign=flats:shop=door:nb",
	"models:facade:24x14:3:25107:sign=flowers:shop=glazed",
	"models:facade:24x14:3:79817:sign=bakery:shop=glazed",
	"models:facade:24x14:3:8513:sign=flowers:shop=shutter:nb",
	"models:facade:24x22:2:6355:sign=flowers:top=flat:in=flowers",
	"models:facade:24x22:2:7264:sign=flowers:top=flat:in=flowers",
	"models:facade:25x14:2:61134:cl:sign=grocer:shop=glazed:nb",
	"models:facade:25x14:3:27201:sign=toys:shop=glazed",
	"models:facade:25x18:2:19640:sign=cafe:shop=counter:nb",
	"models:facade:25x18:3:14506:sign=toys:shop=glazed:nb",
	"models:facade:26x14:2:12666:shop=door",
	"models:facade:26x14:2:21572:cl:shop=garage:nb",
	"models:facade:26x14:2:22018:sign=toys:shop=glazed",
	"models:facade:26x14:2:3914:sign=toys:shop=glazed",
	"models:facade:26x14:2:49817:sign=flats:shop=door",
	"models:facade:26x14:2:69753:sign=office:shop=door",
	"models:facade:26x14:2:70194:cr:shop=garage:nb",
	"models:facade:26x14:3:18041:cr:sign=cafe:shop=glazed:nb",
	"models:facade:26x14:3:57847:sign=bakery:shop=shutter",
	"models:facade:26x14:3:77783:sign=cafe:shop=shutter",
	"models:facade:26x22:2:6077:sign=toys:top=flat:in=toys",
	"models:facade:26x22:2:6490:sign=grocer:top=flat:in=grocer",
	"models:facade:27x14:3:33955:sign=bakery:shop=glazed",
	"models:facade:28x14:2:87417:cl:shop=garage:nb",
	"models:facade:28x14:3:37409:sign=toys:shop=glazed",
	"models:facade:28x14:3:63989:sign=toys:shop=glazed",
	"models:facade:28x14:3:89461:sign=office:shop=door:nb",
	"models:facade:28x14:5:7383:cr:sign=bakery:shop=shutter:nb",
	"models:facade:28x18:2:15698:cl:sign=cafe:shop=glazed:nb",
	"models:facade:28x18:3:17742:shop=glazed:nb",
	"models:facade:28x22:2:6898:sign=clothes:top=flat:in=clothes",
	"models:facade:28x22:2:7067:sign=clothes:top=flat:in=clothes",
	"models:facade:28x22:3:6214:sign=books:top=flat:in=books",
	"models:facade:28x22:3:7093:sign=books:top=flat:in=books",
	"models:facade:29x14:2:81715:sign=flats:shop=door",
	"models:facade:29x18:2:4651:cl:shop=glazed:nb",
	"models:facade:30x14:2:10484:sign=toys:shop=glazed:nb",
	"models:facade:30x14:2:59891:sign=flowers:shop=glazed",
	"models:facade:30x14:2:79827:sign=grocer:shop=glazed",
	"models:facade:30x14:3:47773:cr:sign=flowers:shop=glazed:nb",
	"models:facade:30x14:3:67709:cl:sign=books:shop=glazed:nb",
	"models:facade:30x14:3:71797:sign=clothes:shop=shutter",
	"models:facade:30x14:4:40452:cl:sign=clothes:shop=glazed:nb",
	"models:facade:30x14:5:10814:shop=counter:nb",
	"models:facade:30x14:5:18026:cl:sign=office:shop=door:nb",
	"models:facade:30x14:5:21399:sign=bakery:shop=counter:nb",
	"models:facade:30x18:2:928:sign=cafe:shop=counter:nb",
	"models:facade:30x22:3:5942:sign=cafe:top=flat:in=cafe",
	"models:facade:30x22:3:6370:sign=bakery:top=flat:in=bakery",
	"models:facade:30x22:3:6977:sign=cafe:top=flat:in=cafe",
	"models:facade:31x14:2:77265:sign=clothes:shop=glazed",
	"models:facade:32x14:2:54124:sign=office:shop=door",
	"models:facade:32x14:2:74060:shop=door",
	"models:facade:34x14:3:12820:cr:sign=office:shop=door:nb",
	"models:facade:34x14:3:55659:sign=cafe:shop=glazed",
	"models:facade:34x14:4:39196:cl:shop=counter:nb",
	"models:facade:70x40:3:5938:sign=department:top=flat:in=department",
	"models:farmyard",
	"models:ferrisWheel",
	"models:flagpole",
	"models:fountain",
	"models:hall",
	"models:hillStair",
	"models:hotel",
	"models:houseRow",
	"models:library",
	"models:lighthouse",
	"models:lookout",
	"models:lookoutBluff",
	"models:lot:37x36:garden:5",
	"models:lot:40x41:garden:5",
	"models:lot:41x36:garden:5",
	"models:lot:44x41:garden:5",
	"models:lot:45x38:garden:5",
	"models:lot:66x58:garden:5",
	"models:lot:67x42:garden:5",
	"models:lot:68x41:garden:5",
	"models:lot:71x53:garden:5",
	"models:lot:80x27:garden:5",
	"models:lot:81x38:garden:5",
	"models:marina",
	"models:marketCart",
	"models:marketGate",
	"models:marketGoods",
	"models:marketHall",
	"models:marketMast",
	"models:marketTentA",
	"models:marketTentB",
	"models:museum",
	"models:officeBlue",
	"models:officeTeal",
	"models:postOffice",
	"models:rowboat",
	"models:school",
	"models:shop",
	"models:shopCoral",
	"models:shopLilac",
	"models:skyTower",
	"models:stall",
	"models:station",
	"models:tailor",
	"models:tarn",
	"presets:preset:bakery",
	"presets:preset:cafe",
	"presets:preset:clinic",
	"presets:preset:cottage",
	"presets:preset:family",
	"presets:preset:florist",
	"presets:preset:icecream",
	"presets:preset:library",
	"presets:preset:market",
	"presets:preset:musichall",
	"presets:preset:postoffice",
	"presets:preset:school",
	"presets:preset:studio",
	"presets:preset:townhouse",
	"presets:preset:workshop",
	"starter:starter",
	"town:facade:14x14:3:57492:cl:sign=toys:shop=glazed:nb | ground",
	"town:facade:16x14:4:35561:shop=glazed | ground",
	"town:facade:18x14:3:5230:sign=grocer:shop=glazed | ground",
	"town:facade:18x14:3:59601:sign=flowers:shop=glazed | ground",
	"town:facade:18x14:4:19647:sign=grocer:shop=glazed:nb | ground",
	"town:facade:18x14:4:32349:sign=bakery:shop=glazed | ground",
	"town:facade:18x18:2:8544:shop=glazed:nb | laneLights:16",
	"town:facade:18x18:3:11805:sign=flowers:shop=glazed:nb | laneLights:16",
	"town:facade:20x14:2:2884:sign=toys:shop=glazed | ground",
	"town:facade:20x14:2:3843:sign=flowers:shop=glazed | ground",
	"town:facade:20x14:4:59005:sign=grocer:shop=glazed | ground",
	"town:facade:21x14:3:48651:cr:sign=books:shop=glazed:nb | ground",
	"town:facade:21x14:5:30363:shop=glazed | ground",
	"town:facade:23x14:2:14007:sign=clothes:shop=glazed | ground",
	"town:facade:23x14:2:55830:sign=clothes:shop=glazed | ground",
	"town:facade:23x14:2:74977:sign=books:shop=glazed | ground",
	"town:facade:23x14:3:60210:sign=bakery:shop=glazed | ground",
	"town:facade:23x14:4:69843:sign=bakery:shop=glazed | ground",
	"town:facade:24x14:3:25107:sign=flowers:shop=glazed | ground",
	"town:facade:26x14:2:22018:sign=toys:shop=glazed | ground",
	"town:facade:26x14:2:3914:sign=toys:shop=glazed | ground",
	"town:facade:26x14:3:18041:cr:sign=cafe:shop=glazed:nb | ground",
	"town:facade:27x14:3:33955:sign=bakery:shop=glazed | ground",
	"town:facade:28x14:3:63989:sign=toys:shop=glazed | ground",
	"town:facade:30x14:2:59891:sign=flowers:shop=glazed | ground",
	"town:facade:30x14:3:47773:cr:sign=flowers:shop=glazed:nb | ground",
	"town:facade:30x14:4:40452:cl:sign=clothes:shop=glazed:nb | ground",
	"town:facade:34x14:3:55659:sign=cafe:shop=glazed | ground",
	"town:ground | hedge",
	"town:ground | lot:71x53:garden:5",
	"town:ground | marina",
	"town:ground | parkedCar1",
	"town:ground | tarn",
	"town:ground",
	"town:hillStair | lookoutBluff",
	"town:marketGoods | marketHall",
	"town:towel | towel2",
}

local RED, BLUE, GREEN = Color3.fromRGB(200, 80, 80), Color3.fromRGB(80, 80, 200), Color3.fromRGB(80, 200, 80)

local function scan(r, opts)
	local prims = Z.open(r.prims)
	opts = opts or {}
	opts.group = {}
	for i = 1, #prims do
		opts.group[i] = 1
	end
	opts.supports = opts.supports or { { 0, 1, 0, 0 } } -- standing on a floor at y = 0
	return Z.scan(prims, opts)
end

local function new()
	return Recipe.new(RED, BLUE)
end

describe("Zfight", function()
	describe("the finder", function()
		it("finds two boxes sharing a top", function()
			local r = new()
			r:box(0, 0.5, 0, 4, 1, 4, RED)
			r:box(0, 0.5, 0, 2, 1, 2, BLUE)
			local found = scan(r)
			expect(#found).toBe(1) -- the tops; the bottoms are on the floor
			expect(found[1].cls).toBe("near")
			expect(found[1].area).toBeNear(4, 0.01)
			expect(found[1].at[2]).toBeNear(1, 0.001)
		end)

		it("passes over the same paint", function()
			local r = new()
			r:box(0, 0.5, 0, 4, 1, 4, RED)
			r:box(0, 0.5, 0, 2, 1, 2, RED)
			expect(#scan(r)).toBe(0)
			local q = new()
			q:box(0, 0.5, 0, 4, 1, 4, RED, "Wood")
			q:box(0, 0.5, 0, 2, 1, 2, RED, "Brick")
			expect(#scan(q)).toBe(1) -- the same colour in another material still flickers
		end)

		it("finds a sign level with the wall it is set in", function()
			local r = new()
			r:box(0, 4, 0, 10, 8, 1, RED) -- the wall's face at z = 0.5
			r:box(0, 4, 0.45, 2, 1, 0.1, BLUE)
			local found = scan(r)
			expect(#found).toBe(1)
			expect(found[1].area).toBeNear(2, 0.01)
			expect(found[1].normal[3]).toBeNear(1, 0.001)
		end)

		it("leaves a sign that stands 0.05 off the wall", function()
			local r = new()
			r:box(0, 4, 0, 10, 8, 1, RED)
			r:box(0, 4, 0.5, 2, 1, 0.1, BLUE) -- its face at z = 0.55
			expect(#scan(r)).toBe(0)
		end)

		it("leaves faces that face each other", function()
			local r = new()
			r:box(0, 4, 0, 10, 8, 1, RED)
			r:box(0, 4, 0.55, 2, 1, 0.1, BLUE) -- its back on the wall's face
			expect(#scan(r)).toBe(0)
		end)

		it("leaves what can't be seen for another part over it", function()
			local r = new()
			r:box(0, 0.5, 0, 4, 1, 4, RED)
			r:box(0, 0.5, 0, 2, 1, 2, BLUE)
			r:box(0, 1.5, 0, 4.2, 1, 4.2, GREEN) -- a lid over both tops
			expect(#scan(r)).toBe(0)
		end)

		it("finds slopes, caps and faces inside a piece", function()
			local r = new()
			r:wedge(CFrame.new(0, 1, 0), 2, 2, 2, RED)
			r:wedge(CFrame.new(0, 1, 0), 1, 2, 2, BLUE)
			local found = scan(r)
			local slope = false
			for _, f in found do
				if math.abs(f.normal[2] - math.sqrt(0.5)) < 1e-3 and math.abs(f.normal[3] + math.sqrt(0.5)) < 1e-3 then
					slope = true
				end
			end
			expect(slope).toBe(true)

			local c = new()
			c:box(0, 0.5, 0, 2, 1, 2, RED)
			c:cyl(0, 0.5, 0, 1, 0.8, "y", BLUE) -- its top cap level with the box's top
			found = scan(c)
			expect(#found).toBe(1)
			expect(found[1].area).toBeNear(8 * 0.16 * math.tan(math.rad(22.5)), 0.01)

			local p = new()
			p:piece(function(q)
				q:box(0, 0.5, 0, 2, 1, 2, RED)
				q:box(1.5, 0.5, 0, 1, 1, 2, BLUE) -- beside it: tops level but not over each other
				q:box(0, 1, -0.5, 1, 0.1, 0.8, BLUE) -- a mat sunk in, 0.05 of it showing
				q:box(0, 0.5, 0.5, 1, 1, 1, BLUE) -- sunk to the box's top and front
			end)
			found = scan(p)
			expect(#found).toBe(2) -- the top and the front of the last
		end)

		it("holds big layers 0.1 apart only where asked", function()
			local r = new()
			r:box(0, -0.5, 0, 20, 1, 20, GREEN) -- the ground's top at y = 0
			r:box(0, 0, 0, 4, 0.1, 4, BLUE) -- paint whose top is 0.05 over it
			expect(#scan(r)).toBe(0)
			local found = scan(r, { far = true })
			expect(#found).toBe(1)
			expect(found[1].cls).toBe("far")
		end)
	end)

	describe("the game", function()
		Z.tag()
		local ok, err = pcall(function()
			local known = {}
			for _, k in KNOWN do
				known[k] = true
			end
			local seen = {}
			local owners = {}
			for _, scope in Z.Scopes do
				it("has no new z-fighting in " .. scope, function()
					local new = {}
					local example = {}
					local listed, jobs = pcall(Z.jobs, scope)
					if not listed then
						print("Zfight: " .. scope .. " could not be listed: " .. tostring(jobs):match("^[^\n]*"))
						jobs = {}
					end
					for _, job in jobs do
						-- a model that won't build is another spec's business
						local built, records = pcall(Z.run, job)
						if not built then
							print(
								"Zfight: "
									.. scope
									.. ":"
									.. job.name
									.. " could not be built: "
									.. tostring(records):match("^[^\n]*")
							)
							continue
						end
						for _, rec in records do
							if rec.cls == "near" or scope == "town" then
								local key = Z.knownKey(rec)
								seen[key] = true
								for _, o in rec.owners do
									owners[o] = (owners[o] or 0) + 1
								end
								if not known[key] and not example[key] then
									example[key] = rec
									table.insert(new, key)
								end
							end
						end
					end
					if #new > 0 then
						local lines = {}
						for i, key in new do
							if i > 12 then
								table.insert(lines, string.format("(and %d more)", #new - 12))
								break
							end
							local rec = example[key]
							table.insert(
								lines,
								string.format(
									"%s at (%.1f, %.1f, %.1f)\n      %s\n      %s",
									key,
									rec.at[1],
									rec.at[2],
									rec.at[3],
									rec.a,
									rec.b
								)
							)
						end
						error(
							"new z-fighting (lune run tools/preview/zfight.luau for all of it):\n    "
								.. table.concat(lines, "\n    ")
						)
					end
				end)
			end
			it("says what is left on the known list", function()
				local gone = {}
				for _, k in KNOWN do
					if not seen[k] then
						table.insert(gone, k)
					end
				end
				if #gone > 0 then
					local some = table.move(gone, 1, math.min(#gone, 6), 1, {})
					print(
						string.format(
							"Zfight: %d on KNOWN are clean now (or didn't build), such as %s",
							#gone,
							table.concat(some, ", ")
						)
					)
				end
				local parts = {}
				for o, n in owners do
					table.insert(parts, o .. " " .. n)
				end
				table.sort(parts)
				if #parts > 0 then
					print("Zfight: spots left by owner: " .. table.concat(parts, ", "))
				end
			end)
		end)
		Z.untag()
		if not ok then
			error(err)
		end
	end)
end)

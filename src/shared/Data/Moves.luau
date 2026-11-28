--!strict
-- How villagers move in a cutscene (UI/Cutscene plays them, Data/Cutscenes and the events' own
-- scripts name them). The user: "make custom animations for villagers for them". Animations
-- can't be uploaded from here, so these are keyed poses played from code: each move is a few
-- poses at set times, and the cutscene eases between them every frame and turns each joint of
-- the villager's body (its Motor6D) by the pose's angles. A villager is a Roblox R15 body, so
-- the joints are its own: Waist, Neck, the shoulders, elbows and wrists, the hips, knees and
-- ankles.
--
-- A pose gives, for each joint it moves, its turn in degrees about the joint's own X, Y and Z
-- (missing ones are 0, and a joint a pose leaves out is at rest): with the villager facing -Z,
--   X  a shoulder or a hip forward (up), an elbow bent, a knee straight (it bends at minus),
--      the neck looking up, the waist leaning back (forward is minus)
--   Y  a turn to the villager's left
--   Z  the right arm out to the side (the left arm goes out at minus), the head or the waist
--      leaning to the villager's left
-- and how the whole body sits (`root`): `y` up, `fwd` forward, `side` to their right, in studs
-- on a body with the usual hip height of 2 (the cutscene scales them to the villager), and
-- `pitch` (90 is lying on their back, -90 face down), `roll` (to their left) and `turn` (to
-- their left), in degrees, all about the middle of their body.
--
-- A move:
--   keys   the poses, each at `t` seconds from the start, in order (the first at 0)
--   loop   the move repeats every this many seconds (its last key should be its first again)
--   hold   it stays on its last pose once it gets there (else it ends there and they stand)
--   act    what it looks like, in a few words (a move with it can be a beat's `act`)
-- A move with neither loop nor hold plays once and ends. Moves.sample eases between keys.
--
-- Moves.figure lays out a plain blocky body in a pose, for the previews (tools/preview) and the
-- specs: the parts of a standard R15 body by their joints, as Roblox would place them.

export type Pose = {
	t: number,
	j: { [string]: { number } }?,
	root: { y: number?, fwd: number?, side: number?, pitch: number?, roll: number?, turn: number? }?,
}
export type Move = { keys: { Pose }, loop: number?, hold: boolean?, act: string? }

local Moves = {}

-- The joints a pose may turn.
Moves.Joints = {
	Waist = true,
	Neck = true,
	LeftShoulder = true,
	RightShoulder = true,
	LeftElbow = true,
	RightElbow = true,
	LeftWrist = true,
	RightWrist = true,
	LeftHip = true,
	RightHip = true,
	LeftKnee = true,
	RightKnee = true,
	LeftAnkle = true,
	RightAnkle = true,
}

-- the hip height the root's studs are measured on
Moves.Hips = 2

local list: { [string]: Move } = {}
Moves.list = list

-- A pose that mirrors another, left for right (and turns and leans the other way).
local function mirror(j: { [string]: { number } }): { [string]: { number } }
	local out = {}
	for name, a in j do
		local other = if name:sub(1, 4) == "Left"
			then "Right" .. name:sub(5)
			elseif name:sub(1, 5) == "Right" then "Left" .. name:sub(6)
			else name
		out[other] = { a[1] or 0, -(a[2] or 0), -(a[3] or 0) }
	end
	return out
end

-- The ones that were done before by formula, kept as they looked ------------------------------------

list.sad = {
	act = "hangs their head",
	hold = true,
	keys = { { t = 0 }, { t = 0.5, j = { Neck = { -24 }, Waist = { -7 } } } },
}
list.nod = {
	act = "nods",
	keys = {
		{ t = 0 },
		{ t = 0.22, j = { Neck = { -18 } } },
		{ t = 0.46, j = { Neck = { -2 } } },
		{ t = 0.7, j = { Neck = { -18 } } },
		{ t = 0.95, j = { Neck = { -2 } } },
		{ t = 1.2, j = { Neck = { -12 } } },
		{ t = 1.4 },
	},
}
list.shake = {
	act = "shakes their head",
	keys = {
		{ t = 0 },
		{ t = 0.17, j = { Neck = { -3, 24 } } },
		{ t = 0.5, j = { Neck = { -3, -20 } } },
		{ t = 0.83, j = { Neck = { -3, 14 } } },
		{ t = 1.14, j = { Neck = { -3, -7 } } },
		{ t = 1.4 },
	},
}
list.tilt = {
	act = "tips their head to one side",
	hold = true,
	keys = { { t = 0 }, { t = 0.4, j = { Neck = { 3, 6, 17 } } } },
}
list.shy = {
	act = "looks down and away",
	hold = true,
	keys = {
		{ t = 0 },
		{ t = 0.5, j = { Neck = { -17, 20 }, LeftShoulder = { 18, 0, 6 }, RightShoulder = { 18, 0, -6 } } },
	},
}
list.doze = {
	act = "nods off",
	loop = 3.9,
	keys = {
		{ t = 0, j = { Neck = { -14 } } },
		{ t = 1.95, j = { Neck = { -29 }, Waist = { -4 } } },
		{ t = 3.9, j = { Neck = { -14 } } },
	},
}
list.gaze = {
	act = "looks up at the sky",
	hold = true,
	keys = { { t = 0 }, { t = 0.7, j = { Neck = { 29 }, Waist = { 4 } } } },
}
list.bow = {
	act = "bows",
	keys = {
		{ t = 0 },
		{ t = 0.8, j = { Waist = { -37 }, Neck = { -8 }, LeftShoulder = { 6 }, RightShoulder = { 6 } } },
		{ t = 1.1, j = { Waist = { -37 }, Neck = { -8 }, LeftShoulder = { 6 }, RightShoulder = { 6 } } },
		{ t = 1.8 },
	},
}
list.hop = {
	act = "hops on the spot",
	keys = {
		{ t = 0 },
		{ t = 0.22, root = { y = 0.55 } },
		{ t = 0.45 },
		{ t = 0.67, root = { y = 0.55 } },
		{ t = 0.9 },
		{ t = 1.12, root = { y = 0.55 } },
		{ t = 1.35 },
	},
}
local UP = { LeftShoulder = { 150, 0, -18 }, RightShoulder = { 150, 0, 18 } }
list.jump = {
	act = "jumps for joy",
	keys = {
		{ t = 0 },
		{
			t = 0.15,
			root = { y = -0.3 },
			j = { LeftKnee = { -30 }, RightKnee = { -30 }, LeftHip = { 20 }, RightHip = { 20 } },
		},
		{ t = 0.4, root = { y = 1.5 }, j = UP },
		{ t = 0.7, j = { LeftShoulder = { 120, 0, -18 }, RightShoulder = { 120, 0, 18 } } },
		{ t = 0.95, root = { y = 1.4 }, j = UP },
		{ t = 1.25, j = { LeftShoulder = { 60 }, RightShoulder = { 60 } } },
		{ t = 1.5 },
	},
}
list.fidget = {
	act = "shifts from foot to foot",
	keys = {
		{ t = 0 },
		{ t = 0.37, root = { side = 0.16, turn = 5 } },
		{ t = 1.0, root = { side = -0.16, turn = -5 } },
		{ t = 1.6, root = { side = 0.16, turn = 6 } },
		{ t = 2.2, root = { side = -0.12, turn = -4 } },
		{ t = 2.6 },
	},
}
list.stomp = {
	act = "stamps a foot",
	keys = {
		{ t = 0 },
		{ t = 0.2, j = { RightHip = { 40 }, RightKnee = { -50 }, Waist = { -6 } } },
		{
			t = 0.34,
			root = { y = -0.05 },
			j = { Waist = { -8 }, LeftShoulder = { -10, 0, -14 }, RightShoulder = { -10, 0, 14 } },
		},
		{ t = 0.55, j = { LeftHip = { 40 }, LeftKnee = { -50 }, Waist = { -6 } } },
		{
			t = 0.7,
			root = { y = -0.05 },
			j = { Waist = { -8 }, LeftShoulder = { -10, 0, -14 }, RightShoulder = { -10, 0, 14 } },
		},
		{ t = 1.0 },
	},
}
list.sway = {
	act = "sways, happy",
	loop = 2.86,
	keys = {
		{ t = 0 },
		{ t = 0.71, root = { roll = 4 }, j = { Neck = { 0, 0, -4 } } },
		{ t = 2.14, root = { roll = -4 }, j = { Neck = { 0, 0, 4 } } },
		{ t = 2.86 },
	},
}
list.spin = {
	act = "turns round on the spot",
	keys = { { t = 0 }, { t = 0.6, root = { turn = 180 } }, { t = 1.2, root = { turn = 360 } } },
}
list.kneel = {
	act = "goes down on one knee",
	hold = true,
	keys = {
		{ t = 0 },
		{
			t = 0.5,
			root = { y = -0.5 },
			j = { RightHip = { 86 }, RightKnee = { -86 }, LeftHip = { -9 }, LeftKnee = { -83 }, LeftAnkle = { 30 } },
		},
	},
}
list.hug = {
	act = "steps in for a hug",
	keys = {
		{ t = 0 },
		{
			t = 0.9,
			root = { fwd = 0.9 },
			j = {
				Waist = { -11 },
				LeftShoulder = { 72, 0, 10 },
				RightShoulder = { 72, 0, -10 },
				LeftElbow = { 40 },
				RightElbow = { 40 },
			},
		},
		{
			t = 1.6,
			root = { fwd = 0.9 },
			j = {
				Waist = { -11 },
				LeftShoulder = { 72, 0, 10 },
				RightShoulder = { 72, 0, -10 },
				LeftElbow = { 40 },
				RightElbow = { 40 },
			},
		},
		{ t = 2.4 },
	},
}

-- New for the cutscenes -------------------------------------------------------------------------------

-- running: leaning in, arms pumping, legs going
local RUN = {
	Waist = { -14 },
	Neck = { 8 },
	RightHip = { 58 },
	RightKnee = { -40 },
	LeftHip = { -30 },
	LeftKnee = { -86 },
	LeftAnkle = { -20 },
	RightShoulder = { -42 },
	RightElbow = { 84 },
	LeftShoulder = { 56 },
	LeftElbow = { 92 },
}
list.run = {
	act = "runs",
	loop = 0.52,
	keys = {
		{ t = 0, j = RUN, root = { y = 0.05 } },
		{
			t = 0.13,
			j = { Waist = { -14 }, Neck = { 8 }, LeftKnee = { -60 }, RightKnee = { -60 } },
			root = { y = 0.35 },
		},
		{ t = 0.26, j = mirror(RUN), root = { y = 0.05 } },
		{
			t = 0.39,
			j = { Waist = { -14 }, Neck = { 8 }, LeftKnee = { -60 }, RightKnee = { -60 } },
			root = { y = 0.35 },
		},
		{ t = 0.52, j = RUN, root = { y = 0.05 } },
	},
}
-- down at the start line, one foot back, ready to go
list.ready = {
	act = "gets down at the start line",
	hold = true,
	keys = {
		{ t = 0 },
		{
			t = 0.5,
			root = { y = 0.05 },
			j = {
				Waist = { -34 },
				Neck = { 22 },
				LeftHip = { 62 },
				LeftKnee = { -86 },
				RightHip = { -6 },
				RightKnee = { -40 },
				RightShoulder = { -34 },
				RightElbow = { 60 },
				LeftShoulder = { 52 },
				LeftElbow = { 50 },
			},
		},
	},
}
-- bent over with their hands on their knees, puffing
local PANT = {
	Waist = { -40 },
	Neck = { 22 },
	LeftHip = { 16 },
	RightHip = { 16 },
	LeftKnee = { -26 },
	RightKnee = { -26 },
	LeftShoulder = { 52, 0, 8 },
	RightShoulder = { 52, 0, -8 },
	LeftElbow = { 6 },
	RightElbow = { 6 },
}
local PANT2 = table.clone(PANT)
PANT2.Waist = { -34 }
PANT2.Neck = { 18 }
list.pant = {
	act = "puffs with their hands on their knees",
	loop = 0.9,
	keys = {
		{ t = 0, j = PANT, root = { y = 0.03 } },
		{ t = 0.45, j = PANT2, root = { y = 0.03 } },
		{ t = 0.9, j = PANT, root = { y = 0.03 } },
	},
}
-- pointing high up at the sky
list.pointup = {
	act = "points up at the sky",
	hold = true,
	keys = {
		{ t = 0 },
		{ t = 0.45, j = { RightShoulder = { 158, 0, 10 }, RightElbow = { 4 }, Neck = { 22 }, Waist = { 4 } } },
	},
}
-- lying on their back (a mark's pose: on the grass, in bed)
local LIE = {
	Neck = { -14 },
	LeftShoulder = { 0, 0, -16 },
	RightShoulder = { 0, 0, 16 },
	LeftElbow = { 10 },
	RightElbow = { 10 },
	LeftHip = { 4 },
	RightHip = { 4 },
}
local LIE2 = table.clone(LIE)
LIE2.Waist = { 2 }
list.lie = {
	act = "lies on their back",
	loop = 4,
	keys = {
		{ t = 0, j = LIE, root = { y = -2.45, pitch = 90 } },
		{ t = 2, j = LIE2, root = { y = -2.42, pitch = 90 } },
		{ t = 4, j = LIE, root = { y = -2.45, pitch = 90 } },
	},
}
-- lying down and pointing straight up at the sky (an act for someone lying down)
list.pointsky = {
	act = "points at the sky from where they lie",
	hold = true,
	keys = {
		{ t = 0 },
		{ t = 0.45, j = { RightShoulder = { 92, 0, 8 }, RightElbow = { 2 }, Neck = { -4 } } },
	},
}
-- sitting on the ground, legs out in front, leaning back on their hands
list.sitground = {
	act = "sits on the ground",
	loop = 4,
	keys = {
		{
			t = 0,
			root = { y = -0.93, fwd = -0.2 },
			j = {
				Waist = { 8 },
				LeftHip = { 82 },
				RightHip = { 82 },
				LeftKnee = { -14 },
				RightKnee = { -22 },
				LeftShoulder = { -34, 0, -10 },
				RightShoulder = { -34, 0, 10 },
			},
		},
		{
			t = 2,
			root = { y = -0.93, fwd = -0.2 },
			j = {
				Waist = { 10 },
				Neck = { 4 },
				LeftHip = { 82 },
				RightHip = { 82 },
				LeftKnee = { -14 },
				RightKnee = { -22 },
				LeftShoulder = { -34, 0, -10 },
				RightShoulder = { -34, 0, 10 },
			},
		},
		{
			t = 4,
			root = { y = -0.93, fwd = -0.2 },
			j = {
				Waist = { 8 },
				LeftHip = { 82 },
				RightHip = { 82 },
				LeftKnee = { -14 },
				RightKnee = { -22 },
				LeftShoulder = { -34, 0, -10 },
				RightShoulder = { -34, 0, 10 },
			},
		},
	},
}
-- sitting up in bed out of a dream (from lying down)
list.situp = {
	act = "sits bolt upright",
	hold = true,
	keys = {
		{ t = 0, j = LIE, root = { y = -2.45, pitch = 90 } },
		{
			t = 0.35,
			root = { y = -1.26, pitch = 0, fwd = -0.2 },
			j = {
				Waist = { -4 },
				Neck = { 6 },
				LeftHip = { 86 },
				RightHip = { 86 },
				LeftKnee = { -6 },
				RightKnee = { -6 },
				LeftShoulder = { 40, 0, -40 },
				RightShoulder = { 40, 0, 40 },
				LeftElbow = { 30 },
				RightElbow = { 30 },
			},
		},
		{
			t = 1.1,
			root = { y = -1.26, pitch = 0, fwd = -0.2 },
			j = {
				Waist = { -10 },
				Neck = { -4, 14 },
				LeftHip = { 86 },
				RightHip = { 86 },
				LeftKnee = { -6 },
				RightKnee = { -6 },
				LeftShoulder = { 10, 0, -10 },
				RightShoulder = { 60 },
				RightElbow = { 120 },
			},
		},
	},
}
-- sitting on a seat (`at` on a mark that sits is the seat's top)
list.sit = {
	act = "sits",
	hold = true,
	keys = {
		{
			t = 0,
			root = { y = -1.5, fwd = -0.2 },
			j = {
				LeftHip = { 88 },
				RightHip = { 88 },
				LeftKnee = { -88 },
				RightKnee = { -88 },
				LeftShoulder = { 14, 0, -4 },
				RightShoulder = { 14, 0, 4 },
				LeftElbow = { 30 },
				RightElbow = { 30 },
			},
		},
	},
}
-- crouched down low
local CROUCH = {
	Waist = { -24 },
	Neck = { -12 },
	LeftHip = { 72 },
	RightHip = { 50 },
	LeftKnee = { -118 },
	RightKnee = { -110 },
	LeftAnkle = { 36 },
	RightAnkle = { 50 },
	LeftShoulder = { 24 },
	RightShoulder = { 24 },
	LeftElbow = { 30 },
	RightElbow = { 30 },
}
list.crouch = {
	act = "crouches down",
	hold = true,
	keys = { { t = 0 }, { t = 0.45, j = CROUCH, root = { y = -0.52, fwd = -0.15 } } },
}
-- crouched, stroking something on the ground in front of them
local PET = table.clone(CROUCH)
PET.RightShoulder = { 56 }
PET.RightElbow = { 22 }
PET.Neck = { -24 }
local PET2 = table.clone(PET)
PET2.RightShoulder = { 70 }
PET2.RightElbow = { 6 }
list.pet = {
	act = "strokes something on the ground",
	loop = 1.3,
	keys = {
		{ t = 0, j = PET, root = { y = -0.52, fwd = -0.15 } },
		{ t = 0.65, j = PET2, root = { y = -0.52, fwd = -0.1 } },
		{ t = 1.3, j = PET, root = { y = -0.52, fwd = -0.15 } },
	},
}
-- leaning round to look behind something
list.peek = {
	act = "leans round to look",
	hold = true,
	keys = {
		{ t = 0 },
		{
			t = 0.9,
			root = { side = 0.45, roll = -6 },
			j = {
				Waist = { -6, -8, -16 },
				Neck = { -4, -10, -12 },
				LeftShoulder = { 36, 0, -14 },
				LeftElbow = { 70 },
				RightShoulder = { 10, 0, 30 },
				LeftHip = { 0, 0, 8 },
			},
		},
	},
}
-- a jolt of surprise: arms flung out, a little jump back
list.startle = {
	act = "jumps back in surprise",
	keys = {
		{ t = 0 },
		{
			t = 0.14,
			root = { y = 0.45, fwd = -0.5 },
			j = {
				Waist = { 10 },
				Neck = { 12 },
				LeftShoulder = { 70, 0, -70 },
				RightShoulder = { 70, 0, 70 },
				LeftElbow = { 40 },
				RightElbow = { 40 },
			},
		},
		{
			t = 0.6,
			root = { fwd = -0.5 },
			j = {
				Waist = { 6 },
				LeftShoulder = { 50, 0, -40 },
				RightShoulder = { 50, 0, 40 },
				LeftElbow = { 60 },
				RightElbow = { 60 },
			},
		},
		{ t = 1.4, root = { fwd = -0.5 } },
	},
}
-- tapping away at buttons on a desk in front of them
local TYPE = {
	Waist = { -8 },
	Neck = { -12 },
	LeftShoulder = { 44, 0, 6 },
	RightShoulder = { 44, 0, -6 },
	LeftElbow = { 54 },
	RightElbow = { 40 },
}
local TYPE2 = table.clone(TYPE)
TYPE2.LeftElbow = { 40 }
TYPE2.RightElbow = { 56 }
TYPE2.Neck = { -10, 8 }
list.type = {
	act = "taps at the buttons",
	loop = 0.5,
	keys = { { t = 0, j = TYPE }, { t = 0.25, j = TYPE2 }, { t = 0.5, j = TYPE } },
}
-- shaking with fright, arms held in tight
local SHIVER = {
	Neck = { -8 },
	LeftShoulder = { 34, 0, 16 },
	RightShoulder = { 34, 0, -16 },
	LeftElbow = { 110 },
	RightElbow = { 110 },
	LeftKnee = { -10 },
	RightKnee = { -10 },
}
list.shiver = {
	act = "shakes like a leaf",
	loop = 0.18,
	keys = {
		{ t = 0, j = SHIVER, root = { side = -0.05, y = 0.07 } },
		{ t = 0.09, j = SHIVER, root = { side = 0.05, y = 0.07 } },
		{ t = 0.18, j = SHIVER, root = { side = -0.05, y = 0.07 } },
	},
}
-- arms up over their face
list.cower = {
	act = "cowers behind their arms",
	hold = true,
	keys = {
		{ t = 0 },
		{
			t = 0.3,
			root = { y = 0.06, fwd = -0.2 },
			j = {
				Waist = { -16 },
				Neck = { -18 },
				LeftShoulder = { 118, 0, 10 },
				RightShoulder = { 118, 0, -10 },
				LeftElbow = { 104 },
				RightElbow = { 104 },
				LeftKnee = { -24 },
				RightKnee = { -24 },
				LeftHip = { 12 },
				RightHip = { 12 },
			},
		},
	},
}
-- pulling a face: fingers in the cheeks, head waggling
local FACE = {
	LeftShoulder = { 120, 0, -34 },
	RightShoulder = { 120, 0, 34 },
	LeftElbow = { 142 },
	RightElbow = { 142 },
	Neck = { 6, 10, 8 },
	Waist = { 3 },
}
local FACE2 = table.clone(FACE)
FACE2.Neck = { 2, -10, -10 }
FACE2.Waist = { 3, 0, 3 }
list.facepull = {
	act = "pulls a face",
	loop = 0.8,
	keys = {
		{ t = 0, j = FACE },
		{ t = 0.4, j = FACE2 },
		{ t = 0.8, j = FACE },
	},
}
-- eating as fast as they can: hand to mouth and back, head down to the plate
local EAT = {
	Waist = { -16 },
	Neck = { -16 },
	RightShoulder = { 70, 0, -6 },
	RightElbow = { 80 },
	LeftShoulder = { 40, 0, 6 },
	LeftElbow = { 60 },
}
local EAT2 = table.clone(EAT)
EAT2.RightShoulder = { 100, 0, -16 }
EAT2.RightElbow = { 140 }
EAT2.Neck = { -4 }
list.eat = {
	act = "eats as fast as they can",
	loop = 0.46,
	keys = { { t = 0, j = EAT }, { t = 0.23, j = EAT2 }, { t = 0.46, j = EAT } },
}
-- a play fight: a jab with one hand, then the other, guard up
local GUARD = {
	Waist = { -6, 14 },
	Neck = { 0, -10 },
	LeftShoulder = { 80, 0, 10 },
	RightShoulder = { 70, 0, -16 },
	LeftElbow = { 110 },
	RightElbow = { 120 },
	LeftHip = { 20 },
	LeftKnee = { -20 },
	RightHip = { -8 },
	RightKnee = { -14 },
}
local JAB = table.clone(GUARD)
JAB.RightShoulder = { 92, 0, -4 }
JAB.RightElbow = { 4 }
JAB.Waist = { -8, -10 }
local JAB2 = table.clone(GUARD)
JAB2.LeftShoulder = { 92, 0, 4 }
JAB2.LeftElbow = { 4 }
JAB2.Waist = { -8, 22 }
list.spar = {
	act = "throws a play punch",
	loop = 1.2,
	keys = {
		{ t = 0, j = GUARD, root = { y = 0.1 } },
		{ t = 0.18, j = JAB, root = { y = 0.1, fwd = 0.3 } },
		{ t = 0.45, j = GUARD, root = { y = 0.1 } },
		{ t = 0.75, j = JAB2, root = { y = 0.1, fwd = 0.3 } },
		{ t = 1.0, j = GUARD, root = { y = 0.1 } },
		{ t = 1.2, j = GUARD, root = { y = 0.1 } },
	},
}
-- both hands thrust out in front, a big glowing push
list.blast = {
	act = "pushes both hands out",
	hold = true,
	keys = {
		{ t = 0, j = GUARD, root = { y = 0.1 } },
		{
			t = 0.25,
			root = { y = 0.03, fwd = -0.2 },
			j = {
				Waist = { -10 },
				Neck = { 4 },
				LeftShoulder = { 70, -10, 20 },
				RightShoulder = { 70, 10, -20 },
				LeftElbow = { 120 },
				RightElbow = { 120 },
				LeftHip = { 30 },
				LeftKnee = { -40 },
				RightHip = { -20 },
				RightKnee = { -20 },
			},
		},
		{
			t = 0.55,
			root = { y = 0.02, fwd = 0.35 },
			j = {
				Waist = { -14 },
				Neck = { 4 },
				LeftShoulder = { 90, 0, 4 },
				RightShoulder = { 90, 0, -4 },
				LeftElbow = { 2 },
				RightElbow = { 2 },
				LeftWrist = { 60 },
				RightWrist = { 60 },
				LeftHip = { 40 },
				LeftKnee = { -50 },
				RightHip = { -24 },
				RightKnee = { -10 },
			},
		},
	},
}
-- push ups: face down, arms straight, then bent
local UPP = {
	Neck = { 30 },
	LeftShoulder = { 82, 0, -8 },
	RightShoulder = { 82, 0, 8 },
	LeftElbow = { 4 },
	RightElbow = { 4 },
	LeftAnkle = { 50 },
	RightAnkle = { 50 },
}
local DOWNP = {
	Neck = { 40 },
	LeftShoulder = { 40, 0, -30 },
	RightShoulder = { 40, 0, 30 },
	LeftElbow = { 96 },
	RightElbow = { 96 },
	LeftAnkle = { 64 },
	RightAnkle = { 64 },
}
list.pushup = {
	act = "does push ups",
	loop = 1.3,
	keys = {
		{ t = 0, j = UPP, root = { pitch = -72, y = -1.0, fwd = 0.7 } },
		{ t = 0.65, j = DOWNP, root = { pitch = -82, y = -1.4, fwd = 0.85 } },
		{ t = 1.3, j = UPP, root = { pitch = -72, y = -1.0, fwd = 0.7 } },
	},
}
-- an ear to the door, a hand cupped round it
list.listen = {
	act = "listens hard",
	hold = true,
	keys = {
		{ t = 0 },
		{
			t = 0.6,
			root = { fwd = 0.25 },
			j = {
				Waist = { -10, 0, 12 },
				Neck = { -4, 0, 18 },
				LeftShoulder = { 118, 0, -40 },
				LeftElbow = { 128 },
				RightShoulder = { 14, 0, 6 },
			},
		},
	},
}
-- clapping
local CLAP = { LeftShoulder = { 58, 0, 26 }, RightShoulder = { 58, 0, -26 }, LeftElbow = { 62 }, RightElbow = { 62 } }
local CLAP2 = { LeftShoulder = { 58, 0, 6 }, RightShoulder = { 58, 0, -6 }, LeftElbow = { 70 }, RightElbow = { 70 } }
list.clap = {
	act = "claps",
	loop = 0.36,
	keys = { { t = 0, j = CLAP }, { t = 0.18, j = CLAP2 }, { t = 0.36, j = CLAP } },
}
-- a hand at their chin, thinking it over
list.think = {
	act = "thinks it over",
	hold = true,
	keys = {
		{ t = 0 },
		{
			t = 0.5,
			j = {
				RightShoulder = { 68, 0, -24 },
				RightElbow = { 132 },
				LeftShoulder = { 30, 0, 22 },
				LeftElbow = { 80 },
				Neck = { -6, 0, 9 },
			},
		},
	},
}
-- a shrug
list.shrug = {
	act = "shrugs",
	keys = {
		{ t = 0 },
		{
			t = 0.35,
			root = { y = 0.08 },
			j = {
				LeftShoulder = { 20, 0, -22 },
				RightShoulder = { 20, 0, 22 },
				LeftElbow = { 84 },
				RightElbow = { 84 },
				Neck = { 0, 0, 12 },
			},
		},
		{
			t = 0.75,
			root = { y = 0.08 },
			j = {
				LeftShoulder = { 20, 0, -22 },
				RightShoulder = { 20, 0, 22 },
				LeftElbow = { 84 },
				RightElbow = { 84 },
				Neck = { 0, 0, 12 },
			},
		},
		{ t = 1.1 },
	},
}
-- a big stretch, both arms up, after a sleep or a long ride
list.stretch = {
	act = "stretches",
	keys = {
		{ t = 0 },
		{
			t = 0.7,
			root = { y = 0.15 },
			j = { LeftShoulder = { 172, 0, -12 }, RightShoulder = { 172, 0, 12 }, Waist = { 8 }, Neck = { 20 } },
		},
		{
			t = 1.5,
			root = { y = 0.15 },
			j = { LeftShoulder = { 176, 0, -6 }, RightShoulder = { 176, 0, 6 }, Waist = { 10, 0, 6 }, Neck = { 22 } },
		},
		{ t = 2.2 },
	},
}
-- floating in a dream: arms out, legs trailing, rising and sinking
local FLOAT = {
	LeftShoulder = { 10, 0, -64 },
	RightShoulder = { 10, 0, 64 },
	LeftElbow = { 14 },
	RightElbow = { 14 },
	LeftHip = { 10 },
	RightHip = { -8 },
	LeftKnee = { -30 },
	RightKnee = { -18 },
	LeftAnkle = { -20 },
	RightAnkle = { -20 },
	Neck = { 8 },
}
local FLOAT2 = table.clone(FLOAT)
FLOAT2.LeftShoulder = { 10, 0, -76 }
FLOAT2.RightShoulder = { 10, 0, 76 }
FLOAT2.LeftHip = { -6 }
FLOAT2.RightHip = { 12 }
list.float = {
	act = "floats",
	loop = 3.2,
	keys = {
		{ t = 0, j = FLOAT, root = { y = 0.5, roll = 3 } },
		{ t = 1.6, j = FLOAT2, root = { y = 1.1, roll = -3 } },
		{ t = 3.2, j = FLOAT, root = { y = 0.5, roll = 3 } },
	},
}
-- a fist in the air, again and again
list.celebrate = {
	act = "pumps a fist",
	loop = 0.6,
	keys = {
		{
			t = 0,
			j = { RightShoulder = { 150, 0, 14 }, RightElbow = { 40 }, LeftShoulder = { 20, 0, -12 }, Neck = { 12 } },
		},
		{
			t = 0.3,
			root = { y = 0.22 },
			j = { RightShoulder = { 176, 0, 10 }, RightElbow = { 0 }, LeftShoulder = { 30, 0, -16 }, Neck = { 18 } },
		},
		{
			t = 0.6,
			j = { RightShoulder = { 150, 0, 14 }, RightElbow = { 40 }, LeftShoulder = { 20, 0, -12 }, Neck = { 12 } },
		},
	},
}
-- sitting up straight on a throne, chin up, a slow wave
local REGAL = {
	Neck = { 12 },
	Waist = { 4 },
	RightShoulder = { 70, 0, 24 },
	RightElbow = { 70 },
	LeftShoulder = { 26, 0, -14 },
	LeftElbow = { 50 },
}
local REGAL2 = table.clone(REGAL)
REGAL2.RightShoulder = { 82, -10, 30 }
REGAL2.RightWrist = { 0, 0, 30 }
list.regal = {
	act = "waves like royalty",
	loop = 1.8,
	keys = { { t = 0, j = REGAL }, { t = 0.9, j = REGAL2 }, { t = 1.8, j = REGAL } },
}
-- a little dance of their own: a step side to side, arms swinging, a bounce
local SHUF = {
	Waist = { 0, 10, 4 },
	Neck = { 0, -6, -6 },
	LeftShoulder = { 60, 0, -20 },
	LeftElbow = { 90 },
	RightShoulder = { -20, 0, 20 },
	RightElbow = { 60 },
	LeftHip = { 24 },
	LeftKnee = { -40 },
	RightKnee = { -10 },
}
list.shuffle = {
	act = "dances a little shuffle",
	loop = 1.0,
	keys = {
		{ t = 0, j = SHUF, root = { side = -0.25, y = 0.08, roll = 4 } },
		{ t = 0.25, j = { Waist = { 0, 0, 0 }, LeftKnee = { -16 }, RightKnee = { -16 } }, root = { y = 0.1 } },
		{ t = 0.5, j = mirror(SHUF), root = { side = 0.25, y = 0.08, roll = -4 } },
		{ t = 0.75, j = { Waist = { 0, 0, 0 }, LeftKnee = { -16 }, RightKnee = { -16 } }, root = { y = 0.1 } },
		{ t = 1.0, j = SHUF, root = { side = -0.25, y = 0.08, roll = 4 } },
	},
}
-- holding on to something in front of them (a seesaw's handle, a rail)
list.hold = {
	act = "holds on tight",
	hold = true,
	keys = {
		{ t = 0 },
		{
			t = 0.3,
			j = {
				LeftShoulder = { 62, 0, 10 },
				RightShoulder = { 62, 0, -10 },
				LeftElbow = { 50 },
				RightElbow = { 50 },
			},
		},
	},
}
-- singing into a hairbrush, swaying
local SING = {
	RightShoulder = { 96, 0, -20 },
	RightElbow = { 128 },
	LeftShoulder = { 40, 0, -60 },
	LeftElbow = { 20 },
	Neck = { 14 },
	Waist = { 6 },
}
local SING2 = table.clone(SING)
SING2.LeftShoulder = { 70, 0, -70 }
SING2.Neck = { 20, 0, -8 }
SING2.Waist = { 8, 0, -4 }
list.sing = {
	act = "sings into a hairbrush",
	loop = 1.4,
	keys = {
		{ t = 0, j = SING, root = { roll = 3 } },
		{ t = 0.7, j = SING2, root = { roll = -3, y = 0.06 } },
		{ t = 1.4, j = SING, root = { roll = 3 } },
	},
}
-- waving someone over
local COME = { RightShoulder = { 76, 0, -6 }, RightElbow = { 24 }, Neck = { 4 } }
list.beckon = {
	act = "waves them over",
	loop = 0.8,
	keys = {
		{ t = 0, j = COME },
		{ t = 0.4, j = { RightShoulder = { 82, 0, -6 }, RightElbow = { 104 }, Neck = { 4 } } },
		{ t = 0.8, j = COME },
	},
}
-- slumped, bored stiff
list.slump = {
	act = "slumps, bored",
	hold = true,
	keys = {
		{ t = 0 },
		{
			t = 0.8,
			j = {
				Waist = { -14, 0, 6 },
				Neck = { -20, 0, 12 },
				LeftShoulder = { 0, 0, 8 },
				RightShoulder = { 0, 0, -8 },
			},
		},
	},
}

-- Sampling ---------------------------------------------------------------------------------------------

local function smooth(k: number): number
	k = math.clamp(k, 0, 1)
	return k * k * (3 - 2 * k)
end

local NONE = { 0, 0, 0 }
local ROOTS = { "y", "fwd", "side", "pitch", "roll", "turn" }

-- The joint turns and the body's place at `t` seconds into a move: joints as { [name] = { x, y,
-- z } } in degrees, the root as { y, fwd, side, pitch, roll, turn }, and whether a move that
-- plays once is over. An unknown move is a body at rest, and over.
function Moves.sample(name: string?, t: number): ({ [string]: { number } }, { [string]: number }, boolean)
	local m = name and list[name]
	local root: { [string]: number } = {}
	if not m then
		return {}, root, true
	end
	local keys = m.keys
	local last = keys[#keys]
	local done = false
	if m.loop then
		t = t % m.loop
	elseif t >= last.t then
		t = last.t
		done = not m.hold
	end
	local a, b = keys[1], keys[1]
	for i = 1, #keys - 1 do
		if t >= keys[i].t and t <= keys[i + 1].t then
			a, b = keys[i], keys[i + 1]
			break
		end
	end
	if t >= last.t then
		a, b = last, last
	end
	local span = b.t - a.t
	local k = if span > 1e-6 then smooth((t - a.t) / span) else 0
	local joints: { [string]: { number } } = {}
	local ja: { [string]: { number } } = a.j or {}
	local jb: { [string]: { number } } = b.j or {}
	local names: { [string]: boolean } = {}
	for n in ja do
		names[n] = true
	end
	for n in jb do
		names[n] = true
	end
	for n in names do
		local p, q = ja[n] or NONE, jb[n] or NONE
		joints[n] = {
			(p[1] or 0) + ((q[1] or 0) - (p[1] or 0)) * k,
			(p[2] or 0) + ((q[2] or 0) - (p[2] or 0)) * k,
			(p[3] or 0) + ((q[3] or 0) - (p[3] or 0)) * k,
		}
	end
	local ra: { [string]: number } = (a.root or {}) :: any
	local rb: { [string]: number } = (b.root or {}) :: any
	for _, key in ROOTS do
		local p, q = ra[key] or 0, rb[key] or 0
		if p ~= 0 or q ~= 0 then
			root[key] = p + (q - p) * k
		end
	end
	return joints, root, done
end

-- A joint's turn as a CFrame (to multiply into its C0).
function Moves.turn(a: { number }): CFrame
	return CFrame.Angles(math.rad(a[1] or 0), math.rad(a[2] or 0), math.rad(a[3] or 0))
end

-- Where the body's middle goes for a root, from where it stands (its middle `lift` over its feet,
-- facing -Z in `frame`'s space): the frame for its HumanoidRootPart. `scale` is the body's hip
-- height over Moves.Hips.
function Moves.place(frame: CFrame, root: { [string]: number }, scale: number?): CFrame
	local k = scale or 1
	local offset = CFrame.new((root.side or 0) * k, (root.y or 0) * k, -(root.fwd or 0) * k)
	return frame
		* offset
		* CFrame.Angles(0, math.rad(root.turn or 0), 0)
		* CFrame.Angles(math.rad(root.pitch or 0), 0, math.rad(root.roll or 0))
end

-- Mixes a move over a base one (a mark's pose): the move's joints replace the base's, and its
-- root replaces the base's when it has one.
function Moves.over(
	baseJ: { [string]: { number } },
	baseR: { [string]: number },
	j: { [string]: { number } },
	r: { [string]: number }
): ({ [string]: { number } }, { [string]: number })
	local joints = table.clone(baseJ)
	for n, a in j do
		joints[n] = a
	end
	local root = if next(r) ~= nil then r else baseR
	return joints, root
end

-- A plain blocky R15 body for the previews: each part's size and its joint (the parent, the
-- joint's place on the parent, C0, and on the part, C1), as a standard R15 body has them with a
-- hip height of 2. The HumanoidRootPart's middle is 3 over the feet.
Moves.Body = {
	{
		name = "LowerTorso",
		size = Vector3.new(2, 0.4, 1),
		parent = "HumanoidRootPart",
		joint = "Root",
		c0 = Vector3.new(0, -1, 0),
		c1 = Vector3.new(0, -0.2, 0),
	},
	{
		name = "UpperTorso",
		size = Vector3.new(2, 1.6, 1),
		parent = "LowerTorso",
		joint = "Waist",
		c0 = Vector3.new(0, 0.2, 0),
		c1 = Vector3.new(0, -0.8, 0),
	},
	{
		name = "Head",
		size = Vector3.new(1.2, 1.2, 1.2),
		parent = "UpperTorso",
		joint = "Neck",
		c0 = Vector3.new(0, 0.8, 0),
		c1 = Vector3.new(0, -0.6, 0),
	},
	{
		name = "RightUpperArm",
		size = Vector3.new(1, 1.2, 1),
		parent = "UpperTorso",
		joint = "RightShoulder",
		c0 = Vector3.new(1, 0.6, 0),
		c1 = Vector3.new(-0.5, 0.45, 0),
	},
	{
		name = "RightLowerArm",
		size = Vector3.new(1, 1, 1),
		parent = "RightUpperArm",
		joint = "RightElbow",
		c0 = Vector3.new(0, -0.5, 0),
		c1 = Vector3.new(0, 0.45, 0),
	},
	{
		name = "RightHand",
		size = Vector3.new(1, 0.3, 1),
		parent = "RightLowerArm",
		joint = "RightWrist",
		c0 = Vector3.new(0, -0.5, 0),
		c1 = Vector3.new(0, 0.15, 0),
	},
	{
		name = "LeftUpperArm",
		size = Vector3.new(1, 1.2, 1),
		parent = "UpperTorso",
		joint = "LeftShoulder",
		c0 = Vector3.new(-1, 0.6, 0),
		c1 = Vector3.new(0.5, 0.45, 0),
	},
	{
		name = "LeftLowerArm",
		size = Vector3.new(1, 1, 1),
		parent = "LeftUpperArm",
		joint = "LeftElbow",
		c0 = Vector3.new(0, -0.5, 0),
		c1 = Vector3.new(0, 0.45, 0),
	},
	{
		name = "LeftHand",
		size = Vector3.new(1, 0.3, 1),
		parent = "LeftLowerArm",
		joint = "LeftWrist",
		c0 = Vector3.new(0, -0.5, 0),
		c1 = Vector3.new(0, 0.15, 0),
	},
	{
		name = "RightUpperLeg",
		size = Vector3.new(1, 1, 1),
		parent = "LowerTorso",
		joint = "RightHip",
		c0 = Vector3.new(0.5, -0.2, 0),
		c1 = Vector3.new(0, 0.5, 0),
	},
	{
		name = "RightLowerLeg",
		size = Vector3.new(1, 0.8, 1),
		parent = "RightUpperLeg",
		joint = "RightKnee",
		c0 = Vector3.new(0, -0.5, 0),
		c1 = Vector3.new(0, 0.4, 0),
	},
	{
		name = "RightFoot",
		size = Vector3.new(1, 0.2, 1),
		parent = "RightLowerLeg",
		joint = "RightAnkle",
		c0 = Vector3.new(0, -0.4, 0),
		c1 = Vector3.new(0, 0.1, 0),
	},
	{
		name = "LeftUpperLeg",
		size = Vector3.new(1, 1, 1),
		parent = "LowerTorso",
		joint = "LeftHip",
		c0 = Vector3.new(-0.5, -0.2, 0),
		c1 = Vector3.new(0, 0.5, 0),
	},
	{
		name = "LeftLowerLeg",
		size = Vector3.new(1, 0.8, 1),
		parent = "LeftUpperLeg",
		joint = "LeftKnee",
		c0 = Vector3.new(0, -0.5, 0),
		c1 = Vector3.new(0, 0.4, 0),
	},
	{
		name = "LeftFoot",
		size = Vector3.new(1, 0.2, 1),
		parent = "LeftLowerLeg",
		joint = "LeftAnkle",
		c0 = Vector3.new(0, -0.4, 0),
		c1 = Vector3.new(0, 0.1, 0),
	},
}
Moves.Lift = 3 -- the HumanoidRootPart's middle over the feet

-- The parts of a plain body with its root at `root` and its joints turned: { [part] = CFrame },
-- the HumanoidRootPart included.
function Moves.figure(root: CFrame, joints: { [string]: { number } }): { [string]: CFrame }
	local at: { [string]: CFrame } = { HumanoidRootPart = root }
	for _, b in Moves.Body do
		local parent = at[b.parent]
		local a = joints[b.joint]
		local turn = if a then Moves.turn(a) else CFrame.identity
		at[b.name] = parent * CFrame.new(b.c0) * turn * CFrame.new(b.c1):Inverse()
	end
	return at
end

return Moves

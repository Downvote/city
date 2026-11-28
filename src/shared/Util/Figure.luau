--!strict
-- A plain blocky R15 body in a pose, for the specs and the previews (tools/preview): the parts of a
-- standard R15 body by their joints, as Roblox would place them. ThingModels' spec holds a thing in
-- its hand with it, and the previews draw a villager holding one. A pose gives, for each joint it
-- turns, its turn in degrees about the joint's own X, Y and Z (missing ones are 0), with the body
-- facing -Z: X a shoulder or a hip forward, an elbow bent; Y a turn to the body's left; Z the right
-- arm out to the side.

local Figure = {}

-- A joint's turn as a CFrame (to multiply into its C0).
function Figure.turn(a: { number }): CFrame
	return CFrame.Angles(math.rad(a[1] or 0), math.rad(a[2] or 0), math.rad(a[3] or 0))
end

-- A plain blocky R15 body for the previews: each part's size and its joint (the parent, the
-- joint's place on the parent, C0, and on the part, C1), as a standard R15 body has them with a
-- hip height of 2. The HumanoidRootPart's middle is 3 over the feet.
Figure.Body = {
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
Figure.Lift = 3 -- the HumanoidRootPart's middle over the feet

-- The parts of a plain body with its root at `root` and its joints turned: { [part] = CFrame },
-- the HumanoidRootPart included.
function Figure.figure(root: CFrame, joints: { [string]: { number } }): { [string]: CFrame }
	local at: { [string]: CFrame } = { HumanoidRootPart = root }
	for _, b in Figure.Body do
		local parent = at[b.parent]
		local a = joints[b.joint]
		local turn = if a then Figure.turn(a) else CFrame.identity
		at[b.name] = parent * CFrame.new(b.c0) * turn * CFrame.new(b.c1):Inverse()
	end
	return at
end

return Figure

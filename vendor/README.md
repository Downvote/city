# vendor

`SkinnedGrass.rbxm` is SkinnedGrass by xander_z22, from the Roblox developer forum post "SkinnedGrass:
performant interactive foliage" (https://devforum.roblox.com/t/skinnedgrass-performant-interactive-foliage/3364812).
The author says it's free to change and use in your own projects. Its Octree is Quenty's. The file is kept exactly
as it came: the place file mounts it at `ServerStorage.Vendor.SkinnedGrass`, and the server hands the clients a
copy without its two sample scripts (`World.shareGrass`). The game lays the patches in `client/World/Grass`.

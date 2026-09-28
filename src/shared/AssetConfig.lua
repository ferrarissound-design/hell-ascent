local Assets = {}

-- Creator Store assets selected for Layer One.
-- They are loaded through AssetService:LoadAssetAsync(), sanitized, anchored,
-- and stripped of all Lua source containers before being placed.
-- Every asset is optional; generated scenery remains if a load fails.
Assets.DeadTree = {
	id = 591112009,
	name = "CreatorDeadTree",
}

Assets.Skull = {
	id = 10834008239,
	name = "CreatorSkull",
}

Assets.Chain = {
	id = 9772738118,
	name = "CreatorChain",
}

Assets.Tombstone = {
	id = 491290309,
	name = "CreatorTombstone",
}

return Assets

unused_args = false
allow_defined_top = true

globals = {
	"telemosaic"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"minetest",
	"vector", "ItemStack",
	"dump",

	-- Deps
	"default",
	"digilines"
}

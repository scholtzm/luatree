# luatree

luatree is a Lua package for code analysis and inspection.

The goal of this package is to provide tools for analysis of syntax trees generated
by [luametrics](https://github.com/LuaDist/luametrics) and function call graphs
generated by [luadb](https://github.com/scholtzm/luadb) module.

Some of the functions require usage of [newer version of luametrics](https://github.com/simko/luametrics)
which is not available from LuaDist.

## Installation

luatree is distributed as a standalone luadist package.

1. `git clone https://github.com/scholtzm/luatree.git`
2. `/path/to/luadist /path/to/install/dir make luatree`

You can also manually copy the `luatree` folder from the `src` subfolder
into your `lib/lua` folder.

## Usage

Using luatree is pretty simple ...

```lua
local luatree = require("luatree")

local tree_a = luatree.ast.get_tree("local a")
local tree_b = luatree.ast.get_tree("local b")

luatree.ast.compare(tree_a, tree_b)

local changed_nodes = luatree.utils.get_tree_flag_count(tree_b, "modified")

print("A total of " .. changed_nodes .. " have changed in tree_b.")
```

Check different submodules to see what functions they export.
Do not forget to read the comments.

## Tests

luatree tests use [busted](http://olivinelabs.com/busted/) library for their core functionality.
Once you have this module installed, simply run the following command from the `src` directory:

```sh
$ busted
```

## License

MIT. See `LICENSE`.

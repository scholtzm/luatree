---------------------------------------------
-- Tests for dependency presence
-- @author: Michael Scholtz
---------------------------------------------

describe("dependencies test", function()
    it("luametrics is available", function()
        local luametrics = require("metrics")

        assert.is.truthy(luametrics)
    end)

    it("luadb is available", function()
        local extractor = require("luadb.extraction.functioncalls")
        local hypergraph = require("luadb.hypergraph")

        assert.is.truthy(extractor)
        assert.is.truthy(hypergraph)
    end)

    it("hypergraph is available", function()
        -- hypergraph implementation by Peter Kapec
        local hypergraph = require("hypergraph")

        assert.is.truthy(hypergraph)
    end)
end)

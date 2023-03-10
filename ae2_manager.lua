local MEB = peripheral.wrap("bottom")

local AO = "alltheores:"
local AC = "allthecompressed:"
local AE = "ae2:"
local CD = "createdeco:"
local ES = "exnihilosequentia:"
local FA = "forbidden_arcanus:"
local MA = "mysticalagriculture:"
local MC  = "minecraft:"
local TM = "thermal:"

local inv = {}

--[[
    Maintain a list of desired items to compress/decompress
]]

inv.compressing = {
    nine_by = {
        [MC.."coal_block"] = {
            item_1 = {name = MC.."coal", item_cnt = 9},
            total  = 9,
            output = 1,
            max    = 512
        },
        [MC.."copper_block"] = {
            item_1 = {name = MC.."copper_ingot", item_cnt = 9},
            total  = 9,
            output = 1,
            max    = 512
        },
        [MC.."iron_block"] = {
            item_1 = {name = MC.."iron_ingot", item_cnt = 9},
            total  = 9,
            output = 1,
            max    = 512
        },
        [MC.."lapis_block"]    = {
            item_1 = {name = MC.."lapis_lazuli", item_cnt = 9},
            total  = 9,
            output = 1,
            max    = 512
        },
        [MC.."gold_block"]     = {
            item_1 = {name = MC.."gold_ingot", item_cnt = 9},
            total  = 9,
            output = 1,
            max    = 512
        },
        [MC.."redstone_block"] = {
            item_1 = {name = MC.."redstone", item_cnt = 9},
            total  = 9,
            output = 1,
            max    = 512
        },
        [MC.."diamond_block"]  = {
            item_1 = {name = MC.."diamond", item_cnt = 9},
            total  = 9,
            output = 1,
            max    = 512
        },
        [MC.."emerald_block"]  = {
            item_1 = {name = MC.."emerald", item_cnt = 9},
            total  = 9,
            output = 1,
            max    = 512
        }
    }
}

inv.decompressing = {
    by_nine = {
        [MC.."coal"] = {
            item_1  = {name = MC.."coal_block", item_cnt = 1},
            total  = 1,
            output = 9,
            min    = 64,
            max    = 2048
        },
        [MC.."copper_ingot"] = {
            item_1 = {name = MC.."copper_block", item_cnt = 1},
            total  = 1,
            output = 9,
            min    = 64,
            max    = 2048
        },
        [MC.."iron_ingot"] = {
            item_1 = {name = MC.."iron_block", item_cnt = 1},
            total  = 1,
            output = 9,
            min    = 64,
            max    = 2048
        },
        [MC.."lapis"] = {
            item_1 = {name = MC.."lapis_block", item_cnt = 1},
            total  = 1,
            output = 9,
            min    = 64,
            max    = 2048
        },
        [MC.."gold_ingot"] = {
            item_1 = {name = MC.."gold_block", item_cnt = 1},
            total  = 1,
            output = 9,
            min    = 64,
            max    = 2048
        },
        [MC.."redstone"] = {
            item_1 = {name = MC.."redstone_block", item_cnt = 1},
            total  = 1,
            output = 9,
            min    = 64,
            max    = 2048
        },
        [MC.."diamond"] = {
            item_1 = {name = MC.."diamond_block", item_cnt = 1},
            total  = 1,
            output = 9,
            min    = 64,
            max    = 2048
        },
        [MC.."emerald"] = {
            item_1 = {name = MC.."emerald_block", item_cnt = 1},
            total  = 1,
            output = 9,
            min    = 64,
            max    = 2048
        }
    }
}

-- Compress when:
--  source count >= source min + compress cost and self count < self max

-- Decompress when:
--  self amount < self min and src_n count > 0

local compress = function(itemName)
    local storage_amnt = 0
    for i, v in pairs(MEB.getCraftingCPUs()) do
        storage_amnt = storage_amnt + v.storage
    end

    print("Storage Amount: "..storage_amnt)

    local item       = inv.compressing[itemName]
    local item_entry = MEB.getItem({name = itemName})
    local item_cnt   = item_entry and item_entry.amount or 0
    local item_max   = item.max

    local src_entry  = MEB.getItem({name = item.src_n})
    local src_cnt    = src_entry and src_entry.amount or 0
    local src_min    = inv.decompressing[item.src_n].min
    local src_cost   = item.src_cnt

    local byte_per_craft = 3 + src_cost

    if src_cnt >= src_min + src_cost and item_cnt < item_max then
        local craft_cnt = math.min(item_max - item_cnt, math.floor((src_cnt - src_min) / src_cost))
        print("Crafting "..craft_cnt.." "..itemName)

        local done = false

        while not done do
            if not MEB.isItemCrafting({name = itemName}) and craft_cnt > 0 then
                local craft_size = math.min(math.floor(storage_amnt / byte_per_craft) - 1, craft_cnt)
                print(itemName.." is not crafting.")
                local succ, err = MEB.craftItem({name = itemName, count = craft_size})

                if not succ then error(err) else print(craft_size.."x "..itemName.." craft job started.") end

                repeat os.sleep(1) until MEB.isItemCrafting({name = itemName})

                craft_cnt = craft_cnt - craft_size
            end

            done = craft_cnt == 0
        end
    else
        print("Cannot craft any "..itemName)
    end
end

local decompress = function(itemName)
    local storage_amnt = 0
    for i, v in pairs(MEB.getCraftingCPUs()) do
        storage_amnt = storage_amnt + v.storage
    end

    print("Storage Amount: "..storage_amnt)

    local item       = inv.decompressing[itemName]
    local item_entry = MEB.getItem({name = itemName})
    local item_cnt   = item_entry and item_entry.amount or 0
    local item_min   = item.min

    local src_entry  = MEB.getItem({name = item.src_n})
    local src_cnt    = src_entry and src_entry.amount or 0
    local src_yield  = inv.compressing[item.src_n].src_cnt

    if item_cnt < item_min and src_cnt > 0 then
        local craft_cnt = math.min(src_cnt, math.ceil((item_min - item_cnt) / src_yield))
        print("Crafting "..craft_cnt.." "..itemName)
        local succ, err = MEB.craftItem({name = itemName, count = craft_cnt})

        if not succ then print(err) else print("Should have crafted...") end
    else
        print("Cannot craft any "..itemName)
    end
end

local craftedFrom = function(itemName)
    if inv.compressing.nine_by.itemName then
        return inv.compressing.nine_by.itemName
    elseif inv.decompressing.by_nine then
        return inv.decompressing.by_nine.itemName
    end
end

local computeBytes = function(item)
    local recipe = craftedFrom(item.name)
    return 16 + (
        recipe.total +  -- Number of items in recipe
        1 +             -- Number of crafts required to produce item
        recipe.output   -- Number of items produced by craft
    ) * item.count
end

print(computeBytes({name = MC.."iron_block", count = 1}))
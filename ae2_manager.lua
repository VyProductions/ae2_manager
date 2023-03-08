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
    [MC.."coal_block"]     = { src_n = MC.."coal",         src_cnt = 9, max = 512 },
    [MC.."copper_block"]   = { src_n = MC.."copper_ingot", src_cnt = 9, max = 512 },
    [MC.."iron_block"]     = { src_n = MC.."iron_ingot",   src_cnt = 9, max = 512 },
    [MC.."lapis_block"]    = { src_n = MC.."lapis_lazuli", src_cnt = 9, max = 512 },
    [MC.."gold_block"]     = { src_n = MC.."gold_ingot",   src_cnt = 9, max = 512 },
    [MC.."redstone_block"] = { src_n = MC.."redstone",     src_cnt = 9, max = 512 },
    [MC.."diamond_block"]  = { src_n = MC.."diamond",      src_cnt = 9, max = 512 },
    [MC.."emerald_block"]  = { src_n = MC.."emerald",      src_cnt = 9, max = 512 }
}

inv.decompressing = {
    [MC.."coal"]         = { src_n = MC.."coal_block",    min = 64, max = 2048 },
    [MC.."copper_ingot"] = { src_n = MC.."copper_block",  min = 64, max = 2048 },
    [MC.."iron_ingot"]   = { src_n = MC.."iron_block",    min = 64, max = 2048 },
    [MC.."lapis"]        = { src_n = MC.."lapis_block",   min = 64, max = 2048 },
    [MC.."gold_ingot"]   = { src_n = MC.."gold_block",    min = 64, max = 2048 },
    [MC.."redstone"]     = { src_n = MC.."redston_block", min = 64, max = 2048 },
    [MC.."diamond"]      = { src_n = MC.."diamond_block", min = 64, max = 2048 },
    [MC.."emerald"]      = { src_n = MC.."emerald_block", min = 64, max = 2048 }
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

    local byte_per_craft = 2 + src_cost

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

if arg[1] == "C" then
    if inv.compressing[arg[2]] then
        compress(arg[2])
    else
        print("Invalid item to compress to: "..arg[2])
    end
elseif arg[1] == "D" then
    if inv.decompressing[arg[2]] then
        decompress(arg[2])
    else
        print("Invalid item to decompress to: "..arg[2])
    end
end
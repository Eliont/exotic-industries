-- commonly used functions for the mod

local ei_lib = {}

--====================================================================================================
--FUNCTION OVERIEW
--====================================================================================================

-- switch_string
-- config
-- getn
-- recipe_swap
-- recipe_swap_normal
-- recipe_swap_expensive
-- recipe_add
-- recipe_remove
-- recipe_new
-- add_prerequisite
-- remove_prerequisite
-- empty_sprite         

--====================================================================================================
--FUNCTIONS
--====================================================================================================

function ei_lib.table_contains_value(table_in, value)
    for i,v in pairs(table_in) do
        if v == value then
            return true
        end
    end
    return false
end

-- emulate switch-case in Lua for checking given string with a list of strings
-- retruns the matched element of the switch_table or nil if no match was found
-- switch_table = { ["string_condition"] = return vale, ... }

function ei_lib.switch_string(switch_table, string)
    
    -- retrun if no switch_table is given or no string is given
    if not switch_table or not string then
        return nil
    end

    -- loop over switch_table and check if string is in it
    for i,v in pairs(switch_table) do
        if string == i then
            return v
        end
    end

    -- return nil if no match was found
    return nil
end


-- quick access to startup settings
function ei_lib.config(name)
    return settings.startup["ei_"..name].value
end


-- count how many keys are in a table
function ei_lib.getn(table_in)
    local count = 0
    for _,_ in pairs(table_in) do
        count = count + 1
    end
    return count
end

--RECIPE RELATED
------------------------------------------------------------------------------------------------------

-- change ingredient in a recipe for another
function ei_lib.recipe_swap(recipe, old_ingredient, new_ingredient, amount)
    -- return if recipe or old_ingredient or new_ingredient is not given
    if not recipe or not old_ingredient or not new_ingredient then
        return
    end

    -- test if recipe exists in data.raw.recipe
    if not data.raw.recipe[recipe] then
        log("recipe "..recipe.." does not exist in data.raw.recipe")
        return
    end

    -- check if amount is given
    if not amount then
        
        -- if we got an amount of old_ingredient in the recipe
        -- set amount to that amount
        if data.raw.recipe[recipe].normal then
            for i,v in pairs(data.raw.recipe[recipe].normal.ingredients) do
                if v[1] == old_ingredient then
                    amount = v[2]
                end
            end
        else
            for i,v in pairs(data.raw.recipe[recipe].ingredients) do
                if v[1] == old_ingredient then
                    amount = v[2]
                end
            end
        end

        -- if amount is still nil, set it to 1
        if not amount then
            amount = 1
        end
    end

    -- check if there is a normal/expensive version of the recipe
    if data.raw.recipe[recipe].normal then

        -- loop over all ingredients of the recipe
        for i,v in pairs(data.raw.recipe[recipe].normal.ingredients) do

            -- if ingredient is found, replace it
            -- here first index is ingredient name, second index is amount
            if v[1] == old_ingredient then
                data.raw.recipe[recipe].normal.ingredients[i][1] = new_ingredient
                data.raw.recipe[recipe].normal.ingredients[i][2] = amount
            end

            ei_lib.fix_recipe(recipe, "normal")
        end

        if not data.raw.recipe[recipe].expensive then
            return
        end

        -- loop over all ingredients of the recipe
        for i,v in pairs(data.raw.recipe[recipe].expensive.ingredients) do

            -- if ingredient is found, replace it
            -- here first index is ingredient name, second index is amount
            if v[1] == old_ingredient then
                data.raw.recipe[recipe].expensive.ingredients[i][1] = new_ingredient
                data.raw.recipe[recipe].expensive.ingredients[i][2] = amount
            end

            ei_lib.fix_recipe(recipe, "expensive")
        end
    else
        -- loop over all ingredients of the recipe
        for i,v in pairs(data.raw.recipe[recipe].ingredients) do

            -- if ingredient is found, replace it
            -- here first index is ingredient name, second index is amount
            if v[1] == old_ingredient then
                data.raw.recipe[recipe].ingredients[i][1] = new_ingredient
                data.raw.recipe[recipe].ingredients[i][2] = amount
            end

            ei_lib.fix_recipe(recipe, nil)
        end
    end
end


-- fix recipes for multiple ingredients
function ei_lib.fix_recipe(recipe, mode)
    -- look if an ingredient is multiple times in the recipe, if so, add the amounts
    local ingredients = {}
    if not mode then
        if not data.raw.recipe[recipe].ingredients then
            return
        end

        if not data.raw.recipe[recipe].ingredients[1] then
            return
        end
        ingredients = data.raw.recipe[recipe].ingredients
    end

    if mode == "normal" then
        if not data.raw.recipe[recipe].normal then
            return
        end

        if not data.raw.recipe[recipe].normal.ingredients then
            return
        end

        if not data.raw.recipe[recipe].normal.ingredients[1] then
            return
        end
        ingredients = data.raw.recipe[recipe].normal.ingredients
    end

    if mode == "expensive" then
        if not data.raw.recipe[recipe].expensive then
            return
        end

        if not data.raw.recipe[recipe].expensive.ingredients then
            return
        end

        if not data.raw.recipe[recipe].expensive.ingredients[1] then
            return
        end
        ingredients = data.raw.recipe[recipe].expensive.ingredients
    end

    -- loop over all ingredients
    for i,v in ipairs(ingredients) do
        local total_amount = v[2] or v["amount"]
        for j,x in ipairs(ingredients) do
            -- exclude same index
            if i ~= j then

                -- if is entry for the same ingredient
                if (v["name"] == x["name"] and v["name"]) or (v[1] == x[1] and v[1]) then
                    if x["amount"] then
                        total_amount = total_amount + x["amount"]
                    else
                        total_amount = total_amount + x[2]
                    end
                    
                    if not mode then
                        table.remove(data.raw.recipe[recipe].ingredients, j)
                    end

                    if mode == "normal" then
                        table.remove(data.raw.recipe[recipe].normal.ingredients, j)
                    end

                    if mode == "expensive" then
                        table.remove(data.raw.recipe[recipe].expensive.ingredients, j)
                    end
                end
            end
        end
        if v[2] then
            v[2] = total_amount
        else
            v["amount"] = total_amount
        end
    end

end

-- add new ingredient in recipe
function ei_lib.recipe_add(recipe, ingredient, amount)
    -- amount is optional if not give default to 1
    if not amount then
        amount = 1
    end

    -- test if recipe exists in data.raw.recipe
    if not data.raw.recipe[recipe] then
        log("recipe "..recipe.." does not exist in data.raw.recipe")
        return
    end

    -- add ingredient to recipe
    table.insert(data.raw.recipe[recipe].ingredients, {ingredient, amount})
end


-- remove ingredient from recipe
function ei_lib.recipe_remove(recipe, ingredient)
    -- test if recipe exists in data.raw.recipe
    if not data.raw.recipe[recipe] then
        log("recipe "..recipe.." does not exist in data.raw.recipe")
        return
    end

    -- check if there is a normal/expensive version of the recipe
    if data.raw.recipe[recipe].normal then
        -- loop over all ingredients of the recipe
        for i,v in pairs(data.raw.recipe[recipe].normal.ingredients) do
        
            -- if ingredient is found, remove it
            -- here first index is ingredient name, second index is amount
            if v[1] == ingredient then
                table.remove(data.raw.recipe[recipe].normal.ingredients, i)
            end
        end

        -- loop over all ingredients of the recipe
        for i,v in pairs(data.raw.recipe[recipe].expensive.ingredients) do
        
            -- if ingredient is found, remove it
            -- here first index is ingredient name, second index is amount
            if v[1] == ingredient then
                table.remove(data.raw.recipe[recipe].expensive.ingredients, i)
            end
        end
    else
        -- loop over all ingredients of the recipe
        for i,v in pairs(data.raw.recipe[recipe].ingredients) do

            -- if ingredient is found, remove it
            -- here first index is ingredient name, second index is amount
            if v[1] == ingredient then
                table.remove(data.raw.recipe[recipe].ingredients, i)
            end
        end
    end
end


-- set a completly new set of ingredients for recipe
function ei_lib.recipe_new(recipe, table_in)
    -- test if recipe exists in data.raw.recipe
    if not data.raw.recipe[recipe] then
        log("recipe "..recipe.." does not exist in data.raw.recipe")
        return
    end

    -- check if there are normal/expensive variants of the recipe
    if data.raw.recipe[recipe].normal and data.raw.recipe[recipe].expensive then

        -- set normal ingredients
        data.raw.recipe[recipe].normal.ingredients = table_in
        -- set expensive ingredients
        data.raw.recipe[recipe].expensive.ingredients = table_in
    else
        -- set ingredients
        data.raw.recipe[recipe].ingredients = table_in
    end
end


--TECH RELATED
------------------------------------------------------------------------------------------------------

-- add new prerequisites for tech
function ei_lib.add_prerequisite(tech, prerequisite)
    -- check if tech exists in data.raw.technology
    if not data.raw.technology[tech] then
        log("tech "..tech.." does not exist in data.raw.technology")
        return
    end

    -- if this tech has no prerequisites, create an empty table
    if not data.raw.technology[tech].prerequisites then
        data.raw.technology[tech].prerequisites = {}
    end

    -- check if prerequisite is already in tech
    for i,v in ipairs(data.raw.technology[tech].prerequisites) do
        if v == prerequisite then
            log("tech "..tech.." already has prerequisite "..prerequisite..", skipping...")
            return
        end
    end

    -- add prerequisite to tech
    table.insert(data.raw.technology[tech].prerequisites, prerequisite)
end

-- remove prerequisite from tech
function ei_lib.remove_prerequisite(tech, prerequisite)
    -- check if tech exists in data.raw.technology
    if not data.raw.technology[tech] then
        log("tech "..tech.." does not exist in data.raw.technology")
        return
    end

    -- loop over all prerequisites of the tech
    for i,v in ipairs(data.raw.technology[tech].prerequisites) do

        -- if prerequisite is found, remove it
        if v == prerequisite then
            table.remove(data.raw.technology[tech].prerequisites, i)
        end
    end
end

-- remove a unlock recipe effect from tech
function ei_lib.remove_unlock_recipe(tech, recipe)
    -- check if tech exists in data.raw.technology
    if not data.raw.technology[tech] then
        log("tech "..tech.." does not exist in data.raw.technology")
        return
    end

    -- loop over all effects of the tech
    for i,v in ipairs(data.raw.technology[tech].effects) do

        -- if effect is found, remove it
        if v.type == "unlock-recipe" and v.recipe == recipe then
            table.remove(data.raw.technology[tech].effects, i)
        end
    end
end

--====================================================================================================
--GRAPHICS FUNCTIONS
--====================================================================================================

-- get path of 64x64 empty sprite from graphics mod
function ei_lib.empty_sprite(size)
    size = size or 64

    if size == 64 then
        return ei_graphics_path.."graphics/64_empty.png"
    end

    if size == 128 then
        return ei_graphics_path.."graphics/128_empty.png"
    end
    
    if size == 256 then
        return ei_graphics_path.."graphics/256_empty.png"
    end

    return ei_graphics_path.."graphics/64_empty.png"
end

-- from base factorio
function ei_lib.make_4way_animation_from_spritesheet(animation)
    local function make_animation_layer(idx, anim)
      local start_frame = (anim.frame_count or 1) * idx
      local x = 0
      local y = 0
      if anim.line_length then
        y = anim.height * math.floor(start_frame / (anim.line_length or 1))
      else
        x = idx * anim.width
      end
      return
      {
        filename = anim.filename,
        priority = anim.priority or "high",
        flags = anim.flags,
        x = x,
        y = y,
        width = anim.width,
        height = anim.height,
        frame_count = anim.frame_count or 1,
        line_length = anim.line_length,
        repeat_count = anim.repeat_count,
        shift = anim.shift,
        draw_as_shadow = anim.draw_as_shadow,
        force_hr_shadow = anim.force_hr_shadow,
        apply_runtime_tint = anim.apply_runtime_tint,
        animation_speed = anim.animation_speed,
        scale = anim.scale or 1,
        tint = anim.tint,
        blend_mode = anim.blend_mode
      }
    end
  
    local function make_animation_layer_with_hr_version(idx, anim)
      local anim_parameters = make_animation_layer(idx, anim)
      if anim.hr_version and anim.hr_version.filename then
        anim_parameters.hr_version = make_animation_layer(idx, anim.hr_version)
      end
      return anim_parameters
    end
  
    local function make_animation(idx)
      if animation.layers then
        local tab = { layers = {} }
        for k,v in ipairs(animation.layers) do
          table.insert(tab.layers, make_animation_layer_with_hr_version(idx, v))
        end
        return tab
      else
        return make_animation_layer_with_hr_version(idx, animation)
      end
    end
  
    return
    {
      north = make_animation(0),
      east = make_animation(1),
      south = make_animation(2),
      west = make_animation(3)
    }
end

function ei_lib.make_circuit_connector(Dx, Dy)

    local circuit_wire_connection_point = {
        shadow = {
            green = {0.671875+Dx, 0.609375+Dy},
            red = {0.890625+Dx, 0.5625+Dy}
        },
        wire = {
            green = {0.453125+Dx, 0.453125+Dy},
            red = {0.390625+Dx, 0.21875+Dy}
        }
    }

    local circuit_connector_sprites = {
        blue_led_light_offset = {0.125+Dx, 0.46875+Dy},
        connector_main = {
          filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04a-base-sequence.png",
          height = 50,
          priority = "low",
          scale = 0.5,
          shift = {
            0.09375+Dx,
            0.203125+Dy
          },
          width = 52,
          x = 104,
          y = 150
        },
        connector_shadow = {
          draw_as_shadow = true,
          filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04b-base-shadow-sequence.png",
          height = 46,
          priority = "low",
          scale = 0.5,
          shift = {
            0.3125+Dx,
            0.3125+Dy
          },
          width = 62,
          x = 124,
          y = 138
        },
        led_blue = {
          draw_as_glow = true,
          filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04e-blue-LED-on-sequence.png",
          height = 60,
          priority = "low",
          scale = 0.5,
          shift = {
            0.09375+Dx,
            0.171875+Dy
          },
          width = 60,
          x = 120,
          y = 180
        },
        led_blue_off = {
          filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04f-blue-LED-off-sequence.png",
          height = 44,
          priority = "low",
          scale = 0.5,
          shift = {
            0.09375+Dx,
            0.171875+Dy
          },
          width = 46,
          x = 92,
          y = 132
        },
        led_green = {
          draw_as_glow = true,
          filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04h-green-LED-sequence.png",
          height = 46,
          priority = "low",
          scale = 0.5,
          shift = {
            0.09375+Dx,
            0.171875+Dy
          },
          width = 48,
          x = 96,
          y = 138
        },
        led_light = {
          intensity = 0,
          size = 0.9
        },
        led_red = {
          draw_as_glow = true,
          filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04i-red-LED-sequence.png",
          height = 46,
          priority = "low",
          scale = 0.5,
          shift = {
            0.09375+Dx,
            0.171875+Dy
          },
          width = 48,
          x = 96,
          y = 138
        },
        red_green_led_light_offset = {
          0.109375+Dx,
          0.359375+Dy
        },
        wire_pins = {
          filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04c-wire-sequence.png",
          height = 58,
          priority = "low",
          scale = 0.5,
          shift = {
            0.09375+Dx,
            0.171875+Dy
          },
          width = 62,
          x = 124,
          y = 174
        },
        wire_pins_shadow = {
          draw_as_shadow = true,
          filename = "__base__/graphics/entity/circuit-connector/hr-ccm-universal-04d-wire-shadow-sequence.png",
          height = 54,
          priority = "low",
          scale = 0.5,
          shift = {
            0.25+Dx,
            0.296875+Dy
          },
          width = 70,
          x = 140,
          y = 162
        }
    }


    return {
        circuit_wire_connection_point,
        circuit_connector_sprites
    }

end

return ei_lib
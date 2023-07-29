function round(value)
    if value>=0 then return math.floor(value+0.5)
    else             return math.ceil (value-0.5)
    end
end

function toFixed(value,n)
    local mult = 10^n
    return round(value*mult)/mult
end

function sign(value)
    return value>0 and "+"..value or value
end

function get_setting(player)
    local player_index=player.index
    if not global.settings then global.settings={} end
    local setting = global.settings[player_index]
    if not setting then
        setting = {
            mode = "n_second",
            n_second = 30,
            n_count = 1,
            buffer_request = false,
            requests = {},
            entity_name = nil,
            crafting_speed = 1,
            speed_bonus = 0,
            recipe = nil,
        }
        global.settings[player_index] = setting 
    end
    return setting
end


function on_player_reverse_selected_area(event) 
    local success,message = pcall(function ()
        --game.print("on_player_reverse_selected_area")
        if event.item=='item-requester' then
            local player = game.players[event.player_index]
            local setting = get_setting(player)
            local item_requester = player.gui.left.item_requester

            if #event.entities == 0  then
                return
            end
            if #event.entities > 1 then
                --player.print("하나의 조립기계만 선택할 수 있습니다")
                player.print({"distribution-request-planner.select-one"})
                return
            end

            local target=event.entities[1]
            local recipe = target.get_recipe()

            if not recipe then
                player.print({"distribution-request-planner.no-recipe"})
                return
            end

            local ingredients = {}
            local fluids = {}

            for _,ingredient in pairs(recipe.ingredients) do
                if ingredient.type=="item" then
                    --ingredient.amount = ingredient.amount * speed * 30 / recipe.energy
                    table.insert(ingredients, ingredient)
                else
                    table.insert(fluids, ingredient)
                end
            end

            setting.entity_name    = target.name
            setting.crafting_speed = target.crafting_speed
            setting.speed_bonus    = target.speed_bonus
            setting.recipe         = recipe
            setting.ingredients    = ingredients
            setting.fluids         = fluids

            update_gui(player)



            --player.print("energy:"..recipe.energy)
            --player.print(game.table_to_json(ingredients))

            --if item_requester then
            --    item_requester.top.entity_flow.entity_button.elem_value=target.name
            --    local speed_bonus = (target.speed_bonus~=0) and (" ("..sign(toFixed(target.speed_bonus*100,2)).."%)") or ""
            --    item_requester.top.entity_flow.entity_label.caption={"",target.localised_name,"\n","제작속도 : ",toFixed(target.crafting_speed,2), speed_bonus }
            --    item_requester.top.recipe_flow.recipe_button.elem_value=recipe.name

            --    local recipe_label = {"","재료 목록        ","\n[img=quantity-time]   "..recipe.energy}
            --    for _,ingredient in pairs(ingredients) do
            --        table.insert(recipe_label, "\n[img=item/"..ingredient.name.."] "..ingredient.amount)
            --    end
            --    for _,ingredient in pairs(fluids) do
            --        table.insert(recipe_label, "\n[img=item/"..ingredient.name.."] "..ingredient.amount)
            --    end
            --    item_requester.top.recipe_flow.recipe_label.caption=recipe_label
                
            --    local request_label = {"","요청 목록","\n"}
            --    local mul = tonumber(item_requester.top.n_count_flow.n_count_field.text)
            --    for _,ingredient in pairs(ingredients) do
            --        table.insert(request_label, "\n[img=item/"..ingredient.name.."] "..ingredient.amount*mul)
            --    end
            --    item_requester.top.recipe_flow.request_label.caption=request_label
            --end
            --global.target=ingredients

        end
    end)
    if not success then
        reset()
        error_message(message)
    end
end 

function on_player_selected_area(event) 
    local success,message = pcall(function ()
        --game.print("on_player_selected_area")
        if event.item=='item-requester' then
            local player = game.players[event.player_index]
            local setting= get_setting(player)
            local requests = setting.requests

            if #event.entities == 0  then
                return
            elseif #event.entities > 30 then
                game.print({"distribution-request-planner.too-many-chest"})
                return
            end

            if #requests==0 then
                player.print({"distribution-request-planner.no-request"})
                return
            end

            local requesters={}
            for _,entity in pairs(event.entities) do
               --game.print(entity.unit_number.. entity.prototype.logistic_mode )
               if entity.prototype.logistic_mode == "requester" then
                   table.insert(requesters, entity)
                   --for slot=1, entity.request_slot_count do
                   --    entity.clear_request_slot(slot)
                   --end
                   if entity.request_slot_count>0 then
                       player.print({"distribution-request-planner.already-set"})
                       return
                   end
               end
            end

            local req_num = #requesters
            player.print({"distribution-request-planner.selected-chest",req_num})

            --local toast_info = {}
            for i=1,#requests do 
                local request = requests[i]
                local target_req_num = (i-1)%req_num+1
                local requester = requesters[target_req_num]
                --game.print("i="..i)
                --game.print(game.table_to_json(request))
                requester.set_request_slot({
                    name=request.name,
                    count=request.amount
                },math.floor((i-1)/req_num)+1)
                requester.request_from_buffers = setting.buffer_request

                --if not toast_info[target_req_num] then 
                --    toast_info[target_req_num] = {
                --        entity=requester,
                --        items={}
                --    }
                --end
                --table.insert(toast_info[target_req_num].items, "[item="..ingredient.name.."]")
            end
            --for _,info in pairs(toast_info) do
            --    local entity = info.entity
            --    local items = info.items
            --    local surface = entity.surface
            --    surface.create_entity{
            --        name="flying-text",
            --        position=entity.position,
            --        text=table.concat(items,""),
            --        render_player_index=event.player_index
            --    }
            --end


        end
    end)
    if not success then
        reset()
        error_message(message)
    end
end

--local function get_gui (player)
--    return player.gui.left.item_requester
--end

function update_gui (player)
    --game.print("update_gui")
    local item_requester = player.gui.left.item_requester
    local setting = get_setting(player)
    if item_requester then
        local entity_name = setting.entity_name
        if entity_name then
            local entity=game.entity_prototypes[entity_name]
            item_requester.top.entity_flow.entity_button.elem_value=entity.name
            local speed_bonus = (setting.speed_bonus~=0) and (" ("..sign(toFixed(setting.speed_bonus*100,2)).."%)") or ""
            item_requester.top.entity_flow.entity_label.caption={"",entity.localised_name,"\n",{"description.crafting-speed"}," : ",toFixed(setting.crafting_speed,2), speed_bonus }
        end

        local recipe      = setting.recipe
        local ingredients = setting.ingredients
        local fluids      = setting.fluids

        local n_second_field = item_requester.top.n_second_flow.n_second_field
        local n_count_field  = item_requester.top.n_count_flow .n_count_field
        if n_second_field.text=="" then n_second_field.text="0" end
        if n_count_field .text=="" then n_count_field .text="0" end

        if recipe then
            item_requester.top.recipe_flow.recipe_button.elem_value=recipe.name

            local recipe_label = {"",{"description.ingredients"},"\n[img=quantity-time]   "..recipe.energy}
            for _,ingredient in pairs(ingredients) do
                table.insert(recipe_label, "\n[img=item/"..ingredient.name.."] "..ingredient.amount)
            end
            for _,ingredient in pairs(fluids) do
                table.insert(recipe_label, "\n[img=fluid/"..ingredient.name.."] "..ingredient.amount)
            end
            item_requester.top.recipe_flow.recipe_label.caption=recipe_label
            
            local request_label = {"",{"description.logistic-request"},"\n"}
            local mul
            if setting.mode=="n_second" then
                mul = setting.n_second*setting.crafting_speed/setting.recipe.energy
            else
                mul = setting.n_count 
            end
            local requests = {}
            for _,ingredient in pairs(ingredients) do
                local value = toFixed(ingredient.amount*mul,0)
                table.insert(requests, {name=ingredient.name, amount=value})
                table.insert(request_label, "\n[img=item/"..ingredient.name.."] "..value)
            end
            setting.requests=requests
            item_requester.top.recipe_flow.request_label.caption=request_label
        end
    end
    
end
function show_gui (player)
    --game.print("show_gui")
    --if player.gui.left.item_requester then
    --    player.gui.left.item_requester.destroy()
    --end
    --local item_requester = player.gui.left.add{type="frame",name="item_requester",direction="vertical"}
    local item_requester = player.gui.left.item_requester
    if not item_requester then
        item_requester = player.gui.left.add{type="frame",name="item_requester",direction="vertical"}
        local top = item_requester.add{type="flow",name="top",direction="vertical"}
        top.add{type="label",caption={"distribution-request-planner.instruction-to-select-machine",{"control-keys.mouse-button-2"}}  }
        top.add{type="label",caption={"distribution-request-planner.instruction-to-select-chest"  ,{"control-keys.mouse-button-1"}}  }

        top.add{type="line"}

        local n_second_flow    = top.add{type="flow",name="n_second_flow" ,direction="horizontal"}
        local n_second_radio   = n_second_flow.add{name="n_second_radio"  ,type="radiobutton",state=true}
        local n_second_label_0 = n_second_flow.add{name="n_second_label_0",type="label",caption={"distribution-request-planner.n_second_0"}   }
        local n_second_field   = n_second_flow.add{name="n_second_field"  ,type="textfield",tooltip="0",text="30",numeric=true,allow_decimal=true}
        local n_second_label_1 = n_second_flow.add{name="n_second_label_1",type="label",caption={"distribution-request-planner.n_second_1"}   }

        local n_count_flow     = top.add{type="flow",name="n_count_flow",direction="horizontal"}
        local n_count_radio    = n_count_flow.add{name="n_count_radio"  ,type="radiobutton",state=false}
        local n_count_label_0  = n_count_flow.add{name="n_count_label_0",type="label",caption={"distribution-request-planner.n_count_0"}   }
        local n_count_field    = n_count_flow.add{name="n_count_field"  ,type="textfield",tooltip="0",text="1",numeric=true}
        local n_count_label_1  = n_count_flow.add{name="n_count_label_1",type="label",caption={"distribution-request-planner.n_count_1"}   }

        n_second_flow .style.vertical_align="center"
        n_count_flow  .style.vertical_align="center"
        n_second_field.style.width=40
        n_count_field .style.width=40
        n_second_field.style.horizontal_align="right"
        n_count_field .style.horizontal_align="right"

        local buffer_flow     = top        .add{type="flow"    ,name="buffer_flow"    ,direction="horizontal"}
        local buffer_checkbox = buffer_flow.add{type="checkbox",name="buffer_checkbox",caption={"gui-logistic.request-from-buffer-chests"},state=false}

        top.add{type="line"}

        local entity_flow  =top        .add{type="flow"              ,name="entity_flow"  ,direction="horizontal"}
        local entity_button=entity_flow.add{type="choose-elem-button",name="entity_button",elem_type="entity"}
        local entity_label =entity_flow.add{type="label"             ,name="entity_label" ,caption={"distribution-request-planner.select-machine"}}
        entity_button.locked=true
        entity_label.style.single_line=false
        
        top.add{type="line"}

        local recipe_flow   = top        .add{type="flow"              ,name="recipe_flow"  ,direction="horizontal"}
        local recipe_button = recipe_flow.add{type="choose-elem-button",name="recipe_button",elem_type="recipe"}
        local recipe_label  = recipe_flow.add{type="label"             ,name="recipe_label" ,caption={"distribution-request-planner.select-machine"}}
        recipe_flow.add{type="label",caption="      "}
        local request_label = recipe_flow.add{type="label"             ,name="request_label",caption=""}
        recipe_button.locked=true
        recipe_label.style.single_line=false
        request_label.style.single_line=false


    else    
        item_requester.visible=true

    end
    


    
end
function hide_gui (player)
    --game.print("hide_gui")
    local item_requester = player.gui.left.item_requester
    if item_requester then
        --player.gui.left.item_requester.destroy()
        item_requester.visible=false
    end


end

function on_player_cursor_stack_changed(event) 
    local success,message = pcall(function ()

        local player = game.players[event.player_index]
        if player.cursor_stack and player.cursor_stack.valid and player.cursor_stack.valid_for_read and player.cursor_stack.name=="item-requester" then
            show_gui(player)
        else
            hide_gui(player)
        end
    end)
    if not success then
        reset()
        error_message(message)
    end


end

function on_gui_click(event)
    local success,message = pcall(function ()
        local player_index = event.player_index
        local player = game.players[player_index]
        local item_requester = player.gui.left.item_requester
        if not item_requester then return end

        local setting = get_setting(player)

        local element = event.element
        if element and element.valid then
            if element.name=="n_second_radio" or element.name=="n_second_field" or element.name=="n_second_label" then
                item_requester.top.n_second_flow.n_second_radio.state=true
                item_requester.top.n_count_flow .n_count_radio .state=false
                setting.mode = "n_second"
                update_gui(player)
            elseif element.name=="n_count_radio" or element.name=="n_count_field" or element.name=="n_count_label" then
                item_requester.top.n_second_flow.n_second_radio.state=false
                item_requester.top.n_count_flow .n_count_radio .state=true
                setting.mode = "n_count"
                update_gui(player)
            elseif element.name=="buffer_checkbox" then
                setting.buffer_request = item_requester.top.buffer_flow.buffer_checkbox.state
                update_gui(player)
            end
        end
    end)
    if not success then
        reset()
        error_message(message)
    end
end

function on_gui_text_changed(event)
    local success,message = pcall(function ()
        local player_index = event.player_index
        local player = game.players[player_index]
        local item_requester = player.gui.left.item_requester
        if not item_requester then return end

        local setting = get_setting(player)

        local element = event.element
        if element and element.valid then
            if element.name=="n_second_field" then
                setting.n_second = tonumber(item_requester.top.n_second_flow.n_second_field.text) or 0
                if setting.n_second ~= 0 then update_gui(player) end
            elseif element.name=="n_count_field" then
                setting.n_count  = tonumber(item_requester.top.n_count_flow .n_count_field .text) or 0
                if setting.n_count  ~= 0 then update_gui(player) end
            end
        end
    end)
    if not success then
        reset()
        error_message(message)
    end
end

function reset()
    for _,player in pairs(game.players) do
        local item_requester = player.gui.left.item_requester
        if item_requester then item_requester.destroy() end
    end
    global.settings=nil
end

function error_message(message)
    game.print{"","[",{"mod-name.DistributionRequestPlanner"}," ",script.active_mods.DistributionRequestPlanner,"] ",{"distribution-request-planner.error_message"}}
    game.print(message)
end

function on_configuration_changed()
    reset()
end

script.on_event(defines.events.on_player_reverse_selected_area, on_player_reverse_selected_area)
script.on_event(defines.events.on_player_selected_area, on_player_selected_area)
script.on_event(defines.events.on_player_cursor_stack_changed,on_player_cursor_stack_changed)
script.on_event(defines.events.on_gui_click,on_gui_click)
script.on_event(defines.events.on_gui_text_changed,on_gui_text_changed)
--script.on_event(defines.events.on_gui_click,on_gui_click)
script.on_configuration_changed(on_configuration_changed)

if script.active_mods["gvv"] then require("__gvv__.gvv")() end

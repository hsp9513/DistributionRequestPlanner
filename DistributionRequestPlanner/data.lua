local requester = table.deepcopy(data.raw["selection-tool"]["selection-tool"])

requester.name = 'item-requester'
requester.subgroup = "tool"
requester.localised_name = {'item-name.item-requester'}
requester.localised_description=''
requester.stack_size = 1
requester.stackable = false
requester.entity_type_filters = {"logistic-container"}
requester.reverse_entity_type_filters = {"assembling-machine","rocket-silo"}

requester.flags = {"only-in-cursor", "spawnable"}
requester.icons={
  {
    icon = "__base__/graphics/icons/upgrade-planner.png"
  },
  {
    icon = "__base__/graphics/icons/logistic-chest-requester.png"
  }
}

requester.selection_color={r=0,g=0.5,b=1}
requester.selection_mode='blueprint'
requester.selection_cursor_box_type='logistics'
requester.reverse_selection_mode='blueprint'
requester.reverse_selection_cursor_box_type='copy'

local giveRequester = table.deepcopy(data.raw["shortcut"]["give-deconstruction-planner"])

giveRequester.name='give-item-requester'
giveRequester.localised_name={'shortcut.give-item-requester'}
giveRequester.localised_description=''

giveRequester.item_to_spawn='item-requester'
giveRequester.technology_to_unlock=nil

giveRequester.associated_control_input=''
giveRequester.icon=    {
      filename = "__base__/graphics/icons/logistic-chest-requester.png",
      priority = "extra-high-no-scale",
      size = 64,
      scale = 0.5,
      mipmap_count = 4,
      flags = {"gui-icon"}
    }
giveRequester.style="green"

data:extend{requester,giveRequester}

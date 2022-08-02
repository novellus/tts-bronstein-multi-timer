-- used to corrdinate between all timer clones
GLOBAL_COORDINATION_VAR = 'tts_bronstein_multi_timer'


function concat_tables(table1, table2)
    -- dict format only
    -- table2 entries take precidence, in case of duplicate keys.
    -- does not deep copy references

    new_table = {}
    for key, val in pairs(table1) do
        new_table[key] = val
    end
    for key, val in pairs(table2) do
        new_table[key] = val
    end

    return new_table
end


function format_time(seconds, plus)
    -- seconds is positive number
    -- plus is boolean, include '+' symbol in front

    hours = math.floor(seconds / 3600)
    minutes = math.floor((seconds % 3600) / 60)
    seconds = seconds % 60

    if plus then
        sign = '+ '
    else
        sign = ''
    end

    return string.format('%s%02d:%02d:%02d', sign, hours, minutes, seconds)
end


function generate_ui()
    -- scale UI to be 1-to-1 independant of object scale bias
    object_scale = self.getScale()
    object_height_scale = object_scale[3]
    UI_scale = {}
    for _, scale in pairs(object_scale) do
        table.insert(UI_scale, 0.5 * object_height_scale / scale)
    end
    UI_scale[3] = UI_scale[3] * 0.3 / 0.5  -- font look better at this ratio
    -- UI_scale = {0.147, 2.5, 0.30}
    -- printToAll(tostring(UI_scale[3]), 'White')

    -- vertical positions calculated using ratios of the total space
    --    1 space
    --    10 buttons
    --        1 space
    --        10 button row
    --        1 space
    --        10 button row
    --        1 space
    --    1 space
    --    10 time
    --    1 space / next button
    --    10 time
    --    1 space
    -- Then heights/fonts derived empirically

    -- buttons
    button_template = {
        function_owner = self,
        height         = 250,
        width          = 800,
        font_size      = 120,
        color          = 'Black',
        font_color     = 'White',
        scale          = UI_scale,
    }
    v_pos = 0.51

    self.createButton(concat_tables(
        button_template, {
            click_function = 'test_button',
            label          = 'Start first timer',
            position       = {-0.37, v_pos, -11/34 - 10/34*6/23},
            color          = 'Green',
            width          = 1000,
            tooltip        = 'Start whichever timer is first in turn order. Bronstein field (+time) is reset.',
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'test_button',
            label          = 'Start this timer',
            position       = {-0.37, v_pos, -11/34 + 10/34*6/23},
            color          = 'Green',
            width          = 1000,
            tooltip        = 'Start this timer, disregarding first turn order. Bronstein field (+time) is reset.',
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'test_button',
            label          = 'Reset All',
            position       = {-0.11, v_pos, -11/34},
            color          = 'Red',
            tooltip        = 'Reset and stop all timers',
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'test_button',
            label          = 'Pause All',
            position       = {0.13, v_pos, -11/34},
            tooltip        = 'Pauses all timers',
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'test_button',
            label          = 'Turn Order',
            font_color     = 'Black',
            height         = 0,
            width          = 0,
            position       = {0.37, v_pos, -11/34 - 10/34*6/23},
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'test_button',
            label          = 'Next\nTurn',
            font_color     = 'Black',
            color          = 'Orange',
            height         = 800,
            width          = 1000,
            position       = {0.37, v_pos, 5.5/34},
            alignment      = 3, -- center aligned
        })
    )

    -- turn field
    self.createInput(concat_tables(
        button_template, {
            input_function = 'test_button',
            label          = '1',
            font_color     = 'Black',
            font_size      = 200,
            color          = 'White',
            position       = {0.37, v_pos, -11/34 + 10/34*6/23},
            tooltip        = 'Any number. Determines which timer is triggered when "Next" button is used, in ascending round-robin order.',
            alignment      = 3, -- center aligned
        })
    )

    -- time fields
    input_template = {
        function_owner = self,
        height         = 500,
        width          = 2850,
        font_size      = 450,
        color          = 'White',
        font_color     = 'Black',
        scale          = UI_scale,
        label          = '+00:00:00.00',
        alignment      = 2, -- left aligned
    }

    self.createInput(concat_tables(
        input_template, {
            input_function = 'test_button',
            position       = {-0.13, v_pos, 0},
            tooltip        = 'Pool time remaining, used after Bronstein Time runs out each turn.',
        })
    )

    self.createInput(concat_tables(
        input_template, {
            input_function = 'test_button',
            position       = {-0.13, v_pos, 11/34},
            tooltip        = 'Bronstein Time remaining. Refreshed each turn, and used up before pool time is used.',
        })
    )
end


function test_button()
    printToAll('', 'White')
    printToAll('self: ' .. tostring(self.guid), 'White')
    printToAll('name: ' .. tostring(self.getName()), 'White')
    printToAll('next_relative: ' .. tostring(next_relative.getVar('self').guid), 'White')

    printToAll('family:', 'White')
    family = Global.getTable(GLOBAL_COORDINATION_VAR)
    for relative, _ in pairs(family) do
        printToAll('    ' .. tostring(relative) .. ': ' .. tostring(relative.getVar('self').guid), 'White')
    end
end


function add_relative(id)
    family[id] = true
end


function remove_relative(id)
    family[id] = nil
end


function update_family()
    -- update family list and recompute derived parameters
    family = Global.getTable(GLOBAL_COORDINATION_VAR)

    -- compute next relative in turn order
    earliest_turn = nil
    earliest_relative = nil
    next_turn = nil
    next_relative = nil

    for relative, _ in pairs(family) do
        relative_turn = relative.getVar('state').turn

        if earliest_turn == nil or relative_turn < earliest_turn then
            earliest_turn = relative_turn
            earliest_relative = relative_relative
        end

        if state.turn < relative_turn and relative_turn < next_turn then
            next_turn = relative_turn
            next_relative = relative_relative
        end
    end

    -- next in turn order if there is anyone, or wrap around to earliest
    next_relative = next_relative or earliest_relative or self
end


function add_self_to_family()
    family = Global.getTable(GLOBAL_COORDINATION_VAR)
    if family == nil then
        family = {}
    end
    family[self] = true
    Global.setTable(GLOBAL_COORDINATION_VAR, family)

    -- instruct relatives to update family list and recompute derived parameters
    for relative, _ in pairs(family) do
        relative.call('update_family')
    end
end


function remove_self_from_family()
    family = Global.getTable(GLOBAL_COORDINATION_VAR)
    family[self] = nil
    Global.setTable(GLOBAL_COORDINATION_VAR, family)

    -- instruct relatives to update family list and recompute derived parameters
    for relative, _ in pairs(family) do
        relative.call('update_family')
    end
end


function onDestroy()
    remove_self_from_family()
end


function onSave()
    -- save personal state
    return JSON.encode(state)
end


function onLoad(saved_state)
    -- initialize starter state
    -- 'state' will be stored and recovered across saves, other variables will not
    state = {
        turn = 1,
        pool_time_original = 15*60,
        bronstein_time_original = 15,
    }
    next_relative = nil  -- object cannot be serialized, and is recomputed on load anyway

    -- recover personal state, if any
    if saved_state ~= nil and saved_state ~= '' then
        state = JSON.decode(saved_state)
    end

    add_self_to_family()
    generate_ui()
end


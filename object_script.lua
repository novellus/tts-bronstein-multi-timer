-- used to corrdinate between all timer clones
GLOBAL_COORDINATION_VAR = 'tts_bronstein_multi_timer'


function concat_tables(table1, table2)
    -- util function
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
    -- creates UI elements

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

    -- scale UI to be 1-to-1 independant of object scale bias
    object_scale = self.getScale()
    object_height_scale = object_scale[3]
    UI_scale = {}
    for _, scale in pairs(object_scale) do
        table.insert(UI_scale, 0.5 * object_height_scale / scale)
    end
    UI_scale[3] = UI_scale[3] * 0.3 / 0.5  -- font looks better at this ratio

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
            label          = 'Next\nTurn',
            font_color     = 'Black',
            font_size      = 250,
            color          = 'Orange',
            height         = 800,
            width          = 1000,
            position       = {0.37, v_pos, 5.5/34},
            alignment      = 3, -- center aligned
        })
    )

    -- turn order field
    self.createButton(concat_tables(
        button_template, {
            click_function = 'test_button',
            label          = 'Turn Order',
            font_color     = 'Black',
            height         = 0,  -- text display, not an actual button. There is no pure text tool.
            width          = 0,
            position       = {0.37, v_pos, -11/34 - 10/34*6/23},
        })
    )

    self.createInput(concat_tables(
        button_template, {
            input_function = 'turn_order_edited',
            label          = '1',
            font_color     = 'Black',
            font_size      = 200,
            color          = 'White',
            position       = {0.37, v_pos, -11/34 + 10/34*6/23},
            tooltip        = 'Any number. Determines which timer is triggered when "Next" button is used, in ascending round-robin order.',
            alignment      = 3, -- center aligned
            -- validation     = 3, -- float
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
        validation     = 3, -- float
    }

    self.createInput(concat_tables(
        input_template, {
            input_function = 'pool_time_edited',
            position       = {-0.13, v_pos, 0},
            tooltip        = 'Pool time remaining, used after Bronstein Time runs out each turn.',
        })
    )
    pool_time_edit_index = #self.getInputs() - 1

    self.createInput(concat_tables(
        input_template, {
            input_function = 'bronstein_time_edited',
            position       = {-0.13, v_pos, 11/34},
            tooltip        = 'Bronstein Time remaining. Refreshed each turn, and used up before pool time is used.',
        })
    )
    bronstein_time_edit_index = #self.getInputs() - 1
end


function test_button()
    printToAll('', 'White')
    printToAll('self: ' .. tostring(self.guid), 'White')
    
    -- state
    printToAll('state:', 'White')
    for key, val in pairs(state) do
        printToAll('    ' .. tostring(key) .. ': ' .. tostring(val), 'White')
    end

    -- -- family
    -- printToAll('next_relative: ' .. tostring(next_relative.getVar('self').guid), 'White')
    -- printToAll('family:', 'White')
    -- family = Global.getTable(GLOBAL_COORDINATION_VAR)
    -- for relative, _ in pairs(family) do
    --     printToAll('    ' .. tostring(relative) .. ': ' .. tostring(relative.getVar('self').guid), 'White')
    -- end

    -- -- inputs list
    -- printToAll('inputs:', 'White')
    -- family = Global.getTable(GLOBAL_COORDINATION_VAR)
    -- for key, val in pairs(self.getInputs()) do
    --     printToAll('    ' .. tostring(key) .. ': ' .. tostring(val), 'White')
    --     for key, val in pairs(val) do
    --         printToAll('        ' .. tostring(key) .. ': ' .. tostring(val), 'White')
    --     end
    -- end
end


function turn_order_edited(obj, player_clicker_color, input_value, still_editing)
    validity = validate_input_edit(input_value, still_editing)
    if validity == 1 then
        return tostring(state.turn)  -- return value from this callback sets input state
    elseif validity == 2 then
        state.turn = tonumber(input_value)
        instruct_update_families()
    end
end


function pool_time_edited(obj, player_clicker_color, input_value, still_editing)
    validity = validate_input_edit(input_value, still_editing)
    if validity == 1 then

        printToAll('testedit: ' .. tostring(state) .. ': ' .. tostring(state.pool_time_remaining), 'White')
        for key, val in pairs(state) do
            printToAll('    ' .. tostring(key) .. ': ' .. tostring(val), 'White')
        end

        return format_time(state.pool_time_remaining, false)  -- return value from this callback sets input state
    elseif validity == 2 then
        state.pool_time_original = tonumber(input_value)
    end
end


function bronstein_time_edited(obj, player_clicker_color, input_value, still_editing)
    validity = validate_input_edit(input_value, still_editing)
    if validity == 1 then
        return format_time(state.bronstein_time_remaining, true)  -- return value from this callback sets input state
    elseif validity == 2 then
        state.bronstein_time_original = tonumber(input_value)
    end
end


function validate_input_edit(input_value, still_editing)
    -- returns one of
    --    0 = still editing, do not respond
    --    1 = invalid edit, reset input field
    --    2 = valid

    if still_editing then
        return 0
    else
        if state.any_timer_running then
            printToAll('Cannot update parameters while timer is running!', 'White')
            return 1
        else
            if not validate_float_string(input_value) then
                printToAll('Input value is invalid, must be a valid number (int,float): ' .. input_value, 'White')
                return 1
            else
                return 2
            end
        end
    end
end


function validate_float_string(s)
    -- validates string before numerical conversion
    -- atleast one side of the decimal must contain a number, so can't do double star
    return (string.find(s, '^%d+(%.%d*)?$|^%.%d+$') ~= nil)
end


function start_timer()
--TODO
end


function update_timer()
    -- computes time difference since timer start
    -- handles transition from bronstein timer to pool timer
    -- handles timer run out
    -- updates UI time elements

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


function instruct_update_families()
    -- instruct relatives to update family list and recompute derived parameters
    for relative, _ in pairs(family) do
        relative.call('update_family')
    end
end


function add_self_to_family()
    family = Global.getTable(GLOBAL_COORDINATION_VAR)
    if family == nil then
        family = {}
    end
    family[self] = true
    Global.setTable(GLOBAL_COORDINATION_VAR, family)

    instruct_update_families()
end


function remove_self_from_family()
    family = Global.getTable(GLOBAL_COORDINATION_VAR)
    family[self] = nil
    Global.setTable(GLOBAL_COORDINATION_VAR, family)

    instruct_update_families()
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
        pool_time_original = 900,
        pool_time_remaining = 900,
        bronstein_time_original = 15,
        bronstein_time_remaining = 15,
        
        -- timer is always in one of 3 states: running, paused, or reset
        timer_running = false,
        timer_paused = false,
        any_timer_running = false,  -- coordinates family activity
    }
    next_relative = nil  -- object cannot be serialized, and is recomputed on load anyway
    earliest_relative = nil  -- object cannot be serialized, and is recomputed on load anyway
    countdown_start_time = nil  -- absolute clock reference is not valid between saves
    pool_time_edit_index = nil  -- created on load
    bronstein_time_edit_index = nil  -- created on load

    -- TODO TMP
    test_button()

    -- recover personal state, if any
    if saved_state ~= nil and saved_state ~= '' then
        -- do this piece-wise to allow fields to be added/removed during development
        -- state = JSON.decode(saved_state)
        _state = JSON.decode(saved_state)
        for key, val in pairs(_state) do
            if state[key] ~= nil then  -- allow fields to be deleted
                state[key] = val
            end
        end
    end

    -- TODO TMP
    test_button()

    -- communicate with other timers
    add_self_to_family()

    -- build UI
    generate_ui()

    -- restart timer between saves
    if state.timer_running then
        start_timer()
    end

    -- schedule update loop
    -- TODO
end


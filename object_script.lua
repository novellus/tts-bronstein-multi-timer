-- used to corrdinate between all timer clones
GLOBAL_COORDINATION_VAR = 'tts_bronstein_multi_timer'

-- Update frequency for the main timer loop, which should only run on one timer at a time.
-- Defines update frequency for the UI and alarm functionality
-- As well as the tolerance on the bronstein-to-pool time transition
UPDATE_PERIOD = 0.1  -- in seconds


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

    return string.format('%s%02d:%02d:%05.2f', sign, hours, minutes, seconds)
end


function gui_nop()
    -- endpoint function for a button without click functionality
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
            click_function = 'instruct_start_earliest_timer',
            label          = 'Start first timer',
            position       = {-0.37, v_pos, -11/34 - 10/34*6/23},
            color          = 'Green',
            width          = 1000,
            tooltip        = 'Start whichever timer is first in turn order. Bronstein field (+time) is reset.',
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'start_timer',
            label          = 'Start this timer',
            position       = {-0.37, v_pos, -11/34 + 10/34*6/23},
            color          = 'Green',
            width          = 1000,
            tooltip        = 'Start this timer, disregarding first turn order. Bronstein field (+time) is reset.',
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'instruct_reset_timers',
            label          = 'Reset All',
            position       = {-0.11, v_pos, -11/34},
            color          = 'Red',
            tooltip        = 'Reset and stop all timers',
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'instruct_pause_timers',
            label          = 'Pause All',
            position       = {0.13, v_pos, -11/34},
            tooltip        = 'Pauses all timers',
        })
    )

    self.createButton(concat_tables(
        button_template, {
            click_function = 'next_turn',
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
            click_function = 'gui_nop',
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
            value          = tostring(state.turn),
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
        alignment      = 4, -- right aligned
        -- validation  = built-in validation cannot be used, since we want to display ':' and '+' symbols
    }

    self.createInput(concat_tables(
        input_template, {
            input_function = 'pool_time_edited',
            position       = {-0.13, v_pos, 0},
            value          = format_time(state.pool_time_remaining, false),
            tooltip        = 'Pool time remaining, used after Bronstein Time runs out each turn.',
        })
    )
    pool_time_edit_index = #self.getInputs() - 1

    self.createInput(concat_tables(
        input_template, {
            input_function = 'bronstein_time_edited',
            position       = {-0.13, v_pos, 11/34},
            value          = format_time(state.bronstein_time_remaining, true),
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
        return format_time(state.pool_time_remaining, false)  -- return value from this callback sets input state
    elseif validity == 2 then
        state.pool_time_original = tonumber(input_value)
        state.pool_time_remaining = state.pool_time_original
        return format_time(state.pool_time_original, false)  -- return value from this callback sets input state
    end
end


function bronstein_time_edited(obj, player_clicker_color, input_value, still_editing)
    validity = validate_input_edit(input_value, still_editing)
    if validity == 1 then
        return format_time(state.bronstein_time_remaining, true)  -- return value from this callback sets input state
    elseif validity == 2 then
        state.bronstein_time_original = tonumber(input_value)
        state.bronstein_time_remaining = state.bronstein_time_original
        return format_time(state.bronstein_time_original, true)  -- return value from this callback sets input state
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
            printToAll('Cannot update parameters while any timer is running! Use "Pause All" or "Reset All" if you want to edit fields.', 'White')
            return 1
        else
            if not validate_float_string(input_value) then
                printToAll('Input value is invalid, must be a valid number (int or float): "' .. input_value .. '"', 'White')
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
    valid =          string.find(s, '^%d+%.?%d*$') ~= nil
    valid = valid or string.find(s,    '^%.%d+$')  ~= nil
    return valid
end


function start_timer()
    -- starts this timer
    -- resets bronstein field, logs start time, and schedules an update loop

    if state.any_timer_running then
        printToAll('A timer is already running, cannot start this one! Use "Reset" and then "Start" if you want to restart.', 'White')
        return
    end

    -- update state
    state.timer_running = true
    for relative, _ in pairs(family) do
        relative.setVar('any_timer_running', true)
    end

    -- reset bronstein field on start
    state.bronstein_time_remaining = state.bronstein_time_original
    state.counting_bronstein = true

    -- record timer start clock-time
    countdown_start_time = os.clock()
    pool_time_remaining_at_countdown_start = state.pool_time_remaining

    -- schedule an infinite update loop at fixed frequency
    timer_update_schedule =  Wait.time(update_timer, UPDATE_PERIOD, -1)
end


function instruct_start_earliest_timer()
    -- instructs earliest relative (possibly self) to start
    earliest_relative.call('start_timer')
end


function instruct_any_timer_running(value)
    -- instructs relatives that one of the timers has started, which locks out UI editing
    for relative, _ in pairs(family) do
        relative.setVar('any_timer_running', value)
    end
end


function reset_timer()
    -- halts countdown loop and resets time fields

    -- halt countdown via pause function
    pause_timer()

    -- reset time fields
    state.pool_time_remaining = state.pool_time_original
    pool_time_remaining_at_countdown_start = nil
    state.bronstein_time_remaining = state.bronstein_time_original
    state.counting_bronstein = true
    self.editInput({index=pool_time_edit_index, value=format_time(state.pool_time_remaining, false)})
    self.editInput({index=bronstein_time_edit_index, value=format_time(state.bronstein_time_remaining, true)})
end


function instruct_reset_timers()
    -- instructs entire family to reset
    for relative, _ in pairs(family) do
        relative.call('reset_timer')
        relative.setVar('any_timer_running', false)
    end
end


function pause_timer(clear_global_running_state)
    -- halts countdown loop
    if state.timer_running then
        -- halt loop
        Wait.stop(timer_update_schedule)
        timer_update_schedule = nil
        countdown_start_time = nil
        
        -- set state
        state.timer_running = false
    end
end


function instruct_pause_timers()
    -- instructs entire family to pause
    for relative, _ in pairs(family) do
        relative.call('pause_timer')
        relative.setVar('any_timer_running', false)
    end
end


function update_timer()
    -- updates state and UI with timer status during a countdown
    --     computes time difference since timer start
    --     handles transition from bronstein timer to pool timer
    --     handles timer run out
    --     updates UI time elements

    -- acquire time difference since start
    time_difference = os.clock() - countdown_start_time

    -- update time remaining state
    if state.counting_bronstein then
        -- acquire difference to bronstein timer
        state.bronstein_time_remaining = state.bronstein_time_original - time_difference

        -- check for bronstein timer run out
        if state.bronstein_time_remaining <= 0 then
            state.counting_bronstein = false
            state.bronstein_time_remaining = 0  -- set to precisely 0 for a nice UI display
        end

        -- update UI
        self.editInput({index=bronstein_time_edit_index, value=format_time(state.bronstein_time_remaining, true)})
    end

    if not state.counting_bronstein then  -- might enter this due to bronstein timer run out above
        -- acquire difference to pool timer
        pool_time_difference = time_difference - state.bronstein_time_original
        state.pool_time_remaining = pool_time_remaining_at_countdown_start - pool_time_difference

        -- check for pool time run out
        if state.pool_time_remaining <= 0 then
            state.pool_time_remaining = 0  -- set to precisely 0 for a nice UI display
        end

        -- update UI
        self.editInput({index=pool_time_edit_index, value=format_time(state.pool_time_remaining, true)})

        -- trigger next turn if pool time ran out
        if state.pool_time_remaining <= 0 then
            -- TODO play a sound effect
            next_turn()
        end
    end
end


function next_turn()
    -- Passes turn to the next player, pausing this timer, and starting the next timer

    if not state.timer_running then
        printToAll('This timer is not running, ignoring attempt to go to next turn.', 'White')
    else
        -- TODO play a sound effect on turn pass
        pause_timer(false)
        next_relative.call('start_timer')
    end
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
        pool_time_original = 15*60,
        pool_time_remaining = 15*60,
        bronstein_time_original = 15,
        bronstein_time_remaining = 15,
        counting_bronstein = true,  -- if false, then counting pool time instead
        
        -- timer is always in one of 3 states: running, paused, or reset
        timer_running = false,
        any_timer_running = false,  -- coordinates family activity
    }
    next_relative = nil  -- object cannot be serialized, and is recomputed on load anyway
    earliest_relative = nil  -- object cannot be serialized, and is recomputed on load anyway
    countdown_start_time = nil  -- absolute clock reference is not valid between saves
    pool_time_edit_index = nil  -- created on load
    bronstein_time_edit_index = nil  -- created on load
    timer_update_schedule = nil  -- created on demand
    pool_time_remaining_at_countdown_start = nil  -- created on demand. avoids differential time keeping for as long as possible

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

    -- communicate with other timers
    add_self_to_family()

    -- build UI
    generate_ui()

    -- restart timer between saves
    if state.timer_running then
        start_timer()
    end
end


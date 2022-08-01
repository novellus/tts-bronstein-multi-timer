-- used to corrdinate between all timer clones
GLOBAL_COORDINATION_VAR = 'tts_bronstein_multi_timer'


function generate_ui()
    self.createButton({
        click_function = 'test_button',
        function_owner = self,
        label          = 'test',
        position       = {0, 1, 0},
        rotation       = {0, 0, 0},
        width          = 200,
        height         = 100,
        font_size      = 40,
        color          = 'Black',
        tooltip        = 'test',
    })
end


function test_button()
    printToAll('', {1, 1, 1})
    printToAll('self: ' .. tostring(self.guid), {1, 1, 1})
    printToAll('next_relative: ' .. tostring(next_relative.getVar('self').guid), {1, 1, 1})

    printToAll('family:', {1, 1, 1})
    family = Global.getTable(GLOBAL_COORDINATION_VAR)
    for relative, _ in pairs(family) do
        printToAll('    ' .. tostring(relative) .. ': ' .. tostring(relative.getVar('self').guid), {1,1,1})
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

    -- TMP
    printToAll('--A-- family:', {1, 1, 1})
    for relative, _ in pairs(family) do
        printToAll('    ' .. tostring(relative) .. ': ' .. tostring(relative.getVar('self').guid), {1,1,1})
    end

    family[self] = nil

    -- TMP
    printToAll('--B-- family:', {1, 1, 1})
    for relative, _ in pairs(family) do
        printToAll('    ' .. tostring(relative) .. ': ' .. tostring(relative.getVar('self').guid), {1,1,1})
    end

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
    }
    next_relative = nil  -- object cannot be serialized, and is recomputed on load anyway

    -- recover personal state, if any
    if saved_state ~= nil and saved_state ~= '' then
        state = JSON.decode(saved_state)
    end

    add_self_to_family()
    generate_ui()
end


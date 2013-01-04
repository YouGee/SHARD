-- SHARD 1.0.1
-- (c)UG 2013

function love.load()
    -- loads all stuff and assets we need for our game
    
    -- line for the ZeroBrane debugger
    if arg and arg[#arg] == "-debug" then require("mobdebug").start() end
    
    -- tiles graphics
    tile_black = love.graphics.newImage("Media/Graphic/Tiles/tile_black.png")

    -- tile size: constant
    tile_size = 96

    -- world size: constants
    worldsize = {}
    worldsize.tiles = {}
    worldsize.tiles.x = 8   -- world size (in number of tiles)
    worldsize.tiles.y = 8   -- value must be even, because a 4x4 zone hold the dragon's lair in the center of the map
    worldsize.pixel = {}
    worldsize.pixel.x = worldsize.tiles.x*tile_size    -- world size (in pixels)
    worldsize.pixel.y = worldsize.tiles.y*tile_size

    -- Creation of the multi-dimensional array "World"
    worldAttribs = {"status","type","terrain","graphic", "monster"}
    world = {}          -- create the matrix
    for lig=1,worldsize.tiles.y do
        world[lig] = {}     -- create a new row
        for row=1,worldsize.tiles.x do
            world[lig][row] = {} -- create a new line
            for i=1, table.maxn(worldAttribs) do
                world[lig][row][worldAttribs[i]] = {}
            end
        end
    end

    -- world array initialization
    world = {}
    for lig=1,worldsize.tiles.y do
        world[lig] = {}
        for row=1,worldsize.tiles.x do
            world[lig][row] = {}
            world[lig][row]["status"] = "fog" -- status of the tile fog|explored
            world[lig][row]["type"] = "dungeon" -- exit|boundary|dungeon|lair
            world[lig][row]["terrain"] = {} -- nature of the tile terrain: all different rooms
            world[lig][row]["graphic"] = tile_black -- unexplored tile
            world[lig][row]["monster"] = {} -- monster on the tile

            -- special tiles:
            -- lair?
            if (lig == worldsize.tiles.x/2) and (row == worldsize.tiles.y/2) then
                world[lig][row]["type"] = "lair"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_lair_upperleft -- upper left dragon's lair
            elseif (lig == worldsize.tiles.x/2) and (row == (worldsize.tiles.y/2)+1) then
                world[lig][row]["type"] = "lair"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_lair_downleft -- down left dragon's lair
            elseif (lig == (worldsize.tiles.x/2)+1) and (row == worldsize.tiles.y/2) then
                world[lig][row]["type"] = "lair"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_lair_upperright -- upper right dragon's lair
            elseif (lig == (worldsize.tiles.x/2)+1) and (row == (worldsize.tiles.y/2)+1) then
                world[lig][row]["type"] = "lair"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_lair_downright -- down right dragon's lair

            -- four corners of the map?
            elseif (lig == 1) and (row == 1) then
                -- top left
                world[lig][row]["type"] = "exit"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_exit_topleft
            elseif (lig == 1) and (row == worldsize.tiles.x) then
                -- top right
                world[lig][row]["type"] = "exit"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_exit_topright
            elseif (lig == worldsize.tiles.y) and (row == 1) then
                -- bottom left
                world[lig][row]["type"] = "exit"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_exit_bottomleft
            elseif (lig == worldsize.tiles.y) and (row == worldsize.tiles.x) then
                -- bottom right
                world[lig][row]["type"] = "exit"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_exit_bottomleft

            -- boundaries?
            elseif (lig == 1) and (row ~= 1) and (row ~= worldsize.tiles.x) then
                -- upper boundary
                world[lig][row]["type"] = "boundary"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_boundary_up
            elseif (lig == worldsize.tiles.y) and (row ~= 1) and (row ~= worldsize.tiles.x) then
                -- bottom boundary
                world[lig][row]["type"] = "boundary"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_boundary_down
            elseif (row == 1) and (lig ~= 1) and (lig ~= worldsize.tiles.x) then
                -- left boundary
                world[lig][row]["type"] = "boundary"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_boundary_left
            elseif (row == worldsize.tiles.x) and (lig ~= 1) and (lig ~= worldsize.tiles.x) then
                -- right boundary
                world[lig][row]["type"] = "boundary"
                world[lig][row]["status"] = "explored"
                world[lig][row]["graphic"] = tile_boundary_right
            end
        end
    end

    -- terrain
    terrains = {}

    -- actors
    actors = {}

end

function love.update(dt)
    -- is called before a frame is drawn, all math should be done in here

end

function love.draw()
    -- draws all stuff to the screen

    -- Map draw
    for lig=1,worldsize.tiles.y do
        for row=1,worldsize.tiles.x do
            if (world[lig][row]["graphic"] ~= nil) then
                x_upperleftcorner = (row-1)*tile_size
                y_upperleftcorner = (lig-1)*tile_size
                love.graphics.draw(tile_black, x_upperleftcorner, y_upperleftcorner)
            end
        end
    end

end

-- Custom graphic mouse cursor HOWTO

-- declare in love.load()
    -- cursor = love.graphics.newImage("crosshair.png")
    -- love.mouse.setVisible(false)
    -- love.mouse.setGrab(true)

-- call it in love.draw()
    -- love.graphics.draw(cursor, love.mouse.getX() - cursor:getWidth() / 2, love.mouse.getY() - cursor:getHeight() / 2)

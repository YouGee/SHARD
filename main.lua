-- SHARD 1.0.1
-- (c)UG 2013


function love.load()
    -- loads all stuff and assets we need for our game
    
    -- line for the ZeroBrane debugger
    if arg and arg[#arg] == "-debug" then require("mobdebug").start() end
    
    -- tiles graphics
    tile_black_IMG = love.graphics.newImage("Media/Graphic/Tiles/tile_black.png")
    player_IMG = love.graphics.newImage("Media/Graphic/Sprites/S_Heroe_Warrior.png")

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

    -- Command panel
    panel_IMG = love.graphics.newImage("Media/Graphic/Panel/Panel.png")
    panelWidth = panel_IMG:getWidth()
    panelHeight = panel_IMG:getHeight()

    -- Display Mode
    xdisplay = tile_size*worldsize.tiles.x+panelWidth
    ydisplay = math.max(tile_size*worldsize.tiles.y,panelHeight)
    success = love.graphics.setMode(xdisplay,ydisplay,false,true,0)

    -- Creation of the multi-dimensional array "World"
    worldAttribs = {"status","type","terrain","graphic", "monster"}
    world = {}          -- create the matrix
    for lin=1,worldsize.tiles.y do
        world[lin] = {}     -- create a new row
        for row=1,worldsize.tiles.x do
            world[lin][row] = {} -- create a new line
            for i=1, table.maxn(worldAttribs) do
                world[lin][row][worldAttribs[i]] = {}
            end
        end
    end

    -- world array initialization
    world = {}
    for lin=1,worldsize.tiles.y do
        world[lin] = {}
        for row=1,worldsize.tiles.x do
            world[lin][row] = {}
            world[lin][row]["status"] = "fog" -- status of the tile fog|explored
            world[lin][row]["type"] = "dungeon" -- exit|boundary|dungeon|lair
            world[lin][row]["terrain"] = {} -- nature of the tile terrain: all different rooms
            world[lin][row]["graphic"] = tile_black_IMG -- unexplored tile
            world[lin][row]["monster"] = {} -- monster on the tile

            -- special tiles:
            -- lair?
            if (lin == worldsize.tiles.x/2) and (row == worldsize.tiles.y/2) then
                world[lin][row]["type"] = "lair"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_lair_upperleft -- upper left dragon's lair
            elseif (lin == worldsize.tiles.x/2) and (row == (worldsize.tiles.y/2)+1) then
                world[lin][row]["type"] = "lair"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_lair_downleft -- down left dragon's lair
            elseif (lin == (worldsize.tiles.x/2)+1) and (row == worldsize.tiles.y/2) then
                world[lin][row]["type"] = "lair"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_lair_upperright -- upper right dragon's lair
            elseif (lin == (worldsize.tiles.x/2)+1) and (row == (worldsize.tiles.y/2)+1) then
                world[lin][row]["type"] = "lair"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_lair_downright -- down right dragon's lair

            -- four corners of the map?
            elseif (lin == 1) and (row == 1) then
                -- top left
                world[lin][row]["type"] = "exit"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_exit_topleft
            elseif (lin == 1) and (row == worldsize.tiles.x) then
                -- top right
                world[lin][row]["type"] = "exit"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_exit_topright
            elseif (lin == worldsize.tiles.y) and (row == 1) then
                -- bottom left
                world[lin][row]["type"] = "exit"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_exit_bottomleft
            elseif (lin == worldsize.tiles.y) and (row == worldsize.tiles.x) then
                -- bottom right
                world[lin][row]["type"] = "exit"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_exit_bottomleft

            -- boundaries?
            elseif (lin == 1) and (row ~= 1) and (row ~= worldsize.tiles.x) then
                -- upper boundary
                world[lin][row]["type"] = "boundary"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_boundary_up
            elseif (lin == worldsize.tiles.y) and (row ~= 1) and (row ~= worldsize.tiles.x) then
                -- bottom boundary
                world[lin][row]["type"] = "boundary"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_boundary_down
            elseif (row == 1) and (lin ~= 1) and (lin ~= worldsize.tiles.x) then
                -- left boundary
                world[lin][row]["type"] = "boundary"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_boundary_left
            elseif (row == worldsize.tiles.x) and (lin ~= 1) and (lin ~= worldsize.tiles.x) then
                -- right boundary
                world[lin][row]["type"] = "boundary"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_boundary_right
            end
        end
    end

    -- terrain
    terrains = {}

    -- actors
    actors = {}

    -- hero starts bottom left
    hero = {}
    hero.x = 2 -- x cell
    hero.y = worldsize.tiles.y-1 -- y cell
    hero.orient = 0 -- up

    -- mouse cursor
    cursorImg = love.graphics.newImage("Media/Graphic/Mouse/Sword.png") -- load in a custom mouse image
    love.mouse.setVisible(false)
    love.mouse.setGrab(true)

    -- turn management
    turn = {}
    turn.current = 0
    turn.max = 20
    turn.next = true

end

function love.update(dt)
    -- is called before a frame is drawn, all math should be done in here

    -- keyboard actions for our hero
    if (turn.next == true) then
        if love.keyboard.isDown("left") then
            hero.x = hero.x - 1
            hero.orient = 240
        elseif love.keyboard.isDown("right") then
            hero.x = hero.x + 1
            hero.orient = 90
        elseif love.keyboard.isDown("up") then
            hero.y = hero.y - 1
            hero.orient = 0
        elseif love.keyboard.isDown("down") then
            hero.y = hero.y + 1
            hero.orient = 180
        end
    end
end

function love.draw()
    -- draws all stuff to the screen

    -- Map draw
    for lin=1,worldsize.tiles.y do
        for row=1,worldsize.tiles.x do
            x = centerOfCell(row)
            y = centerOfCell(lin)
            if (world[lin][row]["graphic"] ~= nil) then
                love.graphics.draw(tile_black_IMG,x,y,math.rad(0),1,1,tile_size/2,tile_size/2)
            end
            love.graphics.print(".",x,y)
        end
    end

    -- Panel draw
    x = tile_size*worldsize.tiles.x
    love.graphics.draw(panel_IMG,x,0)

    -- Draw player at current position
    imageXSize = player_IMG:getWidth()
    imageYSize = player_IMG:getHeight()
    x = centerOfCell(hero.x)
    y = centerOfCell(hero.y)
    love.graphics.draw(player_IMG,x,y,math.rad(hero.orient),1,1,imageXSize/2,imageYSize/2)

    -- Draw the custom mouse cursor
    x, y = love.mouse.getPosition() -- get the position of the mouse
    love.graphics.draw(cursorImg, x, y) -- draw the custom mouse image

end

function centerOfCell(logicalC)
    -- turns a games tile coordinate into from up/left pixel coordinate
    return ((logicalC-1)*tile_size)+(tile_size/2)
end

function love.keyreleased(key)
    -- bye bye
    if key == "escape" then
      love.event.push("quit")   -- actually causes the app to quit
    end
end

-- Custom graphic mouse cursor HOWTO

-- declare in love.load()
    -- cursor = love.graphics.newImage("crosshair.png")
    -- love.mouse.setVisible(false)
    -- love.mouse.setGrab(true)

-- call it in love.draw()
    -- love.graphics.draw(cursor, love.mouse.getX() - cursor:getWidth() / 2, love.mouse.getY() - cursor:getHeight() / 2)

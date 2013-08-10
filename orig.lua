-- SHARD 1.0.1
-- (c)UG 2013


function love.load()
    -- loads all stuff and assets we need for our game
    
    -- line for the ZeroBrane debugger
    if arg and arg[#arg] == "-debug" then require("mobdebug").start() end
    
    -- tiles graphics
    tile_black_IMG        = love.graphics.newImage("Media/Graphic/Tiles/tile_black.png")
    tile_exit_IMG         = love.graphics.newImage("Media/Graphic/Tiles/entry.png")
    wall_corner_left_IMG  = love.graphics.newImage("Media/Graphic/Tiles/corner_left.png")
    wall_corner_right_IMG = love.graphics.newImage("Media/Graphic/Tiles/corner_right.png")
    corner_IMG            = love.graphics.newImage("Media/Graphic/Tiles/corner.png")
    wall_IMG              = love.graphics.newImage("Media/Graphic/Tiles/wall.png")
    player_IMG            = love.graphics.newImage("Media/Graphic/Sprites/S_Heroe_Warrior.png")
    shard_ICON            = love.graphics.newImage("Media/Graphic/Logo/icon32.png")

    -- tile size: constant
    tile_size = 96

    -- wall sizes: constant
    wall_length    = 96
    wall_thickness = 48

    -- world size: constants
    worldsize = {}
    worldsize.tiles = {}
    worldsize.tiles.x = 8   -- world size (in number of tiles)
    worldsize.tiles.y = 8   -- value must be even, because a 4x4 zone hold the dragon's lair in the center of the map
    worldsize.pixel = {}
    worldsize.pixel.x = (worldsize.tiles.x*tile_size) + (2*wall_thickness)   -- world size (in pixels)
    worldsize.pixel.y = (worldsize.tiles.y*tile_size) + (2*wall_thickness)

    -- game icon
    love.graphics.setIcon(shard_ICON) -- does not work :(

--[[

                                                    (96)       (48)
     0    1      2      3      4      5      6      7      8     9
   .---.------.------.------.------.------.------.------.------.---.
   | e |  e   |   w  |   w  |   w  |   w  |   w  |   w  |  e   | e | 0 (48)
   .---+------+------+------+------+------+------+------+------+---.
   | e |  e   |      |      |      |      |      |      |  e   | e | 1
   |   | T1,1 | T1,2 | T1,3 | T1,4 | T1,5 | T1,6 | T1,7 | T1,8 |   |
   .---+------+------+------+------+------+------+------+------+---.
   | w |      |      |      |      |      |      |      |      | w | 2 (96)
   |   | T2,1 |      |      |      |      |      |      |      |   |
   .---+------+------+------+------+------+------+------+------+---.
   | w |      |      |      |      |      |      |      |      | w | 3
   |   | T3,1 |      |      |      |      |      |      |      |   |
   .---+------+------+------+------+------+------+------+------+---.
   | w |      |      |      |  L   |  L   |      |      |      | w | 4
   |   |      |      |      |      |      |      |      |      |   |
   .---+------+------+------+------+------+------+------+------+---.
   | w |      |      |      |  L   |  L   |      |      |      | w | 5
   |   |      |      |      |      |      |      |      |      |   |
   .---+------+------+------+------+------+------+------+------+---.
   | w |      |      |      |      |      |      |      |      | w | 6
   |   |      |      |      |      |      |      |      |      |   |
   .---+------+------+------+------+------+------+------+------+---.
   | w |      |      |      |      |      |      |      |      | w | 7
   |   |      |      |      |      |      |      |      |      |   |
   .---+------+------+------+------+------+------+------+------+---.
   | e |  e   |      |      |      |      |      |      |  e   | e | 8
   |   | T8,1 |      |      |      |      |      |      | T8,8 |   |
   .---+------+------+------+------+------+------+------+------+---.
   | e |  e   |   w  |   w  |   w  |   w  |   w  |   w  |  e   | e | 9
   '---'------'------'------'------'------'------'------'------'---'
]]--



    -- Command panel
    panel_IMG = love.graphics.newImage("Media/Graphic/Panel/Panel.png")
    panelWidth = panel_IMG:getWidth()
    panelHeight = panel_IMG:getHeight()

    -- Display Mode
    xdisplay = (tile_size*worldsize.tiles.x)+(2*wall_thickness)+panelWidth
    ydisplay = math.max((tile_size*worldsize.tiles.y)+(2*wall_thickness),panelHeight)
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
    for lin=0,worldsize.tiles.y+1 do
        world[lin] = {}
        for row=0,worldsize.tiles.x+1 do

            -- default tile configuration
            world[lin][row] = {}
            world[lin][row]["status"] = "fog" -- status of the tile fog|explored
            world[lin][row]["type"] = "dungeon" -- exit|boundary|dungeon|lair
            world[lin][row]["terrain"] = {} -- nature of the tile terrain: all different rooms
            world[lin][row]["graphic"] = tile_black_IMG -- unexplored tile
            world[lin][row]["orient"] = 0 -- display orientation
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

            -- four entry/exit points of the map?
            elseif (lin == 1) and (row == 1) then
                -- top left
                world[lin][row]["type"] = "exit"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_exit_IMG
                world[lin][row]["orient"] = 90
            elseif (lin == 1) and (row == worldsize.tiles.x) then
                -- top right
                world[lin][row]["type"] = "exit"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_exit_IMG
                world[lin][row]["orient"] = 180
            elseif (lin == worldsize.tiles.y) and (row == 1) then
                -- bottom left
                world[lin][row]["type"] = "exit"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_exit_IMG
                world[lin][row]["orient"] = 0
            elseif (lin == worldsize.tiles.y) and (row == worldsize.tiles.x) then
                -- bottom right
                world[lin][row]["type"] = "exit"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_exit_IMG
                world[lin][row]["orient"] = 270

            -- boundaries?
            elseif (lin == 0) and (row ~= 0) and (row ~= worldsize.tiles.x+1) then
                -- upper boundary
                world[lin][row]["type"] = "boundary"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_boundary_up
            elseif (lin == worldsize.tiles.y+1) and (row ~= 0) and (row ~= worldsize.tiles.x+1) then
                -- bottom boundary
                world[lin][row]["type"] = "boundary"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_boundary_down
            elseif (row == 0) and (lin ~= 0) and (lin ~= worldsize.tiles.x+1) then
                -- left boundary
                world[lin][row]["type"] = "boundary"
                world[lin][row]["status"] = "explored"
                world[lin][row]["graphic"] = tile_boundary_left
            elseif (row == worldsize.tiles.x+1) and (lin ~= 0) and (lin ~= worldsize.tiles.x+1) then
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
    hero.x = 1 -- x cell
    hero.y = worldsize.tiles.y -- y cell
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
            hero.x = math.max(hero.x-1,1)
            hero.orient = 240
        elseif love.keyboard.isDown("right") then
            hero.x = math.min(hero.x+1,worldsize.tiles.x)
            hero.orient = 90
        elseif love.keyboard.isDown("up") then
            hero.y = math.max(hero.y-1,1)
            hero.orient = 0
        elseif love.keyboard.isDown("down") then
            hero.y = math.min(hero.y+1,worldsize.tiles.y)
            hero.orient = 180
        end
    end
end

function love.draw()
    -- draws all stuff to the screen

    -- debug only
    local x = love.mouse.getX()
    local y = love.mouse.getY()
    -- Draws the position on screen.
    love.graphics.print("Mouse is at (" .. x .. "," .. y .. ")", 1000, 800)


    -- Map draw

        -- First, draw walls

            -- Top
    for row=2,worldsize.tiles.x-1 do
        x,y = centerOfCell(row,0)
        love.graphics.draw(wall_IMG,x,y,math.rad(180),1,1,wall_IMG:getWidth()/2,wall_IMG:getHeight()/2)
    end

            -- Top Left
    x,y = centerOfCell(1,0)
    love.graphics.draw(wall_corner_left_IMG,x,y,math.rad(90),1,1,wall_corner_left_IMG:getWidth()/2,wall_corner_left_IMG:getHeight()/2)
    x,y = centerOfCell(0,1)
    love.graphics.draw(wall_corner_right_IMG,x,y,math.rad(90),1,1,wall_corner_right_IMG:getWidth()/2,wall_corner_right_IMG:getHeight()/2)
    x,y = centerOfCell(0,0)
    love.graphics.draw(corner_IMG,x,y,math.rad(90),1,1,corner_IMG:getWidth()/2,corner_IMG:getHeight()/2)

            -- Top Right
    x,y = centerOfCell(worldsize.tiles.x+1,1)
    love.graphics.draw(wall_corner_left_IMG,x,y,math.rad(180),1,1,wall_corner_left_IMG:getWidth()/2,wall_corner_left_IMG:getHeight()/2)
    x,y = centerOfCell(worldsize.tiles.x,0)
    love.graphics.draw(wall_corner_right_IMG,x,y,math.rad(180),1,1,wall_corner_right_IMG:getWidth()/2,wall_corner_right_IMG:getHeight()/2)
    x,y = centerOfCell(worldsize.tiles.x+1,0)
    love.graphics.draw(corner_IMG,x,y,math.rad(180),1,1,corner_IMG:getWidth()/2,corner_IMG:getHeight()/2)

            -- Bottom
    for row=2,worldsize.tiles.x-1 do
        x,y = centerOfCell(row,worldsize.tiles.y+1)
        love.graphics.draw(wall_IMG,x,y,math.rad(0),1,1,wall_IMG:getWidth()/2,wall_IMG:getHeight()/2)
    end

            -- Bottom Left
    x,y = centerOfCell(0,worldsize.tiles.y)
    love.graphics.draw(wall_corner_left_IMG,x,y,math.rad(0),1,1,wall_corner_left_IMG:getWidth()/2,wall_corner_left_IMG:getHeight()/2)
    x,y = centerOfCell(1,worldsize.tiles.y+1)
    love.graphics.draw(wall_corner_right_IMG,x,y,math.rad(0),1,1,wall_corner_right_IMG:getWidth()/2,wall_corner_right_IMG:getHeight()/2)
    x,y = centerOfCell(0,worldsize.tiles.y+1)
    love.graphics.draw(corner_IMG,x,y,math.rad(0),1,1,corner_IMG:getWidth()/2,corner_IMG:getHeight()/2)

            -- Bottom Right
    x,y = centerOfCell(worldsize.tiles.x,worldsize.tiles.y+1)
    love.graphics.draw(wall_corner_left_IMG,x,y,math.rad(270),1,1,wall_corner_left_IMG:getWidth()/2,wall_corner_left_IMG:getHeight()/2)
    x,y = centerOfCell(worldsize.tiles.x+1,worldsize.tiles.y)
    love.graphics.draw(wall_corner_right_IMG,x,y,math.rad(270),1,1,wall_corner_right_IMG:getWidth()/2,wall_corner_right_IMG:getHeight()/2)
    x,y = centerOfCell(worldsize.tiles.x+1,worldsize.tiles.y+1)
    love.graphics.draw(corner_IMG,x,y,math.rad(270),1,1,corner_IMG:getWidth()/2,corner_IMG:getHeight()/2)

            -- Right
    for lin=2,worldsize.tiles.y-1 do
        x,y = centerOfCell(worldsize.tiles.x+1,lin)
        love.graphics.draw(wall_IMG,x,y,math.rad(270),1,1,wall_IMG:getWidth()/2,wall_IMG:getHeight()/2)
    end
           -- Left
    for lin=2,worldsize.tiles.y-1 do
        x,y = centerOfCell(0,lin)
        love.graphics.draw(wall_IMG,x,y,math.rad(90),1,1,wall_IMG:getWidth()/2,wall_IMG:getHeight()/2)
    end

        -- Draw entries/exits sides
            -- Up Left

    -- Endly, draw playable world
    for lin=1,worldsize.tiles.y do
        for row=1,worldsize.tiles.x do
            x,y = centerOfCell(row,lin)
            if (world[lin][row]["status"] == "fog") then
                love.graphics.draw(world[lin][row]["graphic"],x,y,math.rad(0),1,1,world[lin][row]["graphic"]:getWidth()/2,world[lin][row]["graphic"]:getHeight()/2)
            end
            if (world[lin][row]["type"] == "exit") then
                love.graphics.draw(world[lin][row]["graphic"],x,y,math.rad(world[lin][row]["orient"]),1,1,world[lin][row]["graphic"]:getWidth()/2,world[lin][row]["graphic"]:getHeight()/2)
            end
        end
    end

    -- Panel draw
    x = (tile_size*worldsize.tiles.x)+(2*wall_thickness)
    love.graphics.draw(panel_IMG,x,0)

    -- Mettre un mouseover sur le bouton Next Turn
    -- cf https://love2d.org/forums/viewtopic.php?f=4&p=73180

    -- Draw player at current position
    imageXSize = player_IMG:getWidth()
    imageYSize = player_IMG:getHeight()
    x,y = centerOfCell(hero.x,hero.y)
    love.graphics.draw(player_IMG,x,y,math.rad(hero.orient),1,1,imageXSize/2,imageYSize/2)

    -- Draw the custom mouse cursor
    x, y = love.mouse.getPosition() -- get the position of the mouse
    love.graphics.draw(cursorImg, x, y) -- draw the custom mouse image
    -- afficher autour du tile sous la souris une animation des bords du tile

    -- Finir par tracer toutes les lignes du plateau et un centre au milieu de chaque cellule
    -- Pour valider les algos :)
        -- lignes verticales
    for col=0, worldsize.tiles.x+2 do
        if (col == 0) then
            x1 = 0
        elseif (col == worldsize.tiles.x+2) then
            x1 = worldsize.pixel.x
        else
            x1 = ((col-1)*tile_size)+wall_thickness
        end
        love.graphics.line(x1, 0, x1, worldsize.pixel.y)
    end
        -- lignes horizontales
    for line=0, worldsize.tiles.y+2 do
        if (line == 0) then
            y1 = 0
        elseif (line == worldsize.tiles.y+2) then
            y1 = worldsize.pixel.y
        else
            y1 = ((line-1)*tile_size)+wall_thickness
        end
        love.graphics.line(0, y1,worldsize.pixel.x, y1)
    end
    
end

function centerOfCell(logicalRow,logicalLine)
    -- turns a games cell coordinates into from center pixel coordinates
    if (logicalRow == 0) then
        x = wall_thickness/2
    elseif (logicalRow == worldsize.tiles.x+1) then
        x = wall_thickness + ((logicalRow-1)*tile_size) + (wall_thickness/2)
    else
        x = wall_thickness + (logicalRow*tile_size) - (tile_size/2)
    end
    if (logicalLine == 0) then
        y = wall_thickness/2
    elseif (logicalLine == worldsize.tiles.y+1) then
        y = wall_thickness + ((logicalLine-1)*tile_size) + (wall_thickness/2)
    else
        y = wall_thickness + (logicalLine*tile_size) - (tile_size/2)
    end
    return x,y
end

function love.keyreleased(key)
    -- bye bye
    if key == "escape" then
      love.event.push("quit")   -- actually causes the app to quit
    end
end
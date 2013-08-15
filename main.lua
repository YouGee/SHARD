-- SHARD 0.0.2
-- (c)UG 2013


function love.load()
        -- loads all stuff and assets

    -- ZeroBrane debugger
    if arg and arg[#arg] == "-debug" then require("mobdebug").start() end

    -- Load&execute ton game configuration file
    local ok, chunk, result
    ok, chunk = pcall( love.filesystem.load, "SHARD_data.lua" )
    if not ok then
        print('The following error happend: '..tostring(chunk))
    else
    ok, result = pcall(chunk)
        if not ok then
            print('The following error happened: '..tostring(result))
        else
            print('Loading config file: '..tostring(result))
        end
    end

    -- Init display
    success = love.graphics.setMode(xdisplaySize,ydisplaySize,false,true,0)

    -- Loading graphical ressources
    player_IMG            = love.graphics.newImage("Media/Graphic/Sprites/S_Heroe_Warrior.png")
    tile_black_IMG        = love.graphics.newImage("Media/Graphic/Tiles/tile_black.png")
    panel_IMG             = love.graphics.newImage("Media/Graphic/Panel/Panel.png")

    -- Background sound loading
    if PlaySound == "yes" then
        -- Loading sound ressources
        WaterDrop_sfx = love.audio.newSource("Media/Sound/Ambiance/WaterDrops.ogg", "static")
        -- Playing ambiant sound
        WaterDrop_sfx:setLooping(true)
        WaterDrop_sfx:setVolume(0.3)
        love.audio.play(WaterDrop_sfx)
    end

    -- Allowed world sizes
    allowedWorldSize = {}
    allowedWorldSizeNumber = 4
    for i=1,allowedWorldSizeNumber do
        allowedWorldSize[i] = {}
        allowedWorldSize[i]["x"] = 8*i
        allowedWorldSize[i]["y"] = 8*i
    end
    
    -- Not yet choosable dungeon size
    chosenWorldSize = {}
    chosenWorldSize.x = allowedWorldSize[1]["x"]
    chosenWorldSize.y = allowedWorldSize[1]["y"]
    print("Chosen world size is "..chosenWorldSize.x.."x"..chosenWorldSize.y)

    -- Zoom is the display ratio factor, controlled by mouse wheel
    zoomLevel = {}
    zoomLevel.min     = 0.5
    zoomLevel.max     = 1
    zoomLevel.step    = 0.1
    zoomLevel.default = 0.5
    zoomLevel.current = zoomLevel.default

    -- Tiles dimensions
    tile = {}
    tile.NativeSize = 96
    tile.CurrentSize = tile.NativeSize*zoomLevel.current

    -- On screen debug data
    debugRow        = xdisplaySize-180
    debugFirstLine  = panel_IMG:getHeight()- 100
    debugDeltaLines = 20

    -- Default color
    defaultColor = {}
    defaultColor.r, defaultColor.g, defaultColor.b, defaultColor.a = love.graphics.getColor( )

    -- Font
    myFont = love.graphics.newFont("Media/Fonts/Knigqst.ttf", 20)
    love.graphics.setFont(myFont)

    -- Zoom dependant displayed tiled area
    displayableTiles = {}
    anchorTile = {} -- first bottom left displayed cell
    anchorTile.x = 1
    anchorTile.y = 1
    maxTile = {} -- last top right displayed cell


    -- Tiled world definition
    world = {}
    for lin=1,chosenWorldSize.x do
        world[lin] = {}
        for row=1,chosenWorldSize.y do
            world[lin][row] = {}
            world[lin][row]["graphic"] = tile_black_IMG -- unexplored tile
        end
    end

    -- Hero starts bottom left
    hero = {}
    hero.x,hero.y = 4,3 -- x,y cell
    hero.orient = 0 -- up
end

function love.update(dt)
        -- called before a frame is drawn, all math should be done in here

end

function love.draw()
        -- draws all stuff to the screen

    -- display right panel
    love.graphics.draw(panel_IMG,xdisplaySize-panel_IMG:getWidth(),0)

    -- update anchorTile (zoom can change it)
    displayableTiles.x,displayableTiles.y = maxDisplayableTiles()
    if (anchorTile.x+displayableTiles.x-1) > chosenWorldSize.x then
        anchorTile.x = 1
    end
    if (anchorTile.y+displayableTiles.y-1) > chosenWorldSize.y then
        anchorTile.y = 1
    end

    -- draw tiles
    print("------ New tiles refresh, zoom ="..zoomLevel.current.." ------")
    print("MaxTiles "..displayableTiles.x..","..displayableTiles.y)
    for displayedX=1,displayableTiles.x do
        for displayedY=1,displayableTiles.y do
            tileIDx = anchorTile.x + displayedX -1
            tileIDy = anchorTile.y + displayedY -1
            print("tileIDx = "..tileIDx..", tileIDy ="..tileIDy)
            drawTile(world[tileIDx][tileIDy]["graphic"],displayedX,displayedY)
            -- debug
            local upperLeftX,upperLeftY = logical2physical(displayedX,displayedY,tile.NativeSize,tile.NativeSize)
            love.graphics.print(tileIDx..","..tileIDy,upperLeftX+(tile.NativeSize*zoomLevel.current/4),upperLeftY+(tile.NativeSize*zoomLevel.current/3))
        end
    end
    -- remember the upper right displayed tile
    maxTile.x = anchorTile.x + displayableTiles.x - 1
    maxTile.y = anchorTile.y + displayableTiles.y - 1

    -- Draw player at current position
    local offsetX,offsetY = imageOffset(player_IMG)
    local x,y = logical2physical(hero.x+anchorTile.x-1,hero.y+anchorTile.y-1,tile.NativeSize,tile.NativeSize)
    love.graphics.draw(player_IMG,x,y,0,zoomLevel.current,zoomLevel.current,offsetX,offsetY)
    printDebugLine("Player is at "..x..","..y, 2, "black")

    -- Draw debug informations
    printDebugLine("Mouse is at "..love.mouse.getX()..","..love.mouse.getY(), 1, "black")
    printDebugLine("Zoom Level is "..zoomLevel.current, 3, "black")
end

function drawTile(ressource,logicalX,logicalY)
    -- draw a tile at logical cell coordinates (logicalX,logicalY), (1,1) being bottom left
    local x,y = logical2physical(logicalX,logicalY,tile.NativeSize,tile.NativeSize)
    love.graphics.draw(ressource,x,y,0,zoomLevel.current,zoomLevel.current,0,0)
end

function logical2physical(logicalX,logicalY,imageSizeX,imageSizeY)
    return ((logicalX-1)*imageSizeX*zoomLevel.current),(ydisplaySize - (logicalY*imageSizeY*zoomLevel.current))
end

function imageOffset(ressource)
    local ressourceWidth =  ressource:getWidth()*zoomLevel.current
    local ressourceHeight = ressource:getHeight()*zoomLevel.current
    return -(tile.CurrentSize-ressourceWidth)/2,-(tile.CurrentSize-ressourceHeight)/2
end

function love.keyreleased(key)
    -- bye bye
    if key == "escape" then
      love.event.push("quit")   -- actually causes the app to quit
    end
    -- map panning
    if key == "left" then
        anchorTile.x = math.max(anchorTile.x-1,1)
    elseif key == "right" then
        -- cant we pan?
        if maxTile.x < chosenWorldSize.x then
            anchorTile.x = math.min(anchorTile.x+1,chosenWorldSize.x)
        end
    elseif key == "down" then
        anchorTile.y = math.max(anchorTile.y-1,1)
    elseif key == "up" then
        -- cant we pan?
        if maxTile.y < chosenWorldSize.y then
            anchorTile.y = math.min(anchorTile.y+1,chosenWorldSize.y)
        end
    end
end

function love.mousepressed(x,y,button)
    -- Handle mouse buttons events
    if button == "wu" then
        -- please zoom out
        zoomLevel.current = math.min(zoomLevel.max,zoomLevel.current+zoomLevel.step)
    elseif button == "wd" then
        -- please zoom in
        zoomLevel.current = math.max(zoomLevel.min,zoomLevel.current-zoomLevel.step)
    elseif button == "m" then
        -- zoom reset
        zoomLevel.current = zoomLevel.default
    end
        -- apply zoom factor to current tile size
    tile.CurrentSize = tile.NativeSize*zoomLevel.current
end

function printDebugLine(data,line,aColor)
    -- print debug line in top right corner of the graphical window
    mySetColor(aColor)
    love.graphics.print(data, debugRow, debugFirstLine+(debugDeltaLines*(line-1)))
    mySetColor("default")
end

function mySetColor(aColor)
    if aColor == "red" then
        love.graphics.setColor(255,0,100)
    elseif (aColor == "black") then
        love.graphics.setColor(0,0,0)
    elseif (aColor == "default") then
        love.graphics.setColor(defaultColor.r, defaultColor.g, defaultColor.b, defaultColor.a)
    end
end

function maxDisplayableTiles()
    -- returns the number of tiles that can be displayed given the window size and the current zoom
    local verticalEmptySpace = 5 -- pixels left blank between right most tiles and the panel
    local xTiles = (xdisplaySize-(panel_IMG:getWidth()+verticalEmptySpace))/tile.CurrentSize
    local yTiles = ydisplaySize/tile.CurrentSize
    return math.min(chosenWorldSize.x,math.floor(xTiles)),math.min(chosenWorldSize.y,math.floor(yTiles))
end

-- **BUGS**
--  * Joueur mal positionné si zoom/panning
--  * Gérer coorectement coordonnées logiques et coordonnées du monde pour les tiles et les acteurs

-- **EVOLS**
--  * Centrer l'affichage sur le joueur si appui sur la molette
--  * Pour faire bouger le joueur au lieu de le téléporter : https://love2d.org/wiki/Tutorial:Gridlocked_Player
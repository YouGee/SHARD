-- SHARD 0.0.3
-- (c)UG 2013, 2014


function love.load()
        -- loads all stuff and assets

    -- External librairies
    require("AnAL")

    -- ZeroBrane debugger
    if arg and arg[#arg] == "-debug" then require("mobdebug").start() end

    -- Load&execute the game configuration file
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
    imageRessource = {}
        -- player
    imageRessource.player   = love.graphics.newImage("Media/Graphic/Sprites/S_Heroe_Warrior.png")
        -- panel
    imageRessource.panel    = love.graphics.newImage("Media/Graphic/Panel/Panel.png")
        -- tiles
    imageRessource.tile     = {}
    imageRessource.tile.UKN = love.graphics.newImage("Media/Graphic/Tiles/tile_black.png")
        -- destination icon
    imageRessource.dest     = love.graphics.newImage("Media/Graphic/Sprites/Shoeprint.png")

    -- mouse cursor
    cursorImg = love.graphics.newImage("Media/Graphic/Mouse/Sword.png") -- load in a custom mouse image
    love.mouse.setVisible(false)
    love.mouse.setGrab(false)

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
    debugRow         = xdisplaySize-180
    debugFirstLine   = imageRessource.panel:getHeight()- 200
    debugDeltaLine   = 20
    debugCurrentLine = debugFirstLine

    -- Default color
    defaultColor = {}
    defaultColor.r, defaultColor.g, defaultColor.b, defaultColor.a = love.graphics.getColor( )

    -- Font
    myFont = love.graphics.newFont("Media/Fonts/Knigqst.ttf", 20)
    love.graphics.setFont(myFont)

    -- Zoom dependant displayed tiled area
    displayableTiles = {}
    minTile = {} -- first bottom left displayed cell
    minTile.x = 1
    minTile.y = 1
    maxTile = {} -- last top right displayed cell
    maxTile.x = nil
    maxTile.y = nil

    -- Tiles associated graphics
    terrainImage = {}
    terrainImage["UKN"] = tile_black_IMG

    -- Tiled world definition
    world = {}
    for x=1,chosenWorldSize.x do
        world[x] = {}
        for y=1,chosenWorldSize.y do
            world[x][y] = {}
            world[x][y]["type"] = "UKN" -- unexplored tile
            world[x][y]["visible"] = "no"
            world[x][y]["orient"] = 0
            world[x][y]["display"] = {}
            world[x][y]["display"]["x"] = x
            world[x][y]["display"]["y"] = y
            world[x][y]["valid_dest"] = "no"
            world[x][y]["player"] = "no"
            world[x][y]["actor"] = nil
        end
    end

    -- Hero starts bottom left
    hero = {}
    hero.x,hero.y = 4,3 -- x,y cell
    hero.orient = 0 -- up
    world[4][3]["player"] = "yes"

    -- Mouse
    mouse = {}
    mouseIsInTile = {}

    -- world panning
    shifting = {}
    shifting.x,shifting.y = 0,0
end

function love.update(dt)
        -- called before a frame is drawn, all math should be done in here

    -- reset debugCurrentLine
    debugCurrentLine = debugFirstLine

    -- how many tiles can be displayed
    displayableTiles.x,displayableTiles.y = maxDisplayableTiles()
    
    -- set the bottom left tile
    if (minTile.x+displayableTiles.x-1) > chosenWorldSize.x then
        minTile.x = 1 -- minTile.x too big
    end
    if (minTile.y+displayableTiles.y-1) > chosenWorldSize.y then
        minTile.y = 1 -- minTile.y too big
    end
   
    -- set the upper right tile
    maxTile.x = minTile.x + displayableTiles.x - 1
    maxTile.y = minTile.y + displayableTiles.y - 1

    -- update mouse position
    mouse.x, mouse.y = love.mouse.getPosition()
    mouseIsInTile.x,mouseIsInTile.y = physical2tile(mouse.x, mouse.y)
    
    -- update world tiles
    for x=1,chosenWorldSize.x do
        for y=1,chosenWorldSize.y do
            -- visibility
            if  (x >= minTile.x) and
                (x <= maxTile.x) and
                (y >= minTile.y) and
                (y <= maxTile.y) then
                world[x][y]["visible"] = "yes"
            else
                world[x][y]["visible"] = "no"
            end
            -- shifting
            if shifting.x ~= 0 then
                world[x][y]["display"]["x"] =  world[x][y]["display"]["x"] + shifting.x
            end
            if shifting.y ~= 0 then
                world[x][y]["display"]["y"] =  world[x][y]["display"]["y"] + shifting.y
            end
            -- valid destination tile?
            if (mouseIsInTile.x == x) and (mouseIsInTile.y == y) and playerIsNear(x,y) then
                world[x][y]["valid_dest"] = "yes"
            else
                world[x][y]["valid_dest"] = "no"
            end
        end
    end

    -- reset panning
    shifting.x,shifting.y = 0,0

end

function love.draw()
        -- draws all stuff to the screen

    -- display right panel
    love.graphics.draw(imageRessource.panel,xdisplaySize-imageRessource.panel:getWidth(),0)
    printDebugLine("dispTiles: "..displayableTiles.x..","..displayableTiles.y, "black")
    printDebugLine("minTile: "..minTile.x..","..minTile.y, "black")
    printDebugLine("maxTile: "..maxTile.x..","..maxTile.y, "black")

    -- display tiles
    for x=1,chosenWorldSize.x do
        for y=1,chosenWorldSize.y do
            if world[x][y]["visible"] == "yes" then
                -- display the tile
                drawTile(imageRessource.tile[world[x][y]["type"]],world[x][y]["display"]["x"],world[x][y]["display"]["y"])
                -- debug: display cell coordinates
                local upperLeftX,upperLeftY = logical2physical(world[x][y]["display"]["x"],world[x][y]["display"]["y"],tile.NativeSize,tile.NativeSize)
                love.graphics.print(x..","..y,upperLeftX+(tile.NativeSize*zoomLevel.current/4),upperLeftY+(tile.NativeSize*zoomLevel.current/3))
                -- display this cell as a valid destination?
                if world[x][y]["valid_dest"] == "yes" then
                    local offsetX,offsetY = imageOffset(imageRessource.dest)
                    local x,y = logical2physical(world[x][y]["display"]["x"],world[x][y]["display"]["y"],tile.NativeSize,tile.NativeSize)
                    love.graphics.draw(imageRessource.dest,x,y,0,zoomLevel.current,zoomLevel.current,offsetX,offsetY)
                    printDebugLine("Feet offset "..offsetX..","..offsetY, "black")
                end
                -- display the player?
                if world[x][y]["player"] == "yes" then
                    local offsetX,offsetY = imageOffset(imageRessource.player)
                    local x,y = logical2physical(world[x][y]["display"]["x"],world[x][y]["display"]["y"],tile.NativeSize,tile.NativeSize)
                    love.graphics.draw(imageRessource.player,x,y,hero.orient,zoomLevel.current,zoomLevel.current,offsetX,offsetY)
                    printDebugLine("Player is at "..x..","..y, "black")
                end
            end
        end
    end

    -- Draw the custom mouse cursor
    love.graphics.draw(cursorImg, mouse.x, mouse.y)
    printDebugLine("Mouse in "..mouseIsInTile.x..","..mouseIsInTile.y, "black")

    -- Draw debug informations
    printDebugLine("Mouse is at "..love.mouse.getX()..","..love.mouse.getY(), "black")
    printDebugLine("Zoom Level is "..zoomLevel.current, "black")
end

function drawTile(ressource,logicalX,logicalY)
    -- draw a tile at logical cell coordinates (logicalX,logicalY), (1,1) being bottom left
    local x,y = logical2physical(logicalX,logicalY,tile.NativeSize,tile.NativeSize)
    love.graphics.draw(ressource,x,y,0,zoomLevel.current,zoomLevel.current,0,0)
end

function logical2physical(logicalX,logicalY,imageSizeX,imageSizeY)
    return ((logicalX-1)*imageSizeX*zoomLevel.current),(ydisplaySize - (logicalY*imageSizeY*zoomLevel.current))
end

function physical2tile(physicalX,physicalY)
    -- tells wether physicalX,physicalY point is within a tile or not
    local tileX,tileY = math.floor(physicalX/tile.CurrentSize)+1,math.floor((ydisplaySize-physicalY)/tile.CurrentSize)+1
    if (tileX > displayableTiles.x) or (tileY > displayableTiles.y) then
        tileX = "out"
        tileY = "out"
    end
    return tileX,tileY
end

function imageOffset(ressource)
    -- computes the offset for displaying an image in the center of a tile
    local ressourceWidth,ressourceHeight =  ressource:getWidth()*zoomLevel.current,ressource:getHeight()*zoomLevel.current
    return -(tile.CurrentSize-ressourceWidth)/2,-(tile.CurrentSize-ressourceHeight)/2
end

function love.keyreleased(key)
    -- bye bye
    if key == "escape" then
      love.event.push("quit")   -- actually causes the app to quit
    end
    -- map panning
    if key == "left" then
        if minTile.x > 1 then
            shifting.x,shifting.y = 1,0
            minTile.x = minTile.x-1
        end
    elseif key == "right" then
        if maxTile.x < chosenWorldSize.x then
            shifting.x,shifting.y = -1,0
            minTile.x = minTile.x+1
        end
    elseif key == "down" then
        if minTile.y > 1 then
            shifting.x,shifting.y = 0,1
            minTile.y = minTile.y-1
        end
    elseif key == "up" then
        if maxTile.y < chosenWorldSize.y then
            shifting.x,shifting.y = 0,-1
            minTile.y = minTile.y+1
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

function printDebugLine(data,aColor)
    -- print debug line in top right corner of the graphical window
    mySetColor(aColor)
    love.graphics.print(data, debugRow, debugCurrentLine)
    debugCurrentLine = debugCurrentLine+debugDeltaLine
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
    local xTiles = (xdisplaySize-(imageRessource.panel:getWidth()+verticalEmptySpace))/tile.CurrentSize
    local yTiles = ydisplaySize/tile.CurrentSize
    return math.min(chosenWorldSize.x,math.floor(xTiles)),math.min(chosenWorldSize.y,math.floor(yTiles))
end

function playerIsNear(x,y)
    -- is the tile x,y adjacent to the player?
    if (x == hero.x) and ((y == hero.y-1) or (y == hero.y+1)) then
        return true
    elseif ((x == hero.x+1) or (x == hero.x-1)) and (y == hero.y) then
        return true
    else
        return false
    end
end

-- **BUGS**
--  * Le imageOffset semble ne bien fonctionner que quand le ZoomLeval est à 1 (cf affichage des pieds jaunes si zommlevel <> 1)

-- **EVOLS**
--  * Centrer l'affichage sur le joueur si appui sur la molette
--  * Pour faire bouger le joueur au lieu de le téléporter : https://love2d.org/wiki/Tutorial:Gridlocked_Player
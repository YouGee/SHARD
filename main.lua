-- SHARD 0.0.1
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

    -- allowed world sizes
    allowedWorldSize = {}
    allowedWorldSizeNumber = 4
    for i=1,allowedWorldSizeNumber do
        allowedWorldSize[i] = {}
        allowedWorldSize[i]["x"] = 8*i
        allowedWorldSize[i]["y"] = 8*i
    end
    
    -- Pour l'instant, pas de choix possible pour la taille du donjon
    chosenWorldSize = {}
    chosenWorldSize.x = allowedWorldSize[1]["x"]
    chosenWorldSize.y = allowedWorldSize[1]["y"]

    for i=1,allowedWorldSizeNumber do
        print("World size "..i.." is "..allowedWorldSize[i]["x"].."x"..allowedWorldSize[i]["y"])
    end

    -- zoom is the display ratio factor, it's controlled by mouse wheel
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

    -- Defautt color
    defaultColor = {}
    defaultColor.r, defaultColor.g, defaultColor.b, defaultColor.a = love.graphics.getColor( )

    -- Font
    myFont = love.graphics.newFont("Media/Fonts/Knigqst.ttf", 20)
    love.graphics.setFont(myFont)

end

function love.update(dt)
        -- called before a frame is drawn, all math should be done in here
end

function love.draw()
        -- draws all stuff to the screen

    -- display panel
    love.graphics.draw(panel_IMG,xdisplaySize-panel_IMG:getWidth(),0)

    -- draw tiles
    for x=1,chosenWorldSize.x do
        for y=1,chosenWorldSize.y do
            drawTile(tile_black_IMG,x,y)
        end
    end

    -- Draw player at current position
    local offsetX,offsetY = imageOffset(player_IMG)
    local x,y = logical2physical(4,5,tile.NativeSize,tile.NativeSize)
    love.graphics.draw(player_IMG,x,y,0,zoomLevel.current,zoomLevel.current,offsetX,offsetY)
    printDebugLine("Player is at "..x..","..y, 2, "black")

    -- Draw debug informations
    printDebugLine("Mouse is at "..love.mouse.getX()..","..love.mouse.getY(), 1, "black")
    printDebugLine("Zoom Level is "..zoomLevel.current, 3, "black")
end

function drawTile(ressource,logicalX,logicalY)
    local x,y = logical2physical(logicalX,logicalY,tile.NativeSize,tile.NativeSize)
    love.graphics.draw(ressource,x,y,0,zoomLevel.current,zoomLevel.current,0,0)
    love.graphics.print(logicalX..","..logicalY,x+(tile.NativeSize*zoomLevel.current/4),y+(tile.NativeSize*zoomLevel.current/3))
end

function logical2physical(logicalX,logicalY,imageSizeX,imageSizeY)
    local physicalX,physicalY
    local physicalX =                ((logicalX-1)*imageSizeX*zoomLevel.current)
    local physicalY = ydisplaySize - (logicalY*imageSizeY*zoomLevel.current)
    return physicalX,physicalY
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


-- A FAIRE
-- * Corriger le player qui ne s'affiche pas au milieu de la tile

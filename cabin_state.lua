function gstate_globals()
    -- wall drawing variables, calculated once here.
    walldata={}
    walldata.wallwidth=15
    walldata.wallxstart_l=0
    walldata.wallxstart_r=127-walldata.wallwidth
    walldata.starty=20
    walldata.y_diff=walldata.starty+5 -- to give the lines an angle. y diff between starting linedata and ending linedata of the line
    walldata.middley=64
    walldata.endy=127


    wall_decoration={}
    wall_decoration.blank=function()end
    --
    wall_decoration.door=function(c)
        local startx=55
        local starty=127-walldata.y_diff
        local width=startx+17
        local height=starty-30

        rectfill(startx,starty,    width,height, c)
        rect(startx, starty, width,height, 0) -- border
        circfill(width-3,starty-15, 1, 10)
    end
    --
    wall_decoration.window=function()
        local startx=40
        local starty=walldata.starty+walldata.y_diff + 20
        local width=startx+48
        local height=starty+20

        rectfill(startx, starty, width,height, 12)
        
        line(startx, starty+10, width, starty+10, 7)
        line(startx+24, starty, startx+24,height, 7)
        rect(startx, starty, width,height, 0)
    end
    --
    wall_decoration.ghost=function()
        spr(16, 80,60, 1,1)
    end

    -- the rooms are ardered in an array
    -- backward action moves to the previous room on the stack. exits the cabin if there are no rooms in the stack
    -- forward action moves to the next room in the rooms array
    -- forwardforward action moves to the next of the next room in the array. this allowsme to have 3 doors in the same room
    -- only 2 going forward and one of course going backwards
    -- this are the actions that the player interacts with when facing something on the current facing wall
    wallactions={}
    wallactions.backward=0
    wallactions.forward=1
    wallactions.forwardforward=2
    wallactions.readtext=3 -- read an item like a newspaper or something
    wallactions.pickupitem=4 -- read an item like a newspaper or something
    wallactions.noaction=-1
end


function cabin_state(prev_state)
    gstate_globals()

    fillp(0)
    camera(0,0)

    local s={}
    local updateables={}
    local drawables={}

    -- utility function to define the rooms
    -- todo: this must be outside this state, so that the caller of the state
    -- sends the cabin (a.k.a. a rooms array created by this func)
    -- check to see if you need to define constants before using this. the wall_decoration pops in mind
    function create_rooms()
        local room1=room()
        --forwards
        room1.walls[1].draw=wall_decoration.window

        --left
        room1.walls[4].draw=wall_decoration.door
        room1.walls[4].doorc=4
        room1.walls[4].wallaction=wallactions.forwardforward -- to room 3

        --right
        room1.walls[2].draw=wall_decoration.blank --room1.walls[2].draw=wall_decoration.door    
        --room1.walls[2].doorc=4
        --room1.walls[2].wallaction=wallactions.forward -- to room 2

        -- local room2=room()
        -- --forward
        -- room2.walls[1].draw=wall_decoration.window
        -- --right
        -- room2.walls[2].draw=wall_decoration.blank
        -- --left
        -- room2.walls[4].draw=wall_decoration.window


        local room3=room()
        -- forward
        room3.walls[1].draw=wall_decoration.blank--room3.walls[1].draw=wall_decoration.door    
        -- room3.walls[1].doorc=4
        -- room3.walls[1].wallaction=wallactions.forwardforward
        
        --right
        room3.walls[2].draw=wall_decoration.door    
        room3.walls[2].doorc=4
        room3.walls[2].wallaction=wallactions.forward

        local room4=room()
        --room4.walls[1].draw=wall_decoration.window
        room4.walls[2].draw=wall_decoration.ghost
        room4.walls[2].wallaction=wallactions.readtext
        room4.walls[2].text="go east to find your\nmurderer"
        room4.walls[2].forceinteract=true

        room4.walls[4].draw=wall_decoration.window

        room4.walls[1].draw=wall_decoration.door    
        room4.walls[1].doorc=4
        room4.walls[1].wallaction=wallactions.forwardforward

        local room5=room()
        room5.walls[4].draw=wall_decoration.window

        local room6=room()
        room6.walls[4].draw=wall_decoration.window
        room6.walls[1].draw=wall_decoration.window
        
        -- returns the rooms array
        return {room1, room2, room3, room4, room5, room6}
    end

    function cabin(rooms, drawables, prev_state)
        local c={}
        -- cabin description:
        -- ******************
        -- arbitrary limit of rooms is a grid of 5x5
        -- this is important due to how the map is generated
        -- the entrance of the cabin is always x=3, y=5
        -- here's an example of a cabin with 4 total rooms in the 5x5 max map grid
        -- [ ][ ][ ][ ][ ]
        -- [ ][ ][ ][ ][ ]
        -- [ ][ ][ ][ ][ ]
        -- [ ][R][ ][ ][ ]
        -- [ ][R][E][R][ ]


        -- rooms description:
        -- ******************
        -- every time you enter a new room, you're facing forward.
        -- when you return to the previous room, you're facing the opposite wall
        -- that got you into the previous room (common sense) (wall_id+2)%4=oposite_wall_id
        -- this means that the numbers illustrated in the drawing might rotate, it all comes down
        -- to the side where hero enters the room (which is always the #3 back, but rotated in the context of the cabin)
        --
        --           1                                4
        --        forward                            left
        --       _________                        _________
        --      |         |                      |         |
        --  4   |         |   2           3      |         |     1
        -- left |    x    | right        back         x    |  forward
        --      |         |           (entrance) |         |
        --      |___   ___|                      |_________|
        --           3                                2
        --          back                            right
        --       (entrance)                     
        c.rooms=rooms
        c.curroom=rooms[1]  -- when you change the curroom you need to change the curroom_idx too!!!
        c.curroom_idx=1     -- this too
        c.roomstack={}      -- stores the curroom_idx and needs to be used in a FILO fashion

        c.hero_facing=1

        -- 0=no room, 1=entrance, 2=room
        -- the entrance is fixed, the rest of the rooms appear
        -- when hero enters into them
        c.map={ 
            {0,0,0,0,0}, 
            {0,0,0,0,0},
            {0,0,0,0,0},
            {0,0,0,0,0},
            {0,0,1,0,0}
        }
        c.hero_mapcoord={3,5} -- x,y
        c.compass=1 -- pointing north by default. clockwise order = {'n','e','s','w'}
        c.printtext=""
        
        function c:turnleft(hero)
            -- for wall rendering
            local facing = (hero.facing-1)%4
            if(facing==0) facing=4

            -- compass. for orientation in map
            local pointsto= (self.compass-1)%4
            if(pointsto==0) pointsto=4
            self.compass=pointsto

            hero.facing=facing
            self.hero_facing=facing

            self.printtext=""

            local force = self.curroom.walls[self.hero_facing].forceinteract
            if(force) self:interact(hero)
        end

        function c:turnright(hero)
            -- for wall rendering
            local facing = (hero.facing+1)%4
            if(facing==0) facing=4

            -- compass. for orientation in map
            local pointsto= (self.compass+1)%4
            if(pointsto==0) pointsto=4
            self.compass=pointsto

            hero.facing=facing
            self.hero_facing=facing

            self.printtext=""
            local force = self.curroom.walls[self.hero_facing].forceinteract
            if(force) self:interact(hero)
        end

        -- when you press up you interact with what you have forward
        function c:interact(hero)
            local act = self.curroom.walls[self.hero_facing].wallaction
            if (act == wallactions.noaction) return

            if act == wallactions.backward then
                sfx(8)
                if self.curroom_idx == 1 then
                    -- exit cabin. set the state you want to go on exit here
                    curstate=prev_state
                    return
                end

                local roomstacked=self.roomstack[#self.roomstack]
                del(self.roomstack, roomstacked)
                self.curroom_idx = roomstacked[1]
                self.hero_facing = roomstacked[2]
                self.hero_mapcoord[1] = roomstacked[3]
                self.hero_mapcoord[2] = roomstacked[4]
                hero.facing=self.hero_facing
                self.curroom = self.rooms[self.curroom_idx]
            elseif act == wallactions.forward or act == wallactions.forwardforward then
                sfx(8)
                local facing_back = (self.hero_facing+2)%4
                if(facing_back == 0) facing_back=4
                add(self.roomstack, {self.curroom_idx, facing_back, self.hero_mapcoord[1], self.hero_mapcoord[2]})
                
                -- take care of hero world map coordinates
                if(self.compass == 1) self.hero_mapcoord[2] -= 1 -- north
                if(self.compass == 2) self.hero_mapcoord[1] += 1 -- east
                if(self.compass == 3) self.hero_mapcoord[2] += 1 -- south
                if(self.compass == 4) self.hero_mapcoord[1] -= 1 -- west
                self.map[self.hero_mapcoord[2]][self.hero_mapcoord[1]] = 2 -- add the discovered room to the map

                -- every time hero enters a room, is facing "1", "forward"
                self.hero_facing=1
                hero.facing=1

                if act == wallactions.forward then
                    self.curroom_idx += 1
                    self.curroom = self.rooms[self.curroom_idx]
                elseif act == wallactions.forwardforward then
                    self.curroom_idx += 2
                    self.curroom = self.rooms[self.curroom_idx]
                end
            elseif act == wallactions.readtext then
                self.printtext=self.curroom.walls[self.hero_facing].text
                curstate=vertigo_state(curstate, prev_state)
            end
        end


        -- map render variables
        -- ********************
        local mstartx=107
        local mstarty=1
        local roomsize=3 -- each room will be 3x3

        -- compass render variables
        -- ************************
        local cwidth=3
        local cvx=98        -- compass vertical x
        local cvy=6
        local chx=cvx    -- compass horizontal x
        local chy=cwidth+cvy
        local ccol=7 -- compass color

        function c:draw()
            -- draws the room
            rectfill(0,0,127,127, 3)  -- floor & roof
            draw_rooflines(0)
            draw_lwall(9)
            draw_rwall(9)
            draw_backwall(9)

            -- draws the wall decorations
            local obj=self.curroom.walls[self.hero_facing]
            obj.draw(obj.doorc)

            -- draw map
            local curroomx=mstartx
            local curroomy=mstarty
            local ycoord=1
            local xcoord=1
            rectfill(0,0, 127, 17, 0) -- hud rectangle
            foreach(self.map, 
                function(row)
                    foreach(row, 
                        function(room)
                            -- draw room rectangle
                            if room > 0 then
                                local c=2
                                if(room == 1) c=11
                                rect(curroomx, curroomy,  curroomx+roomsize, curroomy+roomsize, c)
                            
                                -- draw player dot
                                if(self.hero_mapcoord[1] == xcoord and self.hero_mapcoord[2] == ycoord) rect(curroomx+1, curroomy+1,  curroomx+2, curroomy+2, 8)
                            end

                            curroomx+=roomsize+1
                            xcoord+=1
                        end
                    )

                    ycoord+=1
                    xcoord =1

                    curroomy+=roomsize
                    curroomx =mstartx
                end
            )

            -- draw compass
            circ(chx, cvy+cwidth, cwidth+2, 6)
            if(self.compass == 1)then
                line(cvx, cvy,  cvx, cvy+cwidth, ccol) -- north
                pset(cvx, cvy+cwidth,0)
                pset(cvx, cvy,8)
            end
            if(self.compass == 2)then
                line(chx, chy,  chx+cwidth, chy, ccol) -- east
                pset(chx, chy,0)
                pset(chx+cwidth, chy,8)
            end
            if(self.compass == 3)then
                line(cvx, cvy+cwidth,  cvx, cvy+(cwidth*2), ccol) -- south
                pset(cvx, cvy+cwidth,0)
                pset(cvx, cvy+(cwidth*2),8)
            end
            if(self.compass == 4)then
                line(chx, chy,  chx-cwidth, chy, ccol) -- west
                pset(chx, chy,0)
                pset(chx-cwidth, chy,8)
            end

            if not (self.printtext== "") then
                local x0=15
                local y0=67
                rectfill(x0,y0, x0+96, y0+20,0 )
                print(self.printtext, 18, 70, 7)
            end
        end

        return c
    end

    function hero(x,y)
        local e=entity({})
        e:setpos(x,y)

        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true

        e.facing=1 -- by default it faces forward
        function e:update()
            if(btnp(0))then     --left
                self.cabin:turnleft(self)
            elseif(btnp(1))then --right
                self.cabin:turnright(self)
            end
            
            if(btnp(2))then          --up
                self.cabin:interact(self)
            elseif(btnp(3))then  --down
            
            end
        end
        
        function e:draw()
            spr(25,self.x, self.y, 3,4)
        end

        return e
    end

    -- creates a room object with the backdoor and all the id's. this data doesn't change
    -- what is left for you to do is to add decorations on the rest of the walls (if you want... although you should)
    function room()
        local r={}

        local forward={}
        local back={}
        local left={}
        local right={}

        forward.id=1
        right.id=2
        back.id=3
        left.id=4

        -- defaults all walls to no door action
        forward.wallaction=wallactions.noaction
        right.wallaction=wallactions.noaction
        left.wallaction=wallactions.noaction

        -- makes all walls blank...
        forward.draw=wall_decoration.blank
        left.draw=wall_decoration.blank
        right.draw=wall_decoration.blank

        -- ...except for the backdoor
        back.draw=wall_decoration.door
        back.doorc=5
        back.wallaction = wallactions.backward

        r.walls={forward, right, back, left}
        return r
    end

    -- describes a line. used to draw walls with perspective
    function linedata(x0,y0, x1,y1)
        local c={}
        c.x0=x0
        c.y0=y0
        c.x1=x1
        c.y1=y1

        -- checks if two linedatas are equal
        function c:compare(to)
            local comparison = 
                ( self.x0 == to.x0 and 
                self.y0 == to.y0 and
                self.x1 == to.x1 and 
                self.y1 == to.y1 )

            return comparison
        end

        -- moves this linedata <px> down
        function c:move_down(px)
            self.y0 += px
            self.y1 += px

            return self
        end

        return c
    end

    -- paints consecutive lines to create the perspective effect
    -- startc is lower "y" than endc
    function paintwall(startc, endc, c, up)
        local cur = startc

        while (not cur:compare(endc)) do
            line(cur.x0, cur.y0,  cur.x1, cur.y1, c)
            cur = cur:move_down(1)
        end
    end

    function draw_lwall(c)
        local d = walldata
        local lines=30

        local s_angledown= linedata(d.wallxstart_l,d.starty  ,   d.wallwidth, d.starty   +d.y_diff)
        local e_angledown= linedata(d.wallxstart_l,d.starty+lines ,   d.wallwidth, d.starty+lines  +d.y_diff)
        local s_angleup  = linedata(d.wallxstart_l,d.endy  -lines ,   d.wallwidth, d.endy  -lines  -d.y_diff)
        local e_angleup  = linedata(d.wallxstart_l,d.endy    ,   d.wallwidth, d.endy     -d.y_diff)

        paintwall(s_angleup  , e_angleup  , c)
        paintwall(s_angledown, e_angledown, c)
        rectfill(d.wallxstart_l, d.starty+lines,  d.wallxstart_l+15, d.endy-lines, c)
    end

    function draw_rwall(c)
        local d=walldata
        local lines=30

        local s_angleup   = linedata(d.wallxstart_r,d.starty +d.y_diff,   d.wallwidth+d.wallxstart_r, d.starty )
        local e_angleup   = linedata(d.wallxstart_r,d.starty+lines+d.y_diff,   d.wallwidth+d.wallxstart_r, d.starty+lines)
        local s_angledown = linedata(d.wallxstart_r,d.endy-lines-d.y_diff,   d.wallwidth+d.wallxstart_r, d.endy-lines)
        local e_angledown = linedata(d.wallxstart_r,d.endy   -d.y_diff,   d.wallwidth+d.wallxstart_r, d.endy   )

        paintwall(s_angleup  , e_angleup  , c)
        paintwall(s_angledown, e_angledown, c)
        rectfill(d.wallxstart_r+0, d.starty+lines,  127, d.endy-d.y_diff, c)
    end

    -- the rectangle in the middle of the screen
    -- this expects to have walls on each side
    function draw_backwall(c)
        rectfill(walldata.wallwidth , walldata.y_diff+walldata.starty,   127-walldata.wallwidth, 127-walldata.y_diff, 9)
        line(walldata.wallwidth     , walldata.y_diff+walldata.starty,   walldata.wallwidth    , 127-walldata.y_diff, 0)
        line(127-walldata.wallwidth , walldata.y_diff+walldata.starty,   127-walldata.wallwidth, 127-walldata.y_diff, 0)
    end

    function draw_rooflines(c)
        local cury = walldata.y_diff+walldata.starty
        local spacing = 2

        while cury > 0 do
            line(0,cury, 127, cury, c)
            cury -= spacing
            spacing += 1
        end
    end



    local building = cabin(create_rooms(), drawables, prev_state)
    add(drawables, building)


    local h=hero(30,127-29)
    add(updateables,h)
    add(drawables,h)
    h.cabin = building









    













    s.update=function()
        for u in all(updateables) do
            u:update()
        end
    end

    
    s.draw=function()
        cls() -- todo: i only need to redraw the "forward" wall, the left,right walls are always the same, the floor and ceiling too
        
        for d in all(drawables) do
            d:draw()
        end
    end

    return s
end


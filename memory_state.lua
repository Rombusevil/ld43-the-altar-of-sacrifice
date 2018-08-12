-- state
function memory_state(plat_state, msg, value)
    music(1)
    local s={}
    local ents={}
    local h=plat_state.hero
    local timeout=0

    function arrow()
        local e={}
        e.positions={}
        add(e.positions, {x=20  -2, y=88}) -- slot 1
        add(e.positions, {x=49  -2, y=88}) -- slot 2
        add(e.positions, {x=78  -2, y=88}) -- slot 3
        add(e.positions, {x=107 -2, y=88}) -- no
        e.posidx=1

        function e:update()
            if btnp(0) and self.posidx > 1 then     --left
                self.posidx-=1
                sfx(3)
            elseif btnp(1) and self.posidx <= #self.positions-1 then --right
                self.posidx+=1
                sfx(3)
            end
        end
    
        function e:draw()
            local p=self.positions[self.posidx]
            spr(10, p.x, p.y)
        end
    
        return e
    end

    camera(0,0)

    local txt={}
    add(txt, tutils({text=msg,centerx=false, x=20,y=8,fg=7,bg=0,bordered=false,shadowed=true,sh=2}))

    local yy=40
    add(txt, tutils({text="would you like to save this",centerx=true,y=yy,fg=7,bg=0})) yy+=8
    add(txt, tutils({text="memory?",centerx=true,y=yy,fg=7,bg=0}))

    local pressx=tutils({text="❎ to choose", blink=true, on_time=15, centerx=true,y=110,fg=7,bg=1,shadowed=true, sh=6})
    local arrchoose=tutils({text="arrows to choose", blink=true, on_time=15, centerx=true,y=110,fg=7,bg=1,shadowed=true, sh=6})

    local memorized=tutils({text="memorized!",centerx=true,centery=true,fg=7,bg=13, bordered=true})
    local overwrite=tutils({text="overwrite memory?",centerx=true,y=50,fg=7,bg=13, bordered=true})


    local ar=arrow(20, 86)
    add(ents, ar)
    
    local valuestored=false
    local valueoverwrite=false
    local tick=0
    local pendingval=""
    

    local fuse=true
    s.update=function()
        if(valuestored or valueoverwrite) return
        timeout+=1

        for u in all(ents) do
            u:update()
        end

        if timeout > 30 and (btnp(4) or btnp(5)) then -- X || O
            sfx(5)
            if(ar.posidx==4) curstate=plat_state return -- "no" selected

            if h.memslots[ar.posidx] == "empty" then
                h.memslots[ar.posidx] = value
                valuestored=true
            else
                -- memory slot occupied, overwrite?
                pendingval=value
                valueoverwrite=true
            end
        end
        if timeout > 30 and fuse then
            fuse=false
            add(txt, pressx)
        end
    end

    s.draw=function()
        cls()
        rectfill(0,0,127,127, 1)

        if not valuestored and not valueoverwrite then
            local sx = 10
            local yy = 60
            local tw = 24 -- thought widht (also height as there are squares)
            local sp = 5  -- spacing
            for i=1,4 do
                local slottxt="SLOT "..i;
                local c=5
                local to=0 -- text offset

                if(h.memslots[i] != "empty") c=8 

                if i == 4 then
                    slottxt="NO"
                    c=6
                    to=8
                end
                rectfill(sx,yy, sx+tw, yy+tw, c)
                print(slottxt, sx+1+to, yy+8, 7)

                sx+=tw+sp
            end
            
            for d in all(ents) do
                d:draw()
            end
            for d in all(txt) do
                d:draw()
            end
        elseif valuestored then
            memorized:draw()
            tick+=1
            if(tick > 30) curstate=plat_state
        elseif valueoverwrite then
            overwrite:draw()
            arrchoose:draw()

            spr(27, 15,64) --izq
            spr(11, 104,64) --der
            print("yes              no",25,65,7)

            --todo: check for key press
            if btnp(0) then --left
                sfx(5)
                valueoverwrite=false
                valuestored=true
                h.memslots[ar.posidx] = pendingval
            elseif btnp(1) then --right
                sfx(5)
                valueoverwrite=false
            end
        end
    end

    return s
end
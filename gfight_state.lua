-- state
function gfight_state(prev_state,plat_state,text,value,final_b)
    music(2)
    local s={}
    local updateables={}
    local drawables={}
    local bullets=plat_state.bullets
    local h=plat_state.hero
    local hprevpos={x=h.x, y=h.y}
    local cambkp={x=plat_state.cam.x, y=plat_state.cam.y}
    local collideborders=true

    camera(0,0)
    plat_state.cam.x=0
    plat_state.cam.y=0

    h.x=10
    if(final_b) plat_state.hero.finalboss=true

    add(updateables,h)
    add(drawables,h)


    function miniboss(x,y,ebullets)
        local anim_obj=anim()
        local bounds_obj=bbox(16,16)
        if final_b then
            anim_obj:add(167,2,0.2,3,3)
            bounds_obj=bbox(24,24)
        else
            anim_obj:add(12,2,0.2,2,2)
        end
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)

        e.health=20
        if(final_b) e.health=30
        
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true

        function e:hurt(dmg)
            self:flicker(10)
            self.health-=dmg
            sfx(11)
            if self.health <= 0 then
                if final_b then
                    curstate=win_state()
                else
                    sfx(12)
                    local mstate=memory_state(prev_state, text, value)
                    goback(mstate)
                end
            end
        end

        function bul(x,y, bullets)
            local anim_obj=anim()
            anim_obj:add(44,2,0.2,1,1)
        
            local e=entity(anim_obj)
            e:setpos(x,y)
            e:set_anim(1)
        
            local bounds_obj=bbox(8,8,0,0,4,4)
            e:set_bounds(bounds_obj)
            -- e.debugbounds=true
            e.spd=1.8
            e.tick=0
            e.middle=y
            e.dmg=3
        
            function e:update()
                self.tick+=0.05
                self:setx(self.x-self.spd)
                self:sety( sin(self.tick) *10 + self.middle+flr(rnd(3)))
            end

            function e:kill()
                del(bullets,self)
            end
                    
            return e
        end


        e.tick=0
        e.bulltick=0
        function e:update()
            local spdt=0.01
            self.tick+=spdt

            --movement
            self:sety( sin(self.tick) *20 + 50)

            if(final_b) self:setx( self.x + sin(self.tick) )

            if flr(sin(self.tick)) % 2 == 0 then
                if self.bulltick < 100  then
                    self.bulltick+=0.5
                    if(self.bulltick % 10 == 0) add(ebullets, bul(self.x, self.y, ebullets)) sfx(10)
                end
            else
                self.bulltick=0
            end
        end
    
        return e
    end

    function goback(prev_state)
        collideborders=false
        plat_state.cam.x=cambkp.x
        plat_state.cam.y=cambkp.y
        plat_state.hero:setx(hprevpos.x)
        plat_state.hero:sety(hprevpos.y)

        

        curstate=prev_state
    end


    local ebullets={}
    local xx=109
    if(final_b) xx=105
    local ghost=miniboss(xx, 60, ebullets)
    add(updateables, ghost)
    add(drawables, ghost)

    s.update=function()
        for u in all(updateables) do
            u:update()
        end

        plat_state.updateblts(bullets, {ghost}, false)
        plat_state.updateblts(ebullets, {h}, false)

        if(collides(h,ghost)) h:hurt(6)

        -- collide with invisible walls
        if(not collideborders) return
        if(h.x < 1) h:setx(1)
        if(h.x >118) h:setx(118)
    end

    s.draw=function()
        cls()
        --rectfill(0,0,127,127, 1)

        -- wall
        fillp(0b0000001010000000)
        rectfill(0,0,127,127, 13) 

        -- floor
        --fillp(0b0000001010000000)
        --fillp(0b1111000100010001)
        fillp(0)
        rectfill(0,70,127,127, 6) 
        
        



        for d in all(drawables) do
            d:draw()
        end
        for d in all(bullets) do
            d:draw()
        end
        for d in all(ebullets) do
            d:draw()
        end

        plat_state.drawhud()
        
        -- ghost life bar
        local xx=44
        rectfill(xx,25,  xx+(ghost.health*2),28, 9)
        rectfill(xx,26,  xx+(ghost.health*2),27, 8)
    end

    return s
end
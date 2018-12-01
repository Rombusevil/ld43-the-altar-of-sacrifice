-- state
function platforming_state()
    music(1)
    local s={}
    local updateables={}
    local drawables={}
    local thiefs={}
    local victims={}
    local potions={}
    local cam={x=0, y=0}
    s.cam = cam

    local showmsg=false
    local showmsgtxt=""
    local rtick=0
    
    local level={}
    level.hs=150 -- house spacing
    level.fw=150 -- forest width
    level.es=128 -- end spacing
    level.hw=48  -- house width
    level.hcnt=3 -- house count
    level.w=(level.hw+level.hs)*level.hcnt+level.fw +level.es

    local deferpos=false
    local pendingmusic=false
    
    function hero(x,y, platforming_state)
        local anim_obj=anim()
        local e=entity(anim_obj)

        anim_obj:add(1,4,0.3,1,2) -- running
        anim_obj:add(5,1,0.01,1,2) -- idle
        anim_obj:add(6,1,0.01,1,2) -- jumping
        anim_obj:add(7,1,0.5,2,2,true, function() e.shooting=false end) -- shoot
        anim_obj:add(123,4,0.3,1,2) -- running with someone on the head
        anim_obj:add(127,1,0.01,1,2) -- idle with victim

        e:setpos(x,y)
        e:set_anim(2) --idle
    
        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
        --e.debugbounds=true

        e.money = 0
        e.pigs = 0
        e.sacrifices=19
        e.maxsacrifices=20
        e.potions=0
        e.pickedupvictim=nil
        e.blockright=false
        e.blockleft=false
        e.reputation = 15

        e.speed=2--1.3
        e.floory=y
        e.jumppw=7
        e.grav=0.01
        e.baseaccel=1
        e.accel=e.baseaccel
        e.grounded=true
        e.shooting=false
        e.wasshooting=false
        e.compensate=false
        e.compensatepx=-8
        e.health=20
        e.dmg=1
        e.finalboss=false
        e.atacking=false
        e.dropping=false
        
        e.notifyjumpobj=nil

        -- this vars are loaded in the vertigo_state
        e.codes={}
        e.codes.dir='none'
        e.codes.exit=false
        e.codes.dircode='none'
        e.btimer=0
        e.prevsh=-6300

        function e:hurt(dmg)
            if(self.flickerer.is_flickering) return
            self:flicker(30)
            self.health-=dmg
            sfx(5)

            if self.potions > 0 and self.health < 15 then
                -- todo:sfx use potion
                self.potions-=1
                self.health+=5
            end
            if self.health <= 0 then
                music(-1)
                sfx(17)
                curstate=s
                pendingmusic=true
                -- self:reset()
                curstate=gameover_state(s)
            end
        end

        function e:set_notifyjumpobj(obj)
            self.notifyjumpobj=obj
        end

        function e:pickup(victim)
            self.pickedupvictim = victim
        end

        function e:doblockright()
            self.blockright=true
        end
        function e:doblockleft()
            self.blockleft=true
        end

        function e:controlls()
            self.btimer+=1
            if not self.shooting then
                if self.wasshooting then
                    self.wasshooting=false
                    if self.compensate then
                        self.compensate=false
                        self:setx(self.x-self.compensatepx)
                    end
                end

                if btn(0) and not self.blockleft then     --left
                    self:setx(self.x-self.speed)
                    self.flipx=true
                    if self.pickedupvictim == nil then
                        self:set_anim(1) --running
                    else
                        self:set_anim(5) -- running with victim
                    end

                    self.blockright=false
                elseif btn(1) and not self.blockright then --right
                    self:setx(self.x+self.speed)
                    self.flipx=false
                    if self.pickedupvictim ==nil then
                        self:set_anim(1) --running
                    else
                        self:set_anim(5) -- running with victim
                    end
                    self.blockleft=false
                else
                    if self.pickedupvictim ==nil then
                        self:set_anim(2) --idle
                    else
                        self:set_anim(6) -- idle with victim
                    end
                end
                
                -- the up button is taken care on the house entity
                
                if btnp(4) and self.grounded then -- "o"
                    -- jump
                    sfx(4)
                    if self.notifyjumpobj ~= nil then
                        self.notifyjumpobj:tick({x=self.x, y=self.y})
                    end

                    self.grav = -self.jumppw
                    self:sety(self.y + self.grav)
                    self.grounded=false
                    self:set_anim(3) --jump
                elseif not self.grounded then
                    self:set_anim(3) --jump
                end
                
                if btnp(5) then -- "x"
                    if self.pickedupvictim == nil then 
                        self.dropping = false
                        self.atacking = true
                        if(self.btimer-self.prevsh < 5) return -- don't allow shooting like machine gun
                        self.prevsh=self.btimer

                        sfx(0)
                        self.shooting=true
                        self.wasshooting=true
                        self:set_anim(4) -- shoot
                        local dir=1     -- not flip
                        if self.flipx then
                            dir=-1      -- flip
                            -- flag compensate true
                            self.compensate=true
                            self:setx(self.x+self.compensatepx)
                            self.bounds.xoff1+=8
                            self.bounds.xoff2+=8
                        end
                    else
                        self.dropping = true
                    end
                else
                    self.atacking = false
                    self.dropping = false
                end
            end
            
        end
    
        function e:update()
            self:controlls()

            if self.pigs > 0 and self.pickedupvictim == nil then
                local p = pig(self.x-2, self.y-8)
                p.flipy = true
                add(drawables, p)
                
                self.pickedupvictim = p
            end

            if self.y < self.floory then
                --you're jumping
                self:sety(self.y + self.grav)
                self.grav += self.baseaccel * self.accel
                self.accel+=0.1
            else
                -- not jumping
                self.grav = 0.01
                self.accel = self.baseaccel
                self.grounded=true
            end

            if self.y > self.floory then
                -- compensate gravity
                self:sety(self.floory)
                self.grounded=true
            end
            
            if self.pickedupvictim ~=nil then
                self.pickedupvictim:setx(self.x-4)
                self.pickedupvictim:sety(self.y-8)
            end
        end

        -- when you gameover and choose continue, everything's the same but your stats, that get resetted
        function e:reset()
            self.pigs = 0
            self.sacrifices=0
            self.money = 0
            self.speed=2--1.3
            self.floory=y
            self.jumppw=7
            self.grav=0.01
            self.baseaccel=1
            self.accel=e.baseaccel
            self.grounded=true
            self.shooting=false
            self.wasshooting=false
            self.compensate=false
            self.compensatepx=-8
            self.health=20
            self.potions=0
            self.codes.dir='none'
            self.codes.exit=false
            self.codes.dircode='none'
            
            if self.finalboss then
                self.finalboss=false
                deferpos=750 -- lo mando al forest
            end
        end

        return e
    end

    function house(x,y, hero)
        local e=entity({})
        e:setpos(x,y)
        
        local bounds_obj=bbox(12,32, 6, 26, -13, -26)
        e:set_bounds(bounds_obj)
        --e.debugbounds=true
        e.h = hero

        local idx=flr(rnd(4))+1

        function e:update()
            if collides(self,self.h) and btnp(2) and hero.pickedupvictim == nil then -- up btn
                -- *************
                --  enter house
                -- *************
                sfx(8)
                -- todo: add shopstate
                local prevcam = {}
                prevcam.x = s.cam.x
                prevcam.y = s.cam.y
                curstate=shop_state(s)
                s.cam=prevcam
            end            
        end
        
        function e:draw()
            spr(32, x,y, 6, 4)
            rectfill(x+32,y+16,x+46,y+20, 5)
            print("shop",x+32,y+16,8)
            -- if(self.debugbounds) self.bounds:printbounds()
        end

        return e
    end

    function potion(x,y,potions)
        local e=entity(anim_obj)
        e:setpos(x,y)
    
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true

        sfx(3)
        function e:pickup(hero)
            del(potions, self)
            sfx(2)
            -- i'm limiting the potions counter to 10
            if(hero.potions >= 10) return
            hero.potions +=1
        end
    
        function e:draw()
            spr(9, self.x, self.y, 1,1)
        end
    
        return e
    end
 
    -- the potioncreator creates a potion every threshold kills of enemies
    function potioncreator(potions)
        local p={}

        p.ticks=0
        p.threshold=3
        p.lastpos={}
        p.lastpos.x = 60
        p.lastpos.y = 60

        function p:tick(pos)
            self.ticks+=1
            self.lastpos.x=pos.x
            self.lastpos.y=pos.y
        end

        function p:update()
            if self.ticks >= self.threshold then
                self.ticks=0
                local p=potion(self.lastpos.x, self.lastpos.y-14, potions)
                add(potions, p)
            end
        end

        return p
    end

    function pig(x,y,updateables,drawables)
        local anim_obj=anim()
        anim_obj:add(96,1,0.1,2,1) -- idle
        local e=entity(anim_obj)
        anim_obj:add(86,4,0.7,1,1,true,function() 
            del(updateables, e)
            del(drawables, e)
        end) -- explode

        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(16,8)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true

        function e:sacrifice()
            self:set_anim(4)
            -- todo: usar la cant de s.hero.pigs  para sumar points o whatever
            s.hero.pigs = 0
        end

        function e:update()
        end
    
        return e
    end

    function victim(x,y, hero, updateables, drawables,victims)
        local anim_obj=anim()

        local spr=40
        if (flr(rnd(2)+1)%2==0) spr+=04
        -- todo randomizar si spr 40 o 44
        anim_obj:add(spr,1,0.1,1,2) -- idle
        anim_obj:add(spr+1,3,0.9,1,2) -- runaway
        anim_obj:add(spr+32,1,0.9,2,1) -- pickedup
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.health = 3
        e.runaway = false
        e.runawaytick=0
        e.dir = 1

        anim_obj:add(86,4,0.7,1,1,true,function() 
            del(updateables, e)
            del(drawables, e)
            del(victims, e)
        end) -- explode
    
        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
        --e.debugbounds=true
    
        function e:hurt(attacker)
            self.health -=1
            self:flicker(0.2)
            if self.health <= 0 then
                attacker:pickup(self)
                self:set_anim(3) -- pickedup
                self.runaway=false
            else
                self.runaway=true
                self:set_anim(2)
                if flr(rnd(1)+1)%2==0 then
                    self.dir=-1
                    self.flipx=true
                else
                    self.dir=1
                end
            end
        end

        function e:sacrifice()
            self:set_anim(4)
        end

        function e:update()
            if self.runaway then
                self.runawaytick+=1
                self:setx(self.x+(0.8*self.dir))
                if self.runawaytick > 60 then
                    self.dir *= -1
                    self.flipx=not self.flipx
                    self.runawaytick = 0
                end
            end
        end
    
        return e
    end

    function npccreator(parent,houses,potioncreator,hero,updateables,drawables, level)
        local e={}

        e.ticks=1
        e.threshold=2
        e.lastpos={}
        e.lastpos.x = 60
        e.lastpos.y = 70

        e.timetick=0
        e.timethreshold=100
        e.ttick=0
        e.thiefthreshold=1000
        e.level = level

        function e:tick(pos)
            self.ticks+=1
            self.ttick+=1
            self.lastpos.x=pos.x
            --self.lastpos.y=pos.y
        end

        function e:update()
            self.timetick+=1
            self.ttick+=1

            if self.ttick > self.thiefthreshold then
                self.ttick=0
                local t = thief(-16, 70, self.level)
                add(drawables, t)
                add(updateables, t)
                add(thiefs, t)
            end

            if self.timetick > self.timethreshold then
                local idx = flr(rnd(#houses-1)+1)
                local house = houses[idx]
                local rndx = rnd(10)

                local v = victim(house.x-rndx,70,hero, updateables,drawables,parent)
                for b in all(parent) do
                    if collides(b, v) then 
                        v:sety(v.y+rnd(3))
                        v:setx(v.x+rnd(6)*16)
                    end
                end

                add(parent, v)
                self.timetick=0
            end
        end

        return e
    end

    function boulderrain(updateables, drawables, boulders,hero)
        local e={}

        e.ticks=1
        e.threshold=20
        e.lastpos={}
        e.lastpos.x = 60
        e.lastpos.y = 70

        e.timetick=0
        e.timethreshold=250
        e.bouldershadow={}
        function e:newboulder(x,y,spd)
            local anim_obj=anim()
            -- spr: 10,12,14
            local sprs = {25, 10, 12, 14}
            local spridx = flr(rnd(3)+1)
            local w=2
            local h=2
            if spridx == 1 then 
                w=1
                h=1 
            end
            anim_obj:add(sprs[spridx],1,0.01,w,h)
        
            local e1=entity(anim_obj)
            e1:setpos(x,y)
            e1:set_anim(1)
            e1.spd = spd
        
            local bounds_obj=bbox(w*8,h*8)
            e1:set_bounds(bounds_obj)
            --e1.debugbounds=true

            function e1:kill()
                del(updateables, self)
                del(drawables, self)
                del(boulders, self)
                local ex = circle_explo(drawables, updateables)
                add(drawables, ex)
                add(updateables, ex)
                ex:multiexplode(self.x, self.y)
            end
        
            function e1:update()
                if collides(hero,self) then
                    hero:hurt(2)
                    self:kill()
                    return
                end
                
                if self.y > 77 then
                    self:kill()
                    return
                end

                self:sety(self.y+self.spd)
            end
       
            -- overwrite entity's draw() function
            e1._draw=e1.draw
            function e1:draw()
                local yy = self.y
                if (yy < 20) yy = 20
                circfill(self.x+7, 85, yy*0.08, 0)
                self:_draw()
            end
            return e1
        end
        
        function e:tick(pos)
            self.ticks+=1
            self.lastpos.x=pos.x
            --self.lastpos.y=pos.y
        end

        function e:update()
            self.timetick+=1

            if self.timetick > self.timethreshold then
                for b in all(boulders) do
                    del(updateables, b)
                    del(drawables, b)
                    del(boulders, b)
                end

                for i=1,10 do
                    local xx = (hero.x-200)+rnd(50)+10+(i*64)
                    local yy = -150-rnd(100)
                    local spd = 4+rnd(2)
                    local b = self:newboulder(xx, yy, spd)
                    add(boulders, b)
                    add(updateables, b)
                    add(drawables, b)
                end
                
                self.timetick=0
            end
        end
        return e
    end

    function stopper(x,y,hero)
        local anim_obj=anim()
        anim_obj:add(74,1,0.01,1,1)
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(8,128,0,-128)
        e:set_bounds(bounds_obj)
        --e.debugbounds=true
    
        function e:update()
            if collides(hero,self) then
                if self.flipx then
                    hero:doblockright()
                else
                    hero:doblockleft()
                end
            end
        end
    
        return e
    end

    function sacrificestand(x,y)
        local anim_obj=anim()
        anim_obj:add(38,1,0.01,2,2)
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
    
        local bounds_obj=bbox(16,16)
        e:set_bounds(bounds_obj)
        -- e.debugbounds=true
    
        function e:update()
        end
    
        -- overwrite entity's draw() function
        -- e._draw=e.draw
        -- function e:draw()
        --     self:_draw()
        --     ** your code here **
        -- end
    
        return e
    end

    function thief(x,y,level)
        local anim_obj=anim()
        anim_obj:add(91,4,0.3,1,2)
    
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.health = 5
        e.spd = 1.5
    
        local bounds_obj=bbox(8,128,0,-128)
        e:set_bounds(bounds_obj)
        --e.debugbounds=true
    
        function e:hurt()
            if(self.flickerer.is_flickering) return
            self:flicker(30)
            self.health -= 1
        end

        function e:kill()
            del(drawables, self)
            del(updateables, self)
            del(thiefs,self)
        end

        function e:update()
            if self.health <= 0 then
                s.hero.money += 50
                self:kill()
            end

            self:setx(self.x+self.spd)
            -- todo: poner coord correcta
            if self.x > level.w+16 then
                self:kill()
            end
        end
    
        return e
    end

    function fence(x,y)
        local e={}
        function e:draw()
            spr(70,x,y,2,1)
        end
        return e
    end

    function cloud(x)
        local e={}
        e.spr = 99
        e.w=2
        e.y=5+rnd(40)
        e.x=x+rnd(35)

        if flr(rnd(2)+1)%2==0 then
            e.spr=101
            e.w=1
        end

        function e:draw()
            spr(self.spr,x,self.y,e.w,1)
        end
        return e
    end

    -- receives a level config as argument
    function mapbuild(l,hero,this_state,houses,stand)
        local xx=128    -- starting x for first house
        local hy=44     -- house y position (doesn't change)
        local fx=xx+((l.hs+l.hw)*3)-64 -- forest starting x 

        -- *************************
        --      setup fences
        -- *************************
        local ssx =0
        while ssx<l.w+16 do
            add(drawables,fence(ssx, 60))
            ssx+=16
        end

        -- *************************
        --      setup clouds
        -- *************************
        ssx=15
        while ssx<l.w do
            add(drawables, cloud(ssx))
            ssx+=32
        end

        -- *************************
        --      setup forest
        -- *************************
        function sf()
            function tree(sp, x, y, w, h)
                local t={}
                function t:draw()
                    spr(sp,x,y,w,h)
                end
                return t
            end

            -- paint pines
            local fe= fx+l.fw-16  -- forest end
            for i=fx,fe,16 do
                add(drawables, tree(115,i,hy,2,5))
            end

            -- paint small trees
            fx=xx+((l.hs+l.hw)*3)-64 -- forest starting x
            fx+=8 -- make this trees out of phase with the pines
            for i=fx,fe,16 do
                if(flr(rnd(2))==1) add(drawables, tree(133,i,hy+17,2,3))
            end

            -- paint bright trees
            fx=xx+((l.hs+l.hw)*3)-64 -- forest starting x
            fx+=10 -- make this trees out of phase with the pines
            for i=fx,fe,24 do
                if(flr(rnd(2))==1) add(drawables, tree(112,i,hy+10,3,4))
            end
        end
        sf()

        stand.val = sacrificestand(hero.x+20, hero.y)
        add(drawables, stand.val)

        -- *************************
        --      setup houses
        -- *************************
        for i=1,l.hcnt do
            local ho = house(xx,hy,hero)
            add(drawables, ho)
            add(updateables, ho)
            add(houses, ho)
            xx+=l.hw+l.hs       -- setup x for the next house
            if(i==3) xx+=l.fw   -- put2 houses, then the forest, and then the rest
        end
        

        -- *************************
        --      setup stoppers
        -- *************************
        local stoppery=82
        local sright= stopper(64,stoppery, hero)
        local sleft = stopper(l.w-68,stoppery, hero)
        sleft.flipx=true
        add(drawables, sleft)
        add(drawables, sright)
        add(updateables, sleft)
        add(updateables, sright)
    end

    local hero = hero(400,70, s)
    s.hero = hero
    
    local pc = potioncreator(potions)
    add(updateables, pc)

    local houses = {}
    local stand = {}
    mapbuild(level, hero, s, houses,stand)

    local ec = npccreator(victims, houses,pc, hero,updateables,drawables,level)
    add(updateables, ec)
    -- cuando salta hace algo
    -- hero:set_notifyjumpobj(ec)
    
    local boulders = {}
    local brain = boulderrain(updateables, drawables, boulders, hero)
    add(updateables, brain)
    -- add(updateables, boulders)
    --add(drawables, boulders)


    add(updateables, hero)
    add(drawables, hero)


    s.update=function()
        if(deferpos) hero.shooting=false hero.wasshooting=false hero:setx(deferpos) deferpos=false
        if(pendingmusic) music(1) pendingmusic=false

        -- *****************
        --  updating camera
        -- *****************
        if not hero.shooting and not hero.wasshooting then
            if hero.flipx then
                if((hero.x-cam.x) < 55) cam.x=hero.x-55
            else
                if((hero.x-cam.x) > 70) cam.x=hero.x-70
            end
        end
        camera(cam.x, cam.y)


        for u in all(updateables) do
            u:update()
        end

        local keepgoing=true
        for v in all(victims) do
            if keepgoing and hero.atacking and collides(v, hero) then
                v:hurt(hero)
                keepgoing=false
            end
            v:update()
        end

        for t in all(thiefs) do 
            if hero.atacking and collides(t, hero) then
                t:hurt()
            end
        end

        if hero.dropping and collides(stand.val, hero) then
            local v = hero.pickedupvictim
            hero.pickedupvictim=nil
            v.x = stand.val.x+4
            v.y = stand.val.y-3
            v:sacrifice()
            
            -- todo: sfx de money
            hero.money+=3
            hero.sacrifices+=1
            if hero.sacrifices >= hero.maxsacrifices then
                curstate=win_state()
            end
        end

        for p in all(potions) do
            if collides(p, hero) then
                p:pickup(hero)
                break
            end
        end

        --disable texts
        if (hero.x > level.es*2 and hero.x < 500) or (hero.x > 256 and hero.x < level.w-level.es) then
            showmsg=false
            showmsgtxt=""
            rtick=0
        end
    end

    s.draw=function()
        cls()
        
        -- *****************
        --        level
        -- *****************
        -- sky
        fillp(0)
        rectfill(0,0,level.w,127, 12) 

        -- sand
        --fillp(0b0000001010000000)
        rectfill(0,67,level.w,127, 9) 
        
        -- gravel
        --fillp(0b0000010000000001)
        rectfill(0,77,level.w,94, 4) 
        
        -- *****************
        --      objects
        -- *****************
        for d in all(drawables) do
            d:draw()
        end

        for e in all(victims) do
            e:draw()
        end

        for p in all(potions) do
            p:draw()
        end

        
        -- *****************
        --        hud
        -- *****************
        s.drawhud()
    end

    s.drawhud=function()
        camera(0,0)
        fillp(0)
        local yy=100
        rectfill(0,yy,127,127, 0) -- bottom banner
        rect(2,yy+2,125,125, 7) -- white frame top

        local sx=5
        local sy=yy+5
        local hgt=4
        local wdt=58

        print("sacrifices", sx, sy, 8)
        local mssx = (10*4)+4
        for i=1,hero.maxsacrifices do
            local c=1
            if hero.sacrifices >= i then
                c=11
            end
            rectfill(mssx+1,sy-1,mssx+3,sy+5, c)
            mssx+=4
        end
        
        sy+=8
        local ppsy=sy
        rectfill(sx,sy, sx+wdt, sy+hgt, 8)
        rectfill(sx,sy+1, sx+wdt, sy+hgt-1, 0)
        local h=hero.health
        local hx=22
        print("health", sx+wdt+3, sy, 8)
        for i=1,h do
            -- draw each life bar
            rectfill(sx,sy+2, sx+1, sy+hgt-2, 7)
            sx+=3
        end

        print("money", wdt+33, sy, 10)
        local cash = hero.money
        print(cash, wdt+33+6, sy+6, 10)

        print("pot", wdt+33+21, sy, 7)
        print(hero.potions, wdt+33+24, sy+6, 7)

        sx=5
        sy=yy+12+7
        wdt-=15
        rectfill(sx,sy, sx+wdt, sy+hgt, 8)
        rectfill(sx,sy+1, sx+wdt, sy+hgt-1, 0)
        print("popularity", sx+wdt+2, sy, 8)
        local p = hero.reputation
        for i=1,p do
            -- draw each life bar
            rectfill(sx,sy+2, sx+1, sy+hgt-2, 7)
            sx+=3
        end
    end

    return s
end
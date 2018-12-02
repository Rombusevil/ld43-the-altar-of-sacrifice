pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- made with super-fast-framework

------------------------- start imports
function bbox(w,h,xoff1,yoff1,xoff2,yoff2)
    local bbox={}
    bbox.offsets={xoff1 or 0,yoff1 or 0,xoff2 or 0,yoff2 or 0}
    bbox.w=w
    bbox.h=h
    bbox.xoff1=bbox.offsets[1]
    bbox.yoff1=bbox.offsets[2]
    bbox.xoff2=bbox.offsets[3]
    bbox.yoff2=bbox.offsets[4]
    function bbox:setx(x)
        self.xoff1=x+self.offsets[1]
        self.xoff2=x+self.w-self.offsets[3]
    end
    function bbox:sety(y)
        self.yoff1=y+self.offsets[2]
        self.yoff2=y+self.h-self.offsets[4]
    end
    function bbox:printbounds()
        rect(self.xoff1, self.yoff1, self.xoff2, self.yoff2, 8)
    end
    return bbox
end
function anim()
    local a={}
	a.list={}
	a.current=false
	a.tick=0
    function a:_get_fr(one_shot, callback)
		local anim=self.current
		local aspeed=anim.speed
		local fq=anim.fr_cant		
		local st=anim.first_fr
		local step=flr(self.tick)*anim.w
		local sp=st+step
		self.tick+=aspeed
		local new_step=flr(flr(self.tick)*anim.w)		
		if st+new_step >= st+(fq*anim.w) then 
		    if one_shot then
		        self.tick-=aspeed  
		        callback()
		    else
		        self.tick=0
		    end
		end
		return sp
    end
    function a:set_anim(idx)
        if (self.currentidx == nil or idx != self.currentidx) self.tick=0 
        self.current=self.list[idx]
        self.currentidx=idx
    end
	function a:add(first_fr, fr_cant, speed, zoomw, zoomh, one_shot, callback)
		local a={}
		a.first_fr=first_fr
		a.fr_cant=fr_cant
		a.speed=speed
		a.w=zoomw
        a.h=zoomh
        a.callback=callback or function()end
        a.one_shot=one_shot or false
		add(self.list, a)
	end
	function a:draw(x,y,flipx,flipy)
		local anim=self.current
		if( not anim )then
			rectfill(0,117, 128,128, 8)
			print("err: obj without animation!!!", 2, 119, 10)
			return
		end
		spr(self:_get_fr(self.current.one_shot, self.current.callback),x,y,anim.w,anim.h,flipx,flipy)
    end
	return a
end
function entity(anim_obj)
    local e={}
    e.x=0
    e.y=0
    e.anim_obj=anim_obj
    e.debugbounds, e.flipx, e.flipy = false
    e.bounds=nil
    e.flickerer={}
    e.flickerer.timer=0
    e.flickerer.duration=0          
    e.flickerer.slowness=3
    e.flickerer.is_flickering=false 
    function e.flickerer:flicker()
        if(self.timer > self.duration) then
            self.timer=0 
            self.is_flickering=false
        else
            self.timer+=1
        end
    end
    function e:setx(x)
        self.x=x
        if(self.bounds != nil) self.bounds:setx(x)
    end
    function e:sety(y)
        self.y=y
        if(self.bounds != nil) self.bounds:sety(y)
    end
    function e:setpos(x,y)
        self:setx(x)
        self:sety(y)
    end
    function e:set_anim(idx)
		self.anim_obj:set_anim(idx)
    end
    function e:set_bounds(bounds)
        self.bounds = bounds
        self:setpos(self.x, self.y)
    end
    function e:flicker(duration)
        if(not self.flickerer.is_flickering)then
            self.flickerer.duration=duration
            self.flickerer.is_flickering=true
            self.flickerer:flicker()
        end
        return self.flickerer.is_flickering
    end
    function e:draw()
        if(self.flickerer.timer % self.flickerer.slowness == 0)then
            self.anim_obj:draw(self.x,self.y,self.flipx,self.flipy)
        end
        if(self.flickerer.is_flickering) self.flickerer:flicker()        
		if(self.debugbounds) self.bounds:printbounds()
    end
    return e
end

function tutils(args)
	local s={}
	s.private={}
	s.private.tick=0
	s.private.blink_speed=1
	s.height=10 
	s.text=args.text or ""
	s._x=args.x or 2
	s._y=args.y or 2
	s._fg=args.fg or 7
	s._bg=args.bg or 2
	s._sh=args.sh or 3 	
	s._bordered=args.bordered or false
	s._shadowed=args.shadowed or false
	s._centerx=args.centerx or false
	s._centery=args.centery or false
	s._blink=args.blink or false
	s._blink_on=args.on_time or 5
	s._blink_off=args.off_time or 5
	function s:draw()
		if self._centerx then self._x =  64-flr((#self.text*4)/2) end
		if self._centery then self._y = 64-(4/2) end
		if self._blink then 
			self.private.tick+=1
			local offtime=self._blink_on+self._blink_off 
			if(self.private.tick>offtime) then self.private.tick=0 end
			local blink_enabled_on = false
			if(self.private.tick<self._blink_on)then
				blink_enabled_on = true
			end
			if(not blink_enabled_on) then
				return
			end
		end
		local yoffset=1
		if self._bordered then 
			yoffset=2
		end
		if self._bordered then
			local x=max(self._x,1)
			local y=max(self._y,1)
			if(self._shadowed)then
				for i=-1, 1 do	
					print(self.text, x+i, self._y+2, self._sh)
				end
			end
			for i=-1, 1 do
				for j=-1, 1 do
					print(self.text, x+i, y+j, self._bg)
				end
			end
		elseif self._shadowed then
			print(self.text, self._x, self._y+1, self._sh)
		end
		print(self.text, self._x, self._y, self._fg)
    end
	return s
end

function collides(ent1, ent2)
    local e1b=ent1.bounds
    local e2b=ent2.bounds
    if  ((e1b.xoff1 <= e2b.xoff2 and e1b.xoff2 >= e2b.xoff1)
    and (e1b.yoff1 <= e2b.yoff2 and e1b.yoff2 >= e2b.yoff1)) then 
        return true
    end
    return false
end
function point_collides(x,y, ent)
    local eb=ent.bounds
    if  ((eb.xoff1 <= x and eb.xoff2 >= x)
    and (eb.yoff1 <= y and eb.yoff2 >= y)) then 
        return true
    end
    return false
end
function circle_explo(drawable,updateable)
	local ex={}
	ex.circles={}
	ex.started=false
	function ex:explode(x,y)
		ex.started=true
		add(self.circles,{x=x,y=y,t=0,s=2})
	end
	function ex:multiexplode(x,y)
		ex.started=true
		local time=0
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1 }) time-=2
		add(self.circles,{x=x+7,y=y-3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x-7,y=y+3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x+7,y=y+3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x-7,y=y-3,t=time,s=rnd(2)+1}) time-=2
		add(self.circles,{x=x,y=y,t=time,s=rnd(2)+1}) time-=2
	end
	function ex:update()
		if ex.started and #self.circles == 0 then
			del(drawable, self)
			del(updateable, self)
		end
		for ex in all(self.circles) do
			ex.t+=ex.s
			if ex.t >= 15 then
				del(self.circles, ex)
			end
		end
	end
	function ex:draw()
		for ex in all(self.circles) do
			circ(ex.x,ex.y,ex.t/2,8+ex.t%3)
		end
	end
	return ex
end

local tick_dance=0
local step_dance=0
function dance_bkg(delay,color)
    local sp=delay
    local pat=0b1110010110110101
    tick_dance+=1
    if(tick_dance>=sp)then
        tick_dance=0
        step_dance+=1
        if(step_dance>=16)then step_dance = 0 end
    end
    fillp(bxor(shl(pat,step_dance), shr(pat,16-step_dance)))
    rectfill(0,0,64,64,color)
    rectfill(64,64,128,128,color)
    fillp(bxor(shr(pat,step_dance), shl(pat,16-step_dance)))
    rectfill(64,0,128,64,color)
    rectfill(0,64,64,128,color)
    fillp() 
end
function menu_state()
    local state={}
    local texts={}
	music(0)
	sfx(0)
	add(texts, tutils({text="the altar of sacrifice",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
	add(texts, tutils({text="ludum dare 43",centerx=true,y=19,fg=0,bg=0,bordered=false,shadowed=false,sh=2}))
	add(texts, tutils({text="rombosaur studios",centerx=true,y=99,fg=9,sh=2,shadowed=true}))
	local yy=40
	add(texts, tutils({text="jump 🅾️  ",x=12,  y=yy, fg=0,bg=1,shadowed=true, sh=7})) yy+=9
	add(texts, tutils({text="action ❎ ",x=12, y=yy, fg=0,bg=1,shadowed=true, sh=7})) yy+=9
	add(texts, tutils({text="move: ⬅️➡️ ",x=12 ,y=yy, fg=0,bg=1,shadowed=true, sh=7})) yy+=9
	add(texts, tutils({text="press ❎ to start", blink=true, on_time=15, centerx=true,y=80,fg=0,bg=1,shadowed=true, sh=7}))
	add(texts, tutils({text="v0.1", x=106, y=97}))
	local ypos = 111
	add(texts, tutils({text="🅾️             ❎  ", centerx=true, y=ypos, shadowed=true, bordered=true, fg=8, bg=0, sh=2}))
	add(texts, tutils({text="  buttons  ", centerx=true, y=ypos, shadowed=true, fg=7, sh=0}))
    add(texts, tutils({text="  z         x  ", centerx=true, bordered=true, y=ypos+3, fg=8, bg=0}))
    ypos+=10
	add(texts, tutils({text="  remap  ", centerx=true, y=ypos, shadowed=true, fg=7, sh=0}))
	local x1=28 
	local y1=128-19 
	local x2=128-x1-2 
	local y2=128 
	local frbkg=1
	local frfg=6
	state.update=function()
        if(btnp(5)) sfx(4) curstate=platforming_state() 
	end
	cls()
	state.draw=function()
		dance_bkg(10,frbkg)
		rectfill(3,2, 128-4, 104, 7)
		rectfill(2,3, 128-3, 103, 7)
		rectfill(4,3, 128-5, 103, 0)
		rectfill(3,4, 128-4, 102, 0)
		rectfill(5,4, 128-6, 102, frfg)
		rectfill(4,5, 128-5, 101, frfg)
		rectfill(25,97,  101, 111, frbkg)
		rectfill(24,98,  102, 111, frbkg)
		pset(23,104,frbkg)
		pset(103,104,frbkg)
        rectfill(x1,y1-1,  x2,y2+1, 0)
		rectfill(x1-1,y1,  x2+1,y2, 0)
		rectfill(x1,y1,  x2,y2, 6)
		local y=122
		rectfill(75-1,y+1-1, 120+1-8,y+1+1, 0)
		rectfill(121-1-8,y+1-1, 121+1-8,128+1, 0)
		rectfill(75,y+1, 120-8,y+1, 8)
		rectfill(121-8,y+1, 121-8,128, 8)
        for t in all(texts) do
            t:draw()
        end
	end
	return state
end
function shop_state(prevstate)
    local s={}
    local ents={}
    local h=prevstate.hero
    local timeout=0
    camera(0,0)
    function arrow()
        local e={}
        e.positions={}
        add(e.positions, {x=20  -2, y=78}) 
        add(e.positions, {x=49  -2, y=78}) 
        add(e.positions, {x=78  -2, y=78}) 
        add(e.positions, {x=107 -2, y=78}) 
        e.posidx=1
        function e:update()
            if btnp(0) and self.posidx > 1 then     
                self.posidx-=1
                sfx(3)
            elseif btnp(1) and self.posidx <= #self.positions-1 then 
                self.posidx+=1
                sfx(3)
            end
        end
        function e:draw()
            local p=self.positions[self.posidx]
            spr(75, p.x, p.y)
        end
        return e
    end
    local txt={}
    add(txt, tutils({text=msg,centerx=false, x=20,y=8,fg=7,bg=0,bordered=false,shadowed=true,sh=2}))
    local yy=40
    add(txt, tutils({text="shop",centerx=true,y=10,fg=7,bg=0,bordered=true,shadowed=true}))
    add(txt, tutils({text="what do you want?",centerx=true,y=yy,fg=7,bg=0})) yy+=8
    add(txt, tutils({text="money: "..h.money,centerx=false,y=90,x=10,fg=7,bg=0})) yy+=8
    local pressx=tutils({text="❎ to choose", blink=true, on_time=15, centerx=true,y=110,fg=7,bg=1,shadowed=true, sh=6})
    local bought=tutils({text="bougth!",centerx=true,centery=true,fg=7,bg=13, bordered=true})
    local notenoughmoneyt=tutils({text="not enough money",centerx=true,fg=7,bg=13, y=40,bordered=true})
    local ar=arrow(20, 86)
    add(ents, ar)
    local didboughtit=false
    local notenoughmoney=false
    local tick=0
    local pendingval=""
    local fuse=true
    s.update=function()
        if(didboughtit or notenoughmoney) return
        timeout+=1
        for u in all(ents) do
            u:update()
        end
        if timeout > 30 and (btnp(4) or btnp(5)) then 
            sfx(5)
            if(ar.posidx==4) curstate=prevstate  return 
            local prices = {5,8,5}
            if h.money > prices[ar.posidx] then
                if ar.posidx == 1 or ar.posidx == 2then
                    h.pigs += ar.posidx
                elseif ar.posidx == 3 then
                    h.potions += 1
                end
                h.money -= prices[ar.posidx]
                h.reputation += flr(prices[ar.posidx] / 2)
                if (h.reputation > 15) then h.reputation=15 end
                didboughtit=true
            else
                pendingval=value
                notenoughmoney=true
            end
        end
        if timeout > 20 and fuse then
            fuse=false
            add(txt, pressx)
        end
    end
    s.draw=function()
        cls()
        rectfill(0,0,127,127, 1)
        sspr(10*8, 5*8, 8,8,     10,10, 8*3,8*3) 
        rectfill(5,34, 128-5,128-10, 4)
        if not didboughtit and not notenoughmoney then
            local sx = 10
            local yy = 50
            local tw = 24 
            local sp = 5  
            for i=1,4 do
                local slottxt="1 pig\n  $5";
                local c=5
                local to=0 
                if i == 4 then
                    slottxt="bye"
                    c=6
                    to=6
                elseif i == 3 then
                    slottxt="potion\n  $5"
                elseif i == 2 then
                    slottxt="2 pigs\n  $8"
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
        elseif didboughtit then
            bought:draw()
            tick+=1
            if(tick > 30) curstate=prevstate
        elseif notenoughmoney then
            notenoughmoneyt:draw()
            local syy = 100
            spr(74, 15,syy,1,1,true) 
            print("back",25,syy+1,7)
            if btnp(0) or btnp(4) or btnp(1) then 
                sfx(5)
                notenoughmoney=false
            end
        end
    end
    return s
end
function platforming_state()
    sfx(6)
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
    level.hs=150 
    level.fw=150 
    level.es=128 
    level.hw=48  
    level.hcnt=3 
    level.w=(level.hw+level.hs)*level.hcnt+level.fw +level.es
    local deferpos=false
    local pendingmusic=false
    function hero(x,y, platforming_state)
        local anim_obj=anim()
        local e=entity(anim_obj)
        anim_obj:add(1,4,0.3,1,2) 
        anim_obj:add(5,1,0.01,1,2) 
        anim_obj:add(6,1,0.01,1,2) 
        anim_obj:add(7,1,0.5,2,2,true, function() e.shooting=false end) 
        anim_obj:add(123,4,0.3,1,2) 
        anim_obj:add(127,1,0.01,1,2) 
        e:setpos(x,y)
        e:set_anim(2) 
        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
        e.money = 0
        e.pigs = 0
        e.sacrifices=0
        e.maxsacrifices=20
        e.potions=0
        e.pickedupvictim=nil
        e.blockright=false
        e.blockleft=false
        e.reputation = 15
        e.speed=2
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
                self.potions-=1
                self.health+=5
            end
            if self.health <= 0 then
                music(-1)
                sfx(17)
                curstate=s
                pendingmusic=true
                curstate=gameover_state('health')
            end
        end
        function e:set_notifyjumpobj(obj)
            self.notifyjumpobj=obj
        end
        function e:pickup(victim)
            sfx(4)
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
                if btn(0) and not self.blockleft then     
                    self:setx(self.x-self.speed)
                    self.flipx=true
                    if self.pickedupvictim == nil then
                        self:set_anim(1) 
                    else
                        self:set_anim(5) 
                    end
                    self.blockright=false
                elseif btn(1) and not self.blockright then 
                    self:setx(self.x+self.speed)
                    self.flipx=false
                    if self.pickedupvictim ==nil then
                        self:set_anim(1) 
                    else
                        self:set_anim(5) 
                    end
                    self.blockleft=false
                else
                    if self.pickedupvictim ==nil then
                        self:set_anim(2) 
                    else
                        self:set_anim(6) 
                    end
                end
                if btnp(4) and self.grounded then 
                    sfx(4)
                    if self.notifyjumpobj ~= nil then
                        self.notifyjumpobj:tick({x=self.x, y=self.y})
                    end
                    self.grav = -self.jumppw
                    self:sety(self.y + self.grav)
                    self.grounded=false
                    self:set_anim(3) 
                elseif not self.grounded then
                    self:set_anim(3) 
                end
                if btnp(5) then 
                    if self.pickedupvictim == nil then 
                        self.dropping = false
                        self.atacking = true
                        if(self.btimer-self.prevsh < 5) return 
                        self.prevsh=self.btimer
                        sfx(0)
                        self.shooting=true
                        self.wasshooting=true
                        self:set_anim(4) 
                        local dir=1     
                        if self.flipx then
                            dir=-1      
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
                self:sety(self.y + self.grav)
                self.grav += self.baseaccel * self.accel
                self.accel+=0.1
            else
                self.grav = 0.01
                self.accel = self.baseaccel
                self.grounded=true
            end
            if self.y > self.floory then
                self:sety(self.floory)
                self.grounded=true
            end
            if self.pickedupvictim ~=nil then
                self.pickedupvictim:setx(self.x-4)
                self.pickedupvictim:sety(self.y-8)
            end
        end
        function e:reset()
            self.pigs = 0
            self.sacrifices=0
            self.money = 0
            self.speed=2
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
                deferpos=750 
            end
        end
        return e
    end
    function house(x,y, hero)
        local e=entity({})
        e:setpos(x,y)
        local bounds_obj=bbox(12,32, 6, 26, -13, -26)
        e:set_bounds(bounds_obj)
        e.h = hero
        local idx=flr(rnd(4))+1
        function e:update()
            if collides(self,self.h) and btnp(2) and hero.pickedupvictim == nil then 
                sfx(8)
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
        end
        return e
    end
    function potion(x,y,potions)
        local e=entity(anim_obj)
        e:setpos(x,y)
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        sfx(3)
        function e:pickup(hero)
            del(potions, self)
            sfx(2)
            if(hero.potions >= 10) return
            hero.potions +=1
        end
        function e:draw()
            spr(9, self.x, self.y, 1,1)
        end
        return e
    end
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
        anim_obj:add(96,1,0.1,2,1) 
        local e=entity(anim_obj)
        anim_obj:add(86,4,0.7,1,1,true,function() 
            del(updateables, e)
            del(drawables, e)
        end) 
        e:setpos(x,y)
        e:set_anim(1)
        local bounds_obj=bbox(16,8)
        e:set_bounds(bounds_obj)
        function e:sacrifice()
            self:set_anim(4)
            s.hero.pigs = 0
            sfx(11)
        end
        function e:update()
        end
        return e
    end
    function victim(x,y, hero, updateables, drawables,victims)
        local anim_obj=anim()
        local spri=40
        if (flr(rnd(2)+1)%2==0) spri+=04
        anim_obj:add(spri,1,0.1,1,2) 
        anim_obj:add(spri+1,3,0.3,1,2) 
        anim_obj:add(spri+32,1,0.9,2,1) 
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.health = 3
        e.runaway = false
        e.runawaytick=0
        e.dir = 1
        e.isupset=false
        e.pickedup=false
        anim_obj:add(86,4,0.7,1,1,true,function() 
            del(updateables, e)
            del(drawables, e)
            del(victims, e)
        end) 
        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
        function e:hurt(attacker)
            self.health -=1
            self:flicker(0.2)
            if self.health <= 0 then
                attacker:pickup(self)
                self:set_anim(3) 
                self.runaway=false
                self.pickedup=true
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
            sfx(11)
        end
        function e:upset()
            if not self.isupset then
                sfx(5)
                self.isupset=true
                hero.reputation-=3
            end
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
                for v in all(victims) do
                    if not (v==self) then
                        if collides(v,self) then
                            v:upset()
                        end
                    end
                end
            end
        end
        e._draw=e.draw
        function e:draw()
            self:_draw()
            if self.isupset == true and not self.runaway and not self.pickedup then
                spr(78, self.x-4, self.y-4, 1,1)
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
                sfx(9)
            end
            if self.timetick > self.timethreshold then
                sfx(2)
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
            function e1:kill()
                del(updateables, self)
                del(drawables, self)
                del(boulders, self)
                local ex = circle_explo(drawables, updateables)
                add(drawables, ex)
                add(updateables, ex)
                ex:multiexplode(self.x, self.y)
                sfx(10)
            end
            function e1:update()
                if collides(hero,self) then
                    hero:hurt(10)
                    self:kill()
                    return
                end
                if self.y > 77 then
                    self:kill()
                    return
                end
                self:sety(self.y+self.spd)
            end
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
        function e:update()
        end
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
        function e:hurt()
            if(self.flickerer.is_flickering) return
            self:flicker(30)
            self.health -= 1
            sfx(4)
        end
        function e:kill()
            del(drawables, self)
            del(updateables, self)
            del(thiefs,self)
            sfx(6)
            sfx(12)
        end
        function e:update()
            if self.health <= 0 then
                s.hero.money += 50
                self:kill()
            end
            self:setx(self.x+self.spd)
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
    function mapbuild(l,hero,this_state,houses,stand)
        local xx=128    
        local hy=44     
        local fx=xx+((l.hs+l.hw)*3)-64 
        local ssx =0
        while ssx<l.w+16 do
            add(drawables,fence(ssx, 60))
            ssx+=16
        end
        ssx=15
        while ssx<l.w do
            add(drawables, cloud(ssx))
            ssx+=32
        end
        function sf()
            function tree(sp, x, y, w, h)
                local t={}
                function t:draw()
                    spr(sp,x,y,w,h)
                end
                return t
            end
            local fe= fx+l.fw-16  
            for i=fx,fe,16 do
                add(drawables, tree(115,i,hy,2,5))
            end
            fx=xx+((l.hs+l.hw)*3)-64 
            fx+=8 
            for i=fx,fe,16 do
                if(flr(rnd(2))==1) add(drawables, tree(133,i,hy+17,2,3))
            end
            fx=xx+((l.hs+l.hw)*3)-64 
            fx+=10 
            for i=fx,fe,24 do
                if(flr(rnd(2))==1) add(drawables, tree(112,i,hy+10,3,4))
            end
        end
        sf()
        stand.val = sacrificestand(hero.x+20, hero.y)
        add(drawables, stand.val)
        for i=1,l.hcnt do
            local ho = house(xx,hy,hero)
            add(drawables, ho)
            add(updateables, ho)
            add(houses, ho)
            xx+=l.hw+l.hs       
            if(i==3) xx+=l.fw   
        end
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
    local boulders = {}
    local brain = boulderrain(updateables, drawables, boulders, hero)
    add(updateables, brain)
    add(updateables, hero)
    add(drawables, hero)
    s.update=function()
        if(deferpos) hero.shooting=false hero.wasshooting=false hero:setx(deferpos) deferpos=false
        if(pendingmusic) music(1) pendingmusic=false
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
            if collides(v, hero) then
                if keepgoing and hero.atacking  then
                    v:hurt(hero)
                    keepgoing=false
                elseif hero.pickedupvictim ~= nil and v ~= hero.pickedupvictim then
                    v:upset()
                    if hero.reputation <=0 then
                        curstate=gameover_state('reputation')
                    end
                end
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
        if (hero.x > level.es*2 and hero.x < 500) or (hero.x > 256 and hero.x < level.w-level.es) then
            showmsg=false
            showmsgtxt=""
            rtick=0
        end
    end
    s.draw=function()
        cls()
        fillp(0)
        rectfill(0,0,level.w,127, 12) 
        rectfill(0,67,level.w,127, 9) 
        rectfill(0,77,level.w,94, 4) 
        for d in all(drawables) do
            d:draw()
        end
        for e in all(victims) do
            e:draw()
        end
        for p in all(potions) do
            p:draw()
        end
        s.drawhud()
    end
    s.drawhud=function()
        camera(0,0)
        fillp(0)
        local yy=100
        rectfill(0,yy,127,127, 0) 
        rect(2,yy+2,125,125, 7) 
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
            rectfill(sx,sy+2, sx+1, sy+hgt-2, 7)
            sx+=3
        end
    end
    return s
end
function gameover_state(cause)
    local s={}
    local texts={}
    local timeout=2 
    camera(0,0)
    local frbkg=8
    local frfg=6
    music(10)
    sfx(-1)
    local ty=15
    if cause == 'health' then
        add(texts, tutils({text="you couldn't tame the gods",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="the people in your village" ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
        add(texts, tutils({text="hate you.                 ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="game over",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
        add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    else 
        add(texts, tutils({text="people in your village  ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="reunited and killed you." ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
        add(texts, tutils({text="there's probably someone",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="dancing on your grave   ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="right now.              ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
        add(texts, tutils({text="game over",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    end
    local restart_msg = "press ❎ to restart"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)
    s.update=function()
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=menu_state()
    end
    cls()
    s.draw=function()
        dance_bkg(10,frbkg)
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
        if(timeout > 0)then
            local t = flr(timeout) + 1
            msg.text = "wait for it... ("..t..")"
        else
            msg.text = restart_msg
        end
        for t in all(texts) do
            t:draw()
        end
    end
    return s
end
function win_state()
    camera(0,0)
    music(16)
    local s={}
    local texts={}
    local timeout=2 
    local frbkg=11
    local frfg=6
    local ty=15
    add(texts, tutils({text="congratulations billy!!! ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         " ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="you managed to calm the  ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="gods and save the        ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="remaining people in your ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="village. althoug most are",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="cuestioning the method...",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    local restart_msg = "press ❎ to autodestroy"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)
    s.update=function()
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=menu_state() 
    end
    cls()
    s.draw=function()
        dance_bkg(10,frbkg)
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
        if(timeout > 0)then
            local t = flr(timeout) + 1
            msg.text = "wait for it... ("..t..")"
        else
            msg.text = restart_msg
        end
        for t in all(texts) do
            t:draw()
        end
    end
    return s
end


-- <*vertigo_state.lua
--------------------------- end imports

-- to enable mouse support uncomment all of the following commented lines:
-- poke(0x5f2d, 1) -- enables mouse support
function _init()
    curstate=menu_state()
end

function _update()
    -- mouse utility global variables
    -- mousex=stat(32)
    -- mousey=stat(33)
    -- lclick=stat(34)==1
    -- rclick=stat(34)==2
    -- mclick=stat(34)==4
	curstate.update()
end

function _draw()
    curstate.draw()
    -- pset(mousex,mousey, 12) -- draw your pointer here
end
__gfx__
00000000001111000000000000111110000000000001111000111100000000000000000000997700000000000000000000000000000000000000055555000000
00000000011111100011110001111110001111000011111101111110000111000000000009aa7a7005511500000001100005555550000000000554d545000050
0070070001116f100111111001116f1001111110001116f101116f1000111110000000009aaaa7a7051111500555911100554494955000950055d44d45000151
0007700001ffff100116f610001fff1001116f10001ffff101ffff1000116f10000000009aaaaaa7051111105949551105549944d45000550549445445001155
0007700001ffff1001ffff100017710001ffff10001ffff101ffff11001fff100000000049aaaaa900110115444495000544444444555995059445d545555100
0070070001fff100017771000177771001777100001fff1001fff11f001fff10000000004a9aaaa90000505554495000054d444d4455444555944555454d4500
00000000017771001777f100007f77101777f100001777f1017771f1001ff1111110000004aaaa9000005549454500000554d444544454455444954444545500
000000001777771017ff7100001fff1017ff71000017ff711777771000177777fff1000000449900000554945445550000544455544454d555594444494d5000
0000000001ff77f1017771000017771001777100000177711f1777100017777111100000000000000005d494444495550055955444444d450055544549455000
00000000001ff71001777100001777710177710000017771f1177771001777100000000005500055005545444459444500554444454445500000545494550000
00000000001777100177710000177771017771000001777111f101f10017711000000000054455d00054d4545554495500544444544450000005944555050000
0000000000177771017771000007777101777100000177711f1001f100177771000000000054d440001555545d544950005554555d4450000059444451101100
000000000177777101777100001f11f1001f10000001777101f101ff001777710000000000545550551100544544945000054555444d45001155949501111150
0000000001f101f1001f100001f101f1001f100000001f100000000001f101f1000000000055500015100054d44d550000054455555555101119555005111150
000000001f1001f1001f100001ff11ff001f100000001f10000000001f1001f10000000001100000050000545d45500000005550000011100110000000511550
0000000001f101ff001ff10000110011001ff10000001ff10000000001f101ff0000000000100000000000555550000000000000000011100000000000000000
00000000000000777770000000000000000000000777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777766677777777777777777777777766666700000000000000000011110000111100001111000011110000111100001111000011110000111100
00656666665577655567756665666666666666565666666600000000000000000111111001111110011111100111111001111110011111100111111001111110
0065555555577655555677555555555555555555557666700000000000000000016ff6100116f610011f6f10011f6f1001399310019393100199391001993910
006665666577655555556775666666666566666665666660000000000000000001ffff1001ffff1001ffff1001ffff1001999910019999100199991001999910
00655555577655555555567755555555555555555566666007888888888888700122210001ffff1001ffff1001ffff1001555100019999100199991001999910
00656665776555555555556775666666666666566566666086585865588586761222210001222100012221000122210015555100015551000155510001555100
0065555776555555555555567755555555555555555555006858555555856567122222100122221001fff1000122221015555510015555100199910001555510
00656576655555555555555566755666656666666576667055552255555255261222221001ff22f101222100001f221015555510019955910155510000195510
00655766555555555555555556675555555555555566666005112211111112201f222f10001ff210012221000012ff1019555910001995100155510000159910
00657665555555555555555555667566666665666566666000002555555500201222210000122210012221000012222115555100001555100155510000155551
00676655555555655655555555566755555555555566666000025115555550001222210000122221012221000012222115555100001555510155510000155551
00766555555556655665555555556675656666666555550000051155551650001f11f10001222221001f10000002222119119100015555510019100000055551
07665555555556655665555555555667555655565576667001251155551555501f11f10001f101f1001f1000001f11f119119100019101910019100000191191
00555555555566655666555555555555565556565566666005555555511565501f11f1001f1001f1001f100001f101f119119100191001910019100001910191
07666755555565655656555555576667565656565566666065555555511156561ff1ff0001f101ff001ff10001ff11ff19919900019101990019910001991199
0666665555566565565665555556666656565656556666600d000000000000d00000000000000000000990000009900000000000000000008888000000000000
066666555566656556566655555666665656565555555500ddd0000000000ddd00111110000001ff0009a900009aa90001111100000019908aa800000aa00000
066666555565656556565655555666665656565655766670d5dddddddddddd5d0118ff1000001fff9999aa9009aaaa9011899100000199908aa800000aa00000
005555555565666556665655555555555556565655666660dd5555555555555d011fff111111ff109aaaaaa99aaaaaa911999111111991008aa800000aa00000
0766675555656a6556a65655555766675656565655666660ddd0000000000ddd011fff22f222f1109aaaaaa9999aa99911999559555911008aa800000aa00000
066666555566666556666655555666665656555655666660d5dddddddddddd5d0011112ff22221009999aa90009aa90001111599555510008888000000000000
066666555565656556565655555666665656565655555500dd5555555555555d0000122f222221000009a900009aa90000015595555510008aa800000aa00000
066666555565656556565655555666665656565655766670ddd0000000000ddd0000111111111000000990000099990000011111111100008888000000000000
00555555556565655656565555555555565656555566666008118880050000000000600000000000011111110011110000000000001111100000000000000000
0766675555656565565656555557666756565656556666602a56992a000000800000000000000000014444410111111000111100011111100011110000000000
06666655666666655666666655566666555555555566666086fafa8800905000000006000000000001f1f1f111118b100111111001118b100111111000000000
0666665555555555555555555556666666666666675757576298fa8d00000000009000000060000001fffff11bbbbb100118b810001bbb1001118b1000000000
066666566666666666666666655666660000000006656566844f8a8a080050900000000000000000001ff11001bbbb1001bbbb100015510001bbbb1000000000
757575755555555555555555557575757000000006666666a6f89d600000000000500900000000000188888101bbb1000155510001cccc100155510000000000
665656666666666666666666666656566000000000000000a85725a009080900000000500005000018888888015551001cccb100005b55101cccc10000000000
66666660000000000000000000666666600000000000000005865d0600800880000a000000000000f188888f1ccccc1015bb5100001bbb1015bb771000000000
410000011110000000000000000000000000000000000000000000000000000000000000000000000000000001bb55b101177100001177100151771000000000
1411111eeee10000000000000000000000000000000000000000000000000000000000000000000000000000001bb51001778100001777a1011777a100000000
41eeeeee1e110000000000000000777707000000000000000000000000000000000000000000000000000000001177100178a710017778a1011778a100000000
1eeeeeeeeeee1000000000000000777777000000000770000000000000000000000000000000000000000000001778a10178a71001778a7101178a7100000000
1eeeeeeeeeee100000000000007777777707770007777770000000000000000000000000000000000000000001178a71017aa71000178a110011a71000000000
1eeeeeeeee11000000000000007777777777770077777777000000000000000000000000000000000000000001178a710011111001b111b1001b111000000000
01eeeeeee10000000000000007777777777777000000000000000000000000000000000000000000000000001b177771001b100001bb11bb001b100000000000
01e141e14100000000000000777777777777777700000000000000000000000000000000000000000000000001b101bb001bb10000110011001bb10000000000
000000011bb11000000000000000000000000000000000000000000000000000000000000000000000000000ff111ff1ff111ff1ff111ff1ff111ff10ff111ff
0000001bbbbbb1110000000000000000000000000000000000000000000000000000000000000000000000001f1111f11f1111f11f1111f11f1111f101f1111f
000001b33a33bbbb1000000000000000001000000000000000000000000000000000000000000000000000001f1111f11f16f6f11f16f6f11f1111f101f16f6f
00011b33333bb333b100000000000000013100000000000000000000000000000000000000000000000000001f16f6f11ffffff11ffffff11f16f6f101ffffff
001bbbb333bb333a3b10000000000000133310000000000000000000000000000000000000000000000000001ffffff11ffffff11ffffff11ffffff101ffffff
11bb333b33b3333333b1000000000001333310000000000000000000000000000000000000000000000000001ffffff11ffff1f11ffff1f11ffff1f101ffff1f
1b333333bb33333333b1000000000013353310000000000000000000000000000000000000000000000000001f7771f11f7777f11f7771f11f7771f101f7771f
b33333333b33393333b1100000000013333310000000000110000000000000000000000000000000000000001777771117777110077777711777711101777777
b33333333b33333b33bbb10000000133333310000010111331110000000000000000000000000000000000000177777101777100001777710177710000177771
b33bbbbb3b333333bbb3b10000001313333331000131333333331000000000000000000000000000000000000017777101777100001777710177710000077771
b3bb333bbbb33333bb33bb1000013333333310000133353533553100000000000000000000000000000000000017777101777100001777710177710000017771
bbb3a333bb3b333bb3b33b1000001133333310000133355335355100000000000000000000000000000000000017777101777100000777710177710000017771
bb33333bbbbbbbbb33bb3b1000001333b33331001335333535b55310000000000000000000000000000000000177777101777100001f11f1001f100000017771
b3b333bb33b3b33333b3b100000133333333310013553353535553100000000000000000000000000000000001f101f1001f100001f101f1001f100000001f10
b33bbbb333b33b3a33b3b1000013353333533310135b335333333331000000000000000000000000000000001f1001f1001f100001ff11ff001f100000001f10
b33333333bb333b33bb3b100013311333333113113333333353533510000000000000000000000000000000001f101ff001ff10000110011001ff10000001ff1
b333333333b333b3bb33b10000111333333331101355553333533351000000000000000000000000000000000000000000000000000000000000000000000000
bb3333933bbb33bbb33bb10000001353339333101555533333933331000000000000000000000000000000000000000000000000000000000000000000000000
1bb33333bb33bbbb33bb100000013353333333101533335355553351000000000000000000000000000000000000000000000000000000000000000000000000
01bb3b3bb3333bb33bb1000000133333333313311555355335353b51000000000000000000000000000000000000000000000000000000000000000000000000
001bbbbb3333bbbbbb10000001333333333331101553555335353551000000000000000000000000000000000000000000000000000000000000000000000000
0001111b333bb1111100000013b11133333331001353553533335331000000000000000000000000000000000000000000000000000000000000000000000000
00000001bbbb4100000000000111333333b313101333533555355310000000000000000000000000000000000000000000000000000000000000000000000000
0000000144444100000000000013333333333331013b335553333100000000000000000000000000000000000000000000000000000000000000000000000000
00000014544441000000000001333933333311100011113334111000000000000000000000000000000000000000000000000000000000000000000000000000
00000014444541000000000013311133333310000000114444100000000000000000000000000000000000000000000000000000000000000000000000000000
00000014445444100000000001113333333331000000145444100000000000000000000000000000000000000000000000000000000000000000000000000000
00000145454544100000000000133333353333100000144544100000000000000000000000000000000000000000000000000000000000000000000000000000
00000145545454100000000001353333333333100001454454100000000000000000000000000000000000000000000000000000000000000000000000000000
00001454445445410000000013333133333313310001455545100000000000000000000000000000000000000000000000000000000000000000000000000000
00014554444554410000000001111335333531100014544455410000000000000000000000000000000000000000000000000000000000000000000000000000
00011111111111111000000000133333333331000011111111111000000000000000000000000000000000000000000000000000000000000000000000000000
06700000e88e000008800000013333b3333333100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
566500008aa800008aa8000013333333333b33310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
055000008aa800008aa8000033333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000e88e00000880000011111113333331110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000014444110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000014444100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000144444410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001305013050056500c0500c050056500a0501d000210002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000a6500a6100f0500c6200c6500c6300f0500a6100c650070200f650076100f03013050116300a6300a050036101605000000000000000000000000000000000000000000000000000000000000000000
000200002715029100291002915000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000f05011050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000f42011420274000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003025027250272002725000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000076500765005650110500f0500c0501660016600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000505003050000000505007050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000763007050000000363003050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00001605007010130500c01018050000001f0500a0101d0501d0301d0000c0002e700050002e7000500000000050000000000000000000000000000000000000000000000000000000000000000000000000
000300002d610236101b6101661012610016100000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000070500a050111500265003600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001b1501b1301b11027150271302b1502b13030150301503015030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000110500100011050111201305011120180500000016050160501112016050111201305013120160502b0001f000270001f000220001f000270001f0002b00033000370003a000000003a0000000035000
011400201f0001f000106201f0001c13000000301000c0501b00007000106302e2001513000000241000c0501d000291001063000000036000c050240000c0502200018000106300f0001a1500f000181500c050
011400201a13018130106301f0001c13000000301000c0501b0001f130106301c1301513000000131500c0501d000291001063000000036000c050131500c0501115010150106300f0001a1500f000181500c030
011400201c130181301f5301f0001813000000000001f5301b000181301f5301513013130000000e1201d5301c530291001f53000000036001c0301a1301f530211201f1301f5300f0001c1200f0001d13000000
011400201c120181201f5201f0001812000000000001f5201b000181201f5201512013120000000e1201d5201c520291001f52000020036001c0201a1201f520211201f1201f5200f0001c1200f0001d12000000
011400201a12018120106201f0001c12000000301000c0201b0001f120106201c1201512000000131200c0201d000291001062000000036000c020131200c0201112010120106200f0001a1200f000181200c020
011400000405004050040500405000000000000000000000020500205002050020500000000000000000000000050000500005000050000000000000000000000005000050000500005000000000000005002050
01140000000000000000000000000c630000000000000000000000000000000000000c630000000000000000000000000000000000000c630000000000000000000000000000000000000c630000000000000000
011000000000000000000000000000000000000e3310e33000000112320e2330c23400000000000e3310e3300000000000000001023410234000000e3310e330000000c2320e2310000000000000000e3310e330
010c00000c050000000c0501c13018630000001c120000000c050000000c0500000018630000001c120000000c050000000c0501c13018630000001c120000000c050000000c0500000018630000001c12018100
010c0000000000000023110000000000000000231100000000000000001313000000111300000018130000001113000000101300000000000000000000000000231100000000000000000c130000001013000000
010c000000000000001f1100000000000000001f1100000000000000001d130000001f130000001c1300000000000000001f1100000000000000001f11000000000000000018130000001a130000001a13000000
__music__
01 0e4e4f44
00 0e424344
00 0f424344
00 0f504344
00 0f104344
00 0f104344
00 0f104344
02 0f504344
01 11424344
02 51124344
01 13425544
00 13145544
00 13145544
00 13141544
00 13141544
02 13141544
01 16424344
00 16424344
00 16174344
00 16424344
00 16174344
00 16174344
00 16571844
02 16571844


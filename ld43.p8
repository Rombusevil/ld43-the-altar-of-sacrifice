pico-8 cartridge // http://www.pico-8.com
version 15
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
		printh("updating explo")
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
	add(texts, tutils({text="the altar of sacrifices",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
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
        if(btnp(5)) sfx(4) curstate=story_state() 
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
function story_state()
    local state={}
	local texts={}
	local textsm=0 
	local ssy=5
	local ystep=10
	local fgc=7
	local bgc=0
	local dosh=false
	local shc=2
	function texts1()
		local texts={}
		local sy=ssy
		add(texts, tutils({text='hi billy. ',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		sy+=ystep/2
		add(texts, tutils({text='you don\'t need to know who',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		add(texts, tutils({text='i am.',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		sy+=ystep/2
		add(texts, tutils({text='you\'ve been          by an',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  
		add(texts, tutils({text='             murdered       ',centerx=true,y=sy,fg=fgc,bg=8,bordered=true}))  sy+=ystep
		add(texts, tutils({text='old enemy of mine.',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		sy+=ystep/2
		add(texts, tutils({text='don\'t worry, i\'m giving you',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		add(texts, tutils({text='your life back, but you\'re on',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		add(texts, tutils({text='a mission this time',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))sy+=ystep
		sy+=ystep/2
		add(texts, tutils({text='that is to kill your murderer!',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))sy+=ystep
		sy+=ystep/2
		add(texts, tutils({text="❎", blink=true, on_time=15, centerx=true,y=sy,fg=fgc2,bg=bgc1,shadowed=dosh, sh=shc7}))
		return texts
	end
	function texts2()
		local texts={}
		local sy=ssy*3
		add(texts, tutils({text='this process isn\'t cheap.',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		sy+=ystep
		add(texts, tutils({text='your memory will be affected',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		add(texts, tutils({text='and you\'ll only be able',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		add(texts, tutils({text='to remember 3 things before you',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		add(texts, tutils({text='run out of memory space.',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		sy+=ystep
		add(texts, tutils({text='choose them carefully!',centerx=true,y=sy,fg=fgc,bg=bgc,bordered=true,shadowed=dosh,sh=shc2}))  sy+=ystep
		sy+=ystep
		add(texts, tutils({text="❎", blink=true, on_time=15, centerx=true,y=sy,fg=fgc2,bg=bgc1,shadowed=dosh, sh=shc7}))
		return texts
	end
	state.update=function()
		if btnp(5) then  
			sfx(4)
			if textsm == 0 then
				texts = texts2()
			else
				curstate=platforming_state()
			end
			textsm+=1
		end
	end
	state.draw=function()
		fillp(0b1010000110100100)
		rectfill(0,0,127,127, 1)
        for t in all(texts) do
            t:draw()
        end
	end
	texts = texts1()
	return state
end
function platforming_state()
    music(1)
    local s={}
    local updateables={}
    local drawables={}
    local bullets={}
    s.bullets=bullets
    local victims={}
    local potions={}
    local cam={x=0, y=0}
    s.cam = cam
    local respawned=false
    local showmsg=false
    local showmsgtxt=""
    local rtick=0
    local level={}
    level.hs=150 
    level.fw=256 
    level.es=128 
    level.hw=48  
    level.hcnt=5 
    level.w=(level.hw+level.hs)*level.hcnt+level.fw +level.es
    local deferpos=false
    local pendingmusic=false
    function bullet(x,y, dir, spd, bullets, dmg)
        local e=entity({})
        e:setpos(x,y)
        e.dir=dir
        e.spd=spd
        e.dmg=dmg
        local bounds_obj=bbox(8,8,0,0,4,6)
        e:set_bounds(bounds_obj)
        function e:update()
            self:setx(self.x+(self.spd*self.dir))
            if(self.x > cam.x+127)  self:kill()
            if(self.x < cam.x)      self:kill()
        end
        function e:kill()
            del(bullets,self)
        end
        function e:draw()
            spr(72, self.x, self.y, 1,1)
        end
        return e
    end
    function hero(x,y, bullets, platforming_state)
        local anim_obj=anim()
        local e=entity(anim_obj)
        anim_obj:add(1,4,0.3,1,2) 
        anim_obj:add(5,1,0.01,1,2) 
        anim_obj:add(6,1,0.01,1,2) 
        anim_obj:add(7,1,0.5,2,2,true, function() e.shooting=false end) 
        e:setpos(x,y)
        e:set_anim(2) 
        local bounds_obj=bbox(8,16)
        e:set_bounds(bounds_obj)
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
        e.bulletspd=4
        e.health=20
        e.dmg=1
        e.finalboss=false
        e.atacking=false
        e.dropping=false
        e.potions=0
        e.notifyjumpobj=nil
        e.codes={}
        e.codes.dir='none'
        e.codes.exit=false
        e.codes.dircode='none'
        e.btimer=0
        e.prevsh=-6300
        e.memslots={}
        e.pickedupvictim=nil
        e.blockright=false
        e.blockleft=false
        add(e.memslots,"empty")
        add(e.memslots,"empty")
        add(e.memslots,"empty")
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
                self:reset()
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
                if btn(0) and not self.blockleft then     
                    self:setx(self.x-self.speed)
                    self.flipx=true
                    self:set_anim(1) 
                    self.blockright=false
                elseif btn(1) and not self.blockright then 
                    self:setx(self.x+self.speed)
                    self.flipx=false
                    self:set_anim(1) 
                    self.blockleft=false
                else
                    self:set_anim(2) 
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
            self.respawned=true
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
            self.bulletspd=4
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
            if collides(self,self.h) and btnp(2) then 
                sfx(8)
            end            
        end
        function e:draw()
            spr(32, x,y, 6, 4)
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
    function victim(x,y)
        local anim_obj=anim()
        local spr=40
        if (flr(rnd(2)+1)%2==0) spr+=04
        anim_obj:add(spr,1,0.1,1,2) 
        anim_obj:add(spr+1,3,0.9,1,2) 
        anim_obj:add(spr+32,1,0.9,2,1) 
        anim_obj:add(86,4,0.7,1,1) 
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.health = 3
        e.runaway = false
        e.runawaytick=0
        e.dir = 1
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        function e:hurt(attacker)
            self.health -=1
            self:flicker(0.2)
            if self.health <= 0 then
                attacker:pickup(self)
                self:set_anim(3) 
                self.runaway=false
            else
                self.runaway=true
                self:set_anim(2)
                if flr(rnd(1)+1)%2==0 then
                    self.dir=-1
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
    function npccreator(parent,houses,potioncreator)
        local e={}
        e.ticks=1
        e.threshold=2
        e.lastpos={}
        e.lastpos.x = 60
        e.lastpos.y = 70
        e.timetick=0
        e.timethreshold=100
        function e:tick(pos)
            self.ticks+=1
            self.lastpos.x=pos.x
        end
        function e:update()
            self.timetick+=1
            if self.timetick > self.timethreshold then
                local idx = flr(rnd(#houses-1)+1)
                local house = houses[idx]
                local rndx = rnd(10)
                local v = victim(house.x-rndx,70)
                for b in all(parent) do
                    if collides(b, v) then 
                        v.y += rnd(3)
                        v.x += rnd(6)*16
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
        e.timethreshold=100
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
            e1._draw=e1.draw
            function e1:draw()
                local yy = self.y
                if (yy < 10) yy = 10
                circfill(self.x+7, 85, self.y*0.08, 0)
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
                    local yy = -100-rnd(100)
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
    function mapbuild(l,hero,this_state,houses,stand)
        local xx=128    
        local hy=44     
        local fx=xx+((l.hs+l.hw)*3)-64 
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
    local hero = hero(400,70, bullets, s)
    s.hero = hero
    local pc = potioncreator(potions)
    add(updateables, pc)
    local houses = {}
    local stand = {}
    mapbuild(level, hero, s, houses,stand)
    local ec = npccreator(victims, houses,pc)
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
        for v in all(victims) do
            if hero.atacking and collides(v, hero) then
                v:hurt(hero)
            end
            v:update()
        end
        if hero.dropping and collides(stand.val, hero) then
            local v = hero.pickedupvictim
            hero.pickedupvictim=nil
            v.x = stand.val.x+4
            v.y = stand.val.y-3
            v:sacrifice()
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
        for b in all(bullets) do
            b:draw()
        end
        for e in all(victims) do
            e:draw()
        end
        for p in all(potions) do
            p:draw()
        end
        s.drawhud()
        if hero.respawned or showmsg then
            camera(0,0)
            rtick+=1
            if hero.respawned then
                print("your friends where killed", 15,28, 7)
                print("you've been respawned", 21,34, 7)
                if(rtick>100) hero.respawned=false rtick=0
                showmsg=false
            elseif showmsg then
                print(showmsgtxt, 15,28, 7)
                if(rtick>40) rtick=0
            end
        end
    end
    s.drawhud=function()
        camera(0,0)
        fillp(0)
        local yy=106
        rectfill(0,yy,127,127, 0) 
        rect(2,yy+2,125,125, 7) 
        local sx=5
        local sy=yy+5
        local hgt=4
        local wdt=58
        rectfill(sx,sy, sx+wdt, sy+hgt, 8)
        rectfill(sx,sy+1, sx+wdt, sy+hgt-1, 0)
        local h=hero.health
        local hx=22
        print("health", sx+wdt+3, sy, 8)
        for i=1,h do
            rectfill(sx,sy+2, sx+1, sy+hgt-2, 7)
            sx+=3
        end
        print("money", wdt+41, sy, 10)
        local cash = hero.cash or 0
        print(cash, wdt+41+6, sy+6, 10)
        sx=5
        sy=yy+12
        wdt-=15
        rectfill(sx,sy, sx+wdt, sy+hgt, 8)
        rectfill(sx,sy+1, sx+wdt, sy+hgt-1, 0)
        print("popularity", sx+wdt+2, sy, 8)
        local p = hero.popularity or 15
        for i=1,p do
            rectfill(sx,sy+2, sx+1, sy+hgt-2, 7)
            sx+=3
        end
    end
    return s
end
function gameover_state(prev_state)
    local s={}
    local texts={}
    local timeout=2 
    local frbkg=8
    local frfg=6
    music(-1)
    sfx(-1)
    local ty=15
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         " ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    local restart_msg = "press ❎ to restart"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)
    s.update=function()
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=prev_state
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
    music(-1)
    local s={}
    local texts={}
    local timeout=2 
    local frbkg=11
    local frfg=6
    music(-1)
    sfx(-1)
    sfx(13)
    local ty=15
    add(texts, tutils({text="congratulations billy!!! ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="                         " ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
    add(texts, tutils({text="you avenge your death and",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="helped a misterious god  ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="that now owes you one.   ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
    add(texts, tutils({text="your friends are still",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    add(texts, tutils({text="dead though...",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
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
-- <*gfight_state.lua
-- <*memory_state.lua 

-- <*vertigo_state.lua
--------------------------- end imports

-- to enable mouse support uncomment all of the following commented lines:
-- poke(0x5f2d, 1) -- enables mouse support
function _init()
    -- curstate=menu_state()
    curstate=platforming_state()
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
00000000011111100011110001111110001111000011111101111110001111000000000009aa7a7005511500000001100005555550000000000554d545000050
0070070011116f100111111001116f1001111110011116f111116f1001111110000000009aaaa7a7051111500555911100554494955000950055d44d45000151
000770001fffff100116f610001fff1001116f1001fffff11fffff1001116f10000000009aaaaaa7051111105949551105549944d45000550549445445001155
0007700001ffff1001ffff100017710001ffff10001ffff101ffff1101ffff100000000049aaaaa900110115444495000544444444555995059445d545555100
0070070001fff100017771000177771001777100001fff1001fff11f001fff10000000004a9aaaa90000505554495000054d444d4455444555944555454d4500
00000000017771001777f100007f77101777f100001777f1017771f1001ff1111110000004aaaa9000005549454500000554d444544454455444954444545500
000000001777771017ff7100001fff1017ff71000017ff711777771000177777fff1000000449900000554945445550000544455544454d555594444494d5000
ffffffff01ff77f1017771000017771001777100000177711f1777100017777111100000000000000005d494444495550055955444444d450055544549455000
f5f99f5f001ff71001777100001777710177710000017771f1177771001777100000000005500055005545444459444500554444454445500000545494550000
fff58fff001777100177710000177771017771000001777111f101f10017711000000000054455d00054d4545554495500544444544450000005944555050000
ff9859ff00177771017771000007777101777100000177711f1001f100177771000000000054d440001555545d544950005554555d4450000059444451101100
ff9555ff0177777101777100001f11f1001f10000001777101f101ff001777710000000000545550551100544544945000054555444d45001155949501111150
ff5585ff01f101f1001f100001f101f1001f100000001f100000000001f101f1000000000055500015100054d44d550000054455555555101119555005111150
fff95fff1f1001f1001f100001ff11ff001f100000001f10000000001f1001f10000000001100000050000545d45500000005550000011100110000000511550
0f0ff0f001f101ff001ff10000110011001ff10000001ff10000000001f101ff0000000000100000000000555550000000000000000011100000000000000000
00000000000000777770000000000000000000000777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777766677777777777777777777777766666700000000000000000011110000111100001111100011110000111100001111000011111000111100
00656666665577655567756665666666666666565666666600000000000000000111111001111110011111100111111001111110011111100111111001111110
0065555555577655555677555555555555555555557666700000000000000000016ff61011116f1001116f1001116f1001399310111139100111391001113910
006665666577655555556775666666666566666665666660000000000000000001ffff101fffff10001fff1001ffff1001999910199999100019991001999910
00655555577655555555567755555555555555555566666007888888888888700122210001ffff10012222100122210001555100019999100155551001555100
00656665776555555555556775666666666666566566666086585865588586761222210001222100002f22100222f10015555100015551000059551005559100
00655557765555555555555677555555555555555555550068585555558565671222221012222210001fff1002ff210015555510155555100019991005995100
00656576655555555555555566755666656666666576667055552255555255261222221001ff22f1001222100122210015555510019955910015551001555100
00655766555555555555555556675555555555555566666005112211111112201f222f10001ff210001222210122210019555910001995100015555101555100
00657665555555555555555555667566666665666566666000002555555500201222210000122210001222210122210015555100001555100015555101555100
00676655555555655655555555566755555555555566666000025115555550001222210000122221000222210122210015555100001555510005555101555100
00766555555556655665555555556675656666666555550000051155551650001f11f10001222221001f11f1001f100019119100015555510019119100191000
07665555555556655665555555555667555655565576667001251155551555501f11f10001f101f101f101f1001f100019119100019101910191019100191000
00555555555566655666555555555555565556565566666005555555511565501f11f1001f1001f101ff11ff001f100019119100191001910199119900191000
07666755555565655656555555576667565656565566666065555555511156561ff1ff0001f101ff00110011001ff10019919900019101990011001100199100
06666655555665655656655555566666565656565566666009000000000000900000000000000000000990000000000000000000000000008888000000000000
066666555566656556566655555666665656565555555500999000000000099900111110000001ff0009a9000000000001111100000019908aa800000aa00000
06666655556565655656565555566666565656565576667094999999999999490118ff1000001fff9999aa900000000011899100000199908aa800000aa00000
0055555555656665566656555555555555565656556666609944444444444449011fff111111ff109aaaaaa90000000011999111111991008aa800000aa00000
0766675555656a6556a656555557666756565656556666609990000000000999011fff22f222f1109aaaaaa90000000011999559555911008aa800000aa00000
06666655556666655666665555566666565655565566666094999999999999490011112ff22221009999aa900000000001111599555510008888000000000000
06666655556565655656565555566666565656565555550099444444444444490000122f222221000009a9000000000000015595555510008aa800000aa00000
06666655556565655656565555566666565656565576667099900000000009990000111111111000000990000000000000011111111100008888000000000000
00555555556565655656565555555555565656555566666008118880050000000000600000000000000000000000000000000000000000000000000000000000
0766675555656565565656555557666756565656556666602a56992a000000800000000000000000000000000000000000000000000000000000000000000000
06666655666666655666666655566666555555555566666086fafa88009050000000060000000000000000000000000000000000000000000000000000000000
0666665555555555555555555556666666666666675757576298fa8d000000000090000000600000000000000000000000000000000000000000000000000000
066666566666666666666666655666660000000006656566844f8a8a080050900000000000000000000000000000000000000000000000000000000000000000
757575755555555555555555557575757000000006666666a6f89d60000000000050090000000000000000000000000000000000000000000000000000000000
665656666666666666666666666656566000000000000000a85725a0090809000000005000050000000000000000000000000000000000000000000000000000
66666660000000000000000000666666600000000000000005865d0600800880000a000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0400000eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40eeeeee1e1000000000000000007777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeeeeeeeee00000000000000007777770000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeeeeeeeee00000000000000777777770777000777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeeeeeee0000000000000000777777777777007777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00eeeeeee00000000000000007777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e040e0400000000000000077777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000011bb110000000000000000000000000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000
0000001bbbbbb1110000000000000000000000000000000000000000000000000000000000000000266661200000000000000000000000000000000000000000
000001b33a33bbbb100000000000000000100000000000000000000000000000000000002000600066fff1000000000000000000000000000000000000000000
00011b33333bb333b10000000000000001310000000000000000000000000000200060000090000062fff19d0000000000000000000000000000000000000000
001bbbb333bb333a3b10000000000000133310000000000000000000000550900090000000660500144ff9990000000000000000000000000000000000000000
11bb333b33b3333333b10000000000013333100000000000000000009060090000000200066ff50016ff1d600000000000000000000000000000000000000000
1b333333bb33333333b10000000000133533100000000000000000000905500009600000266ff500155725500000000000000000000000000000000000000000
b33333333b33393333b110000000001333331000000000011000000005596000066600002525550005565d060000000000000000000000000000000000000000
b33333333b33333b33bbb10000000133333310000010111331110000811111000080a80000000000000060000000000000000000000000000000000000000000
b33bbbbb3b333333bbb3b10000001313333331000131333333331000a6e668800858819000000000000006000000000000000000000000000000000000000000
b3bb333bbbb33333bb33bb10000133333333100001333535335531001668fa900866999900500000000000000000000000000000000000000000000000000000
bbb3a333bb3b333bb3b33b1000001133333310000133355335355100016af99901868f9a00000050000000000000000000000000000000000000000000000000
bb33333bbbbbbbbb33bb3b1000001333b33331001335333535b553100157109008a68f5009005509000600500000000000000000000000000000000000000000
b3b333bb33b3b33333b3b10000013333333331001355335353555310185855f00157850500050000000000000000000000000000000000000000000000000000
b33bbbb333b33b3a33b3b1000013353333533310135b3353333333310a1a58001595858a05000080006000500000000000000000000000000000000000000000
b33333333bb333b33bb3b100013311333333113113333333353533510151aaef18a5519000800850000000000000000000000000000000000000000000000000
b333333333b333b3bb33b10000111333333331101355553333533351016661080181818008118880050000000000600000000000011111000111110000000000
bb3333933bbb33bbb33bb10000001353339333101555533333933331018e55a008a515a02a56992a000000800000000000000000144444111444441100000000
1bb33333bb33bbbb33bb10000001335333333310153333535555335101a515100985590086fafa88009050000000060000000000144444441444444400000000
01bb3b3bb3333bb33bb1000000133333333313311555355335353b5100158510001551006298fa8d000000000090000000600000155f1f11155f1f1100000000
001bbbbb3333bbbbbb1000000133333333333110155355533535355101511a1000195800844f8a8a080050900000000000000000055fff10155fff1000000000
0001111b333bb1111100000013b1113333333100135355353333533115101510001a9100a6f89d6000000000005009000000000001ff100001ff100000000000
00000001bbbb4100000000000111333333b3131013335335553553101771177000a55180a85725a0090809000000005000050000018881000188811f00000000
0000000144444100000000000013333333333331013b33555333310001100110001778a005865d0600800880000a000000000000018881000188888f00000000
00000014544441000000000001333933333311100011113334111000000fffffffffffffffff0000000000000000000000000000015851000188811100000000
00000014444541000000000013311133333310000000114444100000000fffffffffffffffff000000000000000000000000000001d8d1000155510000000000
00000014445444100000000001113333333331000000145444100000fff77777fffffffffffff000000fffffffffffffff00000001dfd10001ddd10000000000
00000145454544100000000000133333353333100000144544100000fff777777ffffffffffff00000ffffff7fffffffffff0000001dd1001ddddd1000000000
00000145545454100000000001353333333333100001454454100000fff777777ffffffffffff00000ffffff7fffffffffff0000001dd1001dd1dd1000000000
00001454445445410000000013333133333313310001455545100000fff77877777ffffffffffff0ffffff77777ffffffffff00001ddd100ddd1dd1000000000
00014554444554410000000001111335333531100014544455410000ff778887777fffffffffffffff777777777ffffffffffff001dd1000dd11dd1000000000
00011111111111111000000000133333333331000011111111111000ff778877777ffffffff8ffffff777787777ffffffffffff0015551005551555100000000
06700000e88e000008800000013333b3333333100000000000000000ff7777777ffffffff8ffffffff7778877ffffffffffffff0000000000000000000000000
566500008aa800008aa8000013333333333b33310000000000000000fff777777ffffffff88ffffffff778877fffffffffffffff000000000000000000000000
055000008aa800008aa8000033333333333333330000000000000000fff777777fffffff8f8f8ffffff777777ffffffff8f8ffff000000000000000000000000
00000000e88e00000880000011111113333331110000000000000000ffffffffffffffffff88fffffffffffffffffffff888ffff000000000000000000000000
00000000000000000000000000000014444110000000000000000000fffffffffffffffffff8fffffffffffffffffffffff8ffff000000000000000000000000
00000000000000000000000000000014444100000000000000000000ffffffffffffffffff8ffffffffffffffffffffff8f8ffff000000000000000000000000
00000000000000000000000000000144444410000000000000000000ff8999999fffffffffffffffff8888889ffffffffff88fff000000000000000000000000
0000000000000000000000000000011111111000000000000000000000988855899fffffffffffff000ee5889fffffffffffffff000000000000000000000000
000990000000000000fffffffffff00000000000000000000000000000988855899fffffffffffff000ee5889fffffffffffffff000000000000000000000000
009aa90000000000ff555fffffffff0000ffffffffff00000000000000088855599fffffffffffff00055599fffffffffffffff0000000000000000000000000
09aaaa9000000000ff5555ffffffff000ffff5fffffff00000000000000555999fffffffffff000f00f99899fffffffffffffff0000000000000000000000000
9aaaaaa900000000ff55555ffffffff0ffff555fffffff0000000000000555999fffffffffff000f00f99899fffffffffffffff0000000000000000000000000
999aa99900000000f555555ffffffffff555555ffffffff00000000000055599ffffffffffff000f00ffffffffff00ffff00fff0000000000000000000000000
009aa90000000000f55555fffffffffff55555fffffffff00000000000f99899ffffff000ffff00f00000000000000fff000fff0000000000000000000000000
009aa90000000000ff5555ffffffffffff5555ffffffffff0000000000f99899ffffff000ffff00f00000000000000fff000fff0000000000000000000000000
0099990000000000ffffffffffffffffffffffffffffffff0000000000ffffffffff000000fff00f000000000000fff000fff000000000000000000000000000
0000000000000000ffffffffffffffffffffffffffffffff00111100000000000000000000000000011111000000000000000000000000000000000000000000
0000000000000000f89999fffffffffff88889ffffffffff01666610000000000011110000000000166661000000000000111100000000000000000000000000
00000000000000000988589fffffffff00e589ffffffffff166fff10000000000166661000000000166ff1009000000001666610000000000000000000000000
00000000000000000088559fffffffff00559ffffffffff0166fff10090000000166ff1000000000016ff109990000000166ff10000000000000000000000000
0000000000000000005599fffffff00f0f989ffffffffff0016fff10999000000166ff100000000001571000900000000166ff10000000000000000000000000
000000000000000000559ffffffff00f0fffffff0fff0ff0016ff10009000000015771009000000015555555f000000001577100990000000000000000000000
00000000000000000f989ffff00fff0f000000000ff00ff0015775555f0000001555555999000000011551000000000015555550990000000000000000000000
00000000000000000fffffff0000ff0f00000000ff00ff0000155510000000001155510f900000000151555f000000001155510f000000000000000000000000
00000000000000000000000000000000000000000000000000155555f00000000161510000000000016661000000000001615100000000000000000000000000
0000000000000000000000000000000000000000000000000016661000000000015515f0000000000155551000000000015515f0000000000000000000000000
00000000000000000000000000000000000000000000000000155510000000000155510000000000015515100000000001555100000000000000000000000000
00000000000000000000000000000000000000000000000000151551000000000015510000000000001515100000000001555100000000000000000000000000
00000000000000000000000000000000000000000000000000151151000000000015510000000000015115100000000001555100000000000000000000000000
00000000000000000000000000000000000000000000000001510151000000000015510000000000151015100000000001555100000000000000000000000000
00000000000000000000000000000000000000000000000017100151000000000015510000000000177117700000000001555100000000000000000000000000
00000000000000000000000000000000000000000000000001710177000000000017770000000000011001100000000000777700000000000000000000000000

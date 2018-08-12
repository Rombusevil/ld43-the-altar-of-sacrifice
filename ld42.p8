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
	add(texts, tutils({text="password camp",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
	add(texts, tutils({text="rombosaur studios",centerx=true,y=99,fg=9,sh=2,shadowed=true}))
	local yy=33
	add(texts, tutils({text="jump 🅾️  ",x=12,  y=yy, fg=0,bg=1,shadowed=true, sh=7})) yy+=9
	add(texts, tutils({text="shoot ❎ ",x=12, y=yy, fg=0,bg=1,shadowed=true, sh=7})) yy+=9
	add(texts, tutils({text="move: ⬅️➡️ ",x=12 ,y=yy, fg=0,bg=1,shadowed=true, sh=7})) yy+=9
	add(texts, tutils({text="enter cabins ⬆️",x=12,y=yy, fg=0,bg=1,shadowed=true, sh=7})) yy+=9
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
    local guards={}
    s.bullets=bullets
    local enemies={}
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
    local cabinmsgs={}
    add(cabinmsgs, {used=false, value="eastpass", msg="this password get's you\ninto east city."})
    add(cabinmsgs, {used=false, value="exitpass", msg="this password get's you\nout of this city."})
    add(cabinmsgs, {used=false, value="easthint", msg="to find your murderer\ngo east."})
    add(cabinmsgs, {used=false, value="westhint", msg="to find your murderer\ngo west."})
    add(cabinmsgs, {used=false, value="westpass", msg="this password get's you\ninto west city."})
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
        e.potions=0
        e.notifyjumpobj={}
        e.codes={}
        e.codes.dir='none'
        e.codes.exit=false
        e.codes.dircode='none'
        e.btimer=0
        e.prevsh=-6300
        e.memslots={}
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
                if btn(0) then     
                    self:setx(self.x-self.speed)
                    self.flipx=true
                    self:set_anim(1) 
                elseif btn(1) then 
                    self:setx(self.x+self.speed)
                    self.flipx=false
                    self:set_anim(1) 
                else
                    self:set_anim(2) 
                end
                if btnp(4) and self.grounded then 
                    sfx(4)
                    self.notifyjumpobj:tick({x=self.x, y=self.y})
                    self.grav = -self.jumppw
                    self:sety(self.y + self.grav)
                    self.grounded=false
                    self:set_anim(3) 
                elseif not self.grounded then
                    self:set_anim(3) 
                end
                if btnp(5) then 
                    if(self.btimer-self.prevsh < 10) return 
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
                    local b=bullet(self.x+4, self.y+4, dir, self.bulletspd, bullets, self.dmg)
                    add(bullets, b)
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
    function cabin(x,y, hero)
        local e=entity({})
        e:setpos(x,y)
        local bounds_obj=bbox(12,32, 6, 26, -13, -26)
        e:set_bounds(bounds_obj)
        e.h = hero
        local idx=flr(rnd(4))+1
        if cabinmsgs[idx].used then
            for i=1,5 do
                if(not cabinmsgs[i].used) idx=i break
            end
        end
        cabinmsgs[idx].used=true
        e.cabinmsg=cabinmsgs[idx]
        function e:update()
            if collides(self,self.h) and btnp(2) then 
                sfx(8)
                curstate=gfight_state(s, s, self.cabinmsg.msg, self.cabinmsg.value)
            end            
        end
        function e:draw()
            spr(32, x,y, 6, 5)
        end
        return e
    end
    function guard(x,y,hero,dir)
        local anim_obj=anim()
        anim_obj:add(38,1,0.01,1,2) 
        anim_obj:add(39,1,0.01,1,2) 
        anim_obj:add(40,1,0.01,1,2) 
        local e=entity(anim_obj)
        e:setpos(x,y)
        e:set_anim(1)
        e.sfxfuse=true
        local bounds_obj=bbox(16,16, 0,-30,0,0)
        if(x > 300) bounds_obj=bbox(16,16, -8,-30,8,0)
        e:set_bounds(bounds_obj)
        function e:update()
            if collides(self, hero) then
                local exitcity=false
                local dirpass=false
                local hint=false
                local thispass=dir..'pass'
                local dirhint=dir..'hint'
                for m in all(hero.memslots) do
                    if(m == 'exitpass') exitcity=true
                    if(m == thispass)   dirpass=true
                    if(m == dirhint)    hint=true
                end
                if(exitcity and dirpass and hint) self:set_anim(3) return 
                if(self.x < 200 and hero.x < self.x+16) hero:setx(self.x+16)
                if(self.x > 200 and hero.x > self.x-16) hero:setx(self.x-16)
                if(self.sfxfuse) sfx(6) self.sfxfuse=false
                if(not hint)    self:set_anim(2) showmsg=true showmsgtxt="I'LL ONLY LEAVE WITH A HINT\nOF MY MURDERED BEING THERE" return
                if(not exitcity)self:set_anim(2) showmsg=true showmsgtxt="YOU DON'T HAVE THE PASSWORD\nTO LEAVE" return
                if(not dirpass) self:set_anim(2) showmsg=true showmsgtxt="YOU DON'T HAVE THE PASSWORD\nTO ENTER THIS CITY" return
            else
                self:set_anim(1) 
                self.sfxfuse=true
            end
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
    function priest(x,y,hero,enemies,potioncreator)
        local anim_obj=anim()
        local e=entity(anim_obj)
        y=y+8
        anim_obj:add(119,4,0.2,1,1,true,function() e:set_anim(2) e:sety(e.y-8) e.justborn=10 sfx(7) end)     
        anim_obj:add(86,4,0.2,2,2) 
        anim_obj:add(135,6,0.3,1,2,true,function() del(enemies, e) end) 
        e:setpos(x,y)
        e:set_anim(1)
        e.spd=0.8
        e.justborn=-1 
        e.born=false
        e.dying=false
        e.prevflipx=false
        e.dmg=1
        local bounds_obj=bbox(8,8)
        e:set_bounds(bounds_obj)
        sfx(1)
        function e:update()
            if(self.dying) return
            if self.born then
                if self.x > hero.x + 1 then
                    if(not self.prevflipx) self:setx(self.x-8)
                    self.prevflipx=true
                    self.flipx=true
                    self:setx(self.x-self.spd)
                elseif self.x < hero.x-8 then
                    self.prevflipx=false
                    self.flipx=false
                    self:setx(self.x+self.spd)
                else
                    hero:hurt(self.dmg)
                end
            elseif self.justborn != -1 then
                if self.justborn > 0 then
                    self.justborn-=1
                end
                if self.justborn == 0 then
                    self.born = true
                end
            end
        end
        function e:hurt(dmg)
            self.dying = true
            if(self.flipx) self:setx(self.x+8) 
            self:set_anim(3) 
            potioncreator:tick({x=self.x, y=self.y})
            sfx(6)
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
    function enemycreator(enemies,hero,potioncreator)
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
            local cenemy = false
            if self.timetick > self.timethreshold and hero.x > 130 then
                local side=1
                if(flr(rnd(2))%2==0) side=-1
                self.lastpos.x = hero.x + ((flr(rnd(4))+16) *side)
                self.timetick=0
                cenemy = true
            end
            local jenemy=false
            if self.ticks >= self.threshold then 
                self.ticks=0
                self.timetick+=10
                jenemy=true
            end
            if  jenemy or cenemy then
                local e=priest(self.lastpos.x, self.lastpos.y, hero, enemies,potioncreator)
                add(enemies, e)
            end
        end
        return e
    end
    function mapbuild(l, hero,this_state)
        local xx=128    
        local hy=36     
        function sf()
            function tree(sp, x, y, w, h)
                local t={}
                function t:draw()
                    spr(sp,x,y,w,h)
                end
                return t
            end
            local fx=xx+((l.hs+l.hw)*3)-64 
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
        for i=1,l.hcnt do
            local c = cabin(xx,hy,hero)
            add(drawables, c)
            add(updateables, c)
            xx+=l.hw+l.hs       
            if(i==3) xx+=l.fw   
        end
        local npcy=70
        local g = guard(64, npcy, hero, 'west')
        local t=teleport(58,npcy-16, hero)
        add(guards, g)
        add(updateables, t)
        add(drawables, g)
        add(updateables, g)
        g = guard(l.w-68, npcy, hero, 'east')
        local t=teleport(l.w-58,npcy-16, hero)
        add(guards, g)
        add(updateables, t)
        g.flipx=true
        add(drawables, g)
        add(updateables, g)
    end
    function teleport(x,y,hero)
        local e=entity({})
        e:setpos(x,y)
        local bounds_obj=bbox(8,24)
        e:set_bounds(bounds_obj)
        e.debugbounds=true
        function e:update()
            if collides(self, hero) then
                for g in all(guards) do
                    del(updateables, g)
                    del(drawables, g)
                    del(guards,g)
                end
                curstate=vertigo_state(s,s) 
                return 
            end
        end
        function e:draw()
            if(self.debugbounds) self.bounds:printbounds()
        end
        return e
    end
    local hero = hero(120,70, bullets, s)
    s.hero = hero
    local pc = potioncreator(potions)
    add(updateables, pc)
    local ec = enemycreator(enemies, hero,pc)
    add(updateables, ec)
    hero:set_notifyjumpobj(ec)
    mapbuild(level, hero, s)
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
        s.updateblts(bullets, enemies, true)
        for e in all(enemies) do
            e:update()
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
        rectfill(0,47,level.w,127, 3) 
        rectfill(0,77,level.w,94, 4) 
        for d in all(drawables) do
            d:draw()
        end
        for b in all(bullets) do
            b:draw()
        end
        for e in all(enemies) do
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
    s.updateblts=function(bullets, enemies, priest)
        for b in all(bullets) do
            b:update()
            for e in all(enemies) do
                if not priest or (not e.dying and e.born) then
                    if collides(b, e) then
                        b:kill()
                        e:hurt(b.dmg)
                        break
                    end
                end
            end
        end
    end
    s.drawhud=function()
        camera(0,0)
        fillp(0)
        rectfill(0,0,127,20, 0) 
        rect(2,2,125,18, 7) 
        rectfill(0,110,127,127, 0) 
        rect(2,112,125,125, 7) 
        rectfill(50,110, 74, 115, 7)    
        print("MEMORY", 51, 110, 0)
        local sx=5
        local sy=6
        local hgt=4
        local wdt=58
        rectfill(sx,sy, sx+wdt, sy+hgt, 8)
        rectfill(sx,sy+1, sx+wdt, sy+hgt-1, 0)
        local h=hero.health
        local hx=22
        rectfill(hx,16, hx+24,21, 7)
        print("HEALTH", hx+1, 16, 0)
        for i=1,h do
            rectfill(sx,sy+2, sx+1, sy+hgt-2, 7)
            sx+=3
        end
        local p=hero.potions
        local px=88
        rectfill(px,16, px+28,21, 7)
        print("POTIONS", px+1, 16, 0)
        sx=px
        wdt=28
        rectfill(sx,sy, sx+wdt, sy+hgt, 8)
        rectfill(sx,sy+1, sx+wdt, sy+hgt-1, 0)
        for i=1,p do
            rectfill(px,sy+2, px+1, sy+hgt-2, 7)
            px+=3
        end
        local sxt=4
        local syt=116
        local ttw=38
        local tth=7
        local tsp=2
        for i=1,3 do
            local c=8
            if(hero.memslots[i] == "empty") c=5
            local onepx=0
            if(i==2)onepx=1
            rectfill(sxt,syt,  sxt+ttw+onepx, syt+tth, c)
            sxt+=ttw+tsp+onepx
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
        if(not collideborders) return
        if(h.x < 1) h:setx(1)
        if(h.x >118) h:setx(118)
    end
    s.draw=function()
        cls()
        fillp(0b0000001010000000)
        rectfill(0,0,127,127, 13) 
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
        local xx=44
        rectfill(xx,25,  xx+(ghost.health*2),28, 9)
        rectfill(xx,26,  xx+(ghost.health*2),27, 8)
    end
    return s
end
function memory_state(plat_state, msg, value)
    music(1)
    local s={}
    local ents={}
    local h=plat_state.hero
    local timeout=0
    function arrow()
        local e={}
        e.positions={}
        add(e.positions, {x=20  -2, y=88}) 
        add(e.positions, {x=49  -2, y=88}) 
        add(e.positions, {x=78  -2, y=88}) 
        add(e.positions, {x=107 -2, y=88}) 
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
        if timeout > 30 and (btnp(4) or btnp(5)) then 
            sfx(5)
            if(ar.posidx==4) curstate=plat_state return 
            if h.memslots[ar.posidx] == "empty" then
                h.memslots[ar.posidx] = value
                valuestored=true
            else
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
            local tw = 24 
            local sp = 5  
            for i=1,4 do
                local slottxt="SLOT "..i;
                local c=5
                local to=0 
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
            spr(27, 15,64) 
            spr(11, 104,64) 
            print("yes              no",25,65,7)
            if btnp(0) then 
                sfx(5)
                valueoverwrite=false
                valuestored=true
                h.memslots[ar.posidx] = pendingval
            elseif btnp(1) then 
                sfx(5)
                valueoverwrite=false
            end
        end
    end
    return s
end

-- sadly, the cabin "3d" state takes too many tokens :\ so i'm cutting it off
--  --<*cabin_state.lua
function vertigo_state(prev_state, plat_state)
    music(-1)
    local s={}
    local ctr=0
    local prevCtr=0
    local pat1=0b0001000000000000
    local pat2=0b1111110111111111
    local pat=pat1
    camera(0,0)
    sfx(9)
    local texts={}
    local yy=2
    add(texts,tutils({text="you're back billy!",    centerx=true, y=yy, fg=7, bg=2, sh=3, shadowed=true}))yy+=10
    add(texts,tutils({text="i've killed you once",  centerx=true, y=yy, fg=7, bg=2, sh=3, shadowed=true}))yy+=10
    add(texts,tutils({text="i'll kill you twice!!", centerx=true, y=yy, fg=7, bg=2, sh=3, shadowed=true}))yy+=10
    local text=tutils({text="press ❎ to fight", centerx=true, y=110, fg=7, bg=2, sh=3, shadowed=true})
    s.update=function()
        ctr+=0.1
        if( (flr(ctr)%3)==0 )then
            if ctr-prevCtr > 1 then
                if pat==pat1 then
                    pat=pat2
                else
                    pat=pat1
                end
            end
            prevCtr=ctr
        end
        if ctr > 2 then
            if(btn(5)) curstate=gfight_state(prev_state, plat_state,"","",true) 
        end
    end
    s.draw=function()
        cls()
        local width = sin(ctr)*20+50
        local height= sin(ctr)*20+50
        fillp(pat)
        rectfill(0,0,127,127,2)
        fillp()
        sspr(0,8, 8,8, 64-(width/2),64-(height/2), width, height)
        for t in all(texts) do
            t:draw()
        end
        if(ctr > 2) text:draw()
    end
    return s
end
--------------------------- end imports

-- to enable mouse support uncomment all of the following commented lines:
-- poke(0x5f2d, 1) -- enables mouse support
function _init()
    curstate=menu_state()
    --curstate=cabin_state()
    --curstate=platforming_state()
    --curstate=memory_state(platforming_state(), "go east to find your murderer")
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
00000000001111000000000000111110000000000001111000111100000000000000000077777770000990000009900000fffffffffff0000000000000000000
00000000014444100011110001444410001111000014444101444410001111000000000007222700009aa9000009a900ff555fffffffff0000ffffffffff0000
00700700144fff10014444100144ff10014444100144fff1144fff1001444410000000007222827009aaaa909999aa90ff5555ffffffff000ffff5fffffff000
00077000144fff100144ff100014ff100144ff100144fff1144fff10144fff1000000000722222709aaaaaa99aaaaaa9ff55555ffffffff0ffff555fffffff00
00077000014fff100144ff10001cc1000144ff100014fff1014fff11144fff100000000072228270999aa9999aaaaaa9f555555ffffffffff555555ffffffff0
00700700014ff10001ccc10001cccc1001ccc1000014ff10014ff11f014fff100000000072228270009aa9009999aa90f55555fffffffffff55555fffffffff0
0000000001ccc1001cccf100001fcc101cccf100001cccf101ccc1f1014ff1111110000072228270009aa9000009a900ff5555ffffffffffff5555ffffffffff
000000001cc1cc101cffc100001fff101cffc100001cffc11ccccc1001ccccccfff10000077777000099990000099000ffffffffffffffffffffffffffffffff
ffffffff01ffccf10111110000117710011111000001ccc11f177710001cccc111100000000000001111111100099000ffffffffffffffffffffffffffffffff
f5f99f5f001ff71001777100001777710177710000017771f1171171001cccc0000000000000000144444444009a9000f89999fffffffffff88889ffffffffff
fff58fff001777100177710000177171017771000001777111f101f100f7771000000000000000014444544409aa99990988589fffffffff00e589ffffffffff
ff9859ff00171771017771000001f1f10177710000017771171001f1001717710000000000000001444445449aaaaaa90088559fffffffff00559ffffffffff0
ff9555ff001f11f1001f1000001f11f1001f100000001f1001710177001f11f10000000000000001444445449aaaaaa9005599fffffff00f0f989ffffffffff0
ff5585ff01f101f1001f100001f101f1001f100000001f100000000001f101f100000000000000014444444409aa999900559ffffffff00f0fffffff0fff0ff0
fff95fff171001f1001f100001771177001f100000001f1000000000171001f1000000000000000144444444009a90000f989ffff00fff0f000000000ff00ff0
0f0ff0f001710177001771000011001100177100000017710000000001710177000000000000000144444444000990000fffffff0000ff0f00000000ff00ff00
0000000000000000000000000000000000000000000000000111110001111100011111110000000011ffff1100000000e88e0000088000000000000000000000
000000000000000000000000000000000000000000000000144444111444441101444441000011111ffffff1111100008aa800008aa800000000000000000000
000000000000000000000000000000000000000000000000144444441444444401f1f1f10001cccccccccccccccc10008aa800008aa800000000000000000000
000000000000000000000000000000000000000000000000155f1f11155f1f1101fffff10001ccccccccccccccccc100e88e0000088000000000000000000000
000000000000000770000000000000000000000000000000055fff10155fff10001ff110001ccccccccccccccccccc1000000000000000000000000000000000
00000000000000711700000000000000000000000000000001ff100001ff100001888881001ccccccccccccccccccc1000000000000000000000000000000000
000000000000071144700000000000000000000000000000018881000188811f1888888101cccccccccccccccccccc1000000000000000000000000000000000
000000000000711444477777777777777777777777777777018881000188888ff18f888101cccccccccccccccccccc1000000000000000000000000000000000
00000000000711111111711111144144144144144144144701585100018881111155555101cccccccccccccccccccc1000000000000000000000000000000000
00000000007114444444471111144144144144144144144701d8d10001555100001ddd1001cccccccccccccccccccc1000000000000000000000000000000000
00000000071144444444447111144144144144144144144701dfd10001ddd100001ddd1001ffccccccccccccccccff1000000000000000000000000000000000
000000007111111111111117111141441441441441441447001dd1001ddddd1001ddddd101fff1cccccccccccc1fff1000000000000000000000000000000000
000000071144477777744444711141441441441441441447001dd1001dd1dd1001dd1dd101fff1cccccccccccc1fff1000000000000000000000000000000000
00000071144447cc7c74444447111144144144144144144701ddd100ddd1dd101ddd1ddd01fff1cccccccccccc1fff1000000000000000000000000000000000
00000711111117c7cc71111111711144144144144144144701dd1000dd11dd101dd101dd01fff1cccccccccccc1fff1000000000000000000000000000000000
000071444444477cc774444444471144144144144144144701555100555155511551015501fff1cccccccccccc1fff1000000000000000000000000000000000
00071444444447cc7c74444444447144144144144144144700900000000009000670000001fff11cccccccccc11fff1000000000000000000000000000000000
007111111111177777711111111117441441441441441447099900000000999056650000001fff177777777771ffff1000000000000000000000000000000000
071444444444444444444444444444741441441441441447999990000009999905500000001fff1777777777711fff1000000000000000000000000000000000
714444444441111111111444444444477777777777777777999990000009999900000000001ff117777777777101110000000000000000000000000000000000
71111111111111111111111111111117111111111111111799999999999999990000000000011017777777777100000000000000000000000000000000000000
74444444444111111111144444444447111111111111111799499999999994990000000000000017777777777100000000000000000000000000000000000000
74444444444777777777744444444447111444444444444799944444444449990000000000000177777777777710000000000000000000000000000000000000
71111111111744444444711111111117111444444444444799999000000999990000000000000177777777777710000000000000000000000000000000000000
7444444444474ff44ff4744444444447111111111111111700111100000000000000000000000000011111000000000000000000000000000000000000000000
7444444444474ff44ff4744444444447111444444444444701666610000000000011110000000000166661000000000000111100000000000000000000000000
7111111111174ff44ff47111111111171114444444444447166fff10000000000166661000000000166ff1009000000001666610000000000000000000000000
7444444444474ff44ff47444444444471111111111111117166fff10090000000166ff1000000000016ff109990000000166ff10000000000000000000000000
744444444447444444447444444444471114444444444447016fff10999000000166ff100000000001571000900000000166ff10000000000000000000000000
7111111111174ff44ff47111111111171114444444444447016ff10009000000015771009000000015555555f000000001577100990000000000000000000000
7444444444474ff44ff47444444444471111111111111117015775555f0000001555555999000000011551000000000015555550990000000000000000000000
7747474747474ff44ff4747474747477111444444444444700155510000000001155510f900000000151555f000000001155510f000000000000000000000000
7717171717174ff44ff4717171717177111444444444444700155555f00000000161510000000000016661000000000001615100000000000000000000000000
7747474747474ff44ff474747474747777777777777777770016661000000000015515f0000000000155551000000000015515f0000000000000000000000000
77474747474744444444747474747477555555555555575500155510000000000155510000000000015515100000000001555100000000000000000000000000
77777777777777777777777777777777555555555555575500151551000000000015510000000000001515100000000001555100000000000000000000000000
55755555557444444444475555555755555555555555575500151151000000000015510000000000015115100000000001555100000000000000000000000000
55755555557111111111175555555755555555555555575501510151000000000015510000000000151015100000000001555100000000000000000000000000
00000000007444444444470000000000000000000000000017100151000000000015510000000000177117700000000001555100000000000000000000000000
00000000007111111111170000000000000000000000000001710177000000000017770000000000011001100000000000777700000000000000000000000000
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
b333333333b333b3bb33b10000111333333331101355553333533351016661080181818008118880050000000000600000000000000000000000000000000000
bb3333933bbb33bbb33bb10000001353339333101555533333933331018e55a008a515a02a56992a000000800000000000000000000000000000000000000000
1bb33333bb33bbbb33bb10000001335333333310153333535555335101a515100985590086fafa88009050000000060000000000000000000000000000000000
01bb3b3bb3333bb33bb1000000133333333313311555355335353b5100158510001551006298fa8d000000000090000000600000000000000000000000000000
001bbbbb3333bbbbbb1000000133333333333110155355533535355101511a1000195800844f8a8a080050900000000000000000000000000000000000000000
0001111b333bb1111100000013b1113333333100135355353333533115101510001a9100a6f89d60000000000050090000000000000000000000000000000000
00000001bbbb4100000000000111333333b3131013335335553553101771177000a55180a85725a0090809000000005000050000000000000000000000000000
0000000144444100000000000013333333333331013b33555333310001100110001778a005865d0600800880000a000000000000000000000000000000000000
00000014544441000000000001333933333311100011113334111000000fffffffffffffffff0000000000000000000000000000000000000000000000000000
00000014444541000000000013311133333310000000114444100000000fffffffffffffffff0000000000000000000000000000000000000000000000000000
00000014445444100000000001113333333331000000145444100000fff77777fffffffffffff000000fffffffffffffff000000000000000000000000000000
00000145454544100000000000133333353333100000144544100000fff777777ffffffffffff00000ffffff7fffffffffff0000000000000000000000000000
00000145545454100000000001353333333333100001454454100000fff777777ffffffffffff00000ffffff7fffffffffff0000000000000000000000000000
00001454445445410000000013333133333313310001455545100000fff77877777ffffffffffff0ffffff77777ffffffffff000000000000000000000000000
00014554444554410000000001111335333531100014544455410000ff778887777fffffffffffffff777777777ffffffffffff0000000000000000000000000
00011111111111111000000000133333333331000011111111111000ff778877777ffffffff8ffffff777787777ffffffffffff0000000000000000000000000
000000000000000000000000013333b3333333100000000000000000ff7777777ffffffff8ffffffff7778877ffffffffffffff0000000000000000000000000
00000000000000000000000013333333333b33310000000000000000fff777777ffffffff88ffffffff778877fffffffffffffff000000000000000000000000
00000000000000000000000033333333333333330000000000000000fff777777fffffff8f8f8ffffff777777ffffffff8f8ffff000000000000000000000000
00000000000000000000000011111113333331110000000000000000ffffffffffffffffff88fffffffffffffffffffff888ffff000000000000000000000000
00000000000000000000000000000014444110000000000000000000fffffffffffffffffff8fffffffffffffffffffffff8ffff000000000000000000000000
00000000000000000000000000000014444100000000000000000000ffffffffffffffffff8ffffffffffffffffffffff8f8ffff000000000000000000000000
00000000000000000000000000000144444410000000000000000000ff8999999fffffffffffffffff8888889ffffffffff88fff000000000000000000000000
0000000000000000000000000000011111111000000000000000000000988855899fffffffffffff000ee5889fffffffffffffff000000000000000000000000
0000000000000000000000000000000000000000000000000000000000988855899fffffffffffff000ee5889fffffffffffffff000000000000000000000000
0000000000000000000000000000000000000000000000000000000000088855599fffffffffffff00055599fffffffffffffff0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000555999fffffffffff000f00f99899fffffffffffffff0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000555999fffffffffff000f00f99899fffffffffffffff0000000000000000000000000
0000000000000000000000000000000000000000000000000000000000055599ffffffffffff000f00ffffffffff00ffff00fff0000000000000000000000000
0000000000000000000000000000000000000000000000000000000000f99899ffffff000ffff00f00000000000000fff000fff0000000000000000000000000
0000000000000000000000000000000000000000000000000000000000f99899ffffff000ffff00f00000000000000fff000fff0000000000000000000000000
0000000000000000000000000000000000000000000000000000000000ffffffffff000000fff00f000000000000fff000fff000000000000000000000000000
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
001400002e750070102e7500c0102e750000002e7500a0102e750070002e7000c0002e700050002e7000500000000050000000000000000000000000000000000000000000000000000000000000000000000000
000300002d650236501b6501665012650016500000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000070500a050111500265003600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001b1501b1301b11027150271302b1502b13030150301503015030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000001d0501b0501f050240502b0500000000000220501f05024050290502e05033000000001f0502b0501f050270501f050220501f050270501f0502b05033050370503a050000003a0500000035050
000a00201f0501f0001f0501f000036500000030150000001b050070001b0502e2000365000000241502b1001d050291001d05000000036502b100240503015022050180501d0500f050036500f0501605000000
000a00201f0201f0001f0201f000036200000030100000001b020070001b0202e2000362000000241002b1001d020291001d02000000036202b100240203010022020180001d0200f000036200f0001600000000
00060020054500000007400000001d0500000000000000001c0500000000000000001d050000000540000000240500000000000000001d0500000007400000001c0500000005400000001d050000000760000000
000e00002405024050240301f0501f0501f0201805018050180501805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 0e4b4344
03 0f424344
03 10424344


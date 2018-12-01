-- implements updatable and drawable interfaces
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
	
	-- call on _update() (clears & updates circles)
	function ex:update()
		printh("updating explo")
		if ex.started and #self.circles == 0 then
			del(drawable, self)
			del(updateable, self)
		end

		for ex in all(self.circles) do
			ex.t+=ex.s
			if ex.t >= 20 then
				del(self.circles, ex)
			end
		end
	end
	
	-- call on _draw()
	function ex:draw()
		for ex in all(self.circles) do
			circ(ex.x,ex.y,ex.t/2,8+ex.t%3)
		end
	end
	
	return ex
end
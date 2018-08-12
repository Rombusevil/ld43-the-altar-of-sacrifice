-- the story of the game

-- state
function story_state()
    local state={}
	local texts={}
	local textsm=0 --state machine

	local ssy=5
	local ystep=10
	local fgc=7
	local bgc=0
	local dosh=false
	local shc=2

	-- setup texts for first screen
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

	-- setup texts for second screen
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
		if btnp(5) then  -- "x"
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

        -- title
        for t in all(texts) do
            t:draw()
        end
	end


	-- trigger s1 first
	texts = texts1()

	return state
end
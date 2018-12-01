-- state
function gameover_state(cause)
    local s={}
    local texts={}
    local timeout=2 -- for avoiding the user hitting X while playing and by that dismissing this screen. In seconds
    camera(0,0)
    -- graphical frame 
    local frbkg=8
    local frfg=6

    music(-1)
    sfx(-1)
    
    local ty=15
    if cause == 'health' then
        add(texts, tutils({text="you couldn't tame the gods",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="the people in your village" ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
        add(texts, tutils({text="hates you.",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="game over",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
        add(texts, tutils({text="                         ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    else -- 'reputation'
        add(texts, tutils({text="people in your village  ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="reunited and killed you." ,centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))ty+=10
        add(texts, tutils({text="thers probably someone  ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="dancing on your grave   ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
        add(texts, tutils({text="right now.              ",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=20
        add(texts, tutils({text="game over",centerx=true,y=ty,fg=8,bg=0,bordered=true,shadowed=true,sh=2})) ty+=10
    end

    local restart_msg = "press ❎ to restart"
    local msg = tutils({text="", blink=true, on_time=15, centerx=true,y=110,fg=0,bg=1,bordered=false,shadowed=true,sh=7})
    add(texts, msg)

    s.update=function()
        timeout -= 1/60
        if(btnp(5) and timeout <= 0) curstate=menu_state()-- "X"
    end

    cls()
    s.draw=function()
        -- bkg
        dance_bkg(10,frbkg)

        -- frame
        local frame_x0=10	
        local frame_y0=10
        local frame_x1=128-frame_x0	
        local frame_y1=128-frame_y0
        -- white frame
        rectfill(frame_x0  ,frame_y0-1, frame_x1, frame_y1  , 7)
        rectfill(frame_x0-1,frame_y0+1, frame_x1+1, frame_y1-1, 7)
        -- black frame
        rectfill(frame_x0+1,frame_x0  , frame_x1-1, frame_y1-1, 0)
        rectfill(frame_x0  ,frame_x0+1, frame_x1  , frame_y1-2, 0)
        -- main frame
        rectfill(frame_x0+2,frame_x0+1, frame_x1-2, frame_y1-2, frfg)
        rectfill(frame_x0+1,frame_x0+2, frame_x1-1, frame_y1-3, frfg)
                
        -- draw texts
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
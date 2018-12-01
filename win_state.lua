-- state
function win_state()
    music(-1)
    local s={}
    local texts={}
    local timeout=2 -- for avoiding the user hitting x while playing and by that dismissing this screen. in seconds

    -- graphical frame 
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
        if(btnp(5) and timeout <= 0) curstate=menu_state() -- "x"
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
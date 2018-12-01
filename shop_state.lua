-- state
function shop_state(prevstate)
    music(1)
    local s={}
    local ents={}
    local h=prevstate.hero
    local timeout=0
    camera(0,0)

    function arrow()
        local e={}
        e.positions={}
        add(e.positions, {x=20  -2, y=78}) -- slot 1
        add(e.positions, {x=49  -2, y=78}) -- slot 2
        add(e.positions, {x=78  -2, y=78}) -- slot 3
        add(e.positions, {x=107 -2, y=78}) -- no
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

        if timeout > 30 and (btnp(4) or btnp(5)) then -- x || o
            sfx(5)
            if(ar.posidx==4) curstate=prevstate return -- "no" selected
            local prices = {5,8,5}

            if h.money > prices[ar.posidx] then
                if ar.posidx == 1 or ar.posidx == 2then
                    h.pigs += ar.posidx
                elseif ar.posidx == 3 then
                    h.potions += 1
                end
                -- todo: sfx de buy
                h.money -= prices[ar.posidx]
                h.reputation += flr(prices[ar.posidx] / 2)
                if (h.reputation > 15) then h.reputation=15 end
                didboughtit=true
            else
                -- memory slot occupied, overwrite?
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

        sspr(10*8, 5*8, 8,8,     10,10, 8*3,8*3) -- merchant
        rectfill(5,34, 128-5,128-10, 4)

        if not didboughtit and not notenoughmoney then
            local sx = 10
            local yy = 50
            local tw = 24 -- thought widht (also height as there are squares)
            local sp = 5  -- spacing
            for i=1,4 do
                local slottxt="1 pig\n  $5";
                local c=5
                local to=0 -- text offset

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
            spr(74, 15,syy,1,1,true) --izq
            print("back",25,syy+1,7)

            if btnp(0) or btnp(4) or btnp(1) then --left || x
                sfx(5)
                notenoughmoney=false
            end
        end
    end

    return s
end
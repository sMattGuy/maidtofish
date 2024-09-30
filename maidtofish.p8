pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- maid to fish
-- matt & susu

function _init()
 palt(0,false)
 palt(11,true)
 max_levels = 5
 create_player()
 create_fish()
 gen_fish()
 curr_fish.active = false
 game_ended = false
 music(2)
end

function _update()
 update_fx()
	if intro_active then
	 update_intro()
	 if btnp(4) then
	  intro_active = false
	 end
	elseif game_ended then
	 if btnp(4) then
	  _init()
	 end
	elseif player.level_done then
	 if btnp(4) then
	  next_level()
	 end
 elseif curr_fish.active then
  current_btn = -1
  if btnp(0) then
   current_btn = 0
  elseif btnp(1) then
   current_btn = 1
  elseif btnp(2) then
   current_btn = 2
  elseif btnp(3) then
   current_btn = 3
  end
  if (current_btn ~= -1) then process_input(current_btn) end
  check_progress()
  curr_fish.time_left -= 1
 elseif not curr_fish.active and not player.level_done then
  if btnp(4) then
   curr_fish.active = true
   music(1)
  elseif btnp(0) then
   curr_fish.diff_mod = max(1,curr_fish.diff_mod-1)
   gen_fish()
   curr_fish.active = false
  elseif btnp(1) then
   curr_fish.diff_mod = min(5,curr_fish.diff_mod+1)
   gen_fish()
   curr_fish.active = false
  elseif btnp(2) then
   max_levels = min(99,max_levels+1)
  elseif btnp(3) then
   max_levels = max(1,max_levels-1)
  end
 elseif btnp(4) and not curr_fish.active then
  curr_fish.active = true
  music(1)
 end
end

function _draw()
 cls()
 map()
 draw_background()
 if game_ended then
  draw_endscreen()
 elseif not player.level_done then
  if curr_fish.active then
   draw_character()
   draw_progress()
   draw_inputs()
  else
   draw_title_text()
   draw_character()
  end
  if intro_active then
   draw_character()
   draw_intro()
  end
 else
  draw_results()
 end
 draw_fx()
end
-->8
-- fish engine
max_levels = 5
player = {}
function create_player()
 player.score = 0
 player.level = 1
 player.level_done = false
 player.combo = 0
end

curr_fish = {}
function create_fish()
 curr_fish.progress = 0
 curr_fish.time_left = 300
 curr_fish.input_pattern = {}
 curr_fish.input_pos = 1
 curr_fish.fish = fish_dict[1]
 -- 1 easy, 5 hardest
 curr_fish.diff_mod = 2
 curr_fish.active = false
 curr_fish.winner = false
end

function gen_fish()
 curr_fish.progress = 0
 curr_fish.time_left = (curr_fish.diff_mod * 4 + 10)*30
 curr_fish.input_pos = 1
 curr_fish.fish = fish_dict[ceil(rnd(#fish_dict))]
 gen_pattern()
 curr_fish.active = true
end

function gen_pattern()
 curr_fish.input_pattern = {}
 curr_fish.input_pos = 1
 for i=1,4+curr_fish.diff_mod do
  input_value = {}
  input_value.input = flr(rnd(4))
  input_value.result = 0
  curr_fish.input_pattern[i] = input_value
 end
end

function process_input(button)
 if curr_fish.input_pattern[curr_fish.input_pos].input == button then
  player.combo += 1
  curr_fish.input_pattern[curr_fish.input_pos].result = 1
  curr_fish.progress = curr_fish.progress + 6 - curr_fish.diff_mod
  player.score += curr_fish.diff_mod
  explode(108,31,good_hit,3)
  if player.combo >= 5 then
   add_txt(96,28,rnd(5)+10,-1,-1,true,{0},player.combo.."x")
  end
  sfx(0)
 else
  curr_fish.progress = max(curr_fish.progress - curr_fish.diff_mod,0)
  player.score = max(player.score-curr_fish.diff_mod,0)
  explode(108,31,bad_hit,3)
  if player.combo >= 5 then
   add_txt(90,28,rnd(5)+10,-2,-1,true,{8},"combo\nlost!")
  end
  player.combo = 0
  sfx(1)
 end
 curr_fish.input_pos = curr_fish.input_pos + 1
end

function check_progress()
 if curr_fish.input_pos > count(curr_fish.input_pattern) then
  good_count = 0
  for i=1,count(curr_fish.input_pattern) do
   if curr_fish.input_pattern[i].result == 1 then
    good_count += 1
   end
  end
  if good_count <= ceil(#curr_fish.input_pattern * .25) then
   add_txt(90,28,rnd(5)+10,-2,-1,true,{8},"bad!")
  elseif good_count <= ceil(#curr_fish.input_pattern * .50) then
   add_txt(90,28,rnd(5)+10,-2,-1,true,{9},"good!")
  elseif good_count <= ceil(#curr_fish.input_pattern * .75) then
   add_txt(90,28,rnd(5)+10,-2,-1,true,{11},"great!")
  else
   add_txt(90,28,rnd(5)+10,-2,-1,true,{8,11,9,1},"perfect!")
  end
  progress_bonus = max(good_count * (6 - curr_fish.diff_mod),0)
  curr_fish.progress = curr_fish.progress + progress_bonus
  gen_pattern()
 end
 if curr_fish.progress >= 95 then
  music(-1)
  curr_fish.progress = 95
  curr_fish.active = false
  curr_fish.winner = true
  player.level_done = true
  player.score = player.score + (curr_fish.diff_mod * 5)
  sfx(2)
  explode(100,80,water_drops,10)
  for i=0,5 do
   add_txt(28,75,rnd(10)+10,rnd(3)+1,-rnd(3)-1,false,{flr(rnd(16))},"♪")
  end
 end
 if curr_fish.time_left <= 0 then
 	music(-1)
 	curr_fish.active = false
 	curr_fish.winner = false
 	player.level_done = true
 	sfx(3)
 	local curses = {"$","#","!","@","*"}
  for i=0,5 do
   add_txt(29,72,rnd(10)+10,rnd(3)+1,-rnd(3)-1,false,{8},curses[ceil(rnd(#curses))])
  end
 end
end

function next_level()
	player.level_done = false
	player.level += 1
	if player.level > max_levels then
	 game_ended = true
	 music(0)
	 return
	elseif curr_fish.winner then
	 if rnd(1) > 0.5 then
	  curr_fish.diff_mod = min(curr_fish.diff_mod+1,5)
	 end
	else
	 if rnd(1) > 0.5 then
	  curr_fish.diff_mod = max(curr_fish.diff_mod-1,1)
	 end
	end
	music(1)
	gen_fish()
end
-->8
-- gameplay draw
diff_text = {"easy","regular","tough","hard","insane"}
function draw_progress()
 -- background
 rectfill(0,0,128,18,6)
 -- clerical data
 print("score:"..player.score,7,10,0)
 print("time left:"..ceil(curr_fish.time_left/30),7,4,0)
 print("fish:"..max_levels+1-player.level,80,4,0)
 print("lvl:"..diff_text[curr_fish.diff_mod],80,10,0)
 rectfill(0,0,128,1,4) -- top
 rectfill(0,17,128,18,4) -- bot
 rectfill(0,0,1,16,4) -- left
 rectfill(126,0,128,16,4) -- right
 spr(32,0,0)
 spr(32,0,11,1,1,false,true)
 spr(32,120,0,1,1,true,false)
 spr(32,120,11,1,1,true,true)
 -- fill bar
 rectfill(100,19,128,128,1)
 spr(32,100,19)
 rectfill(100,25,101,120,4)
 spr(32,100,120,1,1,false,true)
 rectfill(115,25,125,120,0)
 fill_color = 8
 if (curr_fish.progress > 33) then fill_color = 10 end
 if (curr_fish.progress > 66) then fill_color = 11 end
 rectfill(115,120-curr_fish.progress,125,120,fill_color)
 rect(115,25,125,120,7)
end

function draw_inputs()
 for i=1,curr_fish.input_pos do
  input_glyphs = {"⬅️","➡️","⬆️","⬇️"}
  glyph_color = 7
  if curr_fish.input_pos > i then
  	if curr_fish.input_pattern[i].result == 0 then
    glyph_color = 8
   else
    glyph_color = 11
   end
  end
  print(input_glyphs[curr_fish.input_pattern[i].input+1],105,(curr_fish.input_pos-i)*9+25,glyph_color)
 end
 circ(108,27,5,8) 
end

rod_pose = true
function draw_character()
 if (rnd(1) > 0.99) then rod_pose = not rod_pose end
 rectfill(30,94,49,104,0)
	sspr(38,0,24,10,8,99,48,18)--arm bot
 sspr(0,11,56,53,-8,27) --head
 sspr(0,64,60,60,-8,80) --body
 if rod_pose then
  for i=0,8 do
 	 sspr(0,48,8,8,50+(i*5),96-(i*5))
  end
  line(97,58,108,128,6)
 else
  for i=0,8 do
 	 sspr(0,56,8,8,48+(i*2),95-(i*8))
  end
  line(68,32,112,128,6)
 end
 circfill(48,108,5,4)
 sspr(38,0,24,11,4,103,48,18) --arm top
 -- face
 sspr(8,0,8,8,19,57) -- r eye
 sspr(16,0,8,8,33,56) -- l eye
 sspr(26,1,3,1,30,70) -- mouth
end

function draw_results()
 rectfill(30,94,49,104,0)
	sspr(38,0,24,10,8,99,48,18)--arm botm
 sspr(0,11,56,53,-8,27) --head
 sspr(0,64,60,60,-8,80) --body
 --fishing rod
 for i=0,8 do
  sspr(0,48,8,8,50+(i*5),96-(i*5))
 end
 line(97,58,97,62,6)
 circfill(48,108,5,4)
 sspr(38,0,24,11,4,103,48,18)
 --face
 sspr(8,0,8,8,19,55) --r eye
 sspr(16,0,8,8,33,54) --l eye
 if curr_fish.winner then
  sspr(25,3,4,2,29,66) -- mouth
  local f = curr_fish.fish
  sspr(f.sx,f.sy,f.szx,f.szy,89+f.xadj,62+f.yadj)
  local cm = "you caught a "..curr_fish.fish.name
  print(cm,64-#cm*2,5,0)
 else
  sspr(26,1,3,1,30,67) -- mouth
  print("line broke!",42,5,8)
 end
 print("press \"z\" to continue",24,15,0)
end

function draw_title_text()
 circfill(35,0,8,7)
 circfill(35,15,11,7)
 circfill(50,10,22,7)
 circfill(70,10,22,7)
 circfill(102,20,30,7)
 circfill(60,50,20,7)
 circfill(80,50,20,7)
 circfill(107,50,20,7)
 print("   __  ______   _______\n  \#7/  |/  / _ | /  _/ _ \\\n / /|_/ / __ |_/ // // /\n/_/  /_/_/ |_/___/____/",32,-3,0)
 print(" __________\n\#7/_  __/ __ \\\n / / / /_/ /\n/_/  \\____/",80,17,0)
 print("   ______________ __\n  \#7/ __/  _/ __/ // /\n / _/_/ /_\\ \\/ _  /\n/_/ /___/___/_//_/",48,37,0)
 print("press \"z\" to start",55,61,0)
 local f = "fish:"..max_levels
 local d = "diff:"..diff_text[curr_fish.diff_mod]
 print(f,55,27,0)
 print(d,75-((#d-1)*4),21,0)
end

-- background elements
cloud_pos = {80,43,5}
function draw_cloud(x,y,ind)
 circfill(x,y,6,7)
 circfill(x+5,y-2,6,7)
 circfill(x+10,y+2,6,7)
 circfill(x+15,y-1,6,7)
 cloud_pos[ind] += .25
 if cloud_pos[ind] > 135 then
  cloud_pos[ind] = -20
 end
end

function draw_tree(x,y)
 rectfill(x+1,y,x+2,y+5,4)
 circfill(x,y,2,14)
 circfill(x+4,y,2,14)
 circfill(x+1,y-3,2,14)
end

spr_ind = {{0,64,8,3},{0,67,8,3},{0,70,8,3}} 
curr_waves = {}
function draw_background()
 circfill(40,78,7,3)
 circfill(50,85,10,3)
 circfill(60,82,6,3)
 circfill(61,103,6,1)
 -- clouds
 draw_cloud(cloud_pos[1],50,1)
 draw_cloud(cloud_pos[2],20,2)
 draw_cloud(cloud_pos[3],30,3)
 --waves
 if rnd(1) > .95 then
  local w = {}
  w.x = 50 + rnd(70)
  w.y = 100 + rnd(30)
  w.f = 1
  w.t = 0
  add(curr_waves,w)
 end
 for w in all(curr_waves) do
  w.t += 1
  if w.t > 30 then
   w.f = 3
  elseif w.t > 15 then
   w.f = 2
  end
  sspr(spr_ind[w.f][1],spr_ind[w.f][2],spr_ind[w.f][3],spr_ind[w.f][4],w.x,w.y)
  if w.t > 45 then
   del(curr_waves,w)
  end
 end
 draw_tree(90,80)
 draw_tree(73,77)
 draw_tree(108,76)
 draw_tree(60,81)
 draw_tree(80,76)
 draw_tree(50,73)
end
-->8
-- effects
effects = {}

good_hit = {}
good_hit.colors = {11, 3}
good_hit.size = 2

bad_hit = {}
bad_hit.colors = {8, 2}
bad_hit.size = 2

water_drops = {}
water_drops.colors = {7, 12, 1}
water_drops.size = 4

function add_fx(x,y,die,dx,dy,grav,grow,shrink,radius,col_tbl)
 local fx={
  x=x,
  y=y,
  t=0,
  die=die,
  dx=dx,
  dy=dy,
  grav=grav,
  grow=grow,
  shrink=shrink,
  radius=radius,
  col=0,
  col_tbl=col_tbl
 }
 add(effects,fx)
end

-- pop text
txt_fx = {}

function add_txt(x,y,die,dx,dy,grav,col_tbl,text)
 local fx={
  x=x,
  y=y,
  t=0,
  die=die,
  dx=dx,
  dy=dy,
  grav=grav,
  col=0,
  col_tbl=col_tbl,
  text=text
 }
 add(txt_fx,fx)
end

function draw_fx()
 for fx in all(effects) do
  if fx.radius <= 1 then
   pset(fx.x,fx.y,fx.c)
  else
   circfill(fx.x,fx.y,fx.radius,fx.col)
  end
 end
 for fx in all(txt_fx) do
  print(fx.text,fx.x,fx.y,fx.col)
 end
end

function update_fx()
 for fx in all(effects) do
  -- life
  fx.t += 1
  if fx.t > fx.die then 
   del(effects,fx) 
   break
  end
  -- color
  if fx.t/fx.die < 1/#fx.col_tbl then
   fx.col = fx.col_tbl[1]
  elseif fx.t/fx.die < 2/#fx.col_tbl then
   fx.col = fx.col_tbl[2]
  elseif fx.t/fx.die < 3/#fx.col_tbl then
   fx.col = fx.col_tbl[3]
  else
   fx.col = fx.col_tbl[4]
  end
  -- phys
  if fx.grav then fx.dy += .2 end
  if fx.grow then fx.radius += .1 end
  if fx.shrink then fx.radius -= .1 end
  -- move
  fx.x += fx.dx
  fx.y += fx.dy
 end
 for fx in all(txt_fx) do
  -- life
  fx.t += 1
  if fx.t > fx.die then 
   del(txt_fx,fx) 
   break
  end
  -- color
  if fx.t/fx.die < 1/#fx.col_tbl then
   fx.col = fx.col_tbl[1]
  elseif fx.t/fx.die < 2/#fx.col_tbl then
   fx.col = fx.col_tbl[2]
  elseif fx.t/fx.die < 3/#fx.col_tbl then
   fx.col = fx.col_tbl[3]
  else
   fx.col = fx.col_tbl[4]
  end
  -- phys
  if fx.grav then fx.dy += .2 end
  -- move
  fx.x += fx.dx
  fx.y += fx.dy
 end
end

function explode(x,y,hit,amt)
 for i=0,amt do
  add_fx(x,y,15+rnd(15),rnd(2)-1,rnd(2)-1,true,false,true,hit.size,hit.colors)
 end
end
-->8
-- intro and end screen
intro_active = true
intro_x = 0
intro_time = 60

od_timer = 0
od_flip = false
function draw_overdrive()
 od_timer += 1
 rectfill(55+intro_x,52,75+intro_x,79)
 if od_timer < 16 then
  if od_timer < 4 then
   sspr(28,112,11,16,60+intro_x,57,11,16,od_flip)
  elseif od_timer < 8 then
   sspr(39,112,11,16,60+intro_x,57,11,16,od_flip)
  elseif od_timer < 12 then
   sspr(28,112,11,16,60+intro_x,57,11,16,od_flip)
  elseif od_timer < 16 then
   sspr(39,112,11,16,60+intro_x,57,11,16,od_flip)
  end
  if od_flip then
   sspr(0,96,4,6,63+intro_x,73,4,6,od_flip)
  else
   sspr(0,96,4,6,64+intro_x,73,4,6,od_flip)
  end
 else
  if od_timer < 20 then
   sspr(0,112,14,16,59+intro_x,53,14,16,od_flip)
  elseif od_timer < 24 then
   sspr(14,112,14,16,59+intro_x,53,14,16,od_flip)
  elseif od_timer < 28 then
   sspr(0,112,14,16,59+intro_x,53,14,16,od_flip)
  elseif od_timer < 32 then
   sspr(14,112,14,16,59+intro_x,53,14,16,od_flip)
  end
  if od_flip then
   sspr(0,102,8,10,60+intro_x,69,8,10,od_flip)
  else
   sspr(0,102,8,10,64+intro_x,69,8,10,od_flip)
  end
 end
 if od_timer >= 31 then
  od_timer = 1
  od_flip = not od_flip
 end
end

function draw_intro()
 rectfill(0+intro_x,0,128,128,0)
 print("code: matt",44+intro_x,44,7)
 print("art:  susu",44+intro_x,84,7)
 -- overdrive
 draw_overdrive()
 --print("with help from bowie and jupiter",0+intro_x,120,7)
 if rnd(1) > .9 then
  hit_type = good_hit
  if rnd(1) > .5 then
   hit_type = bad_hit
  end
  positions = {{42,44},{86,44},{42,84},{86,84}}
  curr_pos = positions[ceil(rnd(#positions))]
  explode(curr_pos[1]+intro_x,curr_pos[2],hit_type,3)
 end
end

function update_intro()
 intro_time -= 1
 if intro_time <= 0 then
  intro_x += 2
  if intro_x > 128 then
   intro_active = false
  end
 end
end

function draw_endscreen()
 sspr(38,0,17,11,37,100,34,18) --arm top
 sspr(30,0,7,10,70,101,10,16) --thumbs
 line(73,108,75,114,0)
 sspr(0,11,56,53,-8,27) --head
 sspr(0,64,60,60,-8,80) --body
 sspr(38,0,17,11,4,103,34,18) --arm top
 sspr(30,0,7,10,37,104,10,16) --thumbs
 --face
 sspr(8,0,8,8,19,55) --r eye
 sspr(16,0,8,8,33,54) --l eye
 sspr(26,1,3,1,30,67) -- mouth
 print("game over",50,10,0)
 print("final score:"..player.score,50,20,0)
 print("press \"z\"\nto restart",50,30,0)
end
-->8
-- fish directory
fish_dict = {}

function add_fish(sx,sy,szx,szy,scx,scy,xadj,yadj,name)
 local fish = {}
 fish.sx = sx
 fish.sy = sy -- sprite coord
 fish.szx = szx
 fish.szy = szy -- sprite size
 fish.scx = scx
 fish.scy = scy -- sprite scale
 fish.xadj = xadj
 fish.yadj = yadj -- pos for line
 fish.name = name -- name
 add(fish_dict, fish)
end

add_fish(107,52,21,46,21,46,0,0,"perch")
add_fish(80,0,25,48,25,46,-2,0,"tilapia")
add_fish(105,0,23,52,23,52,0,0,"carp")
add_fish(63,0,17,70,17,70,0,0,"sturgeon")
add_fish(89,48,18,70,18,70,0,0,"gar")

__gfx__
00000000b000000bb000000bbbbbbbbb000bbbbbb000bbbbbbbbbbbbbb000bbbbbbbbbb33bbbbbbbbbbbbbbbbb6b6bbbbbbbbbbbbbbbbbbbbb4455bbbbbbbbbb
00000000000000000000000bbb000bbb0f0bbbb000000bbbbbbbbbbb00ff0bbbbbbbbbb33bbbbbbbbbbbbbbbb66666bbbbbbbbbbbbbbbbbbb444455bbbbbbbbb
00700700000000000000000bbbbbbbb0ff0bbb0000000bbbbbbbbbb0ff0000bbbbbbbbb33bbbbbbbbbbbbbbbb666666bbbbbbbbbbbbb4bbbb4444455bbbbbbbb
00077000bbb000bbbb000bbbb0bbbb0ff0000b00000000bbbbbbbbb0fffff0bbbbb333333bbbbbbbbbbbbbbb66666666bbbbbbbbbbbb444b444444455bbbbbbb
00077000bbb000bbbb00bbbbbb000b0f0fff0bb00000000bbbb0000ffffff0bbbbb33b333bbbbbbbbbbbbbb6666666666bbbbbbbbbbbb444444444445bbbbbbb
00700700bbb000bbbb00bbbbbbbbbbbfffff0bbb000000000007770ffffff0bbbb33bb3333bbbbbbbbbbbbb66665576666bbbbbbbbb44bb44444444455bbbbbb
00000000bbb000bbbb00bbbbbbbbbbbfffff0bbbb00000000007770ffffff0bbbb33bb3333bbbbbbbbbbbb666665576666bbbbbbbbb444444455644455bbbbbb
00000000bbbb00bbbb00bbbbbbbbbbbfffff0bbbb00000000007770fffff0bbbbbbbbb3333bbbbbbbbbbbb6666677766666bbbbbbbbbbb444455644445bbbbbb
11111111bbbbbbbbbbbbbbbbbbbbbbbffff0bbbbbb000000000777000000bbbbbbbbbb37533bbbbbbbbbbb6666666666666bbbbbbbbbbb4444666444455bbbbb
11111111bbbbbbbbbbbbbbbbbbbbbbb0000bbbbbbbb000000006660bbbbbbbbbbbbbbb35533bbbbbbbbbb6666666666666666bbbbbbbbb4444444444445bbbbb
11111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000bbbbbbbbbbbbbbb33333bbbbbbbbbb66666666666666666bbbbbbbb4455444444445bbbbb
11111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333bbbbbbbbb6666dd666666666d66bbbbb444455444454444bbbbb
11111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333bbbbbbbbb6666dd666666666dd6bbbb4544445544554444bbbbb
11111111bbbbbbbbbbbbbbbbbbbbbbbbbb00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333bbbbbbb666666dd6666666666dd6bb455444455555444444bbbb
11111111bbbbbbbbbbbbbbbbbb00000000077700bbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333bbbbb66d6666d66d66666666dd6b55555444444444444444bbb
11111111bbbbbbbbbbbbbbbbb007777700777770000000bbbbbbbbbbbbbbbbbbbbb3333333333bbbb66dd6666dd6d6666666ddddb5555b4444444444444444bb
44444444bbbbbbbbbbbbbb0000777777767777766777700bbbbbbbbbbbbbbbbbbbb3333333333bbb6dddb6666dd6dd6666666ddd6555bb44444444444444444b
44999944bbbbbbbbbbbbb07000777777767777767777700000bbbbbbbbbbbbbbbb33333333333bbbddd6b66666dddd6666666dddd4bbbb44444444444444544b
4994444bbbbbbbbbbbbb0777767777777667777677777700770bbbbbbbbbbbbbb333334333333bbbdddbb666666ddd666666dddddbbbbb444444444444445544
4944bbbbbbbbbbbbbbb007777667777776677776677777667700bbbbbbbbbbbb33333343333333bbdd6bb666666666666666dddd6bbbbb444444444444445544
494bbbbbbbbbbbbbbbb0077777677777766777766777776777000bbbbbbbbbb33333b443333333bbddbbb6666666666666666ddddbbbb4444444444444445554
494bbbbbbbbbbb0000006677776677777767777667777667766770bbbbbbbbb33333b443333333bbbdbbb666666666666666d6dddbbb44444444444444445555
444bbbbbbbbbb000000766677766770000000000000776677677770bbbbbbbb3333bb443333333bbbbbbb666666666666666ddddbbb444444444444444445545
44bbbbbbbbbb000077667667777000000000000000000677667700bbbbbbbbbbbbbbb443333333bbbbbbb666666666666666ddddbbb444b44444444444445554
ccccccccbbb000077776676777000000000000000000007766700bbbbbbbbbbbbbbbb443333333bbbbbbb66666666666666d6dddbbb44bb4444444444444555b
ccccccccbbb000007777666700000000000000000000000077700bbbbbbbbbbbbbbbb443333333bbbbbbbb6666666666666dddddbbbbbbb4444444444444554b
ccccccccbb000000077776600000000000000000000000000700bbbbbbbbbbbbbbbbb443333333bbbbbbb666666666666666d6d6bbbbbbb4444444444445544b
ccccccccbb00000006777700000000000000000000000000000bbbbbbbbbbbbbbbbbb443333333bbbbbb6666666666666666ddddbbbbbbb4444444444445555b
ccccccccbb00000000067000000000000000000000000000000bbbbbbbbbbbbbbbbbb443333333bbbbbb6d666666666666dd6dddbbbbbbbb44444444444555bb
ccccccccbb00000000661000000000000000000000000000000bbbbbbbbbbbbbbbbbb443333333bbbbb6dddd66666666666dddddbbbbbbbb44444444444554bb
ccccccccb0000000007600000000000000000000f00000000000bbbbbbbbbbbbbbbbb444333333bbbbb6dddd66666666666ddddbbbbbbbbb44444444444455bb
ccccccccb000000007770000000000000f000000ff0000000000bbbbbbbbbbbbbbbbb444333333bbbbb6d6dd6666666666b6dddbbbbbbbbb44444444445455bb
33333333b00000000777000000000000ff000000fff000000000bbbbbbbbbbbbbbbbb344333333bbbbb6d6dbb66666666bb6ddbbbbbbbbb44444444444b544bb
33333333b00000000777000000000000ff000000ffff00000000bbbbbbbbbbbbbbbbb344333333bbbbbddddbbb6666666bbbddbbbbbbbbb55444444444b545bb
33333333b0000000077000000000000fff000000ffff000000000bbbbbbbbbbbbbbbb344333333bbbbbddddbbb6666666bbbddbbbbbbbb555544444444bb55bb
33333333b000000007700000000000000ff00000ff000f0000000bbbbbbbbbbbbbbbb344333333bbbbbddddbbbb66666bbbbbbbbbbbbbb5455b444444bbbbbbb
33333333b000000007700000000000fffff00000fffffff000000bbbbbbbbbbbbbbbb344333333bbbbbbbdbbbbb66666bbbbbbbbbbbbb55554b444444bbbbbbb
33333333b00000000760000000000fffffff0000fffffff000000bbbbbbbbbbbbbbbb344333333bbbbbbbbbbbbb66666bbbbbbbbbbbbb5555bb444444bbbbbbb
33333333b00000000760000000000fffffff0000ffffffff00000bbbbbbbbbbbbbbbb344333333bbbbbbbbbbbbbd666dbbbbbbbbbbbbbb55bbb444444bbbbbbb
33333333b000000007600000000fffffffff0000ffffffff00000bbbbbbbbbbbbbbbb344333333bbbbbbbbbbbbdddddd6bbbbbbbbbbbbbbbbbb444444bbbbbbb
54545454b00000000660000000fffffffffff000ffffffff00000bbbbbbbbbbbbbbbb3443333333bbbbbbbbbb65ddd55ddbbbbbbbbbbbbbbbbb4444444bbbbbb
45454545b00000000000000000ffffffffffff00ffffffff00000bbbbbbbbbbbbbb333443333333bbbbbbbbb65d5ddd55ddbbbbbbbbbbbbbbb444444444bbbbb
54545454b000000000f0000000fffffffffffff0ffffffff00000bbbbbbbbbbbbbb333444333333bbbbbbbbb5d55d5d55d5bbbbbbbbbbbbbb4444444554bbbbb
45454545b00000000ff0000000ffffffffffffffffffffff00000bbbbbbbbbbbbbb3334443333333bbbbbbb55d5d555d5556bbbbbbbbbbbbb44545545554bbbb
54545454b00000000ff0000000ffffffffffffffffffffff00000bbbbbbbbbbbbb333b3443333333bbbbbbb5555d55555555bbbbbbbbbbbb444545554555bbbb
45454545b00000000fff000000ffffffffffffffffffffff00000bbbbbbbbbbbbb333b3443333333bbbbbb5555555b555555bbbbbbbbbbb44555555554554bbb
54545454b00000000fff000000ffffffffffffffffffffff00000bbbbbbbbbbbbb33bb3443333333bbbbbb555555bbb55555bbbbbbbbbbb4545455b5444554bb
45454545b00000000fff000000ffffffffffffffffffffff0000bbbbbbbbbbbbbbbbb33443333333bbbbbbbb55bbbbbb555bbbbbbbbbbb4455555bb5554555bb
bbbbbbb4b000000000ff000000ffffffffffffffffffffff0000bbbbbbbbbbbbbbbb333443333b33666666666bbbbbbbb66bbbbbbbbbbb4455555bbb545455bb
bbbbbb44b0000000000ff00000fffffffffffffffffffff0000bbbbbbbbbbbbbbbbb333443333bbb666666666bbbbbbbb66bbbbbbbbbbb454555bbbbb55445bb
bbbbb446b00000000b000000000ffffffffffffffffffff0000bbbbbbbbbbbbbbbb333b343333bbb666666666bbbbbbbb66bbbbbbbbbbb55455bbbbbbb5554bb
bbbb406bb00000000bbbbbb0000fffffffffffffffffff0000bbbbbbbbbbbbbbbb3333b343333bbb666666666bbbbbbbb66bbbbbbbbbbbb444bbbbbbbbb55bbb
bbb446bbb0000000bbbbbbb00000fffffffffffffffff00000bbbbbbbbbbbbbbbb3333b343333bbb666666666bbbbbbbb66bbbbbbbbbbbbbbbbfffbbbbbbbbbb
bb446bbbb000000bbbbbbbbb000000ffffffffffffff0bb00bbbbbbbbbbbbbbbb3333bb343333bbb666666666bbbbbbbb66bbbbbbbbbbbbbbbffffbbbbbbbbbb
b446bbbbb000000bbbbbbbbbbb000ffffffffffffff0bbb0bbbbbbbbbbbbbbbbb3333bbb4433bbbb666666666bbbbbbbb66bbbbbbbbbbbbbbbffff4bbbbbbbbb
446bbbbb0000000bbbbbbbbbbbb0000fffffffffff0bbbbbbbbbbbbbbbbbbbbbb333bbbb4433bbbb666666666bbbbbbbb66bbbbbbbbbbbbbbfffff44bbbbbbbb
bbb46bbb000000bbbbbbbbbbbbb000000fffffff00bbbbbbbbbbbbbbbbbbbbbbb333bbbb4433bbbb666666666bbbbbbbb66bbbbbbbbbbbbbbff55744bbbbbbbb
bbb46bbb00b000bbbbbbbbbbbbb00ffff0000000bbbbb0000bbbbbbbbbbbbbbbbbbbbbbb4433bbbb666666666bbbbbbbb66bbbbbbbbbbbbbbff557f44bbbbbbb
bbb46bbb0bb00bbbbbbbbbbbbb0000fffff000bbbbb000000bbbbbbbbbbbbbbbbbbbbbbb4433bbbb666666666bbbbbbbb666bbbbbbbbbbbbfff777f44bbbbbbb
bb406bbbbb00bbbbbbbbbbbbb00670000000060bb000077700bbbbbbbbbbbbbbbbbbbbbb4433bbbb666666666bbbbbbb6666bbbbbbbbbbbbffffffff44bbbbbb
bb460bbbb00bbb0000bbbbbbb0077777777776000007777770bbbbbbbbbbbbbbbbbbbbbb4433bbbb666666666bbbbbbb66666bbbbbbbbbbbffffff4f444bbbbb
bb46bbbb00bbbb0770000bbb00677777707777000077777770bbbbbbbbbbbbbbbbbbbbbb33333bbb666666666bbbbbbb67566bbbbbbbbbbbfffff44f444bbbbb
bb46bbbbbbbbbb0777700000067777777077776007777666700bbbbbbbbbbbbbbbbbbbb333333bbb666666666bbbbbbb65566bbbbbbbbbbbfffff444444bbbbb
bb46bbbbbbbbbb07777777000777777700777770077776677000bbbbbbbbbbbbbbbbbbb3333333bb666666666bbbbbbb66666bbbbbbbbbbbfff4f4444444bbbb
1111ccc1bbbbb0076667770007777777000777700077667700000bbbbbbbbbbbbbbbbb33333333bb666666666bbbbbbb66666bbbbbbbbb9fff44f44444494bbb
111c1c11bbbb000066667700007777700007777000766777000000bbbbbbbbbbbbbbbb333333333b666666666bbbbbbbd66666bbbbbbb99fff44f444444994bb
ccc111ccbbb0000007666660000777700000770000667777700000bbbbbbbbbbbbbbbb333333333b666666666bbbbbbbd66666bbbbbb99fff444ff455444994b
11111111bbb00000007776600000770000000000006677666000000bbbbbbbbbbbbbb3333bb33333666666666bbbbbbd666666bbbbbb9ffff444ff455544499b
111ccc11bbb000000077777000000000000000000077766670000000bbbbbbbbbbbbb333bbbb3333666666666bbbbbb6666666bbbbb9ff9fff44ff4455544994
ccc111ccbb00000000077770000000000000000000776667700000000bbbbbbbbbbbbbbbbbbbb333666666666bbbbb66666666bbbbb9999fffffff4445594494
11111111bb000000000776670000000000000000777777777000000000bb66666666666666666666666666666bbb6666666666bbbbb999bfffffff4454444494
11111111bb0000000006666700000000000000777777777770000000000b66666666666666666666666666666bbddd66666666bbbbb99bbfffffff445544444b
ccccccccb00000000007777777777770000077777777777770000000000b66666666666666666666666666666bddddbd666d66bbbbbbbbbfffffff44555b444b
66666666b00000000007777777777777777777777777667700000000000066666666666666666666666666666ddddbbd666666bbbbbbbbbfffffff45544bb44b
66666666000000000007777777777777777777777777766600000000000066666666666666666666666666666dddbbbd666666bbbbbbbbbbffffff4555bbb4bb
66666666000000000000777667777777777777777777766000000000000066666666666666666666666666666bbbbbbd666666bbbbbbbbbbffffff4455bbbbbb
66666666000000000000006677777777777777777777766000000000000066666666666666666666666666666bbbbbbd666d66bbbbbbbbbbffffff5545bbbbbb
66666666000000000000000777777777777777777777776000000000000066666666666666666666666666666bbbb666666d66bbbbbbbbbbffffff55444bbbbb
66666666000000000000000777777777777777777777776600000000000b66666666666666666666666666666bbb66666666d6bbbbbbbbb99fffff455444bbbb
6666666600000000000000077777777777777777777777660000000000bb66666666666666666666666666666bb666bd6666d6bbbbbbbbb99fffff445444bbbb
666666660000000000000000777777777777777777777766000000000bbb66666666666666666666666666666b6dd6bd66dd66bbbbbbbbb99fffff444449bbbb
666666660000000000000000777777777777777777777766000000000bbb666666666666666666666666666666dd66bd666666bbbbbbbb9999ffff4444494bbb
666666660000000000000000777777777777777777777766000000000bbb666666666666666666666666666666dd6bdd6666d6bbbbbbbb9999ffff4449444bbb
666666660000000000000000777777777777777777777766000000000bbb66666666666666666666666666666dd66bdd6666d6bbbbbbbb9999ffff444b449bbb
666666660000000000000000677777777777777777777666000000000bbb66666666666666666666666666666dd6bbdd6dd666bbbbbbbb9999bfff444b444bbb
666666660000000000000006677777777777777777777660000000000bbb66666666666666666666666666666bbbbbdd6dd666bbbbbbbb999bbbff44bbb44bbb
6666666600000000000000066777777777777777777766600b0000000bbb66666666666666666666666666666bbbbbdd666dd6bbbbbbbbbbbbbbff44bbbbbbbb
66666666b0000000000000006777777777777777766666000bbbbbbbbbbb66666666666666666666666666666bbbbbdd666dd6bbbbbbbbbbbbbbff44bbbbbbbb
66666666bbb0000000000000667777777777766666660000bbbbbbbbbbbb66666666666666666666666666666bbbbbdd6dddd6bbbbbbbbbbbbb99f99bbbbbbbb
66666666bbbb000000000000667777776666666600000000bbbbbbbbbbbb66666666666666666666666666666bbbbbdd6dd6d6bbbbbbbbbbbbb99999bbbbbbbb
66666666bbbbb00000000000067000006600000000077600bbbbbbbbbbbb66666666666666666666666666666bbbbbdd666666bbbbbbbbbbbbb999999bbbbbbb
66666666bbbbb0000000000000000000000000066777770bbbbbbbbbbbbb66666666666666666666666666666bbbbbdd66dd66bbbbbbbbbbbb9999999bbbbbbb
66666666bbbbb0000000000000666666666666777777700bbbbbbbbbbbbb66666666666666666666666666666bbbbbdd6ddd66bbbbbbbbbbbb99999999bbbbbb
66666666bbbbbb0000000000006666666666777777000000bbbbbbbbbbbb66666666666666666666666666666bbbbbdd66d6d6bbbbbbbbbbbb99999999bbbbbb
66666666bbbbbb00000000000066666777777770000070000bbbbbbbbbbb66666666666666666666666666666bbbbbbd66d666bbbbbbbbbbbb99999999bbbbbb
66666666bbbbbb000000000000000000000000077777766000bbbbbbbbbb66666666666666666666666666666bbbbbbd666666bbbbbbbbbbb9999bbb99bbbbbb
bfffbbbbbbbbbbb000000000066666677777777777777660000bbbbbbbbb66666666666666666666666666666bbbbbbd666666bbbbbbbbbbb999bbbbb9bbbbbb
bfffbbbbbbbbbbb0000000006677766777777777777777660000bbbbbbbb66666666666666666666666666666bbbbbbdd66666bbbbbbbbbbbb9bbbbbbbbbbbbb
b666bbbbbbbbbbbb0000000067777667777777777777777660000bbbbbbb66666666666666666666666666666bbbb666666666bbbbb666666666666666666666
b666bbbbbbbbbbbb00000006677766777777777777777776600000bbbbbb66666666666666666666666666666bbb6666666666bbbbb666666666666666666666
5555bbbbbbbbbbbbb0000066777766777777777777777777660000bbbbbb66666666666666666666666666666bbb6d6666666666bbb666666666666666666666
5555bbbbbbbbbbbb000000667777667777777777777777776600000bbbbb66666666666666666666666666666bb6dddb666666666bb666666666666666666666
666600bbbbbbbbb00000066777766777777777777777777776600000bbbb66666666666666666666666666666bb6dddb666666bdd6b666666666666666666666
666000bbbbbbbb000000066777766777777777777777777776660000bbbb66666666666666666666666666666bbddd6bb6666bbdd6b666666666666666666666
000000bbbbbbbb0000006677777677777777777777777777776600000bbb66666666666666666666666666666bbdd6bbb6666bb6dd6666666666666666666666
bffffbbbbbbbb00000006677777777777777777777777777777660000bbb66666666666666666666666666666bb66bbbbb666bb6dd6666666666666666666666
bfffffbbbbbbb000000667777777777777777777777777777776600000bb66666666666666666666666666666bbbbbbbbb666bb66dd666666666666666666666
bffbff6bbbbb0000000667777777777777777777777777777777660000bb66666666666666666666666666666bbbbbbbbb666bbb666666666666666666666666
b66bb665bbbb00000066777777777777777777777777777777776600000b66666666666666666666666666666bbbbbbbbb666bbbb6b666666666666666666666
b66bb555bbb000000066777777777777777777777777777777777600000b66666666666666666666666666666bbbbbbbb66666bbbbb666666666666666666666
555bb55bbb0000000667777777777777777777777777777777777660000066666666666666666666666666666bbbbbbb666666bbbbb666666666666666666666
555bbbbbb00000000667777777777777777777777777777777777660000066666666666666666666666666666bbbbbb6dddd6d6bbbb666666666666666666666
bbbbbb66bbbbbbbbbbbb66bbbbbbbbbbbb66bbbbbbbbb66bbbbbbbbbbbbb66666666666666666666666666666bbbbbb6d6dd666bbbb666666666666666666666
bbbbbbe66bbbbbbbbbbbe66bbbbbbbb66b66bbbbbb66b66bbbbbbbbbbbbb66666666666666666666666666666bbbbbb6d6dd66dbbbb666666666666666666666
bbbbbbee6bbbbbbbbbbbee6bbbbb66666bb66bb66666bb66bbbbbbbbbbbb66666666666666666666666666666bbbbbb6d6dd66d6bbb666666666666666666666
6666bbbe6bbbbb6666bbbe6bbbbb6ee766666bb6ee766666bbbbbbbbbbbb66666666666666666666666666666bbbbbbdd6dd66d6bbb666666666666666666666
6eee66be6bbbbb6eee66be6bbbbbbbb666666bbbbb666666bbbbbbbbbbbb66666666666666666666666666666bbbbbbdd6ddd6ddbbb666666666666666666666
bbee66bb66bbbbbbee66bb66bbbbbbb6f66666bbbb6f66666bbbbbbbbbbb66666666666666666666666666666bbbbbbbd6ddddddbbb666666666666666666666
bbbbb66666bbbbbbbbb66666bbbbbbb6fff666bbbb6fff666bbbbbbbbbbb66666666666666666666666666666bbbbbbbbbdd6bbbbbb666666666666666666666
bbbb666666bbffffbb666666bbbbbbb6fff666bbbb6fff666bbbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
ffbb6f666666ffff6b6f66666bffbffbb006066bbbbb006066bbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
ff6b6fff66006bb6606fff6666ffbff60000066bbbb00ff066bbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
b6606fff6000bbbb006fff66006bbb6600ff066bff600ff066bbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
bb0000000006bbbbb000000000bbbbbbb0ff06bbff6000006bbbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
bbbb00000066bbbbbbb0000006bbbbbbb6666bbbbbbb6666bbbbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
bbbbbb000066bbbbbbbb000066bbbbbb666600bbbbb666600bbbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
bbbbbb00006bbbbbbbbb00006bbbbbbb666000bbbbb666000bbbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
bbbbbb6666bbbbbbbbbb6666bbbbbbbb000000bbbbb000000bbbbbbbbbbb66666666666666666666666666666bbbbbbbbbbbbbbbbbb666666666666666666666
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000cc00000ccccccccccccccccccccccccccccccccc
ccccccc000000cc000000cccccccc0000000cccccc00000000c00000000000cccccccccccccccccccc000700000770000c000000cccccccccccccccccccccccc
ccccccc007770cc077700cccccccc00777000ccccc07777700c007777777000cccccccccccccccccc00777770007777000007700ccccccccc0000ccccccccccc
ccccccc007770cc077700cccccc00007777000cccc07777700c007777777700cccccccccccccc0000007777776677777600777700000ccc00000000ccccccccc
ccccccc007770cc0777000ccccc007777777000ccc07777700c0077700777000ccccccccccc00000000677777677777766677770000000c0000000000ccccccc
cccccc0007770000777000ccccc007777777000cc007777600c00777000777000ccccccccc007777777677777677777766677777000000000000000000cccccc
cccccc0007770000777700ccc00007700777700cc007777000c00777000077700ccccccccc0777777776677776677667666777770000000000000000000ccccc
cccccc0077776006777700ccc00777000077700cc007777000c00777000077700cccccccc00777777776677776677667666777777770000000000000000ccccc
cccccc00777770077777000cc00777000077700cc077777000c00777000077700cccccccc00777777777677777676677667777777777000000000000000ccccc
ccccc000777777777777000cc00777000077700cc07777700cc00777000777600cccccccc007777777776677776766776677777777777000060000000000cccc
ccccc007777777777777700cc07777777777700cc0777660ccc00777007777600cccc0000066777777776677776666776677777777777000006000000000cccc
ccccc007770067760077700cc07777777777700cc0777000ccc00777777776000cccc07777667777777776700000000000777777777700000006000000000ccc
ccccc007770006600077700cc07777000777700cc0777000ccc00777777770000ccc007777766777777700000000000000000777777700000006000000000ccc
ccccc007770000000077700cc07777000777700cc077700cccc007777777600ccccc007777776677700000000000000000000006677000000000600000000ccc
ccccc006660000000066600cc06666000666600cc066600cccc006666660000ccccc0077777766600000000000000000000000006670000000006000000000cc
ccccc000000000000000000cc00000000000000cc000000cccc00000000000ccccc00067777776000000000000000000000000000666000000000600000000cc
ccccc0000000cccc0000000cc00000000000000cc000000cccc0000000000ccccc000666677770000000000000000000000000000066600000000600000000cc
ccccc0000000cccc0000000cc00000000000000cc000000cccc0000000000ccccc007776666700000000000000000000000000000006660000000000000000cc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0777777760000000000000000000000000000000006660000000600000000c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0077777700000000000000000000000000000000000660000000600000000c
ccccccccccccccccc0000000000000000ccccccccccccccccccccccccccccccccc00777777000000000000000000000000000000000000660000006000000000
ccccccccccccccccc0077777777777700ccccc000000000cccccccccccccccccccc0007770000000000000000000000000000000000000660000006000000000
ccccccccccccccccc0077777777777700cccc00777777700cccccccccccccccccccc000000000000000000000000ff0000000000000000060000006000000000
ccccccccc3ccccccc0066667777666600ccc0077777777700cccccccccccccccccccccccc00000000000000000000f0000000000000000006000006000000000
3ccccc3c33ccccccc0000000777000000cc00777700077770ccccccccccccccccccccccc00000000000f000000000fff00000000000000006000006000000000
3ccccc333333ccccc0000000777000000cc007770000077700cccccccccccccccccccccc0000000000ff000000000ffff0000000000000006000006000000000
3ccccc333333ccccc0000000777000000cc077700000077700cccccccccccccccccccccc0000000000fff000000000f00ff000000000000060000c0000000000
3ccccc333333cccccccccc0077700cccccc077700000077700cccccccccccccccccccccc0000000000fff000000000ffffffff000000000000000c0000000000
3ccccc333333ccc3cccccc0077700cccccc077700000077700cccccccccccccccccccccc000000000000ff00000000ffffffffffff00000000000c0000000000
3cccc33333333cc3c3ccc00077700cccccc077770000777700cccccccccccccccccccccc000000000fffff000000000ffff0000000f00000ff000c0000000000
3ccc333333333cc333ccc00677700cccccc067777777777700cccccccccccccccccccccc000000000ffffff00000000fff00000000000000fff00cc000000000
3ccc333333333c3333ccc00777700cccccc006777777777000cccccccccccccccccccccc000000000fffffff00000000f0000000000f0000fff00cc000000000
3ccc333333333c3333ccc00777700cccccc00667777776600ccccccccccccccccccccccc00000000ff00000ff0000000f000ff00000f0000fff00cc000000000
3ccc33333333333333ccc00777700cccccc00006666660000cccccccccccccccccccccccc0000000f0000000ff000000fffffff0000f0000fff00cc000000000
33cc333333333333333cc00666600ccccccc000000000000ccccccccccccccccccccccccc0000000000000000fff00000ffffff0000f0000fff00cc300000000
33cc333333333333333cc00000000cccccccc00000000000cccccccccccccccccccccccccc000000000ff0000fffff0000ffffff000f0000ff00c33300000000
33cc333333333333333cc00000000ccccccccc000000000ccccccccccccccccccccccccccc00000000ffff0000ffffffffffffff000f0000f000c33300000000
33cc333333333333333cccccccccccccccccccccccccccccc0000000c000000ccccccccccc0000000fffff0000ffffffffffffffffff0000000cc33330000000
33cc300000000000000cccccccccccccccccccccccccccccc0777700c077700cccccccccccc0000000fffff000ffffffffffffffffff0000ccccc33330000000
333c3007777777777703cc00000000ccccc0000000000cccc0777700c077700cccccccccccc0000000fffff000fffffffffffffffff00000ccccc33333000000
333c30077777777777033c07777700ccc0000777777700ccc0777700c077700ccccccccccccc0000000ffffffffffffffffffffffff0000ccccc333333000000
333c30077777666666033c07777700cc000777777777700cc0777700c077700cccccccccccccc000000ffffffffffffffffffffffff0f00ccccc333333000000
333330077700000000033c07777700cc007777777777700cc0777700c077700cccc3cccccccccc000000ffffffffffffff00ffffff0f00cccccc333333300000
333330077700000000033c07777600cc0077777000660003c07777000077700cccc3ccccccccccc000000fffffffffff0000ffffffff00ccccc3333333300000
333330077700000000333c07777600cc0006777000000003c07777777777700cccc3ccccccccccc0000c0fffffffff0000f00ffffff000ccccc3333333330000
333330077777777700333007777000cc0000077777000003307777777777700cccc3cccccccccccc000c00ffffffff00ffff0fffff0000ccccc3333333330000
333330077777777700333007777000cc0000007777770003307777777777700cccc3ccccccccccccc00c000ffffffff00fff0ffff00ff00cccc3333333333000
33333007770000000033300777600ccc0007000067777003307777777777700cccc333cccccccccccc00cc000fffffff00ff0fff00fff000ccc3333330000c00
33333007770000000033300777000ccc0007700006777003307776666677700cccc3333cccccccccccc00cc00000fffff000fff00ffff000cc33333330000000
33333007770000000333300777000ccc0077770000777003307770000077700cccc3333c3cccccccc00000cccc0000ffffffff00dfff00600c33333300777000
33333007770033333333300777000ccc0067777777777003307770000077700cccc3333c333c33cc00777000cccc00000fff000dfff0006600033300077770c0
333330077700333333333007770ccccc00677777777760033077700cc077700cccc33333333333cc077777700cccccc0000000dfff00067760000000777770c0
33333007770033333333300777033ccc00067777777700033077700cc077700cccc33333333333cc0777777700ccccc0066000000000677760000070777770c0
33333006660033333333300666033ccc00006666666600033066600cc066600cccc33333333333cc0777777600000000066660000066777770007770777700cc
333330000000333333333000000333c3c0000000000000033000000c3000000ccc33333333333330006677700777000066666660007777777000777077600ccc
333330000000333333333000000333c33c0000000000003330000000000000033c333333333333000000677007770000667777000077777770007700660000cc
333330000000333333333000003333333c000000000003333000000000003333333333333333000000066670777000006777770000077777700077006600000c
3333333333333333333333333333333333333cccccc333333300fffff00000000003333333000000007766007770000077777700000777770000770077770000
3333333333333333333333333333333333333cccccc33333000ffffffffffffff003333000000000077776007770000007777000000077770000770077777000
33333333333333333333333333333333333333333c33330000fffffffffffffff003300000000000777777007770000007777000000077770000770777777000
333333333333333333333333333333333333333333333000ffffffffffffffffff03000000000000777776077700000007777000000077700007770777777000
33333333333333333333333333333333333333333333000fffffffffffffffffff00000000000000777776077700000000777000000007000007770777770000
3333333333333333333333333333333333333333330000ffffffff0fffffffffff00000000000000006770077700000000070000000000000007770776600000
33333333333333333333333333333333333333333000ffffffffff00fff0ffffff00000000000000006670077700000000000000000000000007700666000000
3333333333333333333333333333333333333333000fffff0f0000000000ffffff00000000000000776660077700000000000000000000000007700667700000
33333333333333333333333333555555555cccc000fffff00f0000000000ffffff00000000000007777760077000060000000000000000000077700777770000
3333333355555555555555555555555ccccccc00ffffff000d00660000d0fffffff0000000000007777760676000666000000000000000000077707777770000
333555555555555555555555ccccccccccccc00fffff0000dd0066660000fffffff0000000000007777760666006666000000000000000000077707777770000
555555555555555555ccccccccccccccccccc0ffffff00000000066666000ffffff0000000000000777766660066666007000000000000007777007777700000
555555555555cccccccccccccccccccccccc00fffffffffff0060066666000ffff00000000000000006666600666666007777000000077777777006777700000
cccccccccccccccccccccccccccccccccccc00fffffffffff0000006666600000000000000000000000666000666666007777777777777777777006660000000
ccccccccccccccccccccccccccccccccc67c00ffffffffffff006000ddd660000000000000000000006660006666666007777777777777777777006666000000
ccccccccccccccccccccccccccccccccc67cc00ffffffffffff0060000ddd6600000000000000000000600066666666007777777777777777777076666000000
ccccccccccccccccccccccccccccccccc677c000fffffffffff00666000dddd660000000000000000000066666666d6006777777777777777777007660000000
cccccccccccccccccccccccccccccccccc77ccc0000ffffffff0066660000dddd660000000000000000066666666dd0006777777777777777777077760000000
cccccccccc677ccc77cccccccccc00ccccc7cccc00000000fff006666666000dddd6000000000000000666666666dd0066777777777777777777607700000000
cccccccccc7777cc677cccccccc000ccccccccc000f000000ff006666666600000ddd60000000000006660d66666dd0066677777777777777777600000000000
cccccccccc77777c667cccccccc0000cccccccc00ffff00000006666666666660000ddd600000000666000d6666ddd0066677777777777777777600000000000
ccccccccccc77777c667ccccccc0d00cccccccc00ffffff00000066666666666660000dd6660000666000dd6666dd00066667777777777777777600000000000
ccccccccccc667777c66cccccc00dd0cccccccc0ffffffff00f000666666666666660000000066666000dd66666dd00066667777777777777776600000000000
ccccccccccccc6677766cccccc00dd0cccccccc0ffffffffffff0066666666666666666600006660000d666666ddd00066666777777777777776000000000000
cccccccccccccc66677cccccc00ddd00ccccccc00ffffffffffff0066666666666666660006666000dd6666666ddd00006666677777777777776000000000000
ccccccccccccccccccccccccc00ddd00ccccccc00ffffffffffff00666666666666660000666000ddd6666666ddddd00006666677777777777760000c0000000
ccccccccccccccccccccccccc00ddd00cccccccc0000ffffffff00066666666666660006600000dd6666666666666d00000666677777777777760000cc000000
cccccccccccccccccccccccc000dddd0ccccccccc00000000000000066666666666000666000dd6666666666666666d0000666667777777777660000cc000000
cccccccccccccccccccccccc0000d6d00ccccccc000fffffffffff006666666666006666666666066666666666666666000066666677777777600000ccc00000
ccccccccccccccccccccccc00d00d6d00ccccccc00fffffffffffff00dd666660006666666660006666600000006666600006666666677777760000cccc00000
cccccccccccccccccccccc000dd006d60ccccccc00ffffffffffff000dd6666600066666660000dd666000777000666660006666666666667660000cccc00000
cccccccccccccccccccccc00ddd0066600ccccccc00fffffffff00ff00d666666000666600000dd666600777770006666000066666666666666000cccccc0000
ccccccccccccccccccccc0000d6d066600ccccccc00fffffff0000ff00dd6666600000000000ddd666007700077006666000066666666666660000cccccc0000
ccccccccccccccccccccc00d0d6d006600cccccccc00000000000ffff0dd666666000000000ddd6666007000000700666006066666666666660000cccccc0000
cccccccccccccccccc0000dd0066006660ccccccccc000000000ffff000d6666666ddddddddd66666600700000070066600600000000000000000cccccccc000
cccccccccccc000000000ddd6006006660ccccccccccc000ffffffff000dd6666666ddddddd666666d00700000070066660000666666666677700cccccccc000
cccccccc0000000ddddd00dd6006d066600cccccccccc0000fffffff000dd666666666ddd66666666d00700000070066660060666666677777700cccccccc000
cccccc000000000ddddd000dd6006006600cccccccccc00000ffff00000ddd6666666666666666666d00777000700666660070666667777777700cccccccc000
cccc0000dddddd000ddd6000d6006006600cccccccccc00000000000000ddd6666666666666666666dd0007777000666660070067777777777000ccccccccc00
ccc00000ddddddd000dd66d00d600006600ccccccccccc0000000000000ddd6666666666666666666ddd0000000066666600700000000000000000cccccccc00
c000dd000000ddddd000666d00600006660ccccccccccccc0000cc060000ddd6666666666666666666ddd00000d6666666007006666000000000000ccccccc00
000000dddd0000dddd00066660060006600cccccccccccccccccc00660000dd66666666666666666666ddddddd666666660070066666666760000000cccccc00
00d00000dddd00006660000660000006600cccccccccccccccccc00660d00ddd66666666666666666666ddd66666666666607006667766677600000000ccccc0
dddddd0000ddddd00066d00066006006600cccccccccccccccccc006d00d00ddd6666666666666666666666666666666666066006677666776600000000cccc0
dddddddd0000666600066d0006600006600cccccccccccccccccc06dd00d000ddd6666666666666666666666666666666660d60066777667776000000000cccc
000ddddddd0000666600066000660006600cccccccccccccccccc06ddd00d00ddddd66666666666666666666666666666660d600667776667766000000000ccc
c00000dd66dd00006666000660000066600cccccccccccccccccc06ddd00dd00dddddd666666666666666666666660066660d600667776667776000000000ccc
cccc00000666dd000066660006000066600cccccccccccccccccc06dd6600dd00ddddddd666d006666666666666600666660d6006677766677766000000000cc
ccccccc0000666dd00006660006006666600ccccccccccccccccc06dd66600dd000dddddddd0006666666666666000666660d60066777666777660000000000c
ccccccccc0000066660000666006666666000cccccccccccccccc06dd6666000dd0000000000066666666666666000666660dd00667777666777660000000000
cccccccccccc00006666000666666666d660000cccccccccccccc06dd666660000dd00000000666666666666660000666600dd00667777666777660000000000
ccccccccccccccc00006666666666666d6666000ccccccccccccc06dd6666666000000000006666666666666660000666600dd00667777666777660000000000
cccccccccccccccc0000006666666666ddd6660000ccccccccccc06ddd666666660000000666666666666666600d06666600dd00667777666777766000000000
ccc7777cccccccccc0000000666666666ddd6666000000c00c00000ddd66666666666666666666666666666600d006666600dd00667777766777766000000000
ccc66777777ccccccccc0000006dd666666ddd666600000000006006dd66666666666666666666666666d66000d006666006dd00667777766777766000000000
ccc66666677ccccccccccccc006dd66666666ddd6666600006666006ddd666666666666666666666666dd6000d006666600ddd00667777777777776000000000
cccccccccccccccccccccccc000dddd6666666ddddd0000666666006ddd66666666666666666666666dd6600dd006666600dd600667777777777776600000000
ccccccccccccccccccccccccc006ddddd666666660000660666600006dd6666666666666666666666dd6000dd006666666d33600666777777777776600000000
ccccccccccccccccccccccccc000d33ddd66666600066600600600006ddd6666666666666666666ddd6000ddd006666666d33600666777777777777600000000
cccccccccccccccccccccccccc00633dddd6666000666006000600006ddd66666666666666666dddd6000ddd0066666666d33600666777777777777660000000
cccccccccccc777cccccccccccc00d33dddd6600666600600066000006ddd666666666ddddddddd66000dd00066666666dd33600666777777777777660000000
cccccccccc7776ccccccccccccc006d33ddddd0066600660066600d000dddd666666666ddddd6666000dd00066666666ddd36006666777777777777760000000
ccccccccc66666cccccccccccccc006333ddddd006000660666600d6006ddd6666666600066000000ddd000666666666dd336006666777777777777760000000
ccccccccc6666cccccccccccccccc006333dddd000006600666600dd6000ddd6666666000000000dddd000666666666ddd336006666677777777777766000000
ccccccccccccccccccccccccccccc0006333dddd00006600666600ddd6000dd666666666600000ddd0006666666666dddd330006666677777777777776000000
cccccccccccccccccccccccccccccc0006333ddddd000006666600ddd6666666666666666666000000066666666666dddd360066666677777777777776000000
ccccccccccccccccccccccccccccccc00663333ddddd0000000000dddd66666666666666666660000666666666666dddd3300066666677777777777776000000
ccccccccccccccccccccccccccccccc000666333ddddddd0000000dddd66666666666666666666666666666666666ddd33600066666677777777777776600000
cccccccccccccccccccccccccccccccc000066d3333dddddddddd0ddddd6666666666666666666666666666666666ddd33000066666677777777777777600000

__map__
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040405050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040405050505050101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040401010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040401010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040401010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010200001d03220036220302303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000011330103370e3360c33600100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000000000000000000000
0107000000000000001d7401d7501f750217500030000300217502175000000227502275022750003000030000300003000030000300003000030000300003000030000300000000000000000000000000000000
01090000000000000013337104320e3320c4320000000500053300000000500023300000000500043320232100312000000000000000000000000000000000000000000000000000000000000000000000000000
011000000204200000020420000000000020420504200000000000204200000020420000000000020420704200000000000504200000050420000000000070420904200000000000904200000020420000000000
011000001803200000180320000000000180321a03200000000001803200000180320000000000180321c03200000000001a032000001a03200000000001c0321d03200000000001d03200000180320000000000
491000002e613000000000000000000002e6130000000000000002e613000000000000000000002e6130000000000000002e613000000000000000000002e61300000000000000000000000002e6130000000000
010900100005701055000000000002053030550000000000000000000002053030550000000000000530105500000000000000000000000000000000000000000000000000000000000000000000000000000000
010900200c0410000000000000000e04000000000000000000000000000e0400000000000000000c04300000180420000000000000001a04000000000000000000000000001a0400000000000000001804000000
010900102661500000000000000000000000000000000000000000000026615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31100010003350000500005003050c335003050000500335000050033500305003050c33500305003050030500305003050030500305003050030500305003050030500305003050030500305000050000500005
01100000187300000000000187301c730000000000018730000001873000000000001c73000000000000000024730000000000024730287300000000000247300000024730000000000028730000000000000000
01100000005330000000533006330453300000000000053300000005330000000000005330053300000000000c533000000053300633005330000000000005330000000533000000000004533000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0020000018f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
04 04050644
03 07080944
03 0a0b0c44


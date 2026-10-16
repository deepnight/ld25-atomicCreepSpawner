import mt.deepnight.Buffer;
import mt.deepnight.SpriteLib;
import mt.deepnight.Tweenie;
import mt.deepnight.Lib;
import mt.deepnight.Tip;
import flash.display.Sprite;

@:bitmap("gfx/levels.png") class GfxLevels extends flash.display.BitmapData {}
@:bitmap("gfx/tiles.png") class GfxTiles extends flash.display.BitmapData {}
@:bitmap("gfx/title.png") class GfxTitle extends flash.display.BitmapData {}

enum Phase {
	PIntro;
	PGame;
}

class Game implements haxe.Public { //}
	static var SOUNDS = mt.data.Sounds.directory("sfx");
	
	static var uniq = 0;
	public static var DP_GROUND = uniq++;
	public static var DP_WALLS = uniq++;
	public static var DP_TORCH = uniq++;
	public static var DP_ENTITY = uniq++;
	public static var DP_FX = uniq++;
	public static var DP_DARKNESS = uniq++;
	public static var DP_CURSOR = uniq++;
	public static var DP_INTERF = uniq++;
	public static var DP_TITLE = uniq++;
	
	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	public static var ME : Game;
	public static var UPSCALE = 3;
	public static var USE_SCALE2X = false;
	
	public static var GRID = 16;
	
	var root		: flash.display.MovieClip;
	var phase		: Phase;
	var time		: Int;
	var buffer		: Buffer;
	var tw			: Tweenie;
	var cm			: mt.deepnight.Cinematic;
	var tiles		: SpriteLib;
	var tip			: Tip;
	var bar			: Bar;
	var hero		: Hero;
	var fx			: Fx;
	var level		: Level;
	var killList	: Array<Entity>;
	var halo		: flash.display.Bitmap;
	var torch		: DSprite;
	var hud			: DSprite;
	var entities	: Sprite;
	var lastMessage	: Sprite;
	var pause		: Bool;
	var cd			: mt.deepnight.Cooldown;
	var curLevel	: Int;
	
	var heroLifeCount: flash.text.TextField;
	var rageCount	: flash.text.TextField;
	var hudOrbs		: Array<DSprite>;
	var rage		: Int;
	
	var viewPort	: flash.geom.Rectangle;
	var scroller	: Sprite;
	var sdm			: mt.DepthManager;
	var drag		: Null< {vx:Float, vy:Float, mx:Float, my:Float} >;
	var cancelClick	: Bool;
	
	var cursor		: DSprite;
	var tg			: TextGen;
	
	var introWrap	: Sprite;
	var musicChan	: flash.media.SoundChannel;
	var musicON		: Bool;
	var musicVol	: Float;
	
	public function new(r) {
		haxe.Log.setColor(0xFFFF00);
		//mt.deepnight.Lib.redirectTracesToConsole();
		ME = this;
		root = r;
		root.addEventListener( flash.events.Event.ENTER_FRAME, main );
		cm = new mt.deepnight.Cinematic();
		fx = new Fx();
		
		#if debug
		rage = 50;
		#else
		rage = 0;
		#end
		pause = false;
		hudOrbs = [];
		cancelClick = false;
		killList = [];
		musicON = true;
		musicVol = 0.5;
		time = 0;
		curLevel = 0;
		tw = new Tweenie();
		tg = new TextGen( haxe.Resource.getString("texts") );
		cd = new mt.deepnight.Cooldown();
		
		buffer = new Buffer(320,240, UPSCALE, false, 0x0, USE_SCALE2X);
		buffer.setTexture( Buffer.makeMosaic(UPSCALE), 0.2, flash.display.BlendMode.OVERLAY, true );
		root.addChild(buffer.render);
		
		root.stage.addEventListener( flash.events.KeyboardEvent.KEY_UP, onKey );
		
		tiles = new SpriteLib( new GfxTiles(0,0) );
		tiles.setUnit(16,16);
		tiles.sliceUnit("wall", 0,0, 4);
		tiles.sliceUnit("ground", 0,1, 3);
		tiles.sliceUnit("ground2", 0,2, 3);
		tiles.sliceUnit("groundProps", 3,1, 4);
		tiles.sliceUnitCustom("hud", 0,15, 320,32);
		tiles.sliceUnit("shadow", 0,3);
		tiles.sliceUnit("exit", 1,3);
		tiles.sliceUnit("entrance", 9,1);
		tiles.sliceUnit("cursor", 2,3, 2);
		tiles.sliceUnit("food", 4,3);
		tiles.sliceUnit("orb", 5,3);
		tiles.sliceUnit("chest", 6,3);
		tiles.sliceUnit("golemSpit", 7,3, 2);
		tiles.setAnim("golemSpit", [0,1], [2]);
		tiles.sliceUnit("rage", 9,3);
		tiles.sliceUnit("gold", 10,3, 3);
		tiles.sliceUnit("smallOrb", 13,3, 2);
		tiles.sliceUnit("barButton", 15,3);
		tiles.sliceUnit("fireball", 16,3, 2);
		tiles.setAnim("fireball", [0,1], [2]);
		tiles.sliceUnit("blood", 0,5, 7);
		tiles.sliceUnit("wood", 7,5, 4);
		tiles.sliceUnit("barIcons", 0,11, 4);
		tiles.slice("torch", 0,384, 100,100);
		tiles.slice("slash", 0,288, 48,80);
		
		tiles.sliceUnit("door", 7,1, 2);
		tiles.sliceUnit("ghost", 0,4, 7);
		tiles.sliceUnit("zombie", 0,10, 6);
		tiles.setAnim("zombieWait", [0], [1]);
		tiles.setAnim("zombieWalk", [0,1,0,2], [4,5,4,5]);
		tiles.setAnim("zombieRun", [3,4,3,5], [2,3,2,3]);
		tiles.sliceUnitCustom("golem", 0,8, 32,32, 4);
		tiles.setAnim("golemWalk", [0,1,2,1,3], [6,4,8,3,8]);
		
		tiles.sliceUnitCustom("mage", 0,12, 32,32, 8);
		tiles.sliceUnitCustom("knight", 0,6, 32,32, 8);
		tiles.setAnim("wait", [0], [1]);
		tiles.setAnim("walk", [0,1,2,1, 0,3,4,3], [3,3,5,3, 3,3,5,3]);
		tiles.setAnim("attack", [5,6], [2,3]);
		tiles.setAnim("hit", [7], [6]);
		
		scroller = new Sprite();
		buffer.dm.add(scroller, DP_WALLS);
		sdm = new mt.DepthManager(scroller);
		
		viewPort = new flash.geom.Rectangle(0,0, buffer.width,buffer.height-20);

		hud = tiles.getSprite("hud");
		hud.setCenter(0,0);
		hud.y = buffer.height-hud.height;
		buffer.dm.add(hud, DP_INTERF);
		
		tip = new Tip();
		root.addChild(tip.spr);
		
		bar = new Bar();
		
		heroLifeCount = createField("Hero");
		heroLifeCount.width = 100;
		var f = heroLifeCount.getTextFormat();
		f.align = flash.text.TextFormatAlign.RIGHT;
		heroLifeCount.defaultTextFormat = f;
		heroLifeCount.setTextFormat(f);
		buffer.dm.add(heroLifeCount, DP_INTERF);
		heroLifeCount.x = buffer.width - 120;
		heroLifeCount.y = buffer.height - 13;
		
		buffer.render.addEventListener( flash.events.MouseEvent.CLICK, onClick );
		buffer.render.addEventListener( flash.events.MouseEvent.MOUSE_DOWN, onMouseDown );
		buffer.render.addEventListener( flash.events.MouseEvent.MOUSE_MOVE, onMouseMove );
		buffer.render.addEventListener( flash.events.MouseEvent.MOUSE_UP, onMouseUp );
		//buffer.render.addEventListener( flash.events.MouseEvent.RELEASE_OUTSIDE, onMouseLeave ); // 11.3
		buffer.render.addEventListener( flash.events.Event.MOUSE_LEAVE, onMouseLeave );
		
		rageCount = createField("Rage");
		//rageCount.filters = [];
		rageCount.textColor = 0xF88007;
		rageCount.x = 20;
		rageCount.y = heroLifeCount.y;
		buffer.dm.add(rageCount, DP_INTERF);
		
		var mask = new Sprite();
		buffer.dm.add(mask, DP_DARKNESS);
		mask.graphics.beginFill(0x211C51, 0.35);
		mask.graphics.drawRect(0,0,buffer.width,buffer.height);
		mask.blendMode = flash.display.BlendMode.LAYER;
		
		var s = new Sprite();
		s.graphics.beginFill(0xff,1);
		s.graphics.drawCircle(0,0, 50);
		var b = 16;
		halo = mt.deepnight.Lib.flatten(s, b);
		var bd = halo.bitmapData;
		bd.applyFilter(bd, bd.rect, new flash.geom.Point(0,0), new flash.filters.BlurFilter(b,b,2));
		mask.addChild(halo);
		halo.blendMode = flash.display.BlendMode.ERASE;
		
		torch = tiles.getSprite("torch");
		sdm.add(torch,DP_TORCH);
		torch.blendMode = flash.display.BlendMode.OVERLAY;
		torch.setCenter(0.5, 0.5);
		torch.alpha = 1;
		
		cursor = tiles.getSprite("cursor");
		buffer.dm.add(cursor, DP_CURSOR);
		cursor.setCenter(0.5, 0.5);
		cursor.visible = false;

		//main(null);
		
		//message("Hello world!", hero.getPoint().x, hero.getPoint().y);
		
		musicChan = SOUNDS.music.play(0,9999);

		#if debug
		root.addChild( introWrap = new Sprite() );
		startGame();
		#else
		startIntro();
		#end
	}
	
	
	
	function startGame() {
		entities = new Sprite();
		sdm.add(entities, DP_ENTITY);

		level = new Level(curLevel);
		
		hero = curLevel==0 ? new hero.Knight() : new hero.Mage();
		hero.cx = level.entrance.x;
		hero.cy = level.entrance.y;
		
		initLevel();
		
		focus(hero, 1);
		hero.updateObjectives();
		changeRage(0);

		var i = 0;
		for( e in Mob.ALL ) {
			if( e.name=="orb" ) {
				var s = tiles.getSprite("smallOrb",0);
				s.setCenter(0.5,0.5);
				hud.addChild(s);
				s.x = Std.int(buffer.width*0.5-25 + i*6);
				s.y = 7;
				i++;
				hudOrbs.push(s);
			}
		}
		
		#if !debug
		for(e in Entity.ALL) {
			e.update();
			e.delay = 30*2;
		}
		cd.set("delay", 30*2);
		#end
		
		pause = false;
		phase = PGame;
		main(null);
		pause = true;
		
		if( introWrap!=null && introWrap.parent!=null )
			tw.create(introWrap, "alpha", 0, TEaseIn, 500).onEnd = function() {
				introWrap.parent.removeChild(introWrap);
			}
		
		cm.create({
			500;
			if( curLevel==0 ) {
				#if !debug
				message("This is a HERO.\n\nHe wants to steal your money, destroy your doors, and probably, VANDALIZE EVERYTHING in your brand new dungeon.", hero.getPoint().x, hero.getPoint().y) > end;
				message("Yes, he does that, so you hate him, he hates you, YOU WANT HIM DEAD.") > end;
				message("He will attack and destroy all your ORBS OF TRUE EVILNESS, then leave.", 265,70) > end;
				message("Invoke minions before he rampages everything in your dungeon!", 140,230) > end;
				message("Invocations consume ANGER, which regenerates slowly OR when the hero does thing you DISLIKE.\n\nLike rampaging your dungeon.", 30,230) > end;
				message("OH, I almost forgot.\nYou CANNOT invoke creatures within LIGHTNING range of the hero.\n\nYou are the villain, remember?", hero.getPoint().x, hero.getPoint().y) > end;
				#else
				pause = false;
				#end
			}
			else
				pause = false;
			notify("Defend","the orbs!");
			musicVol = 0.2;
		});
	}
	
	
	
	function startIntro() {
		musicVol = 0.6;
		
		introWrap = new Sprite();
		buffer.dm.add(introWrap, DP_TITLE);
		
		phase = PIntro;
		pause = true;
		
		var mask = new Sprite();
		mask.graphics.beginFill(0x0, 1);
		mask.graphics.drawRect(0,0,buffer.width, buffer.height);
		introWrap.addChild(mask);
		
		var title = new flash.display.Bitmap( new GfxTitle(0,0) );
		introWrap.addChild(title);
		title.alpha = 0;
		var a = tw.create( title, "alpha", 1, TEase, 1000);
		
		var tf = createField("Click to start\nM to stop music");
		introWrap.addChild(tf);
		tf.x = buffer.width - tf.textWidth - 10;
		tf.y = 180;
		tf.textColor = 0x736f90;
		tf.alpha = 0;
		a.onEnd = function() {
			tw.create( tf, "alpha", 1, TEase, 1000);
		}
	}
	
	function resetGame() {
		for(e in Entity.ALL)
			e.destroy();
		for(e in killList)
			e.unregister();
		for(s in hudOrbs)
			s.parent.removeChild(s);
		hudOrbs = [];
		killList = [];
		Entity.ALL = [];
		Mob.ALL = [];
		Item.ALL = [];
		level.destroy();
		
		pause = false;
		time = 0;
		rage = 0;
		curLevel = 0;
		cd.reset();
		bar.activate(0, false);
		
		root.alpha = 1;
	}
	
	function nextLevel() {
		if( curLevel>=1 )
			final();
		else {
			var mask = new Sprite();
			buffer.dm.add(mask, DP_INTERF);
			mask.graphics.beginFill(0x0, 1);
			mask.graphics.drawRect(0,0,buffer.width,buffer.height);
			
			var l = curLevel;
			resetGame();
			curLevel = l+1;
			startGame();
			tw.create( mask, "alpha", 0, 600 ).onEnd = function() {
				mask.parent.removeChild(mask);
			}
		}
	}
	
	function gameOver() {
		notify("Fail!", 0xFF0000);
		var mask = new Sprite();
		buffer.dm.add(mask, DP_INTERF);
		mask.graphics.beginFill(0x0, 1);
		mask.graphics.drawRect(0,0,buffer.width,buffer.height);
		mask.alpha = 0;
		tw.create( mask, "alpha", 1, 3000 ).onEnd = function() {
			resetGame();
			startIntro();
			mask.parent.removeChild(mask);
		}
	}
	
	function final() {
		pause = true;
		notify("Well","done", 0xB9E817);
		var mask = new Sprite();
		buffer.dm.add(mask, DP_INTERF);
		mask.graphics.beginFill(0x0, 1);
		mask.graphics.drawRect(0,0,buffer.width,buffer.height);
		mask.alpha = 0;
		tw.create( mask, "alpha", 1, 3000 ).onEnd = function() {
			var tf = createField("Thank you for playing :)\nVisit blog.deepnight.net for more!");
			tf.alpha = 0;
			buffer.dm.add(tf, DP_INTERF);
			tw.create(tf, "alpha", 1);
			haxe.Timer.delay( function() {
				resetGame();
				startIntro();
				mask.parent.removeChild(mask);
				tf.parent.removeChild(tf);
			}, 8000);
		}
	}
	
	
	function updateHudOrbs() {
		var n = Lambda.filter(Mob.ALL, function(e) return e.name=="orb" && !e.killed).length;
		for(i in 0...hudOrbs.length) {
			if( i+1>n )
				hudOrbs[i].setFrame(1);
			else
				hudOrbs[i].setFrame(0);
		}
		return n;
	}
	
	function initLevel() {
		for(pt in level.poi) {
			var e = new mob.Orb();
			e.cx = pt.x;
			e.cy = pt.y;
		}
		
		if( curLevel>0 )
			for(i in 0...30) {
				var e = new mob.Zombie();
				var pt = level.freeSpots.splice( Std.random(level.freeSpots.length), 1 )[0];
				e.cx = pt.x;
				e.cy = pt.y;
			}
		for(d in level.doors) {
			var e = new mob.Door(d.strong);
			e.cx = d.pt.x;
			e.cy = d.pt.y;
		}
		for(pt in level.gold) {
			var e = new it.Gold();
			e.cx = pt.x;
			e.cy = pt.y;
		}
		for(i in 0...7) {
			var pt = level.freeSpots.splice( Std.random(level.freeSpots.length), 1 )[0];
			var n = Lib.irnd(3,9);
			while(n>0) {
				var pt2 = {x:pt.x+Lib.irnd(0,2,true), y:pt.y+Lib.irnd(0,2,true)};
				if( !level.getCol(pt2.x, pt2.y) ) {
					var e = new it.Gold();
					e.cx = pt2.x;
					e.cy = pt2.y;
					n--;
				}
			}
		}
	}
	
	public function pop(e:Entity, s:String, ?color=0xffffff, ?icon:DSprite) {
		var w = new Sprite();
		var tf = createField(s, true);
		w.addChild(tf);
		tf.textColor = color;
		tf.filters = [];
		if( icon!=null ) {
			w.addChild(icon);
			icon.setCenter(0,0);
			tf.x+=13;
			tf.y+=2;
		}
		var bmp = Lib.flatten(w);
		sdm.add(bmp, DP_INTERF);
		var pt = e.getPoint();
		bmp.x = pt.x;
		bmp.y = pt.y-15;
		bmp.blendMode = flash.display.BlendMode.ADD;
		tw.create(bmp, "y", bmp.y - Lib.irnd(9,16), TEaseOut, 600);
		tw.create(bmp, "x", bmp.x + Lib.irnd(0,5,true), TEaseOut, 300).onEnd = function() {
			tw.create(bmp, "alpha", 0, TEaseIn, 600).onEnd = function() {
				bmp.parent.removeChild(bmp);
				bmp.bitmapData.dispose();
			}
		}
	}
	
	
	function setPause(b) {
		pause = b;
		if( pause )
			DSprite.updateAll();
		else
			message();
	}
	
	
	public function message(?s:String, ?focusX:Float, ?focusY:Float) {
		if( lastMessage!=null ) {
			var spr = lastMessage;
			tw.terminate(lastMessage);
			tw.create(spr, "alpha", 0, TLinear, 200).onEnd = function() {
				spr.parent.removeChild(spr);
			}
			lastMessage = null;
		}
		
		if( s==null )
			return;
			
		var wrap = new Sprite();
		setPause(true);

		var bg = new Sprite();
		wrap.addChild(bg);

		var tf = createField(s);
		tf.width = 130;
		tf.height = 200;
		tf.width = tf.textWidth+ 5;
		tf.height = tf.textHeight + 7;
		wrap.addChild(tf);
		tf.x = Std.int( buffer.width*0.5 - tf.width*0.5 );
		tf.y = Std.int( buffer.height*0.5 - tf.height*0.5 +2);

		var g = bg.graphics;
		g.beginFill(0x7C2727, 1);
		g.drawRect(0, 0, tf.width+5,tf.height+1);
		bg.x = Std.int( buffer.width*0.5 - bg.width*0.5);
		bg.y = Std.int( buffer.height*0.5 - bg.height*0.5);
		bg.filters = [
			new flash.filters.GlowFilter(0xDE640A,1, 2,2,8, 1,true),
			new flash.filters.DropShadowFilter(1,90, 0xFFC411,0.9, 2,2,1, 1,true),
			new flash.filters.GlowFilter(0x531A1A,1, 2,2,8),
			new flash.filters.GlowFilter(0x0,0.5, 128,64,4, 2),
		];
		
		if( focusX!=null ) {
			var g = wrap.graphics;
			g.beginFill(0x381212, 0.7);
			g.drawRect(0,0,buffer.width,buffer.height);
			g.drawCircle(focusX, focusY, 40);
			g.endFill();
			g.lineStyle(1, 0x8A2D2D, 0.8);
			g.drawCircle(focusX, focusY, 40);
		}
		
		lastMessage = wrap;
		buffer.dm.add(lastMessage, DP_INTERF);
		lastMessage.alpha = 0;
		tw.create(lastMessage, "alpha", 1, TEase, 100);
	}
	
	
	public function notify(l1:String, ?l2:String, ?color=0xFF9900) {
		SOUNDS.warning.play();
		var wrap = new Sprite();
		var tf = createField(l1.toUpperCase(), true);
		wrap.addChild(tf);
		tf.textColor = color;
		tf.filters = [];
		if( l2!=null ) {
			var tf1 = tf;
			var tf = createField(l2.toUpperCase(), true);
			wrap.addChild(tf);
			tf.textColor = color;
			tf.y+=7;
			tf.x = Std.int(wrap.width*0.5 - tf.textWidth*0.5);
			tf.filters = [];
			tf1.x = Std.int(wrap.width*0.5 - tf1.textWidth*0.5);
		}
		
		var bmp = Lib.flatten(wrap);
		buffer.dm.add(bmp, DP_INTERF);
		bmp.width = buffer.width;
		bmp.height = buffer.height;
		bmp.blendMode = flash.display.BlendMode.ADD;
		bmp.bitmapData.applyFilter( bmp.bitmapData, bmp.bitmapData.rect, new flash.geom.Point(0,0), new flash.filters.GlowFilter(color, 0.4, 4,4, 2, 2) );
		
		bmp.alpha = 0;
		tw.create(bmp, "alpha", 1, TEaseOut, 700).onEnd = function() {
			tw.create(bmp, "alpha", 0, TEaseIn, 2000).onEnd = function() {
				bmp.parent.removeChild(bmp);
				bmp.bitmapData.dispose();
			}
		}
	}
		
	
	public function createField(str:String, ?size=8, ?adjustSize=false) {
		var f = new flash.text.TextFormat();
		f.font = "def";
		f.size = size;
		f.color = 0xffffff;
		
		var tf = new flash.text.TextField();
		tf.width = adjustSize ? 500 : 300;
		tf.height = 50;
		tf.mouseEnabled = tf.selectable = false;
		tf.defaultTextFormat = f;
		tf.embedFonts = true;
		tf.text = str;
		tf.multiline = tf.wordWrap = true;
		if( adjustSize ) {
			tf.width = tf.textWidth+5;
			tf.height = tf.textHeight+5;
		}
		
		tf.filters = [
			new flash.filters.GlowFilter(0x0,1, 2,2,5),
		];
		
		return tf;
	}
	
	function getMouseBuffer() {
		return buffer.globalToLocal(root.mouseX,root.mouseY);
	}
	
	
	function getMouseScrolling() {
		var m = getMouseBuffer();
		return {
			x : m.x - scroller.x,
			y : m.y - scroller.y,
		};
	}
	
	function getMouse() {
		return {x:root.mouseX, y:root.mouseY}
	}
	
	function onMouseLeave(_) {
		drag = null;
	}

	function canSpawnHere() {
		var m = getMouseScrolling();
		var pt = hero.getPoint();
		return
			!cd.has("delay") &&
			Mob.ALL.length<100 &&
			!level.getCol(Math.floor(m.x/GRID), Math.floor(m.y/GRID)) &&
			Lib.distance(m.x,m.y, pt.x,pt.y)>=hero.lightRadius;
	}
	
	function onKey(e:flash.events.KeyboardEvent) {
		if( e.keyCode>=flash.ui.Keyboard.NUMBER_1 && e.keyCode<=flash.ui.Keyboard.NUMBER_9 ) {
			var id = e.keyCode-flash.ui.Keyboard.NUMBER_1;
			bar.activate(id);
		}
		switch( e.keyCode ) {
			#if debug
			case flash.ui.Keyboard.N :
				nextLevel();
				#end
			case flash.ui.Keyboard.ESCAPE :
				gameOver();
			case flash.ui.Keyboard.M : musicON = !musicON;
		}
	}
	
	function onClick(_) {
		if( cancelClick )  {
			cancelClick = false;
			return;
		}
		#if debug
		fx.hit(hero);
		#end
		
		if( phase==PIntro )
			startGame();
		
		if( pause && lastMessage!=null ) {
			message();
			cm.signal();
			pause = false;
			return;
		}
		
		if( pause )
			return;
		
		if( bar.onClick() )
			return;
		
		// Spawn
		if( !canSpawnHere() )
			return;
			
		if( bar.runActive() ) {
			SOUNDS.summon.play();
			hero.taunt();
		}
		
		/*
		if( rage<10 )
			return;
			
		changeRage(-10);
			
		hero.taunt();
		var m = getMouseScrolling();
		var r = GRID*1;
		for(i in 0...5) {
			var e = new mob.Ghost();
			//var e = new mob.Zombie();
			//var e = new mob.Golem();
			var tries = 100;
			do {
				var a = Math.random()*6.28;
				e.setPoint( m.x + Math.cos(a)*Std.random(r), m.y + Math.sin(a)*Std.random(r) );
			} while( tries-->0 && (e.getCol(e.cx, e.cy)) );
			if( tries<=0 )
				e.destroy();
		}
		*/
	}
	
	function spawnAround(c:Class<Entity>, count:Int, x,y) {
		var r = GRID*1;
		for(i in 0...count) {
			var tries = 100;
			var e = Type.createInstance(c, []);
			do {
				var a = Math.random()*6.28;
				e.setPoint( x + Math.cos(a)*Std.random(r), y + Math.sin(a)*Std.random(r) );
			} while( tries-->0 && (e.getCol(e.cx, e.cy)) );
			if( tries<=0 )
				e.destroy();
		}
	}
	
	function onMouseDown(_) {
		var m = getMouse();
		drag = {vx:viewPort.x, vy:viewPort.y, mx:m.x, my:m.y}
	}
	
	function focus(e:Entity, speed:Float) {
		var pt = e.getPoint();
		viewPort.x += ((pt.x - viewPort.width*0.5) - viewPort.x)*speed;
		viewPort.y += ((pt.y - viewPort.height*0.5) - viewPort.y)*speed;
		if( speed==1 ) {
			scroller.x = -Std.int(viewPort.x);
			scroller.y = -Std.int(viewPort.y);
		}
	}
	
	function onMouseMove(_) {
		if( drag!=null ) {
			//var m = getMouse();
			//var d = Lib.distance(drag.mx, drag.my, m.x, m.y);
			//if( d>=20 ) {
				//viewPort.x = drag.vx + (drag.mx - m.x)/UPSCALE;
				//viewPort.y = drag.vy + (drag.my - m.y)/UPSCALE;
				//cancelClick = true;
			//}
		}
	}
	function onMouseUp(_) {
		drag = null;
	}
	
	function useRage(d) {
		if( rage<d )
			return false;
		else {
			changeRage(-d);
			return true;
		}
	}
	
	function changeRage(d, ?from:Entity) {
		rage+=d;
		if( from!=null && d!=0 )
			pop(from, ""+d, 0xFF9900, tiles.getSprite("rage"));
		if( rage<0 )
			rage = 0;
		if( rage>100 )
			rage = 100;
		rageCount.text = ""+rage;
	}
	
	function zsort(a:Entity, b:Entity) {
		return Reflect.compare(b.spr.y+b.zpriority, a.spr.y+a.zpriority);
	}
	
	function main(_) {
		cm.update();
		tw.update();
		#if debug musicVol = 0; #end
		musicChan.soundTransform = new flash.media.SoundTransform( musicON ? musicVol : 0 );
		
		if( phase==PIntro ) {
			
		}
		
		if( pause )
			cursor.visible = false;
		
		if( !pause && phase==PGame ) {
			cd.update();
			if( !cd.has("regen") ) {
				cd.set("regen", 30*3);
				changeRage(1);
			}
			
			for(e in Entity.ALL)
				if( e.delay<=0 )
					e.update();
				else
					e.delay--;
			
				
			for(e in killList)
				e.unregister();
			killList = [];
			
			var m = getMouseScrolling();
			var pt = hero.getPoint();
			cursor.visible = true;
			var ok = canSpawnHere();
			cursor.setFrame( ok ? 0 : 1 );
			var m = getMouseBuffer();
			cursor.x = m.x;
			cursor.y = m.y;

			
			focus(hero, 0.03);
			
			if( viewPort.x<0 ) viewPort.x = 0;
			if( viewPort.x+viewPort.width >= Level.WID*GRID) viewPort.x = Level.WID*GRID - viewPort.width;
			if( viewPort.y<0 ) viewPort.y = 0;
			if( viewPort.y+viewPort.height >= Level.HEI*GRID) viewPort.y = Level.HEI*GRID - viewPort.height;
			
			scroller.x = -Std.int(viewPort.x);
			scroller.y = -Std.int(viewPort.y);
			
			halo.x = hero.spr.x + scroller.x - halo.width*0.5;
			halo.y = hero.spr.y + scroller.y - halo.height*0.5;
			halo.scaleX = halo.scaleY = hero.lightRadius/45;
			
			torch.x = hero.spr.x;// - torch.width*0.5;
			torch.y = hero.spr.y;// - torch.height*0.5;
			torch.scaleX = torch.scaleY = Lib.rnd(0.97, 1) * hero.lightRadius/50;
			
			if( time%3==0 ) {
				// z-sort
				Entity.ALL.sort(zsort);
				for(e in Entity.ALL)
					e.spr.parent.setChildIndex(e.spr, 0);
			}

			bar.update();
			tip.update();
			DSprite.updateAll();
			time++;
		}
		fx.update();
		buffer.update();
	}
}

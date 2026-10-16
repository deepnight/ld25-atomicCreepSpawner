import mt.deepnight.SpriteLib;
import mt.deepnight.Lib;
import mt.deepnight.Cooldown;
import flash.display.Sprite;

class Entity implements haxe.Public {
	public static var ALL : Array<Entity> = [];
	public static var UNIQ = 0;
	var game			: Game;
	public var spr		: Sprite;
	public var ds		: DSprite;
	public var shadow	: DSprite;
	public var cx		: Int;
	public var cy		: Int;
	public var xr		: Float;
	public var yr		: Float;
	public var z		: Float;
	public var dx		: Float;
	public var dy		: Float;
	public var dz		: Float;
	public var frict	: Float;
	var zpriority		: Int;
	var maxSpeed		: Float;
	
	public var radius(default,setRadius)	: Float;
	public var speed	: Float;
	public var repels	: Bool;
	public var weight	: Float;
	var name			: String;
	var color			: Int;
	var uid				: Int;
	var collidesWalls	: Bool;
	var cd				: Cooldown;
	var life			: Int;
	var bleedSprite		: Null<String>;
	
	var killed			: Bool;
	var rageGain		: Int;
	
	var delay			: Int;
	
	
	public function new() {
		game = Game.ME;
		uid = UNIQ++;
		maxSpeed = 0.4;
		zpriority = 0;
		delay = 0;
		name = "entity";
		color = 0xD4D4D4;
		spr = new Sprite();
		bleedSprite = "blood";
		cx = cy = 5;
		xr = yr = 0.5;
		z = 0;
		dx =  dy = dz = 0;
		radius = Game.GRID*0.5;
		frict = 0.85;
		speed = 0.025;
		repels = true;
		weight = 1;
		rageGain = 0;
		killed = false;
		collidesWalls = true;
		cd = new Cooldown();
		life = 1;
		cd.onComplete("autokill", destroy);
		cd.onComplete("resetCT", function() {
			spr.transform.colorTransform = new flash.geom.ColorTransform();
		});
		
		shadow = game.tiles.getSprite("shadow");
		game.sdm.add(shadow, Game.DP_GROUND);
		shadow.y+=4;
		shadow.alpha = 0.5;
		shadow.setCenter(0.5,0.5);
		
		register();
	}
	
	inline function autoKill(d) {
		cd.set("autokill", d);
	}
	
	public function destroy() {
		if( killed )
			return;
		game.killList.push(this);
		killed = true;
	}
	
	public function register() {
		ALL.push(this);
		game.entities.addChild(spr);
	}
	
	public function unregister() {
		ALL.remove(this);
		spr.parent.removeChild(spr);
		shadow.parent.removeChild(shadow);
	}
	
	inline function rnd(min,max, ?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min,max, ?sign) { return Lib.irnd(min,max,sign); }
	
	public function setRadius(r) {
		radius = r;
		//spr.graphics.clear();
		//spr.graphics.beginFill(color,1);
		//spr.graphics.drawCircle(0,0, radius);
		//spr.graphics.endFill();
		return radius;
	}
	
	public inline function angTo(e:Entity) {
		var pt = getPoint();
		var ept = e.getPoint();
		return Math.atan2( ept.y-pt.y, ept.x-pt.x );
	}
	
	public inline function moveTo(e:Entity, s:Float, ?predict=true) {
		speed = s;
		if( predict ) {
			var distFactor = Math.min(1,distance(e)/130);
			var ea = Math.atan2(e.dy, e.dx);
			var pt = getPoint();
			var ept = e.getPoint();
			ept.x+= Math.cos(ea)*e.dx*10*distFactor;
			ept.y+= Math.sin(ea)*e.dy*10*distFactor;
			var a = Math.atan2( ept.y-pt.y, ept.x-pt.x );
			dx = Math.cos(a)*speed;
			dy = Math.sin(a)*speed;
		}
		else {
			var a = angTo(e);
			dx = Math.cos(a)*speed;
			dy = Math.sin(a)*speed;
		}
	}
	
	public inline function push(e:Entity, ?pow=1.0) {
		pow/=e.weight;
		var a = angTo(e);
		e.dx += Math.cos(a) * 0.2 * pow;
		e.dy += Math.sin(a) * 0.2 * pow;
	}
		
	function say(s:String) {
		if( cd.has("say") )
			return;
		cd.set("say", 64);
		var tf = game.createField( s );
		var pt = game.buffer.localToGlobal(spr.x+game.scroller.x, spr.y+game.scroller.y);
		tf.width = 80;
		tf.height = 200;
		tf.x = Std.int(pt.x - tf.textWidth*0.5*2);
		tf.y = Std.int(pt.y - 20*Game.UPSCALE);
		tf.width = tf.textWidth+5;
		tf.height = tf.textHeight+5;
		
		var bmp = mt.deepnight.Lib.flatten(tf, true);
		game.root.addChild(bmp);
		bmp.alpha = 0;
		bmp.scaleX = bmp.scaleY = 2;
		bmp.y = bmp.y-bmp.height+15;
		game.tw.create(bmp, "alpha",1, TEaseIn, 200);
		haxe.Timer.delay( function() {
			game.tw.create(bmp, "alpha",0, TEaseIn, 1000).onEnd = function() {
				bmp.parent.removeChild(bmp);
				bmp.bitmapData.dispose();
			}
		}, 1000);
	}
	
	
	inline function onScreen() {
		var pt = getPoint();
		return
			pt.x>=game.viewPort.x-20 &&
			pt.y>=game.viewPort.y-20 &&
			pt.x<game.viewPort.x+game.viewPort.width+20 &&
			pt.y<game.viewPort.y+game.viewPort.height+40;
	}
	
	public function die() {
		destroy();
		game.changeRage( rageGain, this );
		game.fx.death(this);
		bleed(true);
	}
	
	function bleed(death:Bool) {
		if( bleedSprite==null )
			return;
		if( bleedSprite=="blood" )
			game.fx.hit(this, death ? 10 : 3);
		var s = game.tiles.getSprite(bleedSprite, game.tiles.getRandomFrame(bleedSprite));
		s.setCenter(0.5,0.5);
		s.scaleX = Std.random(2)*2-1;
		s.scaleY = Std.random(2)*2-1;
		var pt = getPoint();
		s.x = pt.x - 20 + rnd(0,10,true);
		s.y = pt.y - 40 + rnd(0,10,true);
		s.alpha = rnd(0.6, 1);
		
		var b = if( bleedSprite=="blood" ) flash.display.BlendMode.OVERLAY else flash.display.BlendMode.NORMAL;
		game.level.ground.bitmapData.draw(s, s.transform.matrix, s.transform.colorTransform, b);
		//s.alpha = rnd(0.3, 5);
		//game.level.walls.bitmapData.draw(s, s.transform.matrix, s.transform.colorTransform, flash.display.BlendMode.MULTIPLY);
	}

	
	public function changeLife(d:Int) {
		life+=d;
	}
	
	public function damage(d:Int) {
		changeLife(-d);
		bleed(false);
		//game.pop(this, Std.string(d));
		if( life<=0 )
			die();
		else {
			spr.transform.colorTransform = mt.deepnight.Color.getColorizeCT(0xFF1A00,0.7);
			cd.set("resetCT", 3);
			cd.set("shield", 7);
		}
	}
	
	public inline function inLight() {
		return distance(game.hero)<=game.hero.lightRadius;
	}
	
	public inline function isClose(e:Entity) {
		return Lib.abs(cx-e.cx)<=1 && Lib.abs(cy-e.cy)<=1;
	}
	
	public inline function distance(e:Entity) {
		var pt = getPoint();
		var ept	= e.getPoint();
		return Lib.distance(pt.x, pt.y, ept.x, ept.y);
	}
	
	public inline function roughCaseDistance(e:Entity) {
		return Lib.distanceSqr(cx,cy, e.cx,e.cy);
	}
	
	public function onHitWall() {
	}
	
	function copyPos(e:Entity) {
		var pt = e.getPoint();
		setPoint( pt.x, pt.y );
	}
	
	inline function getCol(x,y) {
		return game.level.getCol(x,y);
	}
	
	function updateSprite() {
		spr.x = Std.int( cx*Game.GRID + xr*Game.GRID );
		spr.y = Std.int( cy*Game.GRID + yr*Game.GRID - z );
		shadow.x = spr.x;
		shadow.y = spr.y+4;
		if( dx>0.01 )
			spr.scaleX = 1;
		if( dx<-0.01 )
			spr.scaleX = -1;
	}
	
	function getPoint() {
		return {x:(cx+xr)*Game.GRID, y:(cy+yr)*Game.GRID}
	}
	
	function toString() {
		return name+"#"+uid;
	}
	
	function setPoint(x:Float,y:Float) {
		cx = Math.floor(x/Game.GRID);
		xr = (x - cx*Game.GRID)/Game.GRID;
		
		cy = Math.floor(y/Game.GRID);
		yr = (y - cy*Game.GRID)/Game.GRID;
	}
	
	public function onHeroContact() {
	}
	
	function jump(d) {
		dz = d;
		z--;
	}
	
	public function update() {
		if( killed )
			return;
			
		cd.update();
		
		if( repels )
			for( e in ALL ) {
				if( e!=this && !e.killed && e.repels && isClose(e) ) {
					var pt = getPoint();
					var ept = e.getPoint();
					var d = Lib.distance(pt.x, pt.y, ept.x, ept.y);
					var min = radius+e.radius;
					if( d < min ) {
						var conflict = min - d;
						var center = {x:pt.x + (ept.x-pt.x)*0.5, y:pt.y + (ept.y-pt.y)*0.5}
						var a = Math.atan2(ept.y-pt.y, ept.x-pt.x);
						var w = weight / (weight+e.weight);
						var ew = e.weight / (weight+e.weight);
						dx -= Math.cos(a)*(conflict/Game.GRID)*ew;
						dy -= Math.sin(a)*(conflict/Game.GRID)*ew;
						e.dx += Math.cos(a)*(conflict/Game.GRID)*w;
						e.dy += Math.sin(a)*(conflict/Game.GRID)*w;
						if( e==game.hero )
							onHeroContact();
					}
				}
			}
			
		var wpen = 0.4 * (1-radius / Game.GRID);
		var max = maxSpeed;

		
		// Gestion X
		if( dx>max ) dx = max;
		if( dx<-max ) dx = -max;
		xr+=dx;
		if( collidesWalls ) {
			if( dx>=0 && xr>=0.5+wpen && getCol(cx+1,cy) ) {
				dx = 0;
				xr = 0.5+wpen;
				onHitWall();
			}
			if( dx<=0 && xr<=0.5-wpen && getCol(cx-1,cy) ) {
				dx = 0;
				xr = 0.5-wpen;
				onHitWall();
			}
		}
		while( xr<0 ) {
			xr++;
			cx--;
		}
		while( xr>1 ) {
			xr--;
			cx++;
		}
		dx = Std.int(dx*frict*10000)/10000;
		
		
		// Gestion Y
		if( dy>max ) dy = max;
		if( dy<-max ) dy = -max;
		yr+=dy;
		if( collidesWalls ) {
			if( dy>=0 && yr>=0.5+wpen && getCol(cx,cy+1) ) {
				dy = 0;
				yr = 0.5+wpen;
				onHitWall();
			}
			if( dy<=0 && yr<=0.5-wpen && getCol(cx,cy-1) ) {
				dy = 0;
				yr = 0.5-wpen;
				onHitWall();
			}
		}
		while( yr<0 ) {
			yr++;
			cy--;
		}
		while( yr>1 ) {
			yr--;
			cy++;
		}
		dy = Std.int(dy*frict*10000)/10000;
		
		if( z>0 ) {
			dz -=0.1;
			z-=dz;
			if( z<=0 )
				z = dz = 0;
		}
				
		updateSprite();
		
		//if( cd.has("shield") && game.time%3==0 )
			//spr.transform.colorTransform = mt.deepnight.Color.getColorizeCT(0xffffff,0.7);
		//else
			//spr.transform.colorTransform = new flash.geom.ColorTransform();
	}
}

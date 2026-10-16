import mt.deepnight.Particle;
import mt.deepnight.Lib;
import flash.display.BlendMode;
import flash.display.Sprite;

class Fx {
	var game		: Game;
	public function new() {
		game = Game.ME;
	}
	
	inline function register(p:Particle, ?b:BlendMode) {
		game.sdm.add(p, Game.DP_FX);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}

	inline function rnd(min:Float, max:Float, ?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min, max,?sign) { return Lib.irnd(min,max,sign); }
	inline function rad(a) { return Lib.rad(a); }
	inline function deg(a) { return Lib.deg(a); }
	
	public function hit(e:Entity, ?n=3) {
		var pt = e.getPoint();
		var colors = [ 0xFF1515, 0xFF1515, 0xFF1515, 0xFF1515, 0xFF1515, 0xC8D095, 0xAD9A67 ];
		for(i in 0...n) {
			var c = colors[Std.random(colors.length)];
			var p = new Particle(pt.x + rnd(0,5,true), pt.y + rnd(0,5,true));
			p.drawBox(3,rnd(1,4), c );
			p.dx = rnd(0,2,true);
			p.dr = rnd(0,8,true);
			p.rotation = rnd(0,360);
			p.alpha = rnd(0.6, 1);
			p.dy = -rnd(4,6);
			if( Std.random(5)==0 )
				p.dy = -rnd(8,12);
			p.groundY = pt.y + rnd(0,10, true);
			p.life = rnd(16,45);
			p.bounce = 0;
			p.onBounce = function() {
				p.dy = 0;
				p.gy = 0;
				p.dr = 0;
				p.rotation = 90 + rnd(0,20,true);
				p.frictX = 0.8;
			}
			p.filters = [
				new flash.filters.GlowFilter(c,0.6, 4,4,1),
				new flash.filters.DropShadowFilter(1,-90, 0x0,0.8, 0,0,1, 1,true),
			];
			register(p, BlendMode.NORMAL);
		}
	}
	
	public function death(e:Entity) {
		var pt = e.getPoint();
		var p = new Particle(pt.x, pt.y);
		p.reset();
		p.drawCircle(10, 0xFFB833);
		p.scaleX = p.scaleY = 0;
		p.ds = 0.2;
		p.life = 0;
		p.flatten();
		//p.onUpdate = function() {
			//
		//}
		register(p);
	}
	
	public function update() {
		Particle.update();
	}
}
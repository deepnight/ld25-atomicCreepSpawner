package mob;

class Golem extends Mob {
	public function new() {
		super();
		radius = 11;
		speed = 0.005;
		power = 8;
		life = 35;
		weight = 30;
		rageGain = 10;
		
		spr.graphics.clear();
		ds = game.tiles.getSprite("golem");
		ds.playAnim("golemWalk");
		spr.addChild(ds);
		ds.y+=6;
		
		maxSpeed = 0.12;
	}

	override function damage(d) {
		super.damage(d);
		var chan = switch( Std.random(2) ) {
			case 0 : Game.SOUNDS.golem1.play();
			case 1 : Game.SOUNDS.golem2.play();
		}
		chan.soundTransform = new flash.media.SoundTransform(0.5);
	}

	override function die() {
		super.die();
		Game.SOUNDS.explode2.play();
	}
	
	override function update() {
		super.update();
		if( !cd.has("shoot") ) {
			cd.set("shoot", 30+Std.random(20));
			var s = new Shoot();
			s.ds = game.tiles.getSprite("golemSpit");
			s.ds.playAnim("golemSpit");
			s.ds.y+=8;
			s.spr.addChild(s.ds);
			s.copyPos(this);
			s.power = 1;
			s.pushes = false;
			s.collidesWalls = false;
			s.autoKill(60);
			s.hitsMobs = false;
			s.moveTo(hero, 0.25);
		}
	}
}
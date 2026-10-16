package hero;

class Mage extends Hero {
	public function new() {
		super();
		
		lightRadius = Game.GRID*5;
		changeLife(0);
		speed = 0.020;
		frict = 0.82;
		life = 400;
		
		reach = Game.GRID*4;
		
		spr.graphics.clear();
		ds = game.tiles.getSprite("mage", 0);
		ds.setCenter(0.5, 1);
		ds.y+=4;
		ds.playAnim("wait");
		ds.defaultAnim = "wait";
		spr.addChild( ds );
		
		rangeAttack = function(m) {
			cd.set("attack", 6+Std.random(2));
			
			var chan = switch( Std.random(1) ) {
				case 0 : Game.SOUNDS.shoot1.play();
				case 1 : Game.SOUNDS.shoot2.play();
			}
			chan.soundTransform = new flash.media.SoundTransform(0.2);
			var s = new Shoot();
			s.ds = game.tiles.getSprite("fireball");
			s.ds.playAnim("fireball");
			s.ds.y+=8;
			s.spr.addChild(s.ds);
			s.copyPos(this);
			s.power = 2;
			s.radius = 5;
			s.pushes = false;
			s.collidesWalls = false;
			s.autoKill(10);
			s.hitsMobs = true;
			s.spr.blendMode = flash.display.BlendMode.ADD;
			s.spr.filters = [
				new flash.filters.GlowFilter(0xFF8000,0.8, 8,8,2),
			];
			s.moveTo(m, 0.8, true);
		}
	}
}

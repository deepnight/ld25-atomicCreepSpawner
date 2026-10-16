package mob;

class Ghost extends Mob {
	public function new() {
		super();
		radius = 5;
		speed = 0.020;
		frict = 0.9;
		life = 5;
		repels = false;
		
		power = 1;
		
		spr.graphics.clear();
		ds = game.tiles.getSprite("ghost", game.tiles.getRandomFrame("ghost"));
		spr.addChild(ds);
		ds.y+=5;
		spr.blendMode = flash.display.BlendMode.ADD;
		spr.filters = [ new flash.filters.GlowFilter(0xFF7C1C,0.7, 8,8,1) ];
	}
	
	override function die() {
		super.die();
		Game.SOUNDS.shout1.play();
	}
	
	override function onHeroContact() {
		super.onHeroContact();
	}
	
	override function updateSprite() {
		super.updateSprite();
		spr.y += Math.sin( uid + game.time*0.05*3.14 ) * 2;
	}
	override function update() {
		super.update();
		if( roughCaseDistance(hero)<=2*2 )
			if( distance(hero)<=radius+hero.radius+3 ) {
				if( !hero.cd.has("ghostHit") ) {
					hero.damage(power);
					hero.cd.set("ghostHit", 18);
				}
				var d = 10;
				if( hero.cd.get("slow")<=30*(d-1) ) {
					game.pop(hero, "Slow!", 0x91B71E);
					Game.SOUNDS.slow.play();
					hero.cd.set("slow", 30*d);
				}
			}
	}
}
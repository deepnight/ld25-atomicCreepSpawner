package mob;

class Door extends Mob {
	public function new(strong:Bool) {
		super();
		radius = 8;
		speed = 0.0;
		frict = 0;
		life = strong ? 35 : 10;
		weight = 9999999;
		bleedSprite = "wood";
		
		power = 0;
		rageGain = 5;
		
		spr.graphics.clear();
		ds = game.tiles.getSprite("door", strong ? 1:0);
		spr.addChild(ds);
		ds.y+=9;
		shadow.visible = false;
	}
	
	override function die() {
		super.die();
		Game.SOUNDS.explode5.play();
	}
}
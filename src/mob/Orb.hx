package mob;

class Orb extends Mob {
	public function new() {
		super();
		name = "orb";
		radius = 9;
		speed = 0;
		life = 10;
		weight = 15;
		power = 0;
		rageGain = 10;
		bleedSprite = null;
		
		spr.graphics.clear();
		ds = game.tiles.getSprite("orb");
		spr.addChild(ds);
		ds.y+=5;
		shadow.visible = false;
	}
	
	override function die() {
		super.die();
		game.tw.create(game.root, "y", -20, TShake, 1000);
		
		Game.SOUNDS.explode1.play();
		var n = game.updateHudOrbs();
		if( n>0 )
			game.notify("Evil orb","obliterated!", 0xFF0000);
		else
			game.notify("Dungeon","cleared!", 0xFF0000);
	}
	
	override function updateSprite() {
		super.updateSprite();
		spr.scaleX = 1;
	}
}
package mob;

class Zombie extends Mob {
	public function new() {
		super();
		radius = 5;
		speed = 0.016;
		life = 2;
		wanderer = true;
		perception = 5;
		
		power = 1; // special
		rageGain = 0;
		
		spr.graphics.clear();
		ds = game.tiles.getSprite("zombie");
		ds.playAnim("zombieWalk");
		spr.addChild(ds);
		ds.y+=5;
		
		cd.set("brain", rnd(200,600));
	}
	
	override function damage(d) {
		super.damage(d);
		var chan = switch( Std.random(2) ) {
			case 0 : Game.SOUNDS.ouch1.play();
			case 1 : Game.SOUNDS.ouch2.play();
		}
		chan.soundTransform = new flash.media.SoundTransform(0.5);
	}

	override function onHeroContact() {
		//power = Std.random(4)==0 ? 1 : 0;
		super.onHeroContact();
	}
	
	//override function onHeroContact() {
		//super.onHeroContact();
		//hero.cd.set("slow", 30*5);
	//}
	
	override function update() {
		super.update();
		if( !cd.has("brain") ) {
			cd.set("brain", rnd(200,500));
			if( onScreen() )
				say( game.tg.zombie() );
		}
			
		if( roughCaseDistance(hero)<=perception*perception )
			ds.playAnim("zombieRun");
		else
			ds.playAnim("zombieWalk");
	}
}
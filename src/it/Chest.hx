package it;

class Chest extends Item {
	public function new() {
		super( Game.ME.tiles.getSprite("chest") );
		important = true;
		rageGain = 1;
	}
	
	public override function pickUp() {
		super.pickUp();
		
		game.changeRage(10, this);
		
		game.hero.cd.unset("say");
		game.hero.say( game.tg.pick() );
		
		game.hero.stop(70);
		game.hero.cd.set("slow", 100);
	}
}
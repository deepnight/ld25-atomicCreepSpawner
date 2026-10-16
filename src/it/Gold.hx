package it;

class Gold extends Item {
	public function new() {
		super( Game.ME.tiles.getSprite("gold", Game.ME.tiles.getRandomFrame("gold")) );
		shadow.visible = false;
		spr.blendMode = flash.display.BlendMode.ADD;
		spr.filters = [
			new flash.filters.GlowFilter(0xFF9F0F, 0.7, 8,8, 2),
		];
		zpriority = -10000;
	}
	
	public override function pickUp() {
		super.pickUp();
		game.changeRage(2, this);
		Game.SOUNDS.pick2.play().soundTransform = new flash.media.SoundTransform(0.3);
	}
}
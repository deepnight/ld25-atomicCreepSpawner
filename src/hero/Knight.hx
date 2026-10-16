package hero;

class Knight extends Hero {
	public function new() {
		super();
		
		lightRadius = Game.GRID*3;
		changeLife(0);
		
		spr.graphics.clear();
		ds = game.tiles.getSprite("knight", 0);
		ds.setCenter(0.5, 1);
		ds.y+=4;
		ds.playAnim("wait");
		ds.defaultAnim = "wait";
		spr.addChild( ds );
		
		closeAttack = function(m) {
			var pt = getPoint();
			var a = angTo(m);
			cd.set("attack", 4+Std.random(5));
			switch( Std.random(3) ) {
				case 0 : Game.SOUNDS.hit2.play();
				case 1 : Game.SOUNDS.hit3.play();
				case 2 : Game.SOUNDS.hit4.play();
			}
			slash(a);
			var e = new Shoot();
			e.power = 1;
			e.setPoint( pt.x + Math.cos(a)*reach*0.5, pt.y + Math.sin(a)*reach*0.5 );
			e.speed = 0.;
			e.radius = Game.GRID*0.5;
			e.cd.set("autokill",5);
		}
	}
}

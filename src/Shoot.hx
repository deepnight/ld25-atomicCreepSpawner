class Shoot extends Entity {
	var hitsMobs			: Bool;
	var multiHits			: Bool;
	var power				: Int;
	var pushes				: Bool;
	
	public function new() {
		super();
		name="shoot";
		hitsMobs = true;
		radius = Game.GRID*0.15;
		repels = false;
		collidesWalls = true;
		multiHits = true;
		power = 1;
		pushes = true;
		
		frict = 1;
		autoKill(45);
	}
	
	public override function register() {
		super.register();
		//game.sdm.add(spr, Game.DP_SHOOT);
	}

	override function onHitWall() {
		destroy();
	}
	
	public override function update() {
		super.update();
		var pt = getPoint();
		var targets : Array<Entity> = hitsMobs ? cast Mob.ALL : cast [game.hero];
		var hit = false;
		for(e in targets) {
			if( !isClose(e) || e.killed )
				continue;
			var pt = getPoint();
			if( distance(e) <= radius+e.radius ) {
				e.damage(power);
				if( pushes )
					push(e, 0.4);
				if( multiHits )
					hit = true;
				else {
					destroy();
					break;
				}
			}
		}
		if( hit )
			destroy();
	}
}

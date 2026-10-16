import Level;

class Mob extends Entity {
	static var ALL : Array<Mob> = [];
	
	var hero		: Hero;
	var pathToHero	: Array<Point>;
	var wanderer	: Bool;
	var target		: Point;
	var power		: Int;
	var perception	: Int;
	
	public function new() {
		super();
		color = 0xC63939;
		name = "mob";
		power = 1;
		perception = 8;
		hero = game.hero;
		radius = Game.GRID*0.25;
		speed = 0.020;
		frict = 0.8;
		wanderer = false;
		life = 3;
		rageGain = 1;
		pathToHero = [];
		cd.set("track", Std.random(50));
	}
	
	public override function register() {
		super.register();
		ALL.push(this);
		//game.sdm.add(spr, Game.DP_MOB);
	}
	
	public override function unregister() {
		super.unregister();
		ALL.remove(this);
	}
	
	public override function onHeroContact() {
		super.onHeroContact();
		if( killed || cd.has("hitHero") || power<=0 )
			return;
		cd.set("hitHero", 30);
		hero.damage(power);
	}
	
	function trackPlayer() {
		if( cd.has("track") )
			return;
		cd.set("track", 120+Std.random(50));
		pathToHero = game.level.pf.astar({x:cx, y:cy}, {x:hero.cx, y:hero.cy}).copy();
	}
	
	public override function update() {
		var s = speed * (cd.has("slow") ? 0.5 : 1);
		if( !cd.has("track") )
			trackPlayer();
		if( pathToHero.length>0 ) {
			var next = pathToHero[0];
			if( next.x>cx )
				dx += s;
			if( next.x<cx )
				dx -= s;
			if( next.y>cy )
				dy += s;
			if( next.y<cy )
				dy -= s;
			if( next.x==cx && next.y==cy )
				next = pathToHero.shift();
		}
		else {
			if( wanderer && roughCaseDistance(hero)>perception*perception ) {
				if( !cd.has("wanderTarget") ) {
					var tries = 30;
					do {
						target = {x:cx+irnd(0,2,true), y:cy+irnd(0,2,true)}
					} while( tries-->0 && getCol(target.x, target.y) );
					cd.set("wanderTarget", rnd(10,30));
					cd.set("track", 60);
					cd.set("slow", cd.get("wanderTarget"));
				}
			}
			else
				target = {x:hero.cx, y:hero.cy};
					
			if( target.x>cx )
				dx+=s;
			if( target.x<cx )
				dx-=s;
			if( target.y>cy )
				dy+=s;
			if( target.y<cy )
				dy-=s;
		}

		/*
		if( !wander )
			target = {x:hero.cx, y:hero.cy};
			
		if( target.x>cx )
			dx+=speed;
		if( target.x<cx )
			dx-=speed;
		if( target.y>cy )
			dy+=speed;
		if( target.y<cy )
			dy-=speed;
			*/
		
		super.update();
	}
}
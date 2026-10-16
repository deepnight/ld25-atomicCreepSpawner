import Game;
import Level;


class Hero extends Entity {
	var path			: Array<Point>;
	
	var reach			: Float;
	var lightRadius		: Float;
	var closeAttack		: Null< Mob->Void >;
	var rangeAttack		: Null< Mob->Void >;
	var objectives		: Array<Entity>;
	var secondary		: Array<Entity>;
	var weapon			: Int;
	
	public function new() {
		super();
		color = 0x00FF00;
		weapon = 0;
		name = "hero";
		path = [];
		objectives = [];
		secondary = [];
		speed = 0.012;
		frict = 0.85;
		lightRadius = Game.GRID*4;
		radius = Game.GRID*0.5;
		weight = 10;
		life = #if debug 1 #else 500 #end;
		reach = Game.GRID*1.5;
		cd.onComplete("stop", function() {
			ds.defaultAnim = "walk";
			if( ds.isPlaying("wait") )
				ds.playAnim("walk");
		});
		
		#if debug
		spr.graphics.lineStyle(1, 0xFFFF00, 0.4);
		spr.graphics.drawCircle(0,0,lightRadius);
		#end
		changeLife(0);
	}
	
	public function updateObjectives() {
		objectives = [];
		secondary = [];
	
		for(e in Mob.ALL)
			if( e.name=="orb" )
				objectives.push(e);
				
		for(e in Item.ALL)
			if( e.important )
				objectives.push(e);
			else
				secondary.push(e);
				
		newTarget();
	}
	
	public function sortObjectives() {
		var d = new IntHash();
		objectives.sort( function(a,b) {
			if( !d.exists(a.uid) )
				d.set(a.uid, distance(a));
			if( !d.exists(b.uid) )
				d.set(b.uid, distance(b));
			return Reflect.compare(d.get(a.uid), d.get(b.uid));
		});
		
		var d = new IntHash();
		secondary.sort( function(a,b) {
			if( !d.exists(a.uid) )
				d.set(a.uid, distance(a));
			if( !d.exists(b.uid) )
				d.set(b.uid, distance(b));
			return Reflect.compare(d.get(a.uid), d.get(b.uid));
		});
	}
	
	public override function register() {
		super.register();
	}
	
	override function changeLife(d) {
		super.changeLife(d);
		game.heroLifeCount.text = ""+life;
	}
	
	override function damage(d) {
		super.damage(d);
		stop( 9+Std.random(8) );
		ds.playAnim("hit", 1);
		game.pop(this, Std.string(-d), 0xFF3333);
	}

	function taunt() {
		say( game.tg.taunt() );
	}
	
	function talk() {
		cd.set("talk", 120+Std.random(200));
		say( game.tg.misc() );
	}
	
	override function die() {
		super.die();
		game.notify("Hero","died", 0x6148D7);
		Game.SOUNDS.hero3.play();
		haxe.Timer.delay( function() {
			game.nextLevel();
		}, 2500 );
	}
	
	function slash(a) {
		var s = game.tiles.getSprite("slash");
		s.x = spr.x;
		s.y = spr.y-8;
		s.setCenter(0.5, 0.5);
		s.rotation = mt.deepnight.Lib.deg(a);
		s.scaleX = s.scaleY = mt.deepnight.Lib.rnd(0.3,0.6);
		s.blendMode = flash.display.BlendMode.ADD;
		game.entities.addChild(s);
		//game.sdm.add(s, Game.DP_HERO);
		s.filters = [new flash.filters.GlowFilter(0xFF8000,0.7, 8,8,2)];
		var x = Math.cos(a)*2 + dx;
		var y = Math.sin(a)*2 + dy;
		game.tw.create(s, "x", s.x+x, TLinear, 100);
		game.tw.create(s, "y", s.y+y, TLinear, 100);
		game.tw.create(s, "alpha", 0, TLinear, 300).onEnd = function() {
			s.parent.removeChild(s);
		}
	}
	
	function randomCloseMobs(caseDistance:Float) {
		if( closeAttack!=null ) {
			var rlist = new mt.deepnight.RandList();
			var max = caseDistance*caseDistance;
			for(e in Mob.ALL) {
				var d = roughCaseDistance(e);
				if( d<=max && distance(e)<=reach ) {
					rlist.add(e, 1 + e.power*e.power + (e.life<=2 ? 500 : 0));
				}
			}
			return rlist.draw();
		}
		else {
			var bd = 999999.;
			var best = null;
			var max = caseDistance*caseDistance;
			for(e in Mob.ALL) {
				var d = roughCaseDistance(e);
				
				if( d<=max ) {
					var rd = distance(e);
					if( rd<=reach && rd<=bd ) {
						best = e;
						bd = rd;
					}
				}
			}
			return best;
			
		}
	}
	
	function newTarget() {
		cd.set("forceNewTarget", 30*5);
		ds.defaultAnim = "walk";
		ds.playAnim("walk");
		sortObjectives();
		
		var t = game.level.exit;
		if( objectives.length>0 ) {
			if( secondary.length==0 )
				t = {x:objectives[0].cx, y:objectives[0].cy};
			else {
				var dmain = distance( objectives[0] );
				var dsec = distance( secondary[0] );
				//trace(dmain+" / "+dsec +" / "+Math.pow(dsec, 1.1));
				if( dmain < Math.pow(dsec, 1.1) )
					t = {x:objectives[0].cx, y:objectives[0].cy};
				else
					t = {x:secondary[0].cx, y:secondary[0].cy};
			}
		}
		path = game.level.pf.astar({x:cx, y:cy},{x:t.x, y:t.y}).copy();
	}
	
	inline function stop(d) {
		cd.set("stop", d);
		dx = dy = 0;
		ds.defaultAnim = "wait";
		if( ds.isPlaying("walk") )
			ds.playAnim("wait");
	}
	
	override public function update() {
		if( !cd.has("talk") )
			talk();
			
		if( objectives.length>0 && objectives[0].killed ) {
			if( objectives[0].name=="orb" ) {
				cd.unset("say");
				say( game.tg.objective() );
			}
			objectives.shift();
			newTarget();
		}
		
		if( secondary.length>0 && secondary[0].killed ) {
			secondary.shift();
			newTarget();
		}
		
		if( objectives.length==0 && cx==game.level.exit.x && cy==game.level.exit.y ) {
			game.gameOver();
			destroy();
			return;
		}
			
		if( Mob.ALL.length>0 ) {
			var m = randomCloseMobs(reach);
			if( m!=null ) {
				var d = distance(m);
				
				if( closeAttack!=null && d<=reach && !cd.has("attack") ) {
					// CaC
					cd.set("talk", 30+Std.random(60));
					stop( cd.get("attack")-1 );
					ds.playAnim("attack", 1);
					closeAttack(m);
				}
				if( rangeAttack!=null && d<=reach && !cd.has("attack") ) {
					// Shoot
					cd.set("talk", 30+Std.random(60));
					stop( cd.get("attack")-1 );
					ds.playAnim("attack", 1);
					rangeAttack(m);
				}
				/*
				if( d>reach && !cd.has("shoot") ) {
					// Tir
					cd.set("shoot", 8);
					ds.playAnim("attack", 1);
					var e = new Shoot();
					e.speed = 0.4;
					e.copyPos(this);
					e.multiHits = false;
					e.power = 10;
					
					var a = e.angTo(m);
					e.dx = Math.cos(a)*e.speed;
					e.dy = Math.sin(a)*e.speed;
				}*/
			}
		}
		
		if( path.length>0 && !cd.has("stop") ) {
			var s = speed * (cd.has("slow") ? 0.25 : 1);
			var next = path[0];
			if( next.x>cx )
				dx += s;
			if( next.x<cx )
				dx -= s;
			if( next.y>cy )
				dy += s;
			if( next.y<cy )
				dy -= s;
			if( next.x==cx && next.y==cy )
				path.shift();
		}
		
		if( path.length==0 || !cd.has("forceNewTarget") )
			newTarget();
			
		super.update();
		
		if( z==0 )
			jump(10);
	}
}
import Game;
import flash.display.Sprite;
import flash.display.BitmapData;
import flash.display.Bitmap;
import mt.deepnight.PathFinder;
import mt.deepnight.SpriteLib;

typedef Point = {
	var x : Int;
	var y : Int;
}

class Level implements haxe.Public {
	public static var WID = 32;
	public static var HEI = 32;
	var cols		: Array<Array<Bool>>;
	var game		: Game;
	var entrance		: Point;
	var exit		: Point;
	var doors		: Array<{strong:Bool, pt:Point}>;
	var gold		: Array<Point>;
	var poi			: Array<Point>;
	var pf			: PathFinder;
	var path		: Array<Point>;
	var freeSpots	: Array<Point>;
	var lperlin		: BitmapData;
	
	var ground		: Bitmap;
	var walls		: Bitmap;
	var level		: Int;
	
	public function new(l) {
		level = l;
		game = Game.ME;
		cols = new Array();
		poi = [];
		freeSpots = [];
		doors = [];
		gold = [];
		
		pf = new PathFinder(WID,HEI);
		//pf.turnCost = 1;

		lperlin = new BitmapData(WID,HEI,false, 0x0);
		lperlin.perlinNoise(4,6,1, Std.random(9999), false, false, true);
		
		for(cx in 0...WID)
			cols[cx] = new Array();
		
		var bd = new GfxLevels(0,0);
		for(x in 0...WID)
			for(y in 0...HEI) {
				var p = bd.getPixel(x+level*WID, y);
				if( p==0xffffff ) {
					cols[x][y] = true;
					pf.setCollision(x,y);
				}
				if( p==0x940031 )
					poi.push( {x:x, y:y} );
				if( p==0x8f8f8f )
					doors.push( {strong:true, pt:{x:x, y:y}} );
				if( p==0x9b4a3a )
					doors.push( {strong:false, pt:{x:x, y:y}} );
				if( p==0xFFFF00 )
					gold.push( {x:x, y:y} );
				if( p==0x009cff )
					entrance = {x:x, y:y}
				if( p==0x00ff0c )
					exit = {x:x, y:y}
				if( p==0x0 )
					freeSpots.push({x:x, y:y});
			}
			
		attach();
		path = pf.astar(entrance, exit);
	}
	
	public function destroy() {
		walls.parent.removeChild(walls);
		walls.bitmapData.dispose();
		
		ground.bitmapData.dispose();
		ground.parent.removeChild(ground);
		
		lperlin.dispose();
	}
	
	public inline function getCol(cx,cy) {
		if( cx<0 || cx>=WID || cy<0 || cy>=HEI )
			return true;
		else
			return cols[cx][cy]==true;
	}
	
	public function attach() {
		var w = new Sprite();
		var g = new Sprite();

		function addSprite(cont:Sprite, s:DSprite,cx,cy) {
			cont.addChild(s);
			s.setCenter(0,0);
			s.x = cx*Game.GRID;
			s.y = cy*Game.GRID;
		}
		
		var perlin = new BitmapData(WID,HEI,false, 0x0);
		perlin.perlinNoise(4,6,1, Std.random(9999), false, false, true);
		//var bmp = new Bitmap(perlin);
		//bmp.scaleX = bmp.scaleY = 20;
		//game.root.addChild( bmp );
		
		for( cx in 0...WID )
			for( cy in 0...HEI ) {
				if( !getCol(cx,cy) ) {
					if( perlin.getPixel(cx,cy)>=0x484848 )
						addSprite( g,  game.tiles.getSprite("ground2", game.tiles.getRandomFrame("ground2")), cx, cy );
					else
						addSprite( g,  game.tiles.getSprite("ground", game.tiles.getRandomFrame("ground")), cx, cy );
					if( Std.random(100)<3 )
						addSprite( g,  game.tiles.getSprite("groundProps", game.tiles.getRandomFrame("groundProps")), cx, cy );
				}
				else
					addSprite( w, game.tiles.getSprite("wall", game.tiles.getRandomFrame("wall")), cx, cy );
			}
			
		addSprite( g, game.tiles.getSprite("exit"), exit.x, exit.y );
		addSprite( w, game.tiles.getSprite("entrance"), entrance.x, entrance.y-1 );
		
		var pt0 = new flash.geom.Point(0,0);
		
		walls = mt.deepnight.Lib.flatten(w);
		game.sdm.add(walls, Game.DP_WALLS);
		
		var bd = walls.bitmapData;
		bd.applyFilter( bd, bd.rect, pt0, new flash.filters.DropShadowFilter(1, 0, 0x0, 0.3, 0,0,1) );
		bd.applyFilter( bd, bd.rect, pt0, new flash.filters.DropShadowFilter(1, 180, 0x0, 0.3, 0,0,1) );
		bd.applyFilter( bd, bd.rect, pt0, new flash.filters.DropShadowFilter(1, -90, 0x0, 0.3, 0,0,1) );
		bd.applyFilter( bd, bd.rect, pt0, new flash.filters.GlowFilter(0xffffff,0.05, 2,2, 8, 1,true) );
		bd.applyFilter( bd, bd.rect, pt0, new flash.filters.GlowFilter(0x000000,0.4, 12,12, 3, 1,true) );
		bd.applyFilter( bd, bd.rect, pt0, new flash.filters.DropShadowFilter(4, -90, 0x0,0.5, 0,0,1,1, true) );
		bd.applyFilter( bd, bd.rect, pt0, new flash.filters.DropShadowFilter(4, 75, 0x0,0.6, 4,4,1) );
		
		ground = mt.deepnight.Lib.flatten(g);
		game.sdm.add(ground, Game.DP_GROUND);
		var bd = ground.bitmapData;
		bd.applyFilter( bd, bd.rect, pt0, new flash.filters.DropShadowFilter(10,90, 0xA9566C,0.1, 0,8, 1, 2,true) );
		
		perlin.dispose();
		//bd.applyFilter( bd, bd.rect, pt0, new flash.filters.GlowFilter(0xFF3900,0.05, 16,16, 3, 2,true) );
	}
	
	public function checkPerlin(x,y) {
		return lperlin.getPixel( x%WID, y%HEI ) >= 0x484848;
	}
	
}




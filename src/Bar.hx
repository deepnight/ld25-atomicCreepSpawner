import flash.display.Sprite;
import mt.deepnight.SpriteLib;

class Bar {
	var game		: Game;
	var wrapper		: Sprite;
	var actions		: Array<{spr:Sprite, cost:Int, cb:Void->Bool, desc:String}>;
	var current		: Int;
	
	public function new() {
		game = Game.ME;
		current = 0;
		actions = [];
		wrapper = new Sprite();
		game.buffer.dm.add(wrapper, Game.DP_INTERF);
		
		wrapper.x = 100;
		wrapper.y = game.buffer.height-17;
		
		addAction(game.tiles.getSprite("barIcons",0), "Cheap but low damages.", 1, function() {
			var m = game.getMouseScrolling();
			game.spawnAround(mob.Zombie, 5, m.x, m.y);
			return true;
		});
		addAction(game.tiles.getSprite("barIcons",1), "FAST but weak.\nSlows down the Hero.", 2, function() {
			var m = game.getMouseScrolling();
			game.spawnAround(mob.Ghost, 1, m.x, m.y);
			return true;
		});
		addAction(game.tiles.getSprite("barIcons",2), "STRONG but slow.", 30, function() {
			var m = game.getMouseScrolling();
			game.spawnAround(mob.Golem, 1, m.x, m.y);
			return true;
		});
		addAction(game.tiles.getSprite("barIcons",3), "Heroes will run to any chest they see.", 10, function() {
			var m = game.getMouseScrolling();
			game.spawnAround(it.Chest, 1, m.x, m.y);
			game.hero.updateObjectives();
			return true;
		});
		
		refresh();
	}
	
	function addAction(icon:DSprite, desc:String, cost:Int, cb:Void->Bool) {
		var s = Game.ME.tiles.getSprite("barButton");
		s.setCenter(0,0);
		wrapper.addChild(s);
		actions.push({spr:s, cost:cost, cb:cb, desc:desc});
		
		icon.setCenter(0,0);
		s.addChild(icon);
		
		//var tf = game.createField(label.charAt(0), true);
		//s.addChild(tf);
		
		var tf = game.createField(""+cost, true);
		s.addChild(tf);
		tf.textColor = 0xFFD942;
		tf.x = Std.int( s.width - tf.textWidth - 1 );
		tf.y = 7;
		
		refresh();
	}
	
	public function runActive() {
		if( current>=0 )
			if( game.useRage(actions[current].cost) )
				return actions[current].cb();
		return false;
	}
	
	function refresh() {
		var x = 0.;
		for(a in actions) {
			a.spr.filters = [];
			a.spr.x = x;
			x+=a.spr.width+5;
		}
		if( current>=0 )
			actions[current].spr.filters = [ new flash.filters.GlowFilter(0x42D5FF, 1,2,2,3) ];
	}
	
	public function activate(i, ?sound=true) {
		current = i;
		if( sound )
			Game.SOUNDS.click2.play();
		refresh();
	}
	
	public function onClick() {
		var m = game.getMouseBuffer();
		var i = 0;
		for(a in actions) {
			var spr = a.spr;
			if( m.x>=wrapper.x+spr.x && m.x<wrapper.x+spr.x+spr.width && m.y>=wrapper.y+spr.y && m.y<wrapper.y+spr.y+spr.height ) {
				activate(i);
				return true;
			}
			i++;
		}
		return false;
	}
		
	public function update() {
		var m = game.getMouseBuffer();
		var over = null;
		for(a in actions) {
			var spr = a.spr;
			if( m.x>=wrapper.x+spr.x && m.x<wrapper.x+spr.x+spr.width && m.y>=wrapper.y+spr.y && m.y<wrapper.y+spr.y+spr.height ) {
				var pt = game.buffer.localToGlobal(a.spr.x+wrapper.x, a.spr.y+wrapper.y-15);
				game.tip.showAt(pt.x, pt.y, a.desc, 0x0);
				over = a;
			}
		}
		wrapper.x = Std.int( game.buffer.width*0.5-wrapper.width*0.5 );
		if( over==null )
			game.tip.hide();
		return false;
	}
	
	
}
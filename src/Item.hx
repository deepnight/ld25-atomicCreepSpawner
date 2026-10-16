class Item extends Entity {
	static var ALL : Array<Item> = [];
	var important		: Bool;
	
	public function new(s) {
		super();
		name = "item";
		important = false;
		ds = s;
		spr.graphics.clear();
		spr.addChild(ds);
		ds.y+=5;
		repels = false;
	}
	
	public function pickUp() {
		destroy();
	}

	public override function register() {
		super.register();
		ALL.push(this);
		//game.sdm.add(spr, Game.DP_ITEM);
	}

	public override function unregister() {
		super.unregister();
		ALL.remove(this);
	}
	
	public override function update() {
		super.update();
		if( !killed && game.hero.cx==cx && game.hero.cy==cy )
			pickUp();
	}
}
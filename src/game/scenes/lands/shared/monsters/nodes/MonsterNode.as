package game.scenes.lands.shared.monsters.nodes {
	
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	
	public class MonsterNode extends Node {

		public var monster:LandMonster;
		public var spatial:Spatial;

		public var life:Life;

	} // class
	
} // package
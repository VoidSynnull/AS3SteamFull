package game.scenes.lands.shared.monsters.nodes {

	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.monsters.MonsterWander;
	import game.scenes.lands.shared.monsters.components.LandMonster;

	public class MonsterWanderNode extends Node {

		public var monster:LandMonster;
		public var wander:MonsterWander;

		public var life:Life;

		public var spatial:Spatial;

	} // class
	
} // package
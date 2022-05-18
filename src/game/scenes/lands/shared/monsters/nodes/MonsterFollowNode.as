package game.scenes.lands.shared.monsters.nodes {

	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.scenes.lands.shared.monsters.MonsterFollow;
	import game.scenes.lands.shared.monsters.components.LandMonster;

	public class MonsterFollowNode extends Node {

		public var monster:LandMonster;
		public var targetInfo:MonsterFollow;
		public var spatial:Spatial;
		public var motionControl:CharacterMotionControl;
		
	} // class
	
} // package
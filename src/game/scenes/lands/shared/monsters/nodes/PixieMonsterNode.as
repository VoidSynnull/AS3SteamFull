package game.scenes.lands.shared.monsters.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.components.LightningTarget;
	import game.scenes.lands.shared.components.SimpleTarget;
	import game.scenes.lands.shared.monsters.components.PixieMonster;
	
	public class PixieMonsterNode extends Node {
		
		public var pixie:PixieMonster;
		
		public var display:Display;
		public var spatial:Spatial;
		
		//public var target:MotionTarget;
		public var target:SimpleTarget;
		//public var motion:Motion;
		public var lightningTarget:LightningTarget;
		
	} // class
	
} // package
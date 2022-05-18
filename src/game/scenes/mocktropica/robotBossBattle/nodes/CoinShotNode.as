package game.scenes.mocktropica.robotBossBattle.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.robotBossBattle.components.CoinShot3D;
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;
	
	
	public class CoinShotNode extends Node {
		
		public var coin:CoinShot3D;
		public var motion:Motion3D;

		public var spatial:Spatial;
		public var display:Display;
		public var zdepth:ZDepthNumber;

	} // End CoinShotNode
	
} // End package
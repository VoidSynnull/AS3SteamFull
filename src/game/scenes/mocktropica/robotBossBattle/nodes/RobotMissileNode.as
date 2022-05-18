package game.scenes.mocktropica.robotBossBattle.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.mocktropica.robotBossBattle.components.RobotMissile;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;

	public class RobotMissileNode extends Node {

		public var missile:RobotMissile;

		public var spatial:Spatial;
		public var display:Display;

		public var sleep:Sleep;
		public var zdepth:ZDepthNumber;

	} // End RobotMissileNode

} // End package
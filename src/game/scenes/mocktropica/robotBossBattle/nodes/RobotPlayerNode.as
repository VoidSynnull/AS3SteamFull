package game.scenes.mocktropica.robotBossBattle.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.robotBossBattle.components.HitBox3D;
	import game.scenes.mocktropica.robotBossBattle.components.Life;
	import game.scenes.mocktropica.robotBossBattle.components.RobotPlayer;

	public class RobotPlayerNode extends Node {

		public var hit:HitBox3D;
		public var spatial:Spatial;
		public var life:Life;

		public var robotPlayer:RobotPlayer;

		public var display:Display;

	} // End RobotPlayerNode

} // End package
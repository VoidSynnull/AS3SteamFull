package game.scenes.mocktropica.robotBossBattle.nodes {

	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.robotBossBattle.components.HitBox3D;
	import game.scenes.mocktropica.robotBossBattle.components.Life;
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthScale;
	import game.scenes.virusHunter.heart.components.ColorBlink;
	import game.scenes.virusHunter.shared.components.Enemy;

	/**
	 * Node used to designate enemy targets in the RobotBossBattle
	 * so they can be shot mercilessly to death with hard, shiny coins.
	 */
	public class RobotEnemyNode extends Node {

		// marker component.
		public var enemy:Enemy;

		public var life:Life;
		public var zdepth:ZDepthNumber;
		//public var zscale:ZDepthScale;
		public var spatial:Spatial;
		public var hit:HitBox3D;
		public var motion:Motion3D;

		public var blink:ColorBlink;

		public var optional:Array = [ ColorBlink ];

	} // End RobotEnemyNode

} // End package
package game.scenes.mocktropica.robotBossBattle.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.VariableTimeline;
	import game.scenes.mocktropica.robotBossBattle.components.HitBox3D;
	import game.scenes.mocktropica.robotBossBattle.components.Life;
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.MoveTarget3D;
	import game.scenes.mocktropica.robotBossBattle.components.RobotBoss;
	import game.scenes.mocktropica.robotBossBattle.components.StateMachine;
	import game.scenes.mocktropica.robotBossBattle.components.Track3D;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;
	import game.scenes.virusHunter.heart.components.ColorBlink;

	public class RobotBossNode extends Node {

		public var boss:RobotBoss;
		public var machine:StateMachine;

		public var zdepth:ZDepthNumber;
		public var spatial:Spatial;

		public var target:MoveTarget3D;
		public var tracking:Track3D;		// for tracking the player to shoot his head.
		public var motion:Motion3D;

		public var display:Display;

		public var life:Life;

		public var blink:ColorBlink;

		public var hit:HitBox3D;

		/**
		 * Using a variable timeline for two reasons:
		 * 1) can easily reset the variable timeline to use a new movieclip when changing robot states.
		 * 2) the variable timeline provides the entity on the frame listener, so the system can listen
		 * for the end-frame event without storing the boss entity.
		 */
		public var timeline:VariableTimeline;

	} // End RobotBossNode

} // End package
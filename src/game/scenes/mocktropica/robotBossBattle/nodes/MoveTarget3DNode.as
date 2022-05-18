package game.scenes.mocktropica.robotBossBattle.nodes {

	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.MoveTarget3D;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;

	public class MoveTarget3DNode extends Node {

		public var spatial:Spatial;
		public var target:MoveTarget3D;

		public var motion:Motion3D;
		public var zdepth:ZDepthNumber;

	} // End MoveTargetNode

} // End package
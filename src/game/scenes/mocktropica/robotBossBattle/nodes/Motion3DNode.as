package game.scenes.mocktropica.robotBossBattle.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;

	/**
	 * Need the display to change the displayObject z, for auto scaling.
	 */
	public class Motion3DNode extends Node {

		public var zdepth:ZDepthNumber;
		public var motion:Motion3D;
		public var spatial:Spatial;

		public var display:Display;

	} // End Motion3DNode

} // End package
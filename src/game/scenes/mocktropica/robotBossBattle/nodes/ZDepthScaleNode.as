package game.scenes.mocktropica.robotBossBattle.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthScale;

	public class ZDepthScaleNode extends Node {

		public var display:Display;
		public var spatial:Spatial;
		public var scaling:ZDepthScale;

		public var sleep:Sleep;
		public var zdepth:ZDepthNumber;

	} // End ZControlNode

} // End package
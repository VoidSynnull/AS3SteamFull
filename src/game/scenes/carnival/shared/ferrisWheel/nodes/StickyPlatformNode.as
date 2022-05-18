package game.scenes.carnival.shared.ferrisWheel.nodes {

	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.hit.Platform;
	import game.scenes.carnival.shared.ferrisWheel.components.StickyPlatform;

	public class StickyPlatformNode extends Node {

		public var platform:Platform;
		public var sticky:StickyPlatform;
		public var spatial:Spatial;

	} // End StickyPlatformNode
	
} // End package
package game.scenes.backlot.sunriseStreet.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.backlot.sunriseStreet.components.SpringBoard;
	
	public class SpringNode extends Node
	{
		public var spring:SpringBoard;
		public var spatial:Spatial;
		public var motion:Motion;
		/*
		public var hit:PlatformCollider;
		public var currentHit:CurrentHit;
		//*/
	}
}
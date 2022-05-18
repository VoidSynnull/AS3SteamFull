package game.scenes.myth.cerberus.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.scenes.myth.cerberus.components.CerberusSnoreComponent;
	
	public class CerberusSnoreNode extends Node
	{
		public var snore:CerberusSnoreComponent;
		public var spatial:Spatial;
		public var tween:Tween;
		public var display:Display;
	}
}
package game.scenes.myth.cerberus.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.scenes.myth.cerberus.components.CerberusHeadComponent;
	
	public class CerberusNode extends Node
	{
		public var head:CerberusHeadComponent;
		public var id:Id;
		public var audio:Audio;
		public var display:Display;
		public var spatial:Spatial
	}
}
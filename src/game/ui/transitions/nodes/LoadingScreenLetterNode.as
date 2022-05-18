package game.ui.transitions.nodes
{
	import ash.core.Node;
	import engine.components.Display;
	import engine.components.Spatial;
	import game.components.input.Input;
	import game.ui.transitions.components.LoadingScreenLetterComponent;
	
	public class LoadingScreenLetterNode extends Node
	{
		public var movingLetterComponent:LoadingScreenLetterComponent;
		public var spatial:Spatial;
		public var display:Display;
		//public var input:Input;
	}
}

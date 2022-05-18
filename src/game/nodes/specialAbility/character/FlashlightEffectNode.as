package game.nodes.specialAbility.character
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.specialAbility.character.FlashlightEffect;

	public class FlashlightEffectNode extends Node
	{
		public var flashlightEffect:FlashlightEffect
		public var spatial:Spatial;
		public var display:Display;
	}
}
package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.SceneWeaponTarget;
	
	public class SceneWeaponTargetNode extends Node
	{
		public var damageTarget:DamageTarget;
		public var collider:MovieClipHit;
		public var id:Id;
		public var display:Display;
		public var spatial:Spatial;
		public var sceneWeaponTarget:SceneWeaponTarget;
	}
}
package game.scenes.shrink.mainStreet.StretchSwingSystem
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.scenes.shrink.shared.Systems.Nodes.HitNode;
	
	public class StretchSwing extends Component
	{
		public var hitNode:HitNode;
		public var stretchScale:Number;
		public var stretching:Boolean;
		public var soundEffect:String;
		public function StretchSwing(swingCollider:Entity = null, stretchScale:Number = 1, soundEffect:String="none")
		{
			stretching = false;
			hitNode = new HitNode();
			hitNode.entity = swingCollider;
			hitNode.idList = swingCollider.get(EntityIdList);
			hitNode.spatial = swingCollider.get(Spatial);
			this.stretchScale = stretchScale;
			this.soundEffect = soundEffect;
		}
	}
}
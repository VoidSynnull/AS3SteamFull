package game.scenes.deepDive3.shared.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.components.entity.collider.SceneObjectCollider;
	import game.scenes.deepDive3.shared.MemoryModuleGroup;
	import game.scenes.deepDive3.shared.nodes.OrbNode;
	
	public class OrbCollisionSystem extends ListIteratingSystem
	{
		public function OrbCollisionSystem($group:MemoryModuleGroup)
		{
			_group = $group;
			super(OrbNode, updateNode);
		}
		
		private function updateNode($node:OrbNode, $time:Number):void{
			try{
				if($node.orb.player.get(SceneObjectCollider)){
					if($node.radialCollider.isHit || $node.sceneCollider.isHit || SceneObjectCollider($node.orb.player.get(SceneObjectCollider)).isHit){
						if(!_collision){
							_group.shellApi.triggerEvent("hitOrb");
							_collision = true;
						}
					} else {
						_collision = false;
					}
				}
			} catch($error:Error){
				trace($error.getStackTrace());
				trace("sceneCollider:"+$node.orb.player.get(SceneObjectCollider));
			}
		}
		
		private var _group:MemoryModuleGroup;
		private var _collision:Boolean = false;
	}
}
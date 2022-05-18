package game.systems.smartFox
{
	import ash.tools.ListIteratingSystem;
	
	import game.nodes.smartFox.SFSceneObjectNode;
	import game.systems.SystemPriorities;
	
	/**
	 * NOT YET IMPLEMENTED
	 * System used for multiplayer scenes, handles non-player entities that share state across server 
	 * @author Bart Henderson
	 */
	public class SFSceneObjectSystem extends ListIteratingSystem
	{
		/**
		 * Updates any entity with the SceneObject component in a scene.
		 */
		
		public function SFSceneObjectSystem()
		{
			super(SFSceneObjectNode, updateNode);
			super._defaultPriority = SystemPriorities.postUpdate;
		}
		
		private function updateNode($node:SFSceneObjectNode, $time:Number):void{
			
		}
	}
}
package game.components.entity.character
{
	import ash.core.Component;
	
	public class Npc extends Component
	{
		/**
		 * <b>DEPRECATED!</b> An NPC component does not determine depth anymore. Refer to PlatformDepthCollider and PlatformDepthCollision.
		 * 
		 * <p>Determines whether an NPC is checked with the player for depth layering.</p>
		 */
		public var ignoreDepth:Boolean = false;
		
		public function Npc()
		{
			
		}
	}
}

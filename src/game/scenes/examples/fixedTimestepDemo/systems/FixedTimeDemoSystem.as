package game.scenes.examples.fixedTimestepDemo.systems
{
	import flash.display.MovieClip;
	
	import game.scenes.examples.fixedTimestepDemo.nodes.FixedTimeDemoNode;
	import game.systems.GameSystem;
	
	public class FixedTimeDemoSystem extends GameSystem
	{
		public function FixedTimeDemoSystem()
		{
			super(FixedTimeDemoNode, updateNode);
			/**
			 * The fixed time step can be set to 1/targetfps.  Additionally, if you want this fixed time system tied to other fixed time 
			 * systems use the 'linkUpdate' property.  This will 'link' this system to other fixed time system that share the same id.
			 * This will cause them to always update together.
			 * 
			 * ex: 
			 * // all updates in this system will happen along with other systems sharing the FixedTimestep.MOTION_LINK id (will still use priority to decide order amongst linked systems).
			 * super.linkedUpdate = FixedTimestep.MOTION_LINK
			 */
			super.fixedTimestep = 1/30;
		}
		
		private function updateNode(node:FixedTimeDemoNode, time:Number):void
		{
			node.fixedTime.totalUpdates++;
			MovieClip(node.display.displayObject).total.text = node.fixedTime.totalUpdates;
		}
	}
}
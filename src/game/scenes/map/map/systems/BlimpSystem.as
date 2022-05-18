package game.scenes.map.map.systems
{
	import game.scenes.map.map.nodes.BlimpNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class BlimpSystem extends GameSystem
	{
		public function BlimpSystem()
		{
			super(BlimpNode, updateNode);
			
			this._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:BlimpNode, time:Number):void
		{
			if(!node.blimp.timeline.playing)
			{
				if(node.spatial.scaleX < 0 && node.display.displayObject.parent.mouseX > node.spatial.x ||
					node.spatial.scaleX > 0 && node.display.displayObject.parent.mouseX < node.spatial.x)
				{
					node.blimp.timeline.gotoAndPlay(0);
				}
			}
			
			//if(!PlatformUtils.isMobileOS && node.target.forceTarget)
			if(node.target.forceTarget)
			{
				var scale:Number = node.spatial.scaleX > 0 ? 1 : -1;
				node.blimp.spatial.rotation = node.motion.velocity.x * 0.05 * scale;
			}
		}
	}
}
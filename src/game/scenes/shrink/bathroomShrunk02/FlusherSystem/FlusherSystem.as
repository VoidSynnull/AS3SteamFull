package game.scenes.shrink.bathroomShrunk02.FlusherSystem
{
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.systems.GameSystem;
	import game.util.TweenUtils;
	
	public class FlusherSystem extends GameSystem
	{
		public function FlusherSystem()
		{
			super(FlusherNode, updateNode);
		}
		
		public function updateNode(node:FlusherNode, time:Number):void
		{
			if(node.flusher.entityIdList.entities.length > 0)
			{
				if(!node.flusher.flushing)
				{
					node.flusher.flushing = true;
					TweenUtils.entityTo(node.entity, Spatial, node.flusher.pressTime,{rotation:node.flusher.down, onComplete:Command.create(flush, node.flusher)});
				}
			}
			else
			{
				if(node.flusher.flushing)
				{
					node.flusher.flushing = false;
					TweenUtils.entityTo(node.entity, Spatial, node.flusher.pressTime,{rotation:node.flusher.up});
				}
			}
		}
		
		private function flush(flusher:Flusher):void
		{
			flusher.flush.dispatch();
		}
	}
}
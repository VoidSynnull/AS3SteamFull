package game.scenes.shrink.livingRoomShrunk.StaticSystem
{
	import com.greensock.easing.Linear;
	
	import flash.geom.Point;
	
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.systems.GameSystem;
	import game.util.TweenUtils;
	
	public class StaticBalloonSystem extends GameSystem
	{
		public function StaticBalloonSystem()
		{
			super(StaticBalloonNode, updateNode);
		}
		
		public function updateNode(node:StaticBalloonNode, time:Number):void
		{
			if(node.balloon.stickingEntity != null)
			{
				if(node.balloon.stickingEntity.hasCharge)
					node.static.contactStaticObject(node.balloon.stickingEntity);
				else
					node.balloon.stickingEntity = null;
				
				return;
			}
			
			if(node.balloon.home || node.balloon.returning)
				return;
			
			if(!node.motion.velocity.equals(new Point()))
			{
				node.balloon.home = false;
				node.balloon.returning = false;
				return;
			}
			
			node.balloon.returning = true;
			TweenUtils.entityTo(node.entity,Spatial,node.balloon.returnTime,{x:node.balloon.origin.x, y:node.balloon.origin.y, ease:Linear.easeInOut, onComplete:Command.create(returned, node.balloon)});
		}
		
		private function returned(balloon:StaticBalloon):void
		{
			balloon.returning = false;
			balloon.home = true;
		}
	}
}
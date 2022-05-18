package game.scenes.reality2.spearThrow.ai
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.data.WaveMotionData;
	import game.scenes.poptropolis.archery.nodes.WindNode;
	import game.systems.GameSystem;
	import game.util.TweenUtils;
	
	public class SpearThrowAiSystem extends GameSystem
	{
		private var _winds:NodeList;
		
		public function SpearThrowAiSystem()
		{
			super(SpearThrowAiNode, updateNode);
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_winds = systemManager.getNodeList( WindNode );
			super.addToEngine(systemManager);
		}
		
		private function updateNode(node:SpearThrowAiNode, time:Number):void
		{
			if(node.ai.aiming)
			{
				var wind:WindNode = _winds.head;
				node.ai.time += time;
				var waveMotionData:WaveMotionData = node.ai.powerBar;
				var powerBarValue:Number = Math[waveMotionData.type](waveMotionData.radians)
				if(node.ai.time > node.ai.delay && Math.abs(powerBarValue) < (1-node.ai.accuracy) + time)
				{
					node.ai.aiming = false;
					node.ai.time = 0;
					node.ai.count++;
					
					var angle:Number = Math.random() * Math.PI * 2;
					var radius:Number = Math.random() * node.ai.aimRadius * (1-node.ai.accuracy);
					var target:Point = new Point(Math.cos(angle) * radius, Math.sin(angle) * radius);
					target.x += node.target.targetX;
					target.y += node.target.targetY;
					var duration:Number = node.ai.delay;
					if(node.ai.count >= node.ai.movements)
					{
						duration = time * 2;
						target.x -= (wind.wind.windSpeed * node.ai.accuracy + wind.wind.windSpeed * Math.random() * (1-node.ai.accuracy)) * 1.5;
					}
					TweenUtils.entityTo(node.entity, Spatial, duration,{x:target.x, y:target.y, onComplete:Command.create(tweenComplete, node)});
				}
			}
			else
			{
				node.ai.target.x = node.spatial.x;
				node.ai.target.y = node.spatial.y;
			}
		}
		
		private function tweenComplete(node:SpearThrowAiNode):void
		{
			if(node.ai.count < node.ai.movements)
			{
				node.ai.aiming = true;
			}
			else
			{
				node.ai.count = 0;
				node.ai.fire.dispatch();
			}
		}
	}
}
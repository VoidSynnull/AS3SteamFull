package game.scenes.cavern1.caveEntrance
{
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.timeline.Timeline;
	import game.systems.GameSystem;
	
	public class WaterGeyserSystem extends GameSystem
	{
		public function WaterGeyserSystem()
		{
			super(WaterGeyserNode,updateNode,onNodeAdded);
		}
		
		private function onNodeAdded(node:WaterGeyserNode):void
		{
			if(!node.waterGeyser.active)
			{
				activateNode(node, false);
			}
			node.waterGeyser.timer = 0;
		}
		
		private function updateNode(node:WaterGeyserNode, time:Number):void
		{
			node.waterGeyser.timer += time;
			if(node.waterGeyser.timer > node.waterGeyser.upTime && node.waterGeyser.active)
			{
				activateNode(node, false);
			}
			else if(node.waterGeyser.timer > node.waterGeyser.downTime && !node.waterGeyser.active)
			{
				activateNode(node, true);
			}
		}
		
		private function activateNode(node:WaterGeyserNode, active:Boolean):void
		{
			var timeline:Timeline;
			if(node.children)
				timeline = node.children.children[0].get(Timeline);
			
			if(!active)
			{
				if(node.waterGeyser.moverEntity)
					node.waterGeyser.moverEntity.remove(Mover);
				if(node.waterGeyser.platform)
					node.waterGeyser.platform.remove(Platform);
				if(timeline)
					timeline.gotoAndPlay("stopGeyser");
			}
			else
			{
				if(node.waterGeyser.mover)
					node.waterGeyser.moverEntity.add(node.waterGeyser.mover);
				if(node.waterGeyser.platform)
					node.waterGeyser.platform.add(new Platform());
				if(timeline)
					timeline.gotoAndPlay("startGeyser");
			}
			
			node.waterGeyser.active = active;
			node.waterGeyser.timer = 0;
		}
	}
}
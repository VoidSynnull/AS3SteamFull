package game.scenes.virusHunter.lungs.systems 
{
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.lungs.components.Alveoli;
	import game.scenes.virusHunter.lungs.nodes.AlveoliNode;
	import game.util.Utils;

	public class AlveoliSystem extends ListIteratingSystem
	{
		public function AlveoliSystem() 
		{
			super( AlveoliNode, updateNode );
		}
		
		private function updateNode( node:AlveoliNode, time:Number ):void
		{
			var alveoli:Alveoli = node.alveoli;
			var entity:Entity = node.entity;
			
			if(!alveoli.isMoving)
			{
				if(alveoli.isHit)
				{
					alveoli.isHit = false;
					alveoli.isMoving = true;
					alveoli.elapsedTime = 0;
					alveoli.waitTime = Utils.randNumInRange(3, 6);
					Timeline(entity.get(Timeline)).gotoAndPlay("moving");
				}
			}
			else
			{
				if(alveoli.isHit)
				{
					alveoli.isHit = false;
					alveoli.elapsedTime = 0;
				}
				
				alveoli.elapsedTime += time;
				if(alveoli.elapsedTime >= alveoli.waitTime)
				{
					alveoli.isMoving = false;
					Timeline(entity.get(Timeline)).handleLabel("end", Command.create(handleEnd, entity));
				}
			}
		}
		
		private function handleEnd(entity:Entity):void
		{
			Timeline(entity.get(Timeline)).gotoAndStop("resting");
		}
	}
}
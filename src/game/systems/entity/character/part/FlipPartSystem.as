package game.systems.entity.character.part
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.components.timeline.Timeline;
	import game.nodes.entity.character.part.FlipPartNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class FlipPartSystem extends GameSystem
	{
		public var paused:Boolean = false;
		public function FlipPartSystem()
		{
			super(FlipPartNode, updateNode);
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:FlipPartNode, time:Number):void
		{
			var charSpatial:Spatial = node.parent.parent.get(Spatial);
			var clip:MovieClip = node.flipPart.instanceData.getInstanceFrom(node.display.displayObject) as MovieClip;
			
			if( clip != null && charSpatial != null )
			{
				// sometimes it takes a while before the Children component has been added
				if (node.entity.has(Children))
				{
					// get child entity that has clip name
					var entity:Entity = node.entity.get(Children).getChildByName(clip.name);
					// if entity found and has timeline
					if ((entity != null) && (entity.has(Timeline)) && !paused)
					{
						var timeline:Timeline = entity.get(Timeline);
						// if facing right
						if(charSpatial.scaleX < 0)
						{
							if( timeline.currentIndex != 1 )
							{
								timeline.gotoAndStop(1);
							}
						}
						// if facing left
						else		
						{
							if( timeline.currentIndex != 0 )
							{
								timeline.gotoAndStop(0);
							}
						}
					}
				}
			}
		}
	}
}
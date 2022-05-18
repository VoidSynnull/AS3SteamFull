package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;

	public class Chicken extends Default
	{
		private const LABEL_LOOP:String = "loop";
		private var cycles:Number = 0;
		
		public function Chicken()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "chicken" + ".xml";
		}
		
		override public function reachedFrameLabel( entity:Entity, label:String ):void
		{
			switch(label)
			{
				case LABEL_LOOP:
					if(cycles < 3){
						cycles++;
					}else{
						var timeline:Timeline = Timeline(entity.get(Timeline));
						timeline.gotoAndPlay("chicken");
						cycles = 0;
					}
					break;
			}
		}
	}
}
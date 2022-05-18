package game.data.animation.entity.character 
{
	import ash.core.Entity;

	public class Eat extends Default
	{
		private const LABEL_SIT:String = "sit";
		
		public function Eat()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "eat" + ".xml";
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			if ( label == LABEL_SIT )
			{
				//Animations.FLA says transition to Sit's animation
			}
		}
	}
}
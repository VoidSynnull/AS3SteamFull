package game.data.animation.entity.character 
{
	import ash.core.Entity;

	public class ExtendGlass extends Default
	{
		private const LABEL_DRINK_2:String = "drink2";
		
		public function ExtendGlass()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "extendGlass" + ".xml";
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			if ( label == LABEL_DRINK_2 )
			{
				//Animations.FLA says transition to Drink2's animation
			}
		}
	}
}
package game.data.animation.entity.character 
{
	public class LandSpin extends Default
	{		
		public function LandSpin()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/landSpin" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/land" + ".xml";
		}
		/*
		// now gets triggered in hit system
		override public function reachedFrameLabel( entity:Entity, label:String ):void
		{

			if ( label != Animation.LABEL_ENDING )
			{
				var hitAudio:HitAudio = entity.get(HitAudio);
				
				if(hitAudio != null)
				{
					if(label == SoundAction.IMPACT)
					{
						hitAudio.active = true;
						hitAudio.action = SoundAction.IMPACT;
					}
				}
			}
		}
		*/
	}

}
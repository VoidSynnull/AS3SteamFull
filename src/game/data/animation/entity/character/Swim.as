package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.components.audio.HitAudio;
	import game.data.sound.SoundAction;

	/**
	 * ...
	 * @author Bard
	 */
	public class Swim extends Default
	{		
		public function Swim()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/swim" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/swim" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/swim" + ".xml";
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var hitAudio:HitAudio = entity.get(HitAudio);
			
			if(hitAudio != null)
			{
				if(label == SoundAction.STEP)
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.STEP;
				}
			}
		}
	}

}
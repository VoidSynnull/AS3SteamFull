package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.components.audio.HitAudio;
	import game.data.sound.SoundAction;

	/**
	 * ...
	 * @author Bard
	 */
	public class Roll extends Default
	{		
		public function Roll()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/roll" + ".xml";
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
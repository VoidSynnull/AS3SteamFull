package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.components.audio.HitAudio;
	import game.data.sound.SoundAction;

	public class WalkSwordSwish extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function WalkSwordSwish()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "walkSwordSwish" + ".xml";
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
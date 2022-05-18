package game.data.animation.entity.character.poptropolis 
{
	import ash.core.Entity;
	
	import game.components.audio.HitAudio;
	import game.data.sound.SoundAction;
	import game.data.animation.entity.character.Default;

	public class JavelinAnim extends Default
	{
		private const LABEL_BREATHE:String = "breathe";
		private const LABEL_START_PARTICLES:String = "startParticles";
		private const LABEL_STOP_PARTICLES:String = "stopParticles";
		private const LABEL_START:String = "start";
		private const LABEL_RUN:String = "run";
		private const LABEL_TOSS:String = "toss";
		private const LABEL_THROW:String = "throw";
		private const LABEL_HURT:String = "hurt";
		
		public function JavelinAnim()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "poptropolis/javelin" + ".xml";
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
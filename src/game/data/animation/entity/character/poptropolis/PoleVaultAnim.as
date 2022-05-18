package game.data.animation.entity.character.poptropolis 
{
	import ash.core.Entity;
	import game.components.audio.HitAudio;
	import game.data.sound.SoundAction;
	import game.data.animation.entity.character.Default;
	
	public class PoleVaultAnim extends Default
	{
		private const LABEL_RUN:String = "run";
		private const LABEL_LAUNCH:String = "launch";
		private const LABEL_LANDING:String = "landing";
		
		public function PoleVaultAnim()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "poptropolis/poleVault" + ".xml";
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
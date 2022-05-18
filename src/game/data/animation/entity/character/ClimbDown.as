package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.components.audio.HitAudio;
	import game.components.timeline.Timeline;
	import game.components.entity.character.CharacterMotionControl;
	import game.data.sound.SoundAction;

	/**
	 * ...
	 * @author Bard
	 */
	public class ClimbDown extends Default
	{		
		private static const LABEL_CLIMB_END:String = "climbDown";
		
		public function ClimbDown()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/climbDown" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/climbDown" + ".xml";
		}
		
		override public function reachedFrameLabel( entity:Entity, label:String ):void
		{
			switch(label)
			{
				case LABEL_CLIMB_END:
					climbEnd(entity);
					break;
			}
		}
		
		private function climbEnd( entity:Entity ):void
		{
			var charMotionControl:CharacterMotionControl = entity.get(CharacterMotionControl);
			var timeline:Timeline = Timeline(entity.get(Timeline));
			
			if ( !charMotionControl.climbingUp )	// if char is actively climbing up, continue playing animation
			{
				timeline.playing = true;
				playAudio(entity);
			}
			else
			{
				timeline.paused = true;	
				stopAudio(entity);
			}
		}
		
		private function playAudio( entity:Entity ):void
		{
			var hitAudio:HitAudio = entity.get(HitAudio);
			if(hitAudio != null)
			{
				if ( !hitAudio.active )
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.CLIMB_DOWN;
				}
			}
		}
		
		private function stopAudio( entity:Entity ):void
		{
			var hitAudio:HitAudio = entity.get(HitAudio);
			if ( hitAudio.active )
			{
				hitAudio.active = false;
			}
		}
	}
}
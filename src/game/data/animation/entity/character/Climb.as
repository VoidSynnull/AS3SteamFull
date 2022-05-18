package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.components.audio.HitAudio;
	import game.components.timeline.Timeline;
	import game.components.entity.character.CharacterMotionControl;
	import game.data.sound.SoundAction;

	public class Climb extends Default
	{	
		private const LABEL_CLIMB_UP:String 	= "climbUp";
		private const LABEL_CLIMB_MID:String 	= "climbMid";
		
		public function Climb()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/climb" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/climb" + ".xml";
		}

		override public function reachedFrameLabel( entity:Entity, label:String ):void
		{
			switch(label)
			{
				case LABEL_CLIMB_UP:
					climbUp(entity);
					break;
				case LABEL_CLIMB_MID:
					climbMid(entity);
					break;
				default:
					break;
			}
		}
		
		private function climbUp( entity:Entity ):void
		{
			var charMotionControl:CharacterMotionControl = entity.get(CharacterMotionControl);
			var timeline:Timeline = Timeline(entity.get(Timeline));
			
			if ( charMotionControl && charMotionControl.climbingUp )	// if char is actively climbing up
			{
				timeline.playing = true;
				playAudio(entity);
			}
			else
			{
				timeline.paused = true;		// pause prevents playhead from progressing, but processes events and labels
				stopAudio(entity); //TODO :: if paused probably want to stop climb audio
			}
		}
		
		private function climbMid( entity:Entity ):void
		{
			var charMotionControl:CharacterMotionControl = entity.get(CharacterMotionControl);
			var timeline:Timeline = Timeline(entity.get(Timeline));
			
			if ( charMotionControl.climbingUp )	// if char is actively climbing up, continue playing animation
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
					hitAudio.action = SoundAction.CLIMB;
				}
			}
		}
		
		private function stopAudio( entity:Entity ):void
		{
			var hitAudio:HitAudio = entity.get(HitAudio);
			if(hitAudio != null)
			{
				if ( hitAudio.active )
				{
					hitAudio.active = false;
				}
			}
		}
		
	}
}
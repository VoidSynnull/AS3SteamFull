package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.components.audio.HitAudio;
	import game.components.entity.collider.EmitterCollider;
	import game.components.hit.CurrentHit;
	import game.data.scene.hit.EmitterHitData;
	import game.data.sound.SoundAction;

	public class Walk extends Default
	{	
		public function Walk()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/walk" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/walk" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/walk" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/walk" + ".xml";
			super.horseXmlPath = super.XML_PATH + super.TYPE_HORSE + "/walk" + ".xml";

		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var hitAudio:HitAudio = entity.get(HitAudio);
			var emitterHit:EmitterCollider = entity.get(EmitterCollider);
			var emitterHitData:EmitterHitData;
			var currentHit:CurrentHit = entity.get( CurrentHit );
			
			if( currentHit != null )
			{
				if( currentHit.hit )
				{
					emitterHitData = currentHit.hit.get( EmitterHitData );
				}
			}
			
			if( hitAudio != null )
			{
				if(label == SoundAction.STEP)
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.STEP;
				}
			}
			
				// If there is emitter data for this platform
			if( emitterHit )
			{
				if( label == SoundAction.STEP )
				{
					emitterHit.setEmitterData( emitterHitData, SoundAction.STEP );
				}
			}
		}
	}
}
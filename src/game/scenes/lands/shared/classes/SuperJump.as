package game.scenes.lands.shared.classes {
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Default;
	import game.data.sound.SoundModifier;
	import game.util.AudioUtils;
	
	public class SuperJump extends Default {
		
		public function SuperJump() {

			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "superJump" + ".xml";

		}
		
		override public function reachedFrameLabel( entity:Entity, label:String ):void {
			
			//check label
			if ( label == LABEL_TRIGGER ) {
				
				this.doHammerJump( entity );
				
			}
			
		} //
		
		private function doHammerJump( entity:Entity ):void {
			
			var fsmControl:FSMControl = entity.get( FSMControl );
			if( fsmControl ) {
				fsmControl.active = true;
			}
			var charMovement:CharacterMovement = entity.get( CharacterMovement );
			if( charMovement ) {
				charMovement.active = true;
			}
			
			AudioUtils.play( entity.group, SoundManager.EFFECTS_PATH + "electric_zap_06.mp3", 1 , false, SoundModifier.EFFECTS );
			AudioUtils.play( entity.group, SoundManager.EFFECTS_PATH + "thunder_clap_03.mp3", 1 , false, SoundModifier.EFFECTS );
			
			var motion:Motion = entity.get( Motion );	
			motion.velocity.y = -1200;
			
		} //
		
	} // class
	
} // package
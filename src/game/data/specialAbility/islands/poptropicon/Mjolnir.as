// Used by:
// card "mjolnir" on can1 island using item poptropicon_mjolnir

package game.data.specialAbility.islands.poptropicon
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.Rig;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Salute;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	/**
	 * Raise Mjolnir hammer with glint and sound effect 
	 */
	public class Mjolnir extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			var rig:Rig = super.entity.get( Rig );
			
			_mjolnir = rig.getPart( CharUtils.ITEM );
			
			var clip:MovieClip = _mjolnir.get( Display ).displayObject[ "glint" ];
			
			if( clip )
			{
				_glint = EntityUtils.createSpatialEntity( super.group, clip );
				TimelineUtils.convertClip( clip, super.group, _glint );
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			trace("mjolnir : deactivate");
			
			super.group.removeEntity( _glint );
		}
		
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			var fsmControl:FSMControl = super.entity.get( FSMControl );
			
			if( fsmControl.state.type == CharacterState.STAND )
			{
				CharUtils.lockControls( super.entity );
				CharUtils.setAnim( super.entity, Proud );
				var rigAnim:RigAnimation = CharUtils.getRigAnim( super.entity, 1 );
				
				// LAYER SOAR ARMS ON TOP OF PROUD
				if ( rigAnim == null )
				{
					var animationSlot:Entity = AnimationSlotCreator.create( super.entity );
					
					rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
				}
				rigAnim.manualEnd = false;
				rigAnim.next = Salute;
				
				rigAnim.addParts( CharUtils.ARM_FRONT, CharUtils.HAND_FRONT ); 
				
				var timeline:Timeline = super.entity.get( Timeline );
				timeline.labelReached.add( animationHandler );
			}
		}
		
		private function animationHandler( label:String ):void
		{
			var timeline:Timeline = super.entity.get( Timeline );
			var rig:Rig = super.entity.get( Rig );
			
			var animControl:AnimationControl = super.entity.get( AnimationControl );
			var rigAnim:RigAnimation = CharUtils.getRigAnim( super.entity, 1 );
			
			if( label == "stand" )
			{
				timeline.stop();
				animControl.pause();
				
				timeline = _glint.get( Timeline );
				timeline.gotoAndPlay( 2 );
				
				AudioUtils.play( super.group, SoundManager.EFFECTS_PATH + EVENT, VOLUME_MODIFIER + 1 );
				timeline.handleLabel( "ending", glintHandler );
			}
			
			else if( label == "ending" )
			{
				CharUtils.lockControls( super.entity, false, false );
				timeline.labelReached.removeAll();
				
				super.shellApi.triggerEvent( "behold_mjolnir", false, super.shellApi.island );
			}
		}
		
		private function glintHandler():void
		{
			var timeline:Timeline = _glint.get( Timeline );
			timeline.labelReached.removeAll();
						
			var animControl:AnimationControl = super.entity.get( AnimationControl );
			animControl.playing();
		}
	
		private var _emitterEntity:Entity;
		private var _glint:Entity;
		private var _mjolnir:Entity;
		
		private const VOLUME_MODIFIER:int = 3;
		private const EVENT:String = "event_01.mp3";
	}
}
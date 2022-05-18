// Used by:
// Card "ghd_guano" using item ghd_guano

package game.data.specialAbility.islands.ghd
{
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.hit.CurrentHit;
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Place;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.ghd.shared.mushroom.Mushroom;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;

	/**
	 * Place guano on mushrooms 
	 */
	public class RubGuano extends SpecialAbility
	{				
		private const USED_GUANO:String		=		"used_guano";
		private const CLOSE_GUANO:String	=		"close_guano";
		private const NO_USE_GUANO:String	=		"no_use_guano";
		private const LEFT:String			=		"left";
		private const RIGHT:String			=		"right";
		private const FART_1:String			=		"fart_01.mp3";
		private const FART_2:String			=		"fart_02.mp3";
		private const MUSHROOM:String		=		"mushroom";
		private const ROOTS:String			=		"roots";
		private var _dialog:Dialog;
		
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			_dialog = super.entity.get( Dialog );
			
			var fsmControl:FSMControl = node.entity.get( FSMControl );
			
			if( fsmControl.state.type == CharacterState.STAND )
			{
				var currentHit:CurrentHit = super.entity.get( CurrentHit );
				if( super.shellApi.sceneName.toLowerCase().indexOf( MUSHROOM ) > -1 && currentHit && currentHit.hit )
				{
					var currentHitId:Id = currentHit.hit.get( Id );
					var mushroomEntity:Entity;
					var mushroomNumber:String;
					var timeline:Timeline;
					
					if( currentHitId.id.indexOf( ROOTS ) > -1 )
					{
						mushroomNumber = currentHitId.id.substr( 5 );
						mushroomEntity = super.group.getEntityById( MUSHROOM + mushroomNumber );
						
						CharUtils.setAnim( super.entity, Place );
						timeline = super.entity.get( Timeline );
						timeline.handleLabel( Animation.LABEL_TRIGGER, Command.create( onPlace, mushroomEntity ));
						SceneUtil.lockInput( super.group );
					}
					else
					{
							_dialog.sayById( CLOSE_GUANO );
					}
				}
				else
				{
					_dialog.sayById( NO_USE_GUANO );
				}
				
				super.setActive( true );
			}
		}
		
		private function onPlace( mushroomEntity:Entity ):void
		{
			var mushroom:Mushroom = mushroomEntity.get( Mushroom );
			var spatial:Spatial = mushroomEntity.get( Spatial );
			SceneUtil.setCameraPoint( Scene(super.group), spatial.x, spatial.y - 200 ); //Target( _scene, mushroomEntity );
			
			if( !mushroom.isMoving && !mushroom.isInvalid )
			{
				if( !super.shellApi.checkEvent( USED_GUANO ))
				{
					super.shellApi.completeEvent( USED_GUANO );
				}
				
				mushroom.isFacingLeft = !mushroom.isFacingLeft;
				mushroom.stemTimeline.play();
				mushroom.stemTimeline.handleLabel( LEFT, Command.create( returnControl, mushroom ));
				mushroom.stemTimeline.handleLabel( RIGHT, Command.create( returnControl, mushroom ));
			}
			
			var sound:String = Math.random() < .5 ? FART_1 : FART_2;
			AudioUtils.play( super.group, SoundManager.EFFECTS_PATH + sound );
		}
		
		private function returnControl( mushroom:Mushroom ):void
		{
			mushroom.stemTimeline.removeLabelHandler( returnControl );
			SceneUtil.setCameraTarget( Scene(super.group), super.entity );
			SceneUtil.lockInput( super.group, false );
			
			
			CharUtils.stateDrivenOn( super.entity );
			super.setActive( false );
		}
	}	
}
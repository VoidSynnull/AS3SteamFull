package game.scenes.survival5.underground
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.part.RotateToJointSystem;
	import game.data.TimedEvent;
	import game.data.animation.AnimationData;
	import game.data.animation.AnimationSequence;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.SitSleepLoop;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Think;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.survival5.shared.Survival5Scene;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class Underground extends Survival5Scene
	{
		private var MAX:Entity;
		
		public function Underground()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival5/underground/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addCharacterDialog( container:Sprite ):void
		{
			var dialogEntity:Entity = new Entity;
			var spatial:Spatial = player.get( Spatial );
			if( PlatformUtils.isDesktop )
			{
				dialogEntity.add( new Spatial( 870, 370 ));
			}
			else
			{
				dialogEntity.add( new Spatial( 950, 370 ));
			}
			var dialog:Dialog = new Dialog();
			dialogEntity.add( dialog );
			dialogEntity.add( new Id( "maxDialog" ));
			
			var audioGroup:AudioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			audioGroup.addAudioToEntity( dialogEntity );
			
			super.addEntity( dialogEntity );
			super.addCharacterDialog( container );
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			
			addSystem( new RotateToJointSystem());
		}
		
		// all assets ready
		override public function loaded():void
		{
			MAX = getEntityById( "max" );
			
			super.loaded();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(550, 690));	

			if( !shellApi.checkEvent( _events.JOINED_THE_FIGHT ))
			{
				// reposition the player to the bottom of his fall
				var spatial:Spatial = player.get( Spatial );
				spatial.x = 1220;
				spatial.y = 450;
				
				CharUtils.setDirection( player, true );
				
				var characterGroup:CharacterGroup = getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
				characterGroup.addAudio( MAX );
				
				var cameraEntity:Entity  = getEntityById( "camera" );
				var camera:Camera = cameraEntity.get( Camera );
				
				camera.scaleTarget = 2;		
				camera.scaleRate = 1;
				startTheInquisition();
			}
			else
			{
				if( MAX )
				{
					spatial = MAX.get( Spatial );
					spatial.x = 975;
					spatial.y = 465;
					
					var animControl:AnimationControl = MAX.get( AnimationControl );
					
					if( animControl )
					{
						var animEntity:Entity = animControl.getEntityAt();
						var animSequencer:AnimationSequencer = animEntity.get( AnimationSequencer );
						
						if(animSequencer == null)
						{
							animSequencer = new AnimationSequencer();
							animEntity.add(animSequencer);
						}
						
						var animations:Vector.<Class> = new Vector.<Class>;
						animations.push( Think, Stand );
						
						var sequence:AnimationSequence = new AnimationSequence();
						for (var i:int = 0; i < animations.length; i++) 
						{
							sequence.add( new AnimationData( animations[i], 180 ));
						}
						
						sequence.loop = true;
						animSequencer.currentSequence = sequence;
						animSequencer.start = true;

					}
				}
			}
		}
		
		override protected function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( event == "introduce_myself" )
			{				
				CharUtils.setAnim( MAX, Proud );
				
				var dialog:Dialog = MAX.get( Dialog );
				dialog.sayById( "max_mcgullicutty" );
				dialog.complete.add( setEyesOpen );
			}
			
			if( event == "return_control" )
			{
				SceneUtil.lockInput( this, false );
				SkinUtils.setEyeStates( MAX, EyeSystem.CASUAL );
				shellApi.completeEvent( _events.JOINED_THE_FIGHT );
			}
			
			super.onEventTriggered( event, save, init, removeEvent );
		}
		
		private function setEyesOpen( dialogData:DialogData ):void
		{
			SkinUtils.setEyeStates( MAX, EyeSystem.CASUAL );
		}
		
		/**
		 * FIRST TIME MEETING MAX
		 *   ZOOM IN ON PLAYER AND HAVE MAX CONFRONT THEM
		 */ 
		private function startTheInquisition():void
		{
			SceneUtil.lockInput( this );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "stunned_01_loop.mp3", 1, true );
			CharUtils.setAnim( player, SitSleepLoop );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.2, 1, cameraReset ));
		}
		
		private function cameraReset():void
		{			
			var cameraEntity:Entity  = getEntityById( "camera" );
			var camera:Camera = cameraEntity.get( Camera );
			
			camera.scaleTarget = 1;		
			camera.scaleRate = .05;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, caughtYou ));
		}
		
		private function caughtYou():void
		{
			var dialogEntity:Entity = getEntityById( "maxDialog" );;
			var dialog:Dialog = dialogEntity.get( Dialog );
			dialog.sayById( "got_you" );
			dialog.complete.addOnce( enterMax );
		}
		
		private function enterMax( dialogData:DialogData ):void
		{			
			CharUtils.moveToTarget( MAX, 1075, 505, true, caughtVanBuren );
			CharacterMotionControl( MAX.get( CharacterMotionControl )).maxVelocityX = 140;
			
			CharUtils.stateDrivenOn( player );
			CharUtils.setDirection( player, false );
			
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.setState( CharacterState.STAND );
			AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "stunned_01_loop.mp3" );
		}
		
		private function caughtVanBuren( character:Entity ):void
		{
			CharUtils.setAnim( MAX, Grief );
			var dialog:Dialog = MAX.get( Dialog );
			
			dialog.sayById( "not_vanBuren" );
		}
	}
}
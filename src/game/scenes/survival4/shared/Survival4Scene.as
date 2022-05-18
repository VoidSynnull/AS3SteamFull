package game.scenes.survival4.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Hide;
	import game.components.motion.FollowTarget;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.PourPitcher;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.survival4.Survival4Events;
	import game.scenes.survival4.guestRoom.GuestRoom;
	import game.systems.SystemPriorities;
	import game.systems.entity.AlertSoundSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	public class Survival4Scene extends PlatformerGameScene
	{
		public function Survival4Scene()
		{
			super();
		}
		
		override public function loaded():void
		{
			setupHideHits();
			super.loaded();
			
			shellApi.eventTriggered.add( eventTriggers );
			
			_audioGroup = super.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			_alertSystem = new AlertSoundSystem();
			_events = super.events as Survival4Events; 
			
			_alertSystem.triggered.addOnce( alertSounded );
			super.addSystem( _alertSystem, SystemPriorities.moveComplete );
			
			if( shellApi.checkHasItem(_events.VOICE_RECORDING))
			{
				createRecordingEntity();
			}
		}
		
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == GameEvent.GOT_ITEM + _events.VOICE_RECORDING )
			{
				createRecordingEntity();
			}
			
			if( event == _events.USE_VOICE_RECORDING && !playingSound )
			{
				var motion:Motion = player.get( Motion );
				playingSound = true;
				
				if( motion.velocity.x == 0 && motion.velocity.y == 0 )
				{
					CharUtils.setAnim( player, PourPitcher );
					SkinUtils.setSkinPart( player, SkinUtils.ITEM, "survival_soundrecording" );
					
					var timeline:Timeline = player.get( Timeline );
					
					timeline.handleLabel( TRIGGER, playRecording );
				}
			}
		}
		
		private function playRecording():void
		{
			var spatial:Spatial = player.get( Spatial );
			var recordingEntity:Entity = getEntityById( "recording_entity" );
			var recordingSpatial:Spatial = recordingEntity.get( Spatial );
			var dialog:Dialog = recordingEntity.get( Dialog );
			
			var followTarget:FollowTarget = recordingEntity.get( FollowTarget );
			
	//		recordingSpatial.x = spatial.x - 35;
	//		recordingSpatial.y = spatial.y - 50;
			recordingSpatial.scaleX = spatial.scaleX;
				
			if( spatial.scaleX < 0 )
			{
				followTarget.offset.x = 35;
			}
			else
			{
				followTarget.offset.x = -35;
			}
			
			EntityUtils.position( recordingEntity, recordingSpatial.x, recordingSpatial.y );
			
			dialog.sayById( TRIGGER );
			
			var securityPanel:Entity = getEntityById( "securityInteraction" );
			if( securityPanel )
			{
				if( EntityUtils.distanceBetween( securityPanel, recordingEntity ) < 400 )
				{
					shellApi.triggerEvent( _events.USE_TALLY_HO );
				}
			}
		
			var audio:Audio = recordingEntity.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "ending", putAwayDevice );
		}
		
		public function putAwayDevice():void
		{
			var recordingEntity:Entity = getEntityById( "recording_entity" );
			
			CharUtils.stateDrivenOn( player );
			playingSound = false;
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "empty" );
		}
		
		public function alertSounded():void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "caught" );
			dialog.complete.addOnce( reloadScene );
		}
		
		private function reloadScene( dialogData:DialogData = null ):void
		{
			super.shellApi.loadScene( GuestRoom, 300, 690, "right" );
		}
		
		private function setupHideHits():void
		{
			player.add(new Hide());
			var child:MovieClip;
			var hideClips:Array = [];
			for each(child in _hitContainer)
			{
				if(child.name.indexOf("hide") == 0)
				{
					hideClips.push(child);
				}
			}
			
			for each(child in hideClips)
			{
				child.parent.setChildIndex(child, 0);
				var hideable:Entity = EntityUtils.createSpatialEntity(this, child);
				BitmapTimelineCreator.convertToBitmapTimeline(hideable);
				
				InteractionCreator.addToEntity(hideable, [InteractionCreator.CLICK]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.add(hideReached);
				sceneInteraction.validCharStates = new <String> [ CharacterState.STAND];
				sceneInteraction.minTargetDelta = new Point(30, 100);
				sceneInteraction.ignorePlatformTarget = false;
				hideable.add(sceneInteraction);
				ToolTipCreator.addToEntity(hideable);
			}
		}
		
		private function hideReached(player:Entity, hideable:Entity):void
		{
			var timeline:Timeline = hideable.get(Timeline);
			if(timeline)
				timeline.play();
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "grass_rustle_01.mp3");
			
			var hide:Hide = player.get(Hide);
			if(!hide.hidden)
			{
				hide.hidden = true;
				
				var hideableSpatial:Spatial = hideable.get(Spatial);
				var playerSpatial:Spatial = player.get(Spatial);
				
				PlatformDepthCollider(player.get(PlatformDepthCollider)).manualDepth = true;
				
				playerSpatial.x = hideableSpatial.x;
				playerSpatial.y = hideableSpatial.y;
				
				CharUtils.setAnim(player, DuckDown);
				CharUtils.lockControls(player);
			}
			else
			{
				hide.hidden = false;
				
				PlatformDepthCollider(player.get(PlatformDepthCollider)).manualDepth = false;
				
				CharUtils.setState(player, CharacterState.STAND);
				CharUtils.lockControls(player, false, false);
			}
			
			var container:DisplayObjectContainer = player.get(Display).displayObject.parent;
			container.swapChildren(hideable.get(Display).displayObject, player.get(Display).displayObject);
		}
		
		private function createRecordingEntity():void
		{
			var recordingEntity:Entity = new Entity();
			var followTarget:FollowTarget = new FollowTarget( player.get( Spatial ), 1 );
			followTarget.offset = new Point( -35, -50 );
			
			recordingEntity.add( new Spatial()).add( followTarget );
			recordingEntity.add(new Display(this._hitContainer.addChild(new Sprite())));
			
			recordingEntity.add( new Id( "recording_entity" ));	
			
			addEntity( recordingEntity );
			
			_audioGroup.addAudioToEntity( recordingEntity );
			
			CharUtils.assignDialog(recordingEntity, this);
		}
		
		private const TRIGGER:String =	"trigger";
		private var playingSound:Boolean = false;
		
		protected var _audioGroup:AudioGroup;
		protected var _alertSystem:AlertSoundSystem;
		protected var _events:Survival4Events;
	}
}
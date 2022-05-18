package game.scenes.carrot.loading
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.carrot.loading.components.Box;
	import game.scenes.carrot.loading.systems.BoxSystem;
	import game.scenes.carrot.shared.rabbotEars.RabbotEars;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Loading extends PlatformerGameScene
	{
		public function Loading()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/loading/";
			
			super.init(container);
		}
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			_events = super.events as CarrotEvents;
			
			super.loaded();
			
			super.addSystem( new BoxSystem(), SystemPriorities.update );
			
			_drone1 = super.getEntityById( _drone1_id );
			_systemPassword = super.getEntityById( "systemPassword" );
			super.shellApi.eventTriggered.add( onEventTriggered );
			
			if ( super.shellApi.checkEvent( _events.DESTROYED_RABBOT ))
			{
				super.removeEntity( super.getEntityById( "drone1" ));
				super.removeEntity( super.getEntityById( "interaction1" ));
			}
			
			else
			{
				if ( !super.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.SYSTEM_PASSWORD ))
				{
					var displayObject:MovieClip = EntityUtils.getDisplayObject( _systemPassword ) as MovieClip 
					TimelineUtils.convertClip( displayObject.itemsystemPassword, null, _systemPassword );
					
					if ( !super.shellApi.checkEvent( _events.DRONE_FREED_ + 1 ))
					{
						SceneInteraction(super.getEntityById("interaction1").get(SceneInteraction)).reached.add(sceneInteractionTriggered);
						
						Sleep( _systemPassword.get( Sleep )).ignoreOffscreenSleep = true;
						Sleep( _systemPassword.get( Sleep )).sleeping = true;
					}
					else
					{
						Timeline(_systemPassword.get( Timeline )).gotoAndStop("complete");
					}
				}
				else
				{
					super.removeEntity( super.getEntityById( "interaction1" ));
				}
			}
			
			setupCrates();
		}
		
		/**
		 * Listen for computer click
		 * @param	target
		 */
		private function sceneInteractionTriggered( character:Entity, interactionEntity:Entity):void
		{
			if( Id(interactionEntity.get(Id)).id == "interaction1")
			{
				super.shellApi.triggerEvent( _events.DRONE_DENIAL, false, false );
			}
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var spatial:Spatial;
			var dialog:Dialog;
			
			switch( event )
			{
				case _events.DRONE_FREE:
					SceneUtil.lockInput( this, true );
					spatial = _drone1.get( Spatial );
					SceneInteraction(super.getEntityById("interaction1").get(SceneInteraction)).reached.remove(sceneInteractionTriggered);					
					CharUtils.dialogComplete( _drone1, onDialogueComplete );	
					break;
				case GameEvent.GOT_ITEM + _events.SYSTEM_PASSWORD: 
					dialog = _drone1.get( Dialog );
					dialog.sayCurrent();
					super.removeEntity( super.getEntityById( "interaction1" ));
					break;
				case _events.DRONE_TRICKED_ + 1:
					spatial = _drone1.get( Spatial );
					spatial.scaleX *= -1;
				 	SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, Command.create( loadPopup, 1 )));	
					break;
				case GameEvent.GOT_ITEM + _events.SYSTEM_PASSWORD:
					onPrinterComplete();
					break;
			}
		}
		
		private function loadPopup( droneNum:int ):void
		{
			super.addChildGroup( new RabbotEars( super.overlayContainer, new Array( "drone_freed_", droneNum )));
		}
		
		private function onDialogueComplete( dialog:DialogData ):void
		{
			CharUtils.moveToTarget( _drone1, 680, 1643, false, onReachedTarget ).setDirectionOnReached( CharUtils.DIRECTION_LEFT );
		}
		
		private function onReachedTarget( char:Entity ):void
		{
			var sleep:Sleep = _systemPassword.get( Sleep );
			sleep.ignoreOffscreenSleep = false;
			sleep.sleeping = false;
			
			// play printer animation, listen for clip to reach end
			var timeline:Timeline = _systemPassword.get( Timeline );
			timeline.labelReached.add( onLabelReached );
			timeline.gotoAndPlay( "start" );
			super.shellApi.triggerEvent( _events.PRINTING_PAPER );
		}
		
		private function onLabelReached( label:String ):void
		{
			if ( label == "complete" )
			{
				onPrinterComplete();
			}
		}
		
		private function onPrinterComplete():void
		{
			SceneUtil.lockInput( this, false );
//			var motionControl:MotionControl = player.get( MotionControl );
//			motionControl.lockInput = false;
//			_drone1.add( new CharacterWander( 100 ));
		}

		//////////////////////////////////////////////////////////////
		//////////////////////////  CRATES  //////////////////////////
		//////////////////////////////////////////////////////////////
		
		/**
		 * There are 3 chutes that drop crates, since only one crates is visible at a time for each chute
		 * we create a single crate entity for each chute.
		 */
		private function setupCrates():void
		{
			var total:int = 3;

			var crateHit:Entity;
			var crateDisplay:Entity;
			var box:Box;
			var motion:Motion;
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			
			for(var i:int = 1; i <= total; i++) 
			{	
				crateHit = super.getEntityById( "crateHit" + ( i ));
				crateDisplay = super.getEntityById( "crate" + (i));
				EntityUtils.getDisplayObject(crateDisplay).mask = _hitContainer["crateMask"+i];
				
				var followTarget:FollowTarget = new FollowTarget( crateHit.get(Spatial) );
				followTarget.properties = new <String>["x", "y", "rotation" ];
				crateDisplay.add( followTarget );

				box = new Box( );
				box.chute = i;
				box.level = box.chute * 2;	// first chute has 2, second has 4, third has 6 
				box.currentLevel = box.level; // start at end so system handles start up
				box.start = crateHit.get( Spatial ).y;
				box.initVelocity = 300;
				box.waitTime = .8;
				box.target = box.start + 250;
				box.display = crateDisplay.get(Display);
				crateHit.add( box )
					
				motion = new Motion();
				crateHit.add( motion );

				var sleep:Sleep = crateHit.get(Sleep);
				sleep.ignoreOffscreenSleep = true;
				sleep.sleeping = false;
				
				audioGroup.addAudioToEntity( crateHit );
				crateHit.add( new AudioRange( 600, 0.01, 1 ));
			}
		}
	
		/*
		 * Pseudo code
		 * on drone freed, lock control, move to target (642, 1630)
		 * on reach target, call statement
		 * on statement complete, play print paper
		 * on print paper complete, create item
		 * on item get, play statement, restart npc wander
		*/
		private var _events:CarrotEvents;
		private var _systemPassword:Entity;
		private var _printer:Entity;
		private var _drone1_id:String = "drone1";
		private var _drone1:Entity;

	}
}
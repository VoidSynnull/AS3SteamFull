package game.scenes.carrot.robot
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.SpatialOffset;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.components.scene.SceneInteraction;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.scenes.carrot.CarrotEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PhotoGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.computer.Computer;
	import game.scenes.carrot.shared.rabbotEars.RabbotEars;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	public class Robot extends PlatformerGameScene
	{
		public function Robot()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/robot/";
			super.init(container);
		}
		
		override public function loaded():void
		{
			super.loaded();
			_events = super.events as CarrotEvents;
			_drHare = super.getEntityById("drHare");
			var sleep:Sleep = _drHare.get(Sleep);
			
			if( !shellApi.checkEvent( _events.DESTROYED_RABBOT ))
			{
				removeEntity( getEntityById( "ropeExit" ));
				var climb:Entity = getEntityById( "climb1" );
				removeEntity( getEntityById( "climb1" ));
			}
			
			if ( super.shellApi.checkEvent( _events.DESTROYED_RABBOT ) )
			{
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;
				super.removeEntity( super.getEntityById( "interaction1" ));
				super.removeEntity( super.getEntityById( "rabbot" ));
				
				if ( super.shellApi.checkEvent( _events.ALL_DRONES_FREE ))
				{
					super.removeEntity( super.getEntityById( "drone4" ));
				}
				else if ( !super.shellApi.checkEvent( _events.DRONE_CONGRATS ) )
				{
					//SceneUtil.lockInput(this, true, false);
					shellApi.triggerEvent( _events.DRONE_CONGRATS, true );
					SceneUtil.getDialogComplete( this ).addOnce( removeDrone );
				}

				var photoGroup:PhotoGroup =  super.getGroupById(PhotoGroup.GROUP_ID) as PhotoGroup;
				if( photoGroup )
				{
					photoGroup.takePhotoByEvent(_events.DESTROYED_RABBOT);
				}
			}
			else
			{
				super.shellApi.eventTriggered.add( onEventTriggered );
				
//				for( var i:int = 0; i < 2; i ++ )
//				{
//					setupRabbotHands( i );
//				}
				
//				var rotatingSystem:RotatingPlatformSystem = new RotatingPlatformSystem();
//				rotatingSystem._armMoved.add( armMoveHandler );
//				
//				super.addSystem( rotatingSystem );
				
				var sceneInt:SceneInteraction = super.getEntityById("interaction1").get(SceneInteraction);
				sceneInt.offsetY = 200;
				sceneInt.reached.add(sceneInteractionTriggered);
				
				if ( !super.shellApi.checkEvent( _events.DRHARE_TALK_TO ) )
				{
					initHoverPad();
					var spatial:Spatial = super.player.get( Spatial) as Spatial;
					SceneUtil.lockInput(this, true, false);
					CharUtils.moveToTarget( super.player, spatial.x + 100, spatial.y, false, queueHare );
				}
				else
				{
					sleep.sleeping = true;
					sleep.ignoreOffscreenSleep = true;
				}
			}
		}
		
		private function removeDrone( dialog:DialogData ):void
		{
			var drone:Entity = super.getEntityById("drone4");
			var sleep:Sleep = drone.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			
			var path:Vector.<Point> = new Vector.<Point>;
			path.push( new Point( 1400, 800 ));
			path.push( new Point (1418, 5 ));
			
			CharUtils.followPath( drone, path, onReachedTarget );
		}
		
		private function onReachedTarget( drone:Entity ):void
		{
			super.removeEntity( drone );
			super.shellApi.triggerEvent( _events.ALL_DRONES_FREE, true, true );
			SceneUtil.lockInput(this, false, false);
		}
		
		private function armMoveHandler( armID:String ):void
		{
			switch( armID )
			{
				case "handHit1":
					super.shellApi.triggerEvent( _events.MOVE_LEFT_HAND );
					break;
				case "handHit2":
					super.shellApi.triggerEvent( _events.MOVE_RIGHT_HAND );
					break;
			}
		}
		
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if ( event == _events.DRONE_TRICKED_ + 4 )
			{
				Spatial( Entity( super.getEntityById( "drone4" )).get( Spatial )).scaleX *= -1;
				SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, Command.create( loadPopup, 4 )));	
			}
		}
		
		private function loadPopup( droneNum:int ):void
		{
			super.addChildGroup( new RabbotEars( super.overlayContainer, new Array( "drone_freed_", droneNum )));
		}
		/**
		 * Create rotating platforms for the rabbot's hands
		 */
		private function setupRabbotHands( number:int ):void
		{
			var handHit:Entity = super.getEntityById( "handHit" + ( number + 1 ));
			var spatial:Spatial = handHit.get( Spatial );
			var motion:Motion = new Motion();
		
			handHit.remove( Sleep );
			var hand:Entity = EntityUtils.createMovingEntity( this, super._hitContainer[ "hand" + ( number + 1 )]);
			hand.add( motion );
			
			var rotationalPlatform:RotatingPlatform = new RotatingPlatform( spatial.x, spatial.y );
		
			rotationalPlatform.spatial = hand.get( Spatial );
			rotationalPlatform.motion = motion;
			handHit.add( rotationalPlatform );
			
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( handHit );
		}
		
		/**
		 * Create hoverPad and link drHare to it
		 */
		private function initHoverPad():void
		{
			_hoverPad = EntityUtils.createSpatialEntity( this, super.getAsset( "hoverPad.swf" ), super._hitContainer );
			Display( _hoverPad.get(Display)).moveToBack();					// move display to back
			EntityUtils.positionByEntity( _hoverPad, _drHare );				// move to drHare's position
			_hoverPad.add( new SpatialOffset( 0, Edge(super.player.get(Edge)).rectangle.bottom ) ); 	// offset to account for char's center not being at feet
			MotionUtils.addWaveMotion(_hoverPad, new WaveMotionData( "y", 6, .05 ), this); // add wave motion
			
			EntityUtils.followTarget( _drHare, _hoverPad );  
			
			_drHare.add( _hoverPad.get( SpatialAddition ) );		// share effects of wave motion with drHare
		}
		
		private function queueHare( entity:Entity = null ):void
		{
			super.shellApi.triggerEvent( _events.DRHARE_TALK_TO, true );
			Dialog(_drHare.get(Dialog)).sayById("drhare_talks");
			SceneUtil.getDialogComplete(this).addOnce( readyHare );
		}

		private function readyHare( dialog:DialogData ):void
		{
			Dialog(_drHare.get(Dialog)).sayById("drhare_move_it");
			SceneUtil.getDialogComplete(this).addOnce( onHareDialogComplete );
		}
		/**
		 * When drHare dialogue finishes move hoverPad and remove after a time
		 * @param	dialog
		 */
		private function onHareDialogComplete( dialog:DialogData ):void
		{
			//CharUtils.lockControls( super.player, false, false );
			SceneUtil.lockInput(this, false, false);
			// move hoverPad up
			var motion:Motion =  new Motion();
			motion.acceleration.y = -600;	// TODO :: will want to replace this with transition
			_hoverPad.add( motion );
			
			super.shellApi.triggerEvent( _events.RAISE_PLATFORM );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, onHareGone) );
		}
					
		/**
		 * Unlock control, remove drHare & hoverPad
		 */
		private function onHareGone():void
		{
			super.removeEntity( _hoverPad );
			super.removeEntity( _drHare );
		}
		
		/**
		 * Listen for computer click
		 * @param	target
		 */
		private function sceneInteractionTriggered( character:Entity, interactionEntity:Entity):void
		{
			if( Id(interactionEntity.get(Id)).id == "interaction1")
			{
				// check for drone freed
				if ( super.shellApi.checkEvent( _events.DRONE_FREED_ + 4 ) )
				{
					var display:Display = interactionEntity.get(Display);
					var bounds:Rectangle = display.displayObject.getBounds(display.displayObject.parent);
					bounds.inflate(200, 100);
					var sp:Spatial = character.get(Spatial) as Spatial;
					if (bounds.contains(sp.x, sp.y)) 
					{
						super.shellApi.loadScene( Computer );
					}
				}
				else
				{
					// deny access
					super.shellApi.triggerEvent( _events.DRONE_DENIAL, false, false );
				}
			}
		}

		private var _events:CarrotEvents;
		private var _hoverPad:Entity;
		private var _drHare:Entity;
	}
}
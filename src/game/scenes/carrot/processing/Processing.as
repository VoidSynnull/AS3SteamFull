package game.scenes.carrot.processing
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.TransportGroup;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.motion.RotateControl;
	import game.components.motion.Spring;
	import game.components.motion.TargetSpatial;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.scene.hit.MovingHitData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.carrot.freezer.Freezer;
	import game.scenes.carrot.processing.components.Dial;
	import game.scenes.carrot.processing.systems.DialSystem;
	import game.scenes.carrot.shared.rabbotEars.RabbotEars;
	import game.systems.SystemPriorities;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	
	public class Processing extends PlatformerGameScene
	{
		public function Processing()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/processing/";
			super.init(container);
			
			_transportGroup = super.addChildGroup( new TransportGroup() ) as TransportGroup;
			_transportGroup.targetScene = Freezer;
		}
		
		override public function loaded():void
		{
			super.loaded();
			_events = super.events as CarrotEvents;
			_caught = false;
			
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			super.addSystem( new WaveMotionSystem() );
			
			var securityPanel:MovieClip = MovieClip( super._hitContainer ).securityPanel;
			var audioGroup:AudioGroup;
			
			if ( super.shellApi.checkEvent( _events.DESTROYED_RABBOT ))
			{
				super.removeEntity( super.getEntityById( "drone2" ));
				super.removeEntity( super.getEntityById( "drone3" ));
			}
			
			if ( !super.shellApi.checkEvent( _events.SECURITY_DISABLED ) )
			{
				securityPanel.gotoAndStop(1);
				createBunnyCam( true );
				var zoneHitEntity:Entity = super.getEntityById("zoneLight");
				var zoneHit:Zone = zoneHitEntity.get(Zone);
				zoneHit.shapeHit = true;
				zoneHit.entered.add(onZoneEntered);
				
				audioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
				audioGroup.addAudioToEntity( zoneHitEntity );
			}
			else
			{
				securityPanel.gotoAndStop(2);
				createBunnyCam( false );
			}
			
			// turn off exit door lights
			_lightRed = MovieClip(super._hitContainer).lightRed;
			_lightGreen = MovieClip(super._hitContainer).lightGreen;
			_lightRed.gotoAndStop(1);
			_lightGreen.gotoAndStop(1);
			
			
			// trapdoor
			_trapDoorHit = super.getEntityById("platformTrap");
			_trapDoor = TimelineUtils.convertClip( MovieClip(super._hitContainer).trapDoor, this );
			//super.addEntity( _trapDoor );
			
			// security door
			var doorSecurity:Entity = super.getEntityById("doorSecurity");
			SceneInteraction(doorSecurity.get(SceneInteraction)).reached.removeAll();
			SceneInteraction(doorSecurity.get(SceneInteraction)).reached.add(doorReached);
			
			// setup tornado and dial
			_tornado = new Vector.<Entity>;
			var tornadoSeg:Entity;
			var wave:WaveMotion;
			
			for ( var i:int = 0; i < 9; i ++ )
			{
				wave = new WaveMotion();
				wave.add( new WaveMotionData( "x", i * 3, .05 ));
				tornadoSeg = EntityUtils.createMovingEntity( this, super._hitContainer[ "tornado" ][ "t" + ( i + 1 )]);
				Spatial( tornadoSeg.get( Spatial )).scaleX = 0;
				tornadoSeg.add( wave );
				tornadoSeg.add(new SpatialAddition());
				_tornado.push( tornadoSeg );
			}

			var interactionEnt:Entity = super.getEntityById( "interaction" );
			var doorTrap:Entity = super.getEntityById( "doorTrap" );
			var sleep:Sleep = doorTrap.get(Sleep);
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = false;
			
			
		//////////////////////////////////////////////////////////		
			var dial:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "interaction" ]);
			dial.add( new Dial() );

			dial.get( Spatial ).rotation = -50;
			interactionEnt.get( SceneInteraction ).offsetY = 50;
			var btnClip:MovieClip = MovieClip( EntityUtils.getDisplayObject( dial ));
			var dialButton:Entity = ButtonCreator.createButtonEntity( btnClip, this );
			var interaction:Interaction = Interaction( dialButton.get( Interaction ));
			
			var targetSpatial:TargetSpatial =  new TargetSpatial( shellApi.inputEntity.get( Spatial ) );
			dial.add( targetSpatial );
			
			_rotateControl = new RotateControl();
			_rotateControl.targetInLocal = true;
			
			this.addSystem( new RotateToTargetSystem() );
			
			interaction.down.add( Command.create( dialTurned, dial ));
			interaction.up.add( Command.create( stopDialTurn, dial ));
			interaction.out.add( Command.create( stopDialTurn, dial ));

			var dialSystem:DialSystem = new DialSystem();
			dialSystem.moved.add( updateVortex );
			super.addSystem( dialSystem );
			
		//////////////////////////////////////////////////////////		
			
			audioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( interactionEnt );
			
			// create carrot buckets 
			super.addSystem( new ThresholdSystem() );
			createBuckets( );			
			
			// listen for rabbot ear popups
			super.shellApi.eventTriggered.add( onEventTriggered );
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if ( event == _events.DRONE_TRICKED_ + 2 )
			{
				Spatial( Entity( super.getEntityById( "drone2" )).get( Spatial )).scaleX *= -1;
				SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, Command.create( loadPopup, 2 )));	
			}
			else if ( event == _events.DRONE_TRICKED_ + 3 )
			{
				Spatial( Entity( super.getEntityById( "drone3" )).get( Spatial )).scaleX *= -1;
				SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, Command.create( loadPopup, 3 )));	
			}
		}
		
		private function loadPopup( droneNum:int ):void
		{
			super.addChildGroup( new RabbotEars( super.overlayContainer, new Array( "drone_freed_", droneNum )));
		}
		
		private function dialTurned( button:Entity, dial:Entity ):void
		{
			dial.add( _rotateControl );	
		}
		
		private function stopDialTurn( button:Entity, dial:Entity ):void
		{
			dial.remove( RotateControl );
			DialSystem ( super.getSystem( DialSystem )).ready = true;
		}
		
		private function updateVortex( label:String ):void
		{
			var segment:Entity;
			var spatial:Spatial;
			var wave:WaveMotion;
			var waveData:WaveMotionData;
			var step:Number; 
			
			for ( var i:int = 0; i < _tornado.length; i++ )
			{
				segment = _tornado[ i ];
				spatial = segment.get( Spatial );
				wave = segment.get( WaveMotion );
				waveData = wave.data[0];
				
				step = i / 30;
				waveData.magnitude = i * step;
				
				switch( label )
				{	
					case "off":
						spatial.scaleX = 0;
						break;
					case "mix":
						spatial.scaleX = 1 + step;
						waveData.rate = .01 - step;
						break;
					case "blend":
						spatial.scaleX = 1.5 + ( 5 * step );
						waveData.rate = .015 - step;
						break;
					case "liquify":
						spatial.scaleX = 2 + ( 10 * step );	
						waveData.rate = .02 - step;
						break;
					case "vaporize":
						spatial.scaleX = 3 + ( 15 * step );
						waveData.rate = .03 - step;					
						break;
				}
			}
			
			switch ( label )
			{
				case "off":
					super.shellApi.triggerEvent( _events.SET_OFF );
					break;
				case "mix":
					super.shellApi.triggerEvent( _events.SET_TO_MIX );
					break;
				case "blend":
					super.shellApi.triggerEvent( _events.SET_TO_BLEND );
					break;
				case "liquify":
					super.shellApi.triggerEvent( _events.SET_TO_LIQUIFY );
					break;
				case "vaporize":
					super.shellApi.triggerEvent( _events.SET_TO_VAPORIZE );
					break;
			}
		}
	/*	private function dialTurned( char:Entity, dial:Entity ):void
		{
			if ( spatial.rotation == -17 )
			{
				spatial.rotation = 18;
				updateVortex( "mix" );
			}
			else if ( spatial.rotation == 18 )
			{
				spatial.rotation = 60;
				updateVortex( "blend" );
			}
			else if ( spatial.rotation == 60 )
			{
				spatial.rotation = 115;
				updateVortex( "liquify" );
			}
			else if ( spatial.rotation == 115 )
			{
				spatial.rotation = 180;
				updateVortex( "vaporize" );
			}
			else if ( spatial.rotation == 180 )
			{
				spatial.rotation = -17;
				updateVortex( "off" );
			}
			var targetRotation:Number = spatial.rotation;		
			
			TweenLite.to( mc, .2, { rotation: targetRotation });
			
		}*/
				
		
		
		private function onZoneEntered( zoneId:String, characterId:String ):void
		{
			if( zoneId == "zoneLight" && !_caught )
			{
				super.shellApi.triggerEvent( _events.PLAYER_SURRENDER );
				_caught = true;
				_transportGroup.transportOut(player);
			}
		}
		
		// handle what happens when security door is reached, does trapdoor open or not.
		private function doorReached(entity:Entity, door:Entity):void
		{
			if ( !super.shellApi.checkEvent( _events.DESTROYED_RABBOT ) )
			{
				// lock controls
				SceneUtil.lockInput( this );
				
				/*
				Change the player's MotionBounds to confine them to the hole where the trapdoor is.
				Should prevent the player from moving away from the hole in the event they click the door too high and start jumping.
				*/
				var trapdoor:Entity = this.getEntityById( "doorTrap" );
				var display:DisplayObject = Display(trapdoor.get(Display)).displayObject;
				var trapdoorBounds:Rectangle = display.getBounds(display.parent);
				var bounds:MotionBounds = player.get(MotionBounds);
				bounds.box = bounds.box.clone();
				bounds.box.left = trapdoorBounds.left + 20;
				bounds.box.right = trapdoorBounds.right - 20;
				
				// check to see if player is wearig the drone ears
				if ( SkinUtils.getSkinPart( super.player, SkinUtils.FACIAL ).value == "rabbitcon2" )
				{
					// turn on green light
					_lightGreen.gotoAndStop(2);
					Door(door.get(Door)).open = true;
				}
				else
				{
					// turn on red light
					_lightRed.gotoAndStop(2);
					var timeline:Timeline =  _trapDoor.get(Timeline);
					timeline.handleLabel( "opened", onOpened, true );
					Timeline( _trapDoor.get(Timeline) ).gotoAndPlay("open");
					super.shellApi.triggerEvent( _events.FELL_IN_TRAP );
				}
			}
			else
			{
				_lightGreen.gotoAndStop(2);
				Door(door.get(Door)).open = true;
			}
		}
		
		private function onOpened():void
		{
			_trapDoorHit.remove( Platform );
		}
		
				
		//////////////////////////////////////////////////////////////
		/////////////////////// CARROT BUCKETS ///////////////////////
		//////////////////////////////////////////////////////////////
		
		private function createBuckets( ):void
		{
			var numBuckets:int = 2;	
			var numCarrots:int = 8;
			
			var bucket:Entity;
			var bucketDisplay:Entity;
			var axel:Entity;
			var displayObject:MovieClip;
			
			for( var i:int = 0; i < numBuckets; i++ )
			{	
				bucket = super.getEntityById( "bucketHit" + ( i + 1 ));
				bucketDisplay = super.getEntityById( "bucket" + ( i + 1 ));
				
				bucket.remove( MovingHitData );
				bucket.add( new Children());
				
				displayObject = EntityUtils.getDisplayObject( bucketDisplay ) as MovieClip;
				axel = EntityUtils.createMovingEntity( this, displayObject.pully );
				
				for ( var j:int = 0; j <  numCarrots; j++ )
				{
					super.loadFile( "carrot.swf", onCarrotLoaded, bucket, bucketDisplay );
				}
				
				super.shellApi.triggerEvent( _events.BUCKET_FULL_ + ( i + 1 ));
				bucketMove( bucket, bucketDisplay, axel, 1 );
			}
		}
		
		private function bucketReachedMidpoint( bucket:Entity, bucketDisplay:Entity, axel:Entity ):void
		{
			var motion:Motion = bucket.get( Motion );
			var axelMotion:Motion = axel.get( Motion );
			var children:Children = bucket.get( Children );
			var id:Id = bucket.get(Id);
			
			var bucketNum:int = int(id.id.charAt(id.id.length - 1));
						
			for each ( var carrot:Entity in children.children )
			{
				SceneUtil.addTimedEvent(this, new TimedEvent( Math.random() / 2, 1, Command.create( dropCarrots, carrot )));
			}
			
			super.shellApi.triggerEvent( _events.BUCKET_EMPTY_ + bucketNum );
			super.shellApi.removeEvent( _events.BUCKET_FULL_ + bucketNum );
			motion.velocity.x = 0;
			axelMotion.rotationVelocity = 0;
			
			SceneUtil.addTimedEvent( super, new TimedEvent( 3, 1, Command.create( bucketMove, bucket, bucketDisplay, axel, 2 )));	
		}
		
		private function dropCarrots( carrot:Entity ):void	
		{
			var threshold:Threshold;
			var carrotMotion:Motion = new Motion();
			
			threshold = new Threshold( "y", ">" );
			carrotMotion = carrot.get( Motion );
			
			carrotMotion.acceleration.y = 450;
			carrotMotion.maxVelocity = new Point( 0, 700 ); 
			
			threshold.threshold = 235;
			threshold.entered.add( Command.create( stopCarrot, carrot ));
			carrot.add( threshold );
		}
		
		private function bucketMove( bucket:Entity, bucketDisplay:Entity, axel:Entity, state:uint ):void
		{
			var motion:Motion = bucket.get( Motion );
			var spatial:Spatial = bucket.get( Spatial );
			var axelMotion:Motion = axel.get( Motion );
			
			var threshold:Threshold = new Threshold( "x", ">" );
			
			// first half of journey
			if ( state == 1 )
			{
				resetCarrots( bucket );
				motion.velocity.x = 100;
				axelMotion.rotationVelocity = 100;
				threshold.threshold = 1705;
				threshold.entered.addOnce( Command.create( bucketReachedMidpoint, bucket, bucketDisplay, axel ));
				bucket.add( threshold );
			}
			// second half of journey
			else if ( state == 2 )
			{
				motion.velocity.x = 100;
				axelMotion.rotationVelocity = 100;
				threshold.threshold = 3411;
				threshold.entered.addOnce( Command.create( bucketMove, bucket, bucketDisplay, axel, 3 ));
				bucket.add( threshold );
			}
			// reset
			else if ( state == 3 )
			{
				spatial.x = 0;
				bucketMove( bucket, bucketDisplay, axel, 1 );
			}
		}

		private function onCarrotLoaded( asset:DisplayObjectContainer, bucket:Entity, bucketDisplay:Entity ):void
		{
			var display:Display = bucketDisplay.get( Display );
			var spatial:Spatial = bucket.get( Spatial );
			var children:Children = bucket.get( Children );
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			
			var carrot:Entity = EntityUtils.createMovingEntity( this, asset, MovieClip( display.displayObject ).carrotContainer );	// TODO :: want to put behind foreground?

			var carrotDisplay:Display = carrot.get( Display );
			var carrotSpatial:Spatial = carrot.get( Spatial );
			var carrotMotion:Motion = carrot.get( Motion );
			
			carrotMotion.velocity.y = 0;
			carrotMotion.acceleration.y = 0;
				
			carrotSpatial.x = ( Math.random() * 100 )  - 50 ;
			carrotSpatial.y = 0;
			carrotSpatial.rotation = ( Math.random() * 360 );
			carrot.add( sleep );
			
			children.children.push( carrot );		
		}
			
		private function stopCarrot( carrot:Entity ):void 
		{
			var carrotSpatial:Spatial = carrot.get( Spatial );
			var sleep:Sleep = carrot.get( Sleep );

			carrot.remove( Threshold );
			carrot.remove( Motion );
			sleep.sleeping = true;
		}
		
		private function resetCarrots( bucket:Entity ):void 
		{
			var children:Children = bucket.get( Children );
			var bucketNum:Number = bucket.get( Number );
			
			var carrotSpatial:Spatial = new Spatial();
			
			var carrotDisplay:Display = new Display();
			var sleep:Sleep = new Sleep();
			
			for each ( var carrot:Entity in children.children )
			{
				var carrotMotion:Motion = new Motion();
				carrot.add( carrotMotion );
				carrotDisplay = carrot.get( Display );
				carrotSpatial = carrot.get( Spatial );
				sleep = carrot.get( Sleep );
				sleep.sleeping = false;
				
				carrotMotion.velocity.y = 0;
				carrotMotion.acceleration.y = 0;
		
				carrotSpatial.x = ( Math.random() * 100 ) - 50 ;
				carrotSpatial.y = 0;
				carrotSpatial.rotation = ( Math.random() * 360 );
			}
			
			super.shellApi.removeEvent( _events.BUCKET_EMPTY_ + bucketNum );
			super.shellApi.triggerEvent( _events.BUCKET_FULL_ + bucketNum );
		}
		
		//////////////////////////////////////////////////////////////
		////////////////////////// BUNNYCAM //////////////////////////
		//////////////////////////////////////////////////////////////
		
		private function createBunnyCam( enabled:Boolean ):void
		{
			_bunnyCam = EntityUtils.createMovingEntity( this, super.getAsset("bunnyCam.swf", true) as MovieClip, super._hitContainer );	// TODO :: want to put behind foreground?
			EntityUtils.position( _bunnyCam, 837, 1272 );
			
			// hide & stop internal movieclips
			bunnyCamActive( false );
			
			if ( enabled )
			{
				var threshold:Threshold = new Threshold( "y", ">", _bunnyCam, -400 );
				threshold.entered.addOnce( bunnyCamStart );
				
				super.player.add( threshold );
			}
		}

		private function bunnyCamStart():void
		{
			_bunnyCam.remove( Threshold );
			bunnyCamActive( true );
			
			_bunnyCam.add( new Id( "bunnyCam" ));

			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( _bunnyCam );
			
			super.shellApi.triggerEvent( _events.CAM_ACTIVE );
			var spatial:Spatial = super.player.get( Spatial );
			var spring:Spring = new Spring( spatial, .6, .09 );
			
			spring.offsetY = -200;
			spring.startPositioned = false;
			spring.rotateByVelocity = true;
			spring.rotateRatio = .5;
			spring.threshold = 8;
			
			spring.reachedLeader.addOnce( onReachedPlayer );
			_bunnyCam.add( spring );
		}
		
		private function onReachedPlayer():void
		{
			// TODO :: play zap animation
			
			_bunnyCam.remove( Spring );
			EntityUtils.stopFollowTarget( _bunnyCam );
			
			if( !_caught )
			{
				_caught = true;
				Timeline(_zap.get(Timeline)).gotoAndPlay("start");
				
				_zap.add( new Id( "zap" ));
				var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
				audioGroup.addAudioToEntity( _zap );
				
				super.shellApi.triggerEvent( _events.PLAYER_CAUGHT );	
	
				_transportGroup.transportOut(player);
			}
		}
		
		private function bunnyCamActive( bool:Boolean ):void
		{
			var displayObject:MovieClip = EntityUtils.getDisplayObject( _bunnyCam ) as MovieClip;
			
			if ( !bool )
			{
				// hide certain content
				displayObject.content.visible = false;
				displayObject.content.ear_R.visible = false;
				displayObject.content.ear_L.visible = false;
				displayObject.content.head.siren.visible = false;
				displayObject.content.zap.visible = false;
				
				displayObject.content.ear_R.stop();
				displayObject.content.ear_L.stop();
				displayObject.content.head.siren.stop();
				displayObject.content.zap.stop();
			}
			else
			{
				// unhide certain content
				displayObject.content.visible = true;
				displayObject.content.ear_R.visible = true;
				displayObject.content.ear_L.visible = true;
				displayObject.content.head.siren.visible = true;
				displayObject.content.zap.visible = true;
				
				// create timeline entities
				TimelineUtils.convertClip( displayObject.content.ear_R, this, null, _bunnyCam );
				TimelineUtils.convertClip( displayObject.content.ear_L, this, null, _bunnyCam );
				TimelineUtils.convertClip( displayObject.content.head.siren, this, null, _bunnyCam );
				_zap = TimelineUtils.convertClip( displayObject.content.zap, this, null, _bunnyCam );
			}
		}

		private var _events:CarrotEvents;
		private var _caught:Boolean;
		private var _bunnyCam:Entity;
		private var _zap:Entity;
		private var _trapDoor:Entity;
		private var _trapDoorHit:Entity;
		
		private var _lightRed:MovieClip;
		private var _lightGreen:MovieClip;
		
		private var _tornado:Vector.<Entity>;
		
		private var _rotateControl:RotateControl;
		private var _transportGroup:TransportGroup;
	}
}
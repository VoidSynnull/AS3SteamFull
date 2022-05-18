package game.scenes.carrot.smelter
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.hit.Mover;
	import game.components.hit.Wall;
	import game.components.motion.ShakeMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.managers.EntityPool;
	import game.scene.template.AudioGroup;
	import game.scene.template.PhotoGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.carrot.processing.Processing;
	import game.scenes.carrot.smelter.components.Conveyor;
	import game.scenes.carrot.smelter.components.ConveyorControlComponent;
	import game.scenes.carrot.smelter.components.Molten;
	import game.scenes.carrot.smelter.components.PressedLeadComponent;
	import game.scenes.carrot.smelter.components.Smasher;
	import game.scenes.carrot.smelter.systems.ConveyorSystem;
	import game.scenes.carrot.smelter.systems.MoltenSystem;
	import game.scenes.carrot.smelter.systems.PressedLeadSystem;
	import game.scenes.carrot.smelter.systems.SmasherSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	
	public class Smelter extends PlatformerGameScene
	{
		public function Smelter()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/smelter/";
			
			super.init(container);
			
			_entityPool = new EntityPool();
			_total = new Dictionary();
		}
						
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			var audioGroup:AudioGroup;
			
			_events = super.events as CarrotEvents;
			
			_rods = new Vector.<Entity>();
			
			_conveyorControl = new ConveyorControlComponent();
			_conveyorControl.moving = false;
			_conveyorControl.stopped = false;
			_squished = false;
			
			setupConveyor();
			setupSmashers();
			createMolten();
			
			//super.shellApi.eventTriggered.add( eventTriggers );
			
			for ( var number:int = 0; number < 2; number ++ )
			{
				var squirter:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "squirter" + ( number + 1 )]);
					
				squirter.add( new Id( "squirter" + ( number + 1 )));
				audioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
				audioGroup.addAudioToEntity( squirter );
			}
			
			_highQuality = ( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST ) ? false : true;
			
			if( _highQuality )
			{
				addSystem( new ShakeMotionSystem());
			}
			
			var smasherSystem:SmasherSystem = new SmasherSystem();
			smasherSystem._squished.add( squishPlayer );
			smasherSystem._unsquished.add( unsquishPlayer );
			
			super.addSystem( new TimelineClipSystem());
			super.addSystem( new ConveyorSystem( _conveyorControl ));
			super.addSystem( smasherSystem );
			super.addSystem( new PressedLeadSystem( _conveyorControl, _entityPool, _total ));
			super.addSystem( new MoltenSystem( _conveyorControl, _entityPool, _total ));	
			
			_total[ "molten" ] = 0;
			_total[ "leadInner" ] = 0;
			_total[ "leadOutter" ] = 0;
			
			var smasher:Smasher;
			for( var i:int = 0; i < _rods.length; i++ )
			{
				smasher = _rods[i].get( Smasher );
				Timeline( _rods[i].get( Timeline )).gotoAndStop( "start_up" );
				smasher.state = smasher.PAUSE_DOWN;
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, mainHandler ));
		}
		/*
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if ( event == GameEvent.GOT_ITEM + _events.DRONE_EARS ) 
			{
				// if taking photo, interrupt SceneInteraction so photo can display before player leaves scene 
				if( shellApi.takePhoto("11713", photoFinished) )
				{
					var door:Entity = getEntityById( "door1" );
					var sceneInteraction:SceneInteraction = door.get( SceneInteraction );
					sceneInteraction.reached.removeAll();
				}
			}
		}
		
		private function photoFinished( ):void
		{
			var door:Entity = getEntityById( "door1" );
			var sceneInteraction:SceneInteraction = door.get( SceneInteraction );
			sceneInteraction.reached.addOnce( loadProcessing );
		}
		*/
		
		private function loadProcessing( ...args ):void
		{
			shellApi.loadScene( Processing, 1166, 1400 ); 
		}
	
		/////////////////////////////////////////////////////////////
		////////////////   CONVEYOR BELT AND GEARS   ////////////////
		/////////////////////////////////////////////////////////////
		
		// set gears and conveyor belt to be handled by ConveyorSystem using a flag to deliniate between
		private function setupConveyor():void 
		{		
			var gear:Entity;
			var belt:Entity;
			var conveyor:Conveyor;
			
			for ( var number:int = 0; number < 11; number++ )
			{
				gear = EntityUtils.createMovingEntity( this, super._hitContainer[ "gear" + ( number + 1 )]);
				
				conveyor = new Conveyor();
				conveyor.gears = true;
				conveyor.motion = gear.get( Motion );
				
				gear.add( conveyor );
			}
			
			conveyor = new Conveyor();
			conveyor.gears = false;
			
			belt = super.getEntityById( "conveyorBelt" );
			belt.add( conveyor );
			conveyor.mover = belt.get( Mover );
		
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( belt );
		}
		
		/////////////////////////////////////////////////////////////
		////////////////////////   SMASHERS   ///////////////////////
		/////////////////////////////////////////////////////////////
		
		// sets the walls, zones and smashers to be handled by the SmasherSystem
			// smasher is actually handled mostly by the scene AS by interacting with the timeline 
		private function setupSmashers():void
		{
			var number:int;
			var cap:Entity;
			var wall:Entity;
			var timeClipSys:TimelineClipSystem;
			var movieClip:MovieClip;
			var rod:Entity;
			var smasher:Smasher;
			var timeline:Timeline;
			
			for (number = 0; number < 2; number++ )			
			{
				//  Create smasher rod with timeline
				timeClipSys = new TimelineClipSystem();
				movieClip = super._hitContainer[ "smasher" + ( number + 1 )] as MovieClip;
				rod = TimelineUtils.convertClip( movieClip );
				
				smasher = new Smasher();
				if( number == 1 )
				{
					smasher.innerSmasher = false;
				}
				
				timeline = rod.get( Timeline );
				timeline.labelReached.add( Command.create( labelHandler, rod ));
				
				cap = EntityUtils.createMovingEntity( this, super._hitContainer[ "ceiling" + ( number + 1 )]);
				smasher.capSpatial = cap.get( Spatial );
				smasher.capMotion = cap.get( Motion );
				
				wall = EntityUtils.createMovingEntity( this, super._hitContainer[ "wall" + ( number + 1 )]);
				wall.add( new Wall( ));
				smasher.wallSpatial = wall.get( Spatial );
				smasher.wallMotion = wall.get( Motion );
				
				// Hide hit displays
				Display( cap.get( Display )).visible = false;
				Display( wall.get( Display )).visible = false;
		
				rod.add( smasher );
				super.addEntity( rod );
				_rods.push( rod );
			}
			// move player behind pistons
			super._hitContainer.swapChildren( Display( shellApi.player.get( Display )).displayObject,  super._hitContainer[ "playerEmpty" ]);
		}

		private function labelHandler( label:String, rod:Entity ):void
		{
			var timeline:Timeline = rod.get( Timeline );
			var smasher:Smasher = rod.get( Smasher );
			var entity:Entity;
			var lead:PressedLeadComponent;
			var sleep:Sleep;
			
			switch( label )
			{
			 	case smasher.PAUSE_DOWN:
					if ( timeline.paused == false )
					{
						timeline.paused = true;
						smasher.state = smasher.PAUSE_DOWN; 
						_conveyorControl.stopped = true;
						
						if( smasher.innerSmasher )
						{
							entity = _entityPool.request( "leadInner" );
							_total[ "leadInner" ] ++;
						}
						else
						{
							entity = _entityPool.request( "leadOutter" );
							_total[ "leadOutter" ] ++;
						}
						lead = entity.get( PressedLeadComponent );
						
						sleep = entity.get( Sleep );
						sleep.sleeping = false;
						EntityUtils.position( entity, lead.startX, lead.startY );
						
						if( _highQuality )
						{
							shakeScene();
						}
					}
					break;
				
				case smasher.PAUSE_UP:
					if ( timeline.paused == false )
					{
						timeline.paused = true;
						smasher.state = smasher.PAUSE_UP;
					}
					break;
			}
		}
		
		private function smashDown( ):void
		{
			var smasher:Smasher;
			for( var i:int = 0; i < _rods.length; i++ )
			{
				super.shellApi.triggerEvent( _events.SMASHER_HIT );
				smasher = _rods[i].get( Smasher );
				smasher.state = smasher.START_DOWN;
				Timeline( _rods[i].get( Timeline )).paused = false;
			}
			mainHandler( "down" );	
		}
		
		
		//////////////////////////////////////////////////////////////
		/////////////////////////   ZONES   //////////////////////////
		//////////////////////////////////////////////////////////////
	
		private function squishPlayer():void
		{
			super.shellApi.triggerEvent( _events.SQUISHED );
			if( ! super.shellApi.player.get( Tween ))
			{
				super.player.add( new Tween());
			}
		}
		
		// run when user is getting un-squashed hard code the SpatialOffset and Spatial scale
		private function unsquishPlayer( ):void 
		{
			var spatial:Spatial = super.player.get( Spatial );
			
			spatial.scaleY = .05;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, returnOriginal ));
		}
			
		// run after 2 seconds to unsquish and tween to normal from current SpatialOffset and Spatial scale
		private function returnOriginal():void
		{
			var spatial:Spatial = super.player.get( Spatial );
			
			var tween:Tween = player.get( Tween );
			if( tween )
			{
				trace( tween.getTweenByName( "teleport" ));
				if(! tween.getTweenByName( "teleport" ))
				{
					tween = new Tween();
					tween.to( spatial, 2, {  scaleY : .36 });
					
					super.player.add( tween );
				}
			}
			CharUtils.lockControls( super.player, false, false );
			
			super.shellApi.triggerEvent( "unsquished" );
	//		SceneUtil.lockInput(this, false, false);
			_squished = false;
		}

		//////////////////////////////////////////////////////////////
		/////////////////////////   MOLTEN   /////////////////////////
		//////////////////////////////////////////////////////////////
		
		public function createMolten():void
		{
			var clip:MovieClip;
			var entity:Entity;
			var startX:Array = [ 797, 1475 ];
			var startY:Number = 527;
			var wrapper:BitmapWrapper;
			var molten:Molten;
			var lead:PressedLeadComponent;
			var hitData:HazardHitData;
			var sleep:Sleep;
			var hitCreator:HitCreator = new HitCreator();
			var sparks:Sparks;
			
			clip = _hitContainer[ "molten" ];	
			var outter:int;
			var inner:int;
			var hex:uint;
			
			// liquid molten
		    for( outter = 0; outter < 20; outter ++ )
			{
				startY -= 1;
				for( inner = 0; inner < 2; inner++ )
				{
					wrapper = DisplayUtils.convertToBitmapSprite(clip, null, 1, false, _hitContainer[ "emptyMolten" ]);
					//wrapper = DisplayUtils.convertToBitmapSprite( clip, true, 0, _hitContainer[ "emptyMolten" ], null, false );
					wrapper.sprite.x = startX[ inner ];
					wrapper.sprite.y = startY;
					
					if( Math.random() < .5 )
					{
						wrapper.sprite.scaleX = wrapper.sprite.scaleY -= Math.random() * .15;
					}
					else
					{
						wrapper.sprite.scaleX = wrapper.sprite.scaleY += Math.random() * .15;
					}

					wrapper.sprite.alpha = 1;
					entity = EntityUtils.createMovingEntity( this, wrapper.sprite, _hitContainer[ "emptyMolten" ]);
					entity.add( new Id( "molten" + outter + "." + inner ));
					
					sleep = new Sleep();
					sleep.sleeping = true;
					sleep.ignoreOffscreenSleep = true;
					entity.add( sleep );
					
					hitData = new HazardHitData();
					hitData.knockBackVelocity = new Point( 1000, 500 );
					
					hitCreator.makeHit( entity, HitType.HAZARD, hitData, this );
					
					molten = new Molten();
					molten.startX = startX[ inner ];
					molten.startY = startY;
					molten.originColor = wrapper.sprite.transform.colorTransform;
					
					hex = 0xC10000;
					molten.redColor = new ColorTransform( 1, 0, 0, 1, 0, 0 );
					molten.redColor.redOffset = (hex >> 16) & 0xC1;
					molten.redColor.greenOffset = (hex >> 8) & 0x00;
					molten.redColor.blueOffset = hex & 0x00;
					
					hex = 0xFFFFFF;
					molten.whiteColor = new ColorTransform( 1, 1, 1, 1, 0 );
					molten.whiteColor.redOffset = (hex >> 16) & 0xFF;
					molten.whiteColor.greenOffset = (hex >> 8) & 0xFF;
					molten.whiteColor.blueOffset = hex & 0xFF;
					
					entity.add( molten );
					_entityPool.release( entity, "molten" );
				}
			}
			
			startX = [ 500, 1130 ];
			startY = 753;
			clip = _hitContainer[ "sheetMetal" ];
			
			// pressed lead
			for( inner = 0; inner < 5; inner ++ )
			{
				wrapper = DisplayUtils.convertToBitmapSprite(clip, null, 1, false, _hitContainer[ "leadEmpty" ]);

				wrapper.sprite.x = startX[ 0 ];
				wrapper.sprite.y = startY;
				
				wrapper.sprite.alpha = 1;
				entity = EntityUtils.createMovingEntity( this, wrapper.sprite, _hitContainer[ "leadEmpty" ]);
				entity.add( new Id( "leadInner" + inner ));
				
				sleep = new Sleep();
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;
				entity.add( sleep );
				
				lead = new PressedLeadComponent();
				lead.innerSide = true;
				lead.startY = startY;
				lead.startX = startX[ 0 ];
						
				entity.add( lead );
				_entityPool.release( entity, "leadInner" );
			}
			
			for( inner = 0; inner < 10; inner ++ )
			{
				wrapper = DisplayUtils.convertToBitmapSprite( clip, null, 1, false, _hitContainer[ "leadEmpty" ]);

				wrapper.sprite.x = startX[ 1 ];
				wrapper.sprite.y = startY;
				
				wrapper.sprite.alpha = 1;
				entity = EntityUtils.createMovingEntity( this, wrapper.sprite, _hitContainer[ "leadEmpty" ]);
				entity.add( new Id( "leadOutter" + inner ));
				
				sleep = new Sleep();
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;
				entity.add( sleep );
				
				lead = new PressedLeadComponent();
				lead.innerSide = false;
				lead.startY = startY;
				lead.startX = startX[ 1 ];
				
				entity.add( lead );
				_entityPool.release( entity, "leadOutter" );
			}

			// sparks
			for( outter = 0; outter < 2; outter ++ )
			{
				sparks = new Sparks();
				sparks.init();
			
				entity = EmitterCreator.create(  this, super._hitContainer[ "sparks" + ( outter )], sparks, 0, 10, null, "sparks" + outter );
			}
		}
		
		public function spawnMolten():void
		{
			var entity:Entity;
			var sleep:Sleep;
			var motion:Motion;
			var molten:Molten;
			var number:int;
			var spatial:Spatial;
			
			for( number = 0; number < 10; number ++ )
			{
				entity = _entityPool.request( "molten" );
				if( entity != null )
				{
					_total[ "molten" ] ++;
					
					molten = entity.get( Molten );
					molten.state = molten.FALLING;
					
					sleep = entity.get( Sleep );
					sleep.sleeping = false;
					
					spatial = entity.get( Spatial );
					spatial.y -= number * 20;
					
					motion = entity.get( Motion );
					motion.velocity = new Point( 0, 200 );
					motion.acceleration.y = MotionUtils.GRAVITY / 2;
				}
			}
			
			beginSparks();
		}		
		 
		/*******************************************
			scene shake needs to be implimented 
		******************************************/
		
		
		private function shakeScene():void
		{
			if( !_cameraEntity )
			{
				_cameraEntity = getEntityById( "camera" );
			}
			var shake:ShakeMotion = new ShakeMotion( new RectangleZone( -10, -10, 10, 10 ));
			_cameraEntity.add( shake ).add( new SpatialAddition());
			shake.active = true;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, endShake ));
		}
		
		private function endShake():void
		{
			if( !_cameraEntity )
			{
				_cameraEntity = getEntityById( "camera" );
			}
			var shake:ShakeMotion = _cameraEntity.get( ShakeMotion );
			var spatialAddition:SpatialAddition = _cameraEntity.get( SpatialAddition );
			spatialAddition.x = 0;
			spatialAddition.y = 0;
			
			shake.active = false;
		}
	
		/**
		 *   Handles most of the scene progression
		 *  sets functionality based on position of the smasher pistons
		 */
		public function mainHandler( label:String = "up" ):void
		{
			var i:int;
			var j:int;
			var smasherSpatial:Spatial;
			var leadSpatial:Spatial;
			var smasher:Smasher;
			
			switch( label )
			{
				
			// set conveyors and gears to ease to a stop, pause any molten on the conveyor
				case "down":
					super.shellApi.triggerEvent( _events.CONVEYOR_STOP );
					
					_conveyorControl.moving = false;
					SceneUtil.addTimedEvent( this, new TimedEvent( .75, 1, mainHandler ));
					break;
				
			// turn conveyor and gears back on, move pistons up, trigger a new round of molten and 
			//	offset next iteration so the pistons land before the conveyor easing starts
				case "up":
					super.shellApi.triggerEvent( _events.CONVEYOR_START );
					
					for( i = 0; i < _rods.length; i++ )
					{
						smasher = _rods[i].get( Smasher );
						smasher.state = smasher.START_UP;
						Timeline( _rods[i].get( Timeline )).paused = false;
					}
					
					_conveyorControl.moving = true;
					_conveyorControl.stopped = false;
					SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, spawnMolten ));
					break;
			}
		}
		
		// create sparks as molten comes out
		private function beginSparks():void
		{
			var sparks:Emitter2D;
			var emitter:Emitter;
			var entity:Entity;
			
			for( var number:int = 0; number < 2; number ++ )
			{
				entity = getEntityById( "sparks" + number );
				emitter = entity.get( Emitter );
				sparks = emitter.emitter;
				sparks.counter = new TimePeriod( 20, 1 );
			} 
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, smashDown ));
		}
		
		private var _events:CarrotEvents;
		private var _rods:Vector.<Entity>;
		public var _conveyorControl:ConveyorControlComponent;
		
		private var _entityPool:EntityPool;
		private var _total:Dictionary;
		
		private var _cameraEntity:Entity;
		private var _squished:Boolean;
		private var _highQuality:Boolean;
		
		private var _waitForPhoto:Boolean = false;
		private var _canUnloadScene:Signal;
	}
}
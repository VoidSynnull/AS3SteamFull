package game.utils
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.nodes.CameraLayerNode;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.LooperCollider;
	import game.components.entity.MotionMaster;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.collider.ClimbCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.motion.Looper;
	import game.components.motion.MotionControlBase;
	import game.components.motion.Threshold;
	import game.creators.animation.FSMStateCreator;
	import game.creators.scene.MotionLayerCreator;
	import game.data.scene.CameraLayerData;
	import game.data.scene.hit.HitData;
	import game.data.scene.hit.LooperHitData;
	import game.nodes.entity.character.FlyingPlatformStateNode;
	import game.nodes.hit.LooperHitNode;
	import game.nodes.motion.MotionWrapNode;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scenes.arab3.skyChase.SkyChase;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.shrink.carGame.creators.RaceSegmentCreator;
	import game.systems.SystemPriorities;
	import game.systems.entity.LooperCollisionSystem;
	import game.systems.entity.LoopingObjectSystem;
	import game.systems.entity.MotionMasterSystem;
	import game.systems.entity.MotionWrapSystem;
	import game.systems.entity.character.states.FlyingPlatformHurt;
	import game.systems.entity.character.states.FlyingPlatformRide;
	import game.systems.entity.character.states.FlyingPlatformState;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.MotionUtils;
	
	import org.osflash.signals.Signal;
	
	public class LoopingSceneUtils
	{
		private static const SEGMENTS:String = "segments";
		private static var _componentClasses:Array = [ WallCollider, PlatformCollider, ClimbCollider, HazardCollider, WaterCollider, CharacterMovement, CharacterMotionControl, Motion ];
		
		/**
		 * Instantiates the player's <code>Motion Master</code> component, assigns it to 
		 * looping background and obstacles, and determines which assets are awake and asleep.
		 * @param scene
		 * @param cameraStationary
		 * @param finishedRace
		 */
		static public function createMotion( scene:Scene, cameraStationary:Boolean, finishedRace:Function = null):void
		{
			var player:Entity = scene.shellApi.player;
			var cameraGroup:CameraGroup = CameraGroup(scene.getGroupById( CameraGroup.GROUP_ID ));
			var cameraLayerNode:CameraLayerNode;
			var cameraLayerNodes:NodeList = scene.systemManager.getNodeList( CameraLayerNode );
			var display:Display;
			var hitData:HitData;
			var id:Id;
			var interactiveLayerData:CameraLayerData;
			var isFirst:Boolean = true;
			var layerData:CameraLayerData;
			var looper:Looper;
			var looperHitData:LooperHitData;
			var looperHitNode:LooperHitNode;
			var looperHitNodes:NodeList = scene.systemManager.getNodeList( LooperHitNode );
			var motionLayerCreator:MotionLayerCreator = new MotionLayerCreator();
			var motionMaster:MotionMaster = player.get( MotionMaster );
			var motionWrapSystem:MotionWrapSystem = new MotionWrapSystem();
			var motionWrapNode:MotionWrapNode;
			var motionWrapNodes:NodeList = scene.systemManager.getNodeList( MotionWrapNode );
			var motionXML:XML = scene.getData( "motionMaster.xml" );
			var number:int;
			var orderedLayers:Array = cameraGroup.getOrderedLayers( scene.sceneData.layers );
			var segmentTiles:Boolean = false;
			var sleep:Sleep;
			var spatial:Spatial;
			
			// reposition camera so it doesn't destroy android
			if( cameraStationary )
			{
				spatial = player.get( Spatial );
				var cameraTarget:Entity = new Entity();
				cameraTarget.add( new Spatial( 0, spatial.y ));
				scene.addEntity( cameraTarget );
				
				cameraGroup.setTarget( cameraTarget.get( Spatial ), true );
			}
			else
			{
				cameraGroup.setTarget( player.get( Spatial ), true );
			}
			
			if( !motionMaster && motionXML )
			{
				motionMaster = motionLayerCreator.createMotionMaster( scene, motionXML);
				player.add( motionMaster );
			}
			
			if( motionMaster )
			{					
				// setup xml driven layers specified in scene.xml
				for( cameraLayerNode = cameraLayerNodes.head; cameraLayerNode; cameraLayerNode = cameraLayerNode.next )
				{
					for( number = 0; number < orderedLayers.length; number ++ ) 
					{ 
						layerData = orderedLayers[ number ];
						id = cameraLayerNode.entity.get( Id );
						
						if( layerData.id == id.id )
						{
							if( layerData.motionRate != 0 )
							{
								motionLayerCreator.addLayerMotion( scene, motionMaster, cameraLayerNode.entity, layerData, isFirst );
								isFirst = false;
							}
							if( layerData.id == "interactive" )
							{
								interactiveLayerData = layerData;
							}
						}
					}
				}
				
				// setup xml driven tiles specified in segmentPatterns.xml
				if( scene.getData( "segmentPatterns.xml" ))
				{
					interactiveLayerData.motionRate = 1;
					interactiveLayerData.subGroup = SEGMENTS;
					isFirst = true;
					
					for( motionWrapNode = motionWrapNodes.head; motionWrapNode; motionWrapNode = motionWrapNode.next )
					{
						if( motionWrapNode.motionWrap.subGroup == SEGMENTS )
						{
							motionLayerCreator.addLayerMotion( scene, motionMaster, motionWrapNode.entity, interactiveLayerData, isFirst );
							segmentTiles = true;
							isFirst = false;
						}
					}
				}
				
				isFirst = true;
				// iterate through all looper hits and toggle their motion.
				for( looperHitNode = looperHitNodes.head; looperHitNode; looperHitNode = looperHitNode.next )
				{		
					sleep = looperHitNode.sleep;
					
					// RANDOM OBSTACLES
					if( looperHitNode.hitData )
					{
						looperHitData = looperHitNode.hitData.components[ "looper" ];
						looper = looperHitNode.looperHit;
						
						// KIND OF HACKY WAY OF ADDING THE NAME :: ASSUMES THERE IS A NUMBERS AT THE END OF THE ID
						looper.type = looperHitNode.id.id.substr( 0, looperHitNode.id.id.length - 1 );
						motionLayerCreator.addLoopingHitMotion( scene, motionMaster, looperHitNode.entity, looperHitData ); 
						if( isFirst && looperHitData.active )
						{
							sleep = looperHitNode.entity.get( Sleep );
							sleep.sleeping = false;
							isFirst = false;
						}
					}
						
						// XML SEGMENT DRIVEN OBSTACLES
					else
					{
						looperHitData = new LooperHitData();
						
						motionLayerCreator.addLoopingHitMotion( scene, motionMaster, looperHitNode.entity, looperHitData ); 
						if( sleep.sleeping )
						{
							spatial = looperHitNode.spatial;
							display = looperHitNode.display;
							display.alpha = 0;
						}
					}
				}
				
				scene.addSystem( motionWrapSystem,SystemPriorities.preRender );
				scene.addSystem( new DestinationSystem());
				scene.addSystem( new MotionMasterSystem(),SystemPriorities.moveControl);	
				
				if( segmentTiles )
				{
					if (finishedRace)
					{
						if( !motionWrapSystem.finalTile )
						{
							motionWrapSystem.finalTile = new Signal();
						}
						motionWrapSystem.finalTile.addOnce( finishedRace );
					}
				}	
			}
		}
		
		/** 
		 * Create <code>Motion Master</code> component for player and add looper collider
		 * @param scene
		 * @param fileName : <code>String</code> xml file name for motion master data.
		 */
		public static function setupPlayer( scene:Scene, fileName:String = "motionMaster.xml", progressClip:MovieClip = null):void
		{
			var player:Entity = scene.shellApi.player;
			player.add( new LooperCollider());
			var motionXML:XML = scene.getData( fileName );
			var motionMaster:MotionMaster;
			var motionLayerCreator:MotionLayerCreator = new MotionLayerCreator();
			
			if( motionXML )
			{
				motionMaster = motionLayerCreator.createMotionMaster( scene, motionXML, progressClip );
				player.add( motionMaster );
			}
			
			// ADD HIT TO PLAYER
			var displayObject:MovieClip = player.get( Display ).displayObject as MovieClip;
			var sprite:Sprite = new Sprite();
			sprite.graphics.beginFill( 0x00ff00 );
			sprite.graphics.drawRect( -10, -120, 60, 180 );
			sprite.name = "hit";
			sprite.alpha = 0;
			displayObject.addChildAt( sprite, displayObject.numChildren );
			
			// ADD ANY EXTRA AUDIO
			var audioGroup:AudioGroup = scene.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			if (audioGroup)
				audioGroup.addAudioToEntity( player );
		}
		
		/**
		 * Setup player on flying platform such as a carpet or broom 
		 * @param scene
		 * @param componentInstances
		 */
		static public function setupFlyingPlayer( scene:Scene, rotation:Number = 0):void
		{
			var player:Entity = scene.shellApi.player;
			
			// SETUP FSM for flying platform
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.removeAll(); 
			
			var stateCreator:FSMStateCreator = new FSMStateCreator();
			var stateClasses:Vector.<Class> = new <Class>[ FlyingPlatformHurt, FlyingPlatformRide ];
			
			stateCreator.createStateSet( stateClasses, player, FlyingPlatformStateNode );
			fsmControl.setState( FlyingPlatformState.RIDE );
			
			scene.addSystem( new MoveToTargetSystem( scene.shellApi.viewportWidth, scene.shellApi.viewportHeight), SystemPriorities.moveControl );
			scene.addSystem( new MotionControlBaseSystem(), SystemPriorities.move );
			
			// PLATFORM CONTROLS
			MotionUtils.zeroMotion(player);
			if( player.has( CharacterMotionControl ))
				CharacterMotionControl(player.get(CharacterMotionControl)).spinEnd = true;
			Motion( player.get(Motion)).rotation = 0;
			Spatial( player.get(Spatial)).rotation = rotation;
		}
		
		/**
		 * Start flying player 
		 * @param scene
		 * @param componentInstances
		 */
		static public function startFlyingPlayer(scene:Scene, componentInstances:Array):void
		{
			var player:Entity = scene.shellApi.player;
			
			for( var index:int = _componentClasses.length - 1; index > -1; --index )
			{
				componentInstances.push( player.remove( _componentClasses[ index ]));
			}
			
			var motion:Motion = new Motion();
			motion.maxVelocity = new Point( 800, 500 );
			player.add(motion);
		}
		
		/**
		 * Restore player after flying platform
		 * @param scene
		 * @param componentInstances
		 */
		static public function endFlyingPlayer( scene:Scene, componentInstances:Array ):void
		{
			var player:Entity = scene.shellApi.player;
			player.remove( MotionControlBase );
			
			for(var index:int = componentInstances.length - 1; index > -1; --index )
			{
				player.add( componentInstances[ index ]);
			}
			componentInstances = [];
			
			MotionUtils.zeroMotion( player );
		}
		
		/**
		 * Activate <code>Motion Master</code> component and starts the motion for all <code>Motion Wrap Node</code> nodes.
		 * @param scene
		 */
		static public function triggerLayers( scene:Scene ):void
		{
			var motionMaster:MotionMaster = scene.shellApi.player.get( MotionMaster );
			motionMaster.active = true;
			
			var motionWrapNodes:NodeList = scene.systemManager.getNodeList( MotionWrapNode );
			var motionWrapNode:MotionWrapNode;
			
			for( motionWrapNode = motionWrapNodes.head; motionWrapNode; motionWrapNode = motionWrapNode.next )
			{
				trace("Starting motion on wrap layer : "+ Id( motionWrapNode.entity.get( Id )).id );
				motionWrapNode.motionWrap.startMotion( motionWrapNode );
			}
		}
		
		/**
		 * Adds required systems for looper motion and collision.
		 * @param scene
		 */
		static public function triggerObstacles( scene:Scene ):void
		{
			scene.addSystem( new LoopingObjectSystem());			
			scene.addSystem( new LooperCollisionSystem());
		}
		
		/**
		 * Toggles <code>Looper Hit Node</code> activity based on event.
		 * @param scene
		 * @param	event : <code>String</code> event that determines which loopers are active.
		 */
		static public function toggleLooperEvent( scene:Scene, event:String ):void
		{
			var looperHitNodes:NodeList = scene.systemManager.getNodeList( LooperHitNode );
			var looperHitNode:LooperHitNode;
			
			for( looperHitNode = looperHitNodes.head; looperHitNode; looperHitNode = looperHitNode.next )
			{
				trace("Toggle Event : " + event + " on looper object : "+ Id( looperHitNode.entity.get( Id )).id );
				looperHitNode.looperHit.toggleEvent( event );
			}
		}
		
		/**
		 * Halts scene asset and looper obstacle motion.
		 * @param scene
		 * @param includeLoopers
		 */
		static public function stopSceneMotion( scene:Scene, includeLoopers:Boolean = true ):void
		{
			var motionMaster:MotionMaster = scene.shellApi.player.get( MotionMaster );
			
			// STOP THE MOTION FOR LOOPER OBJECTS AND MOTION WRAPPED LAYERS
			if( motionMaster )
			{
				var motionWrapNodes:NodeList = scene.systemManager.getNodeList( MotionWrapNode );
				var motionWrapNode:MotionWrapNode;
				
				for( motionWrapNode = motionWrapNodes.head; motionWrapNode; motionWrapNode = motionWrapNode.next )
				{
					trace("Removing motion layer components : "+ Id( motionWrapNode.entity.get( Id )).id );
					motionWrapNode.motionWrap.stopMotion( motionWrapNode );
				}
				
				if( includeLoopers )
				{
					var looperHitNodes:NodeList = scene.systemManager.getNodeList( LooperHitNode );
					var looperHitNode:LooperHitNode;
					
					for( looperHitNode = looperHitNodes.head; looperHitNode; looperHitNode = looperHitNode.next )
					{
						trace("Removing motion layer components : "+ Id( looperHitNode.entity.get( Id )).id );
						looperHitNode.looperHit.stopMotion( looperHitNode );
					}
				}
			}
		}
		
		/**
		 * Restarts scene asset and looper obstacle motion.
		 * @param scene
		 */
		static public function restartSceneMotion( scene:Scene ):void
		{
			var motionMaster:MotionMaster = scene.shellApi.player.get( MotionMaster );
			
			// STOP THE MOTION FOR LOOPER OBJECTS AND MOTION WRAPPED LAYERS
			if ( motionMaster )
			{
				var motionWrapNodes:NodeList = scene.systemManager.getNodeList( MotionWrapNode );
				var motionWrapNode:MotionWrapNode;
				
				var looperHitNodes:NodeList = scene.systemManager.getNodeList( LooperHitNode );
				var looperHitNode:LooperHitNode;
				
				for( looperHitNode = looperHitNodes.head; looperHitNode; looperHitNode = looperHitNode.next )
				{
					trace("Restoring motion layer components : "+ Id( looperHitNode.entity.get( Id )).id );
					looperHitNode.looperHit.startMotion( looperHitNode.motion );
				}
				
				for( motionWrapNode = motionWrapNodes.head; motionWrapNode; motionWrapNode = motionWrapNode.next )
				{
					trace("Restoring motion layer components : "+ Id( motionWrapNode.entity.get( Id )).id );
					motionWrapNode.motionWrap.startMotion(  motionWrapNode );
				}
			}
		}
		
		// HANDLE OBSTACLES IN FLYING GAME ///////////////////////////////////////////
		
		/**
		 * Hide all obstacles for game setup
		 * @param raceSegmentCreator
		 * @param obstacles
		 */
		static public function hideObstacles(raceSegmentCreator:RaceSegmentCreator, obstacles:Vector.<String>):void
		{
			var display:Display;
			var looper:Looper;
			var obstacle:Entity; 	
			var obstaclePool:Vector.<Entity>;
			var spatial:Spatial;
			var threshold:Threshold;
			
			for( var outter:Number = 0; outter < obstacles.length; outter ++ )
			{
				obstaclePool = raceSegmentCreator._pool.getPool( obstacles[ outter ]);
				
				if( obstaclePool )
				{
					for( var inner:Number = 0; inner < obstaclePool.length; inner ++ )
					{
						obstacle 					= 	obstaclePool[ inner ];
						
						looper 						= 	obstacle.get( Looper );
						looper.linkedToTiles 		= 	false;
						
						display  	  				= 	looper.visualEntity.get( Display );
						display.visible 			=	false;
					}
				}
			}
		}
		
		/**
		 * Start obstacles for game
		 * @param scene
		 * @param raceSegmentCreator
		 * @param obstacles
		 */
		static public function startObstacles( scene:Scene, raceSegmentCreator:RaceSegmentCreator, obstacles:Vector.<String> ):void
		{
			var looper:Looper;
			var motion:Motion;
			var motionMaster:MotionMaster 			= 	scene.shellApi.player.get( MotionMaster );
			var obstacle:Entity; 	
			var obstaclePool:Vector.<Entity>;
			var spatial:Spatial;
			var threshold:Threshold;
			
			for( var outter:Number = 0; outter < obstacles.length; outter ++ )
			{
				obstaclePool = raceSegmentCreator._pool.getPool( obstacles[ outter ]);
				
				if( obstaclePool )
				{
					for( var inner:Number = 0; inner < obstaclePool.length; inner ++ )
					{
						obstacle 					= 	obstaclePool[ inner ];
						trace("start " + obstacle.get(Id).id);
						
						motion 						= 	obstacle.get( Motion );
						motion.velocity 			= 	motionMaster.velocity;
						motion.minVelocity 			= 	new Point( 0, 0 );
						motion.maxVelocity 			= 	motionMaster.maxVelocity;
						motion.acceleration 		= 	motionMaster.acceleration;
						
						spatial 					=	obstacle.get( Spatial );
						var direction:String 		= 	motionMaster.direction == "+"?">=":"<=";
						threshold 					= 	new Threshold( motionMaster.axis, direction );
						threshold.threshold 		= 	motionMaster.axis == "+"?spatial.height:-spatial.width;
						
						threshold.entered.addOnce( Command.create( summonObstacle, scene, obstacle ));
						obstacle.add( threshold );
					}
				}	
			}
		}
		
		
		/**
		 * Summon obstacle for SkyChase game 
		 * @param scene
		 * @param obstacle
		 */
		static public function summonObstacle( scene:Scene, obstacle:Entity ):void
		{
			// NOTE: obstacles don't drop when summon obstacle is too far above edge of device rect
			// need to widen scene or figure out startY that is 50 pixels below top edge of device
			// using scene width of 1000 seems to work
			var startY:Number				=	50;
			var startX:Number 				= 	-50;
			
			// TO-DO :: GET THIS TO WORK WITH THE LOOPING OBJECT SYSTEM
			var motion:Motion 				= 	obstacle.get( Motion );
			motion.velocity 				= 	new Point( 0, 0 );
			motion.minVelocity 				= 	new Point( 0, 0 );
			motion.maxVelocity 				= 	new Point( 0, 0 );
			motion.acceleration 			= 	new Point( 0, 0 );
			motion.previousY 				= 	0;
			
			var spatial:Spatial 			= 	obstacle.get( Spatial );
			if(MotionMaster(scene.shellApi.player.get(MotionMaster)).axis == "y")
			{
				spatial.y					= 	startY;
				motion.y 					= 	startY;
			}
			else
			{
				spatial.x					=	startX;
				motion.x					=	startX;
			}
			
			var looper:Looper 				= 	obstacle.get( Looper );
			looper.firstLinkCheck			= 	true;
			
			// SkyChase scene shows smoke puff first
			if (scene is SkyChase)
				SkyChase(scene).smokePuffGroup.poofAt( obstacle, .5, true, Command.create( dropObstacle, scene, obstacle ), true );
			else
				QuestGame(scene).gameClass.summonObstacle(obstacle, Command.create( dropObstacle, scene, obstacle ) );
		}
		
		/**
		 * Drop obstacle from sky 
		 * @param scene
		 * @param obstacle
		 */
		static public function dropObstacle( scene:Scene, obstacle:Entity ):void
		{
			// skip out if game is over
			if ((scene is QuestGame) && (!QuestGame(scene).gameClass.playing))
				return;
			
			var dropVelocity:Number			= 600;
			var motionXML:XML = scene.getData( "motionMaster.xml" );
			if ((motionXML) && (motionXML.dropVelocity))
				dropVelocity = Number(motionXML.dropVelocity);
			
			var spatial:Spatial 			= 	obstacle.get( Spatial );
			var motion:Motion 				= 	obstacle.get( Motion );
			motion.acceleration				= 	new Point( 0, 0 );
			if(motionXML.axis == "y")
			{
				spatial.x 						-= 	.5 * spatial.width;
				spatial.y 						= 	- spatial.height;
				motion.maxVelocity				= 	new Point( 0, Infinity );
				motion.velocity 				= 	new Point( 0, dropVelocity );
				motion.y 						= 	- spatial.height;
			}
			else
			{
				spatial.y 						-= 	.5 * spatial.height;
				spatial.x 						= 	scene.sceneData.bounds.right + spatial.width;
				motion.maxVelocity				= 	new Point( Infinity, 0 );
				motion.velocity 				= 	new Point( -dropVelocity, 0 );
				motion.x 						= 	scene.sceneData.bounds.right + spatial.width;
			}
			
			var looper:Looper 				= 	obstacle.get( Looper );
			var display:Display  			= 	looper.visualEntity.get( Display );
			display.visible 				=	true;
			var id:String					= 	looper.visualEntity.get( Id ).id;
			
			trace("drop obstacle " + id);
			
			// play sfx if motionMaster has sound reference
			if (motionXML)
			{
				var soundFile:String = DataUtils.getString(motionXML[id + "Sound"]);
				if ((soundFile != null) && (soundFile != ""))
					AudioUtils.play(scene, SoundManager.EFFECTS_PATH + soundFile, 3);
			}
			
			var visualSpatial:Spatial 		= 	looper.visualEntity.get( Spatial );
			
			var threshold:Threshold 		= 	obstacle.get( Threshold );
			threshold.property 				=	motionXML.axis;
			threshold.operator 				= 	motionXML.direction == "+"?">=":"<=";
			threshold._firstCheck 			= 	true;
			threshold.threshold 			= 	threshold.operator == ">="? scene.shellApi.viewportHeight + visualSpatial.height:-visualSpatial.width;
			threshold.entered.addOnce( Command.create( stopObstacle, scene, obstacle ));
		}
		
		/**
		 * Stop obstacle from falling 
		 * @param scene
		 * @param obstacle
		 */
		static public function stopObstacle( scene:Scene, obstacle:Entity ):void
		{
			var spatial:Spatial 			=	obstacle.get( Spatial );
			spatial.x 						= 	1356;
			spatial.y 						= 	-410;
			
			var looper:Looper				=	obstacle.get( Looper ); 
			
			var display:Display				=	looper.visualEntity.get( Display );
			display.visible 				=	false;
			
			var motionMaster:MotionMaster 	=	scene.shellApi.player.get( MotionMaster );
			
			var motion:Motion 				= 	obstacle.get( Motion );
			motion.y 						= 	-410;
			motion.previousY				=  	-410;
			motion.lastVelocity 			= 	new Point( 0, 0 );
			motion.velocity 				= 	motionMaster.velocity;
			motion.maxVelocity 				= 	motionMaster.maxVelocity;
			motion.acceleration 			= 	motionMaster.acceleration;
			
			var threshold:Threshold 		= 	obstacle.get( Threshold );
			threshold.property 				=	motionMaster.axis;
			var direction:String 			= 	motionMaster.direction == "+"?">=":"<=";
			threshold.operator 				= 	direction;
			threshold._firstCheck 			= 	true;
			threshold.threshold 			= 	spatial.height;
			threshold.entered.add( Command.create( summonObstacle, scene, obstacle ));
			
			var sleep:Sleep 				= 	obstacle.get( Sleep );
			sleep.sleeping 					=	true;
		}
	}
}
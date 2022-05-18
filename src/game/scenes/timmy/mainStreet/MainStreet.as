package game.scenes.timmy.mainStreet
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Npc;
	import game.components.entity.character.part.SkinPart;
	import game.components.hit.Item;
	import game.components.hit.ValidHit;
	import game.components.motion.Destination;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.components.ui.WordBalloon;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Throw;
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.ToolTipType;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.timmy.TimmyScene;
	import game.scenes.timmy.timmysStreet.TimmysStreet;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.CharacterDepthSystem;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.movieClip.MCWalkState;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class MainStreet extends TimmyScene
	{
		private var _timmy:Entity;
		private var _bank:Entity;
		private var _bankDoor:Entity;
		private var _bankDoorSequence:BitmapSequence;
		private var _bankEntrance:Entity;
		private var _bankWindow:Entity;
		private var _bankTop:Entity;
		private var _camera:Entity;
		private var _outsideValidHit:ValidHit;
		
		private var _inBank:Boolean 						=	false;
		private var _scutaro:Entity;
		private var _scutaroTimer:TimedEvent;
		
		private var _scutaroOnTheScene:Boolean 				=	false;
		private var _scutaroScared:Boolean 					=	false;
		private var _scutaroTalking:Boolean 				=	false;
		private var _shakeTimer:TimedEvent;
		
		private const DRIVE:String 							=	"drive";
		
		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/mainStreet/";
			
			super.init(container);
		}
		
		override public function destroy():void
		{
			if( _shakeTimer )
			{
				_shakeTimer.stop();
				_shakeTimer									=	 null;
			}
			if( _scutaroTimer )
			{
				_scutaroTimer.stop();
				_scutaroTimer								=	 null;
			}
			if( _bankDoorSequence )
			{
				_bankDoorSequence.destroy();
				_bankDoorSequence 							=	null;
			}
			
			super.destroy();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addBaseSystems():void
		{
			if( !super.getSystem( CharacterDepthSystem ))
			{
				addSystem( new CharacterDepthSystem());
			}
			addSystem( new TriggerHitSystem());
			super.addBaseSystems();
		}
		
		// all assets ready
		override public function loaded():void
		{
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);

			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(1235, 1200),"minibillboard/minibillboardMedLegs.swf");	

			if( !shellApi.checkEvent( _events.INTRO_COMPLETE ))
			{
				shellApi.loadScene( TimmysStreet, 550, 970, "right" );
			}
			else
			{
				super.loaded();
				shellApi.eventTriggered.add( eventTriggered );
				
				setupAssets();
				addItemHitSystem();
			}
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		// UTILITY FUNCTIONS
		private function setupAssets():void
		{
			var bush:Entity;
			var cameraClip:MovieClip 						=	_hitContainer[ _events.CAMERA ];
			var entity:Entity;
			var sceneInteraction:SceneInteraction;
			_timmy 											=	getEntityById( "timmy" );
			_scutaro										=	getEntityById( "scutaro" );
			
			if( _scutaro && _scutaro.has( Npc ))
			{
				Npc( _scutaro.get( Npc )).ignoreDepth = true;
			}
			
			var validHit:ValidHit							=	new ValidHit( "bankWall", "bankFloor", "bankCeiling", "scutaroPath" );
			validHit.inverse 								=	true;
			player.add( validHit );
			
			_total.add( new ValidHit( "baseGround" ));
			
			// BANK
			_bank											=	makeEntity( _hitContainer[ "bank" ]);
			_bankWindow 									=	makeEntity( _hitContainer[ "bankWindow" ]);
			_bankEntrance 									=	makeEntity( _hitContainer[ "bankEntrance" ]);
			_bankTop										=	makeEntity( _hitContainer[ "bankTop" ]);
			
			var clip:MovieClip 								=	_hitContainer[ "bankEnt" ];
			_bankDoorSequence 								=	BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 1.0 );
			_bankDoor										=	makeEntity( clip, _bankDoorSequence );
			makeEntity( _hitContainer[ "lampPost" ]);
			
			makeBankDoor( _bankWindow, bankWindowApproached, "ENTER" );
			makeBankDoor( _bankEntrance, bankEntranceApproached, "ENTER" );
			
			// IS SCUTARO AROUND?
			if( !shellApi.checkEvent( _events.DROPPED_CAMERA ))
			{
				_scutaro.add( new ValidHit( "baseGround", "concrete", "scutaroPath" ));
				sceneInteraction							=	_scutaro.get( SceneInteraction );
				sceneInteraction.reached.add( scutaroFacesPlayer );
				
				var timeline:Timeline 						=	_scutaro.get( Timeline );
				timeline.gotoAndPlay( "stand" );
				
				_scutaroTimer								=	new TimedEvent( 4, 1, scutaroKnocks );
				SceneUtil.addTimedEvent( this, _scutaroTimer );
				
				var sleep:Sleep								=	_scutaro.get( Sleep );
				sleep.sleeping 								=	false;
				sleep.ignoreOffscreenSleep					=	true;
				
				var dialog:Dialog							=	_scutaro.get( Dialog );
				dialog.complete.add( scutaroFacesBank );
				//dialog.allowOverwrite						=	true;
				_camera 									=	makeEntity( _hitContainer[ _events.CAMERA ]);
				Display( _camera.get( Display )).alpha 		=	0;
				
				DisplayUtils.moveToOverUnder( Display( _bankEntrance.get( Display )).displayObject, Display( _bank.get( Display )).displayObject, true );
				DisplayUtils.moveToTop( Display( _scutaro.get( Display )).displayObject );
			}
			else
			{
				removeEntity( _scutaro );
				_scutaro 									=	null;
				
				if( !shellApi.checkItemEvent( _events.CAMERA ))
				{
					_camera 								=	makeItem( _hitContainer[ _events.CAMERA ], inPositionForCamera, true );
				}
				else
				{
					_hitContainer.removeChild( _hitContainer[ _events.CAMERA ]);
				}
			}
			
			// run intro
			if(!shellApi.checkItemEvent( _events.DETECTIVE_LOG ))
			{
				bush										=	makeEntity( _hitContainer[ "bush" ]);
				addSystem( new ShakeMotionSystem());
				
				DisplayUtils.moveToOverUnder( Display( _timmy.get( Display )).displayObject, Display( bush.get( Display )).displayObject, false );
				
				var displayObject:DisplayObject 			=	Display( _timmy.get( Display )).displayObject;
				displayObject[ "shorts" ].alpha				=	0;
				displayObject[ "shirt_garbage" ].alpha		=	0;
				displayObject[ "head_garbage" ].alpha		=	0;
				
				//Remove click interaction, and only trigger opening dialog when you've reached the threshold.
				//Click interaction and threshold code were conflicting.
				_timmy.remove(SceneInteraction);
				_timmy.remove(Interaction);
				ToolTipCreator.removeFromEntity(_timmy);
				
				var threshold:Threshold 					= new Threshold( "x", ">=" );
				threshold.target							= player.get(Spatial);
				threshold.offset							= -200;
				threshold.entered.addOnce( positionForTimmy );	
				_timmy.add( threshold );
				
				addSystem( new ThresholdSystem());
				
				var shakeMotion:ShakeMotion 				=	new ShakeMotion( new RectangleZone( -1, -1, 1, 1 ));
				shakeMotion.active 							=	false;
				_shakeTimer 								=	 new TimedEvent( 2, 1, outOfBush );
				_timmy.add( new Tween());
				Npc( _timmy.get( Npc )).ignoreDepth = true;
				
				bush.add( shakeMotion ).add( new SpatialAddition()).add( new AudioRange( 600 ));
				_audioGroup.addAudioToEntity( bush );
				SceneUtil.addTimedEvent( this, _shakeTimer );
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ "bush" ]);
				removeEntity( _timmy );
				_timmy 										=	null;
			}
			
			// HANDBOOK PAGE
			if( !shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "3" ) || shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "3" ) && shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "4" ))
			{
				_hitContainer.removeChild( _hitContainer[ _events.HANDBOOK_PAGE ]);
			}
			else
			{
				makeItem( _hitContainer[ _events.HANDBOOK_PAGE ], getHandbookPage );
			}
			
			// MOVE TOTAL AND PLAYER TO TOP LAYER
			DisplayUtils.moveToTop( Display( _total.get( Display )).displayObject );
			DisplayUtils.moveToTop( Display( player.get( Display )).displayObject );
			
			// CRISPIN'S CAR
			if( !shellApi.checkEvent( _events.CRASHED_CAR ))
			{
				var car:Entity								=	makeAutomobile( this, _hitContainer[ "car" ]);
				
				ToolTipCreator.addToEntity( car, InteractionCreator.CLICK );
				InteractionCreator.addToEntity( car, [ InteractionCreator.CLICK ]);
				var interaction:Interaction					=	car.get( Interaction );
				interaction.click.add( checkTheCar );
				
				DisplayUtils.moveToTop( Display( car.get( Display )).displayObject );
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ "car" ]);
			}
			
			// ADD TRIGGER HITS TO CONCRETE AND STONE TO LAYER TOTAL CORRECTLY
			var triggerHit:TriggerHit				=	new TriggerHit( null, new <String>[ "player" ]);
			triggerHit.triggered					=	new Signal();
			triggerHit.triggered.add( relayerWithTotal );
			
			var stone:Entity 						=	getEntityById( "stones" );
			stone.add( triggerHit );
			
			var concrete:Entity 					=	getEntityById( "concreteBag" );
			concrete.add( triggerHit );
		}
		
		// BUSH LOGIC
		private function outOfBush():void
		{
			if( !shellApi.checkEvent( _events.SAW_TIMMY_MAINSTREET ))
			{
				var bush:Entity 							=	getEntityById( "bush" );
				var shakeMotion:ShakeMotion 				=	bush.get( ShakeMotion );
				shakeMotion.active 							=	true;
				
				var audio:Audio 							=	bush.get( Audio );
				audio.playCurrentAction( TRIGGER );
				
				var spatial:Spatial 						=	_timmy.get( Spatial );
				
				var tween:Tween 							=	_timmy.get( Tween );
				tween.to( spatial, 1, { y : 1480, onComplete : startCountdown, onCompleteParams : [ true ]});
			}
		}
		
		private function startCountdown( isUp:Boolean ):void
		{
			if( !shellApi.checkEvent( _events.SAW_TIMMY_MAINSTREET ))
			{
				var bush:Entity 							=	getEntityById( "bush" );
				var shakeMotion:ShakeMotion 				=	bush.get( ShakeMotion );
				shakeMotion.active 							=	false;
				
				var spatialAddition:SpatialAddition 		=	bush.get( SpatialAddition  );
				spatialAddition.x 							=	0;
				spatialAddition.y 							=	0;
				
				var handler:Function 						=	isUp ? intoBush : outOfBush;
				
				_shakeTimer 								= 	new TimedEvent( 3, 1, handler );
				SceneUtil.addTimedEvent( this, _shakeTimer );
			}		
		}
		
		private function intoBush():void
		{
			if( !shellApi.checkEvent( _events.SAW_TIMMY_MAINSTREET ))
			{
				var bush:Entity 							=	getEntityById( "bush" );
				var shakeMotion:ShakeMotion 				=	bush.get( ShakeMotion );
				shakeMotion.active 							=	true;
				
				var audio:Audio 							=	bush.get( Audio );
				audio.playCurrentAction( TRIGGER );
				
				var spatial:Spatial 						=	_timmy.get( Spatial );
				
				var tween:Tween 							=	_timmy.get( Tween );
				tween.to( spatial, 1, { y : 1500, onComplete : startCountdown, onCompleteParams : [ false ]});
			}
		}
		
		private function makeBankDoor( door:Entity, handler:Function, label:String ):void
		{
			ToolTipCreator.addToEntity( door, InteractionCreator.CLICK, label );
			InteractionCreator.addToEntity( door, [ InteractionCreator.CLICK ]);
			
			var sceneInteraction:SceneInteraction			=	new SceneInteraction();
			sceneInteraction.reached.add( handler );
			door.add( sceneInteraction );
			
			var display:Display								=	door.get( Display );
			display.alpha 									=	0;
		}
		
		public function makeItem( clip:MovieClip, handler:Function, addItemHit:Boolean = true ):Entity
		{
			var entity:Entity 								=	makeEntity( clip );
			var sceneInteraction:SceneInteraction			=	new SceneInteraction();
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( entity, InteractionCreator.CLICK );
			
			sceneInteraction.reached.addOnce( handler );
			entity.add( sceneInteraction );
			
			if( addItemHit )
			{
				entity.add( new Item());
			}
			
			return entity;
		}
		
		private function getHandbookPage( $player:Entity = null, handbookPage:Entity = null ):void
		{
			removeEntity( handbookPage );
			shellApi.completeEvent( _events.GOT_DETECTIVE_LOG_PAGE + "4" );
			showDetectivePage( 4 );
		}
		
		// ADD ITEM FUNCTIONALITY IF NOT PRESENT
		public function addItemHitSystem():void
		{
			var itemHitSystem:ItemHitSystem 				=	getSystem( ItemHitSystem ) as ItemHitSystem;
			if( !itemHitSystem )	// items require ItemHitSystem, add system if not yet added
			{
				itemHitSystem 								=	new ItemHitSystem();
				addSystem( itemHitSystem, SystemPriorities.resolveCollisions );
			}	
			itemHitSystem.gotItem.removeAll();
			itemHitSystem.gotItem.add( itemHit );
		}
		
		public function itemHit( entity:Entity ):void
		{
			var id:Id 										=	entity.get( Id );
			
			if( id.id 										==	_events.HANDBOOK_PAGE )
			{
				getHandbookPage();
			}
			else
			{
				_itemGroup.showAndGetItem( id.id, null, null, null, entity );
			}
		}
		
		private function relayerWithTotal():void
		{
			DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _total.get( Display )).displayObject, false );	
		}
		
		// EVENT HANDLER
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			switch( event )
			{
				case _events.GET_DETECTIVE_LOG:
					SceneUtil.lockInput( this, false );
					shellApi.triggerEvent( _events.GOT_DETECTIVE_LOG_PAGE + "1", true );
					shellApi.getItem( _events.DETECTIVE_LOG, null, true, Command.create( super.showDetectivePage, 1, whereToFindTotal ));
					break;
				
				case _events.USE_CAR_KEYS:
					if( !shellApi.checkEvent( _events.CRASHED_CAR ))
					{
						moveToCar();	
					}
					else
					{
						Dialog( player.get( Dialog )).sayById( "cant_use_car_keys" );
					}
					break;
				
				default:
					super.eventTriggered( event, makeCurrent, init, removeEvent );
					break;
			}
		}
		
		/**
		 * TIMMY LOGIC
		 */
		private function positionForTimmy():void
		{
			SceneUtil.lockInput( this );
			CharUtils.lockControls( player );
			var destination:Destination 					=	CharUtils.moveToTarget( player, Spatial( _timmy.get( Spatial )).x + 150, Spatial( _timmy.get( Spatial )).y, true, talkToTimmy );
			destination.ignorePlatformTarget				=	true;
		}
		
		private function talkToTimmy( $player:Entity ):void
		{
			CharUtils.setDirection( player, false );
			shellApi.completeEvent( _events.SAW_TIMMY_MAINSTREET );

			var tween:Tween 								=	_timmy.get( Tween );
			tween.pauseAllTweens( true );
			var spatial:Spatial 							=	_timmy.get( Spatial );
			spatial.y 										=	1480;
			
			var bush:Entity 								=	getEntityById( "bush" );
			var shakeMotion:ShakeMotion 					=	bush.get( ShakeMotion );
			shakeMotion.active 								=	false;
			
			var spatialAddition:SpatialAddition 			=	bush.get( SpatialAddition );
			spatialAddition.x 								=	0;
			spatialAddition.y 								=	0;
			
			var dialog:Dialog								=	_timmy.get( Dialog );
			dialog.sayById( "evil_doings" );
			
			var audio:Audio	 								=	bush.get( Audio );
			audio.playCurrentAction( TRIGGER );
		}
		
		private function whereToFindTotal():void
		{
			SceneUtil.lockInput( this );
			
			var dialog:Dialog 								=	_timmy.get( Dialog );
			dialog.sayById( "lounging" );
			dialog.complete.addOnce( timmyMakesToLeave );
		}
		
		private function timmyMakesToLeave( dialogData:DialogData ):void
		{
			var bush:Entity 								=	getEntityById( "bush" );
			DisplayUtils.moveToOverUnder( Display( _timmy.get( Display )).displayObject, Display( bush.get( Display )).displayObject, true );
			
			var audio:Audio	 								=	bush.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var charMotion:CharacterMotionControl 			=	new CharacterMotionControl();
			charMotion.maxVelocityX 						=	300;
			_timmy.add( charMotion );
			
			_characterGroup.addFSM( _timmy, true, null, "", true );
			
			CharUtils.setAnim( player, Laugh );
			var dialog:Dialog 								=	player.get( Dialog );
			dialog.sayById( "no_pants" );
			dialog.complete.addOnce( timmyHurt );
		}
		
		private function timmyHurt( dialogData:DialogData ):void
		{
			var timeline:Timeline 							=	_timmy.get( Timeline );
			timeline.gotoAndPlay( "hit" );
			
			var dialog:Dialog 								=	_timmy.get( Dialog );
			dialog.sayById( "dont_remind" );
			dialog.complete.addOnce( timmyWalksAway );
		}
		
		private function timmyWalksAway( dialogData:DialogData ):void
		{
			CharUtils.moveToTarget( _timmy, 2100, Spatial( player.get( Spatial )).y, true, timmyOut ); 
		}
		
		private function timmyOut( timmy:Entity ):void
		{
			SceneUtil.lockInput( this, false );
			CharUtils.lockControls( player,  false, false );
			removeEntity( _timmy );
		}
		
		// SCUTARO AND THE BANK
		private function bankWindowApproached( $player:Entity, bankWindow:Entity ):void
		{
			_inBank 										=	!_inBank;
			
			var validHit:ValidHit 							=	player.get( ValidHit );
			validHit.inverse 								=	!_inBank;
			var reference:DisplayObject 					=	Display( _bank.get( Display )).displayObject;
			var spatial:Spatial								=	player.get( Spatial );
			
			// YOU ARE NOW IN THE BANK
			if( _inBank )
			{
				player.remove( PlatformDepthCollider );
				ToolTipCreator.removeFromEntity( _bankWindow );
				ToolTipCreator.addToEntity( _bankWindow, InteractionCreator.CLICK, "EXIT" );
				
				ToolTipCreator.removeFromEntity( _bankEntrance );
				ToolTipCreator.addToEntity( _bankEntrance, InteractionCreator.CLICK, "EXIT" );
				
				Npc( _total.get( Npc )).ignoreDepth = true;
				DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _bank.get( Display )).displayObject, false );
				
				CharUtils.lockControls( player );
				var bankFloor:Entity 							=	getEntityById( "bankFloor" );
				var triggerHit:TriggerHit 						=	bankFloor.get( TriggerHit );
				if( !triggerHit )
				{
					triggerHit 									=	new TriggerHit( null, new <String>[ "player" ]);
					bankFloor.add( triggerHit );
				}
				
				triggerHit.triggered 							=	new Signal();
				triggerHit.triggered.addOnce( landInBank );			
				
				if( _scutaro )
				{
					_scutaro.remove( SceneInteraction );
				}
				
				// remove sceneInteraction and Item from camera if dropped
				if( shellApi.checkEvent( _events.DROPPED_CAMERA ) && !shellApi.checkItemEvent( _events.CAMERA ))
				{
					_camera.remove( Item );
					_camera.remove( Interaction );
					_camera.remove( SceneInteraction );
					ToolTipCreator.removeFromEntity( _camera );
				}
				
				// position in bank
				CharUtils.position( player, 950, 740 );
			}
			else
			{
				player.add( new PlatformDepthCollider());
				ToolTipCreator.removeFromEntity( _bankWindow );
				ToolTipCreator.addToEntity( _bankWindow, InteractionCreator.CLICK, "ENTER" );
				
				ToolTipCreator.removeFromEntity( _bankEntrance );
				ToolTipCreator.addToEntity( _bankEntrance, InteractionCreator.CLICK, "ENTER" );
				
				spatial.y 										=	Spatial( _bankWindow.get( Spatial )).y;
				Npc( _total.get( Npc )).ignoreDepth = false;
				
				if( _scutaro )
				{	
					var sceneInteraction:SceneInteraction		=	new SceneInteraction();
					sceneInteraction.reached.add( scutaroFacesPlayer );
					_scutaro.add( sceneInteraction );
					
					reference 									=	Display( _scutaro.get( Display )).displayObject;
				}
				
				DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, reference, true )					
			}
		}
		
		private function landInBank():void
		{
			CharUtils.lockControls( player, false, false );
			DisplayUtils.moveToOverUnder( Display( _bankTop.get( Display )).displayObject, Display( player.get( Display )).displayObject, true );
		}
		
		private function bankEntranceApproached( $player:Entity, bankExit:Entity ):void
		{
			var audio:Audio 								=	_bankDoor.get( Audio );
			var dialog:Dialog 								=	player.get( Dialog );
			var spatial:Spatial 							=	player.get( Spatial );
			var exitSpatial:Spatial 						=	bankExit.get( Spatial );
			var sceneInteraction:SceneInteraction;
			var timeline:Timeline							=	_bankDoor.get( Timeline );
			
			if( !_inBank )
			{
				dialog.sayById( "locked" );
			}
			else
			{		
				Npc( _total.get( Npc )).ignoreDepth = false;
				
				timeline.play();
				timeline.handleLabel( "open", closeBankDoor );
				
				audio.playCurrentAction( TRIGGER );
				
				ToolTipCreator.removeFromEntity( _bankWindow );;
				ToolTipCreator.addToEntity( _bankWindow, InteractionCreator.CLICK, "ENTER" );
				
				ToolTipCreator.removeFromEntity( _bankEntrance );
				ToolTipCreator.addToEntity( _bankEntrance, InteractionCreator.CLICK, "ENTER" );
				
				spatial.x 									=	exitSpatial.x;
				
				player.add( new PlatformDepthCollider());
				
				if( shellApi.checkEvent( _events.DROPPED_CAMERA ) && !shellApi.checkItemEvent( _events.CAMERA ))
				{
					InteractionCreator.addToEntity( _camera, [ InteractionCreator.CLICK ]);
					ToolTipCreator.addToEntity( _camera, InteractionCreator.CLICK );
					
					sceneInteraction 						=	new SceneInteraction();
					sceneInteraction.reached.addOnce( inPositionForCamera );
					_camera.add( sceneInteraction ).add( new Item());
				}
			}
			
			if( _scutaro && !_scutaro.has( SceneInteraction ))
			{
				sceneInteraction							=	new SceneInteraction();
				sceneInteraction.reached.add( scutaroFacesPlayer );
				_scutaro.add( sceneInteraction );
			}
		}
		
		private function closeBankDoor():void
		{
			var validHit:ValidHit 						=	player.get( ValidHit );
			validHit.inverse 							=	true;
			_inBank 									=	false;
			var reference:Display						=	_bankDoor.get( Display );
			
			if( _scutaro )
			{
				SceneUtil.lockInput( this );
				CharUtils.moveToTarget( player, 690, 1430, true, inPositionForScutaro );
				reference 								=	_scutaro.get( Display );
			}
			
			DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, reference.displayObject, true );
			
			var timeline:Timeline 						=	_bankDoor.get( Timeline );
			timeline.reverse							=	true;
			timeline.play();
			timeline.handleLabel( "closed", exitBank );
			
			var audio:Audio 							=	_bankDoor.get( Audio );
			audio.playCurrentAction( TRIGGER_OUT );
		}
		
		private function exitBank():void
		{
			var timeline:Timeline 						=	_bankDoor.get( Timeline );
			timeline.reverse							=	false;
		}
		
		private function scutaroKnocks():void
		{	
			if( !_scutaroScared )
			{
				if( !_scutaroTalking )
				{
					var timeline:Timeline 							=	_scutaro.get( Timeline );
					timeline.gotoAndPlay( "start_knock" );
					timeline.handleLabel( "end_knock", setScutaroStand );
					
					_scutaroTalking									=	true;
					
					var dialog:Dialog 								=	_scutaro.get( Dialog );
					dialog.faceSpeaker								=	false;
					//dialog.allowOverwrite							=	false;
					dialog.sayById( "knock" );
					dialog.complete.addOnce( setScutaroWait );
				}
				else
				{
					_scutaroTimer									=	new TimedEvent( 10, 1, scutaroKnocks );
					SceneUtil.addTimedEvent( this, _scutaroTimer );			
				}
			}
		}
		
		private function setScutaroStand():void
		{
			var timeline:Timeline 							=	_scutaro.get( Timeline );
			timeline.gotoAndPlay( "stand" );
		}
		
		private function setScutaroWait( dialogData:DialogData ):void
		{			
			var dialog:Dialog 								=	_scutaro.get( Dialog );
			dialog.faceSpeaker								=	true;
			//dialog.allowOverwrite							=	true;
			
			_scutaroTalking									=	false;
			_scutaroTimer									=	new TimedEvent( 10, 1, scutaroKnocks );
			SceneUtil.addTimedEvent( this, _scutaroTimer );			
		}
		
		private function scutaroFacesPlayer( $player:Entity, $scutaro:Entity ):void
		{
			if( !_scutaroTalking && Spatial( $player.get( Spatial )).x < Spatial( $scutaro.get( Spatial )).x )
			{
				CharUtils.setDirection( _scutaro, false );
				_scutaroTalking								=	true;
			}
		}
		
		private function scutaroFacesBank( dialogData:DialogData ):void
		{
			CharUtils.setDirection( _scutaro, true );
			_scutaroTalking									=	false;
		}
		
		// in place to talk to scutaro
		private function inPositionForScutaro( $player:Entity ):void
		{
			var timeline:Timeline 							=	player.get( Timeline );
			timeline.handleLabel( "startBreath", interactWithScutaro );
			
			var children:Children 							=	_scutaro.get( Children );
			var entity:Entity;
			var wordBalloon:WordBalloon;
			
			for each( entity in children.children )
			{
				if(	entity.has( WordBalloon ))
				{
					wordBalloon 							= 	entity.get( WordBalloon );
					wordBalloon.lifespan 					=	0;
				}
			}
		}
		
		private function interactWithScutaro():void
		{
			CharUtils.setDirection( player, false );
			CharUtils.setAnim( player, Throw );
			var dialog:Dialog 								=	player.get( Dialog );
			
			if( SkinPart( SkinUtils.getSkinPart( player, SkinUtils.FACIAL )).value == "tf_garbanzo_man_head" )
			{
				_scutaroScared 								=	true;
				_characterGroup.addFSM( _scutaro, true, null, "", true );
				
				// stop timer for scutaro
				_scutaroTimer.stop();
				_scutaroTimer 								=	null;
				
				dialog.sayById( "ooga" );
				dialog.complete.addOnce( scareScutaro );
				
				dialog 										=	_scutaro.get( Dialog );
				dialog.complete.removeAll();
			}
			else
			{
				_scutaroTalking 							=	true;
				dialog.sayById( "boo" );
				SceneUtil.lockInput( this, false );
			}
		}
		
		private function scareScutaro( dialogData:DialogData ):void
		{
			CharUtils.setDirection( player, false );
			var motionControl:CharacterMotionControl 		=	_scutaro.get( CharacterMotionControl );
			motionControl.maxVelocityX 						=	800;
			
			var fsmControl:FSMControl 						=	_scutaro.get( FSMControl );
			var walkState:MCWalkState 						=	fsmControl.getState( MovieclipState.WALK ) as MCWalkState;
			walkState.walkLabel								=	"run";
			
			var timeline:Timeline 							=	_scutaro.get( Timeline );
			timeline.gotoAndPlay( "shocked" );
			timeline.handleLabel( "end_drop_box", setScutaroRun );
			
			var spatial:Spatial 							=	_scutaro.get( Spatial );
			var tween:Tween 								=	new Tween();
			tween.to( spatial, .5, { x : spatial.x - 50 });
			_scutaro.add( tween );
		}
		
		private function setScutaroRun():void
		{
			var spatial:Spatial 							=	_camera.get( Spatial );
			spatial.x 										=	Spatial( _scutaro.get( Spatial )).x + 35;
			
			Display( _camera.get( Display )).alpha 			=	1;
			
			InteractionCreator.addToEntity( _camera, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( _camera, InteractionCreator.CLICK );
			
			var sceneInteraction:SceneInteraction 			=	new SceneInteraction();
			sceneInteraction.reached.addOnce( inPositionForCamera );
			_camera.add( sceneInteraction );
			
			_camera.add( new Item());
			
			var timeline:Timeline 							=	_scutaro.get( Timeline );
			CharUtils.moveToTarget( _scutaro, -10, 1540, true, scutaroFled );
		}
		
		private function scutaroFled( scutaro:Entity ):void
		{
			removeEntity( _scutaro );
			_scutaro 										=	null;
			
			CharUtils.lockControls( player, false, false );
			SceneUtil.lockInput( this, false );
			
			shellApi.completeEvent( _events.DROPPED_CAMERA );
		}
		
		// CAMERA LOGIC
		private function inPositionForCamera( $player:Entity = null, camera:Entity = null ):void
		{
			SceneUtil.lockInput( this );	
			camera.remove( Item );
			CharUtils.moveToTarget( player, 570, 1420, true, checkPositionForCamera );
		}
		
		private function checkPositionForCamera( $player:Entity ):void
		{
			DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _camera.get( Display )).displayObject, false );
			MotionUtils.zeroMotion( player );
			CharUtils.setState( player, CharacterState.STAND );
			
			startReachIntoBox();
		}
		
		private function startReachIntoBox():void
		{
			CharUtils.setDirection( player, false );
			
			var timeline:Timeline 							=	player.get( Timeline );
			timeline.handleLabel( "startBreath", reachIntoBox );
		}
		
		private function reachIntoBox():void
		{
			CharUtils.position( player, 540, 1460 );
			CharUtils.setAnim( player, Place );
			
			var timeline:Timeline 							=	player.get( Timeline );
			timeline.handleLabel( "trigger", getCamera );
		}
		
		private function getCamera():void
		{
			shellApi.getItem( _events.CAMERA, "timmy", true, gotCamera);
		}
		
		private function gotCamera():void
		{
			removeEntity( _camera );
			SceneUtil.lockInput( this, false );
			CharUtils.lockControls( player, false, false );
		}
		
		// CRISPIN'S CAR SEQUENCE
		private function checkTheCar( ...p ):void
		{
			if( shellApi.checkItemEvent( _events.CAR_KEY ))
			{
				moveToCar();
			}
			else
			{
				CharUtils.setDirection( player, true );
				var dialog:Dialog 								=	player.get( Dialog );
				dialog.sayById( "no_keys" );
			}
		}
		
		private function moveToCar():void
		{
			CharUtils.moveToTarget( player, 5480, 1555, true, atCar );
		}
		
		private function atCar( player:Entity ):void
		{
			SceneUtil.lockInput( this );
			if( shellApi.checkEvent( _events.TOTAL_PRESENT ))
			{
				super.totalUnfollow();
			}
			
			var display:Display 							=	player.get( Display );
			display.visible 								=	false;
			
			var shakeMotion:ShakeMotion 					=	new ShakeMotion( new RectangleZone( -2, -2, 2, 2 ));
			
			var car:Entity 									=	getEntityById( "car" );
			var audio:Audio	 								=	car.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			car.add( shakeMotion ).add( new SpatialAddition());
			
			CharUtils.setDirection( player, false );
			var spatial:Spatial 							=	player.get( Spatial );
			spatial.x 										=	5340;
			
			var dialog:Dialog 								=	player.get( Dialog );
			dialog.sayById( "here_we_go" );
			dialog.complete.addOnce( startCar );
		}
		
		private function startCar( dialogData:DialogData ):void
		{
			var car:Entity 									=	getEntityById( "car" );
			var shakeMotion:ShakeMotion 					=	car.get( ShakeMotion );
			shakeMotion.active 								=	false;
			
			var spatialAddition:SpatialAddition 			=	car.get( SpatialAddition );
			spatialAddition.x 								=	0;
			spatialAddition.y 								=	0;
			
			vehicleSmoke( car, new Point( 120,  0 ));
			
			shellApi.completeEvent( _events.CRASHED_CAR );
			super.moveVehicle( car, 4000, -400, zoomOff );
		}
		
		private function zoomOff( car:Entity ):void
		{
			shellApi.removeItem( _events.CAR_KEY );
			shellApi.loadScene( TimmysStreet, 3100, 950, "left", NaN, 1 );
		}
	}
}
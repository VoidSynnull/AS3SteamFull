package game.scenes.timmy.school
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Talk;
	import game.components.entity.character.part.SkinPart;
	import game.components.hit.CurrentHit;
	import game.components.hit.Item;
	import game.components.hit.ValidHit;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Throw;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundAction;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.timmy.TimmyScene;
	import game.scenes.timmy.timmysStreet.TimmysStreet;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.CharacterDepthSystem;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.movieClip.MCStandState;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class School extends TimmyScene
	{
		private var _quizing_rollo:Boolean 							=	false;
		private var _molly:Entity;
		private var _rollo:Entity;
		private var _panic:int 										=	0;
//		private var _catSequence:BitmapSequence;
//		private var _totalUpSequence:BitmapSequence;
//		private var _totalDownSequence:BitmapSequence;
		private var _totalClimb:Entity;
		private var _totalStuck:Entity;
		private var _logoTimeline:Timeline;
		private var _totalMissle:Entity;
		private var _cameraEntity:Entity;
		
		private const TOTAL_SLIDE_X:Number 							=	1470;
		
		private const PANIC:String 									=	"panic";
		private const GARBANZO:String 								=	"tf_garbanzo_man_head";
		private const HIGHER:String 								=	"higher";
		private const OVER:String 									=	"over";
		private const END_TEST:String 								=	"end_test";
		private const UNLOCK:String 								=	"unlock";
		private const GARBAGE_TRUCK:String							=	"garbageTruck";
		private const ON_TOWER:String 								=	"on_tower";
		
		public function School()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/school/";
			super.init(container);
		}
		
		override protected function addBaseSystems():void
		{
			if( !super.getSystem( CharacterDepthSystem ))
			{
				addSystem( new CharacterDepthSystem());
			}
			addSystem( new ThresholdSystem());
			addSystem( new TriggerHitSystem());
			super.addBaseSystems();
		}
		
//		override public function destroy():void
//		{
////			if( _catSequence )
////			{
////				_catSequence.destroy();
////				_catSequence= null;
////			}
//			if( _totalUpSequence )
//			{
//				_totalUpSequence.destroy();
//				_totalUpSequence= null;
//			}
//			if( _totalDownSequence )
//			{
//				_totalDownSequence.destroy();
//				_totalDownSequence= null;
//			}
//			
//			super.destroy();
//		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			setupAssets();
			addItemHitSystem();
		}
		
		/**
		 * UTILITY FUNCTIONS
		 */
		private function setupAssets():void
		{
			_molly 													=	getEntityById( "molly" );
			_rollo 													=	getEntityById( "rollo" );
			
			if( _rollo && _rollo.has( Npc ))
			{
				Npc( _rollo.get( Npc )).ignoreDepth = true;
			}
			if( _molly && _molly.has( Npc ))
			{
				Npc( _molly.get( Npc )).ignoreDepth = true;
			}
			
			player.remove( PlatformDepthCollider );
			
			var highQuality:Boolean = ( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST ) ? false : true;
			
			if( highQuality )
			{
				addSystem( new ShakeMotionSystem());
			}
			
			_characterGroup.addFSM( _rollo, true, null, "", true );
			_audioGroup.addAudioToEntity( _rollo );
			
			sceneInteraction										=	_rollo.get( SceneInteraction );
			sceneInteraction.reached.add( talkToRollo );
		
			var validHit:ValidHit 									=	new ValidHit( "inSlide" );
			validHit.inverse 										=	true;
			
			_total.add( new ValidHit( "ground", "baseGround" ));
			
			player.add( validHit );
			
			validHit												=	new ValidHit( "inSlide" );
			validHit.inverse 										=	true;
			_rollo.add( validHit );
			CharUtils.setDirection( _rollo, true );
			_logoTimeline	 										=	EntityUtils.getChildById( _rollo, "stanford" ).get( Timeline );
			_logoTimeline.gotoAndStop( 1 );
			
			var display:Display;
			var entity:Entity;
			var spatial:Spatial;
			var handbookPage:Entity;
			
			var sceneInteraction:SceneInteraction;
			var sleep:Sleep;
			var slide:Entity 										=	makeEntity( _hitContainer[ "slide" ]);
			var totalUpClip:MovieClip 								=	_hitContainer[ "totalUp" ];
			var totalDownClip:MovieClip 							=	_hitContainer[ "totalDown" ];
			
			totalUpClip.mouseChildren 								=	false;
			totalUpClip.mouseEnabled								=	false;
			
			totalDownClip.mouseChildren 							=	false;
			totalDownClip.mouseEnabled								=	false;
						
			if( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "5" ))
			{
				_characterGroup.addFSM( _molly, true, null, "", true );
				
				handbookPage 										=	makeEntity( _hitContainer[ _events.HANDBOOK_PAGE ], null, null, false, PerformanceUtils.defaultBitmapQuality + 2.0 );
				
				if( !shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "6" ))
				{	
					display 										= 	_molly.get( Display );
					display.visible 								=	false;
					sleep 											=	_molly.get( Sleep );
					if( !sleep )
					{
						sleep 										=	new Sleep();
						_molly.add( sleep );
					}
					sleep.sleeping 									=	true;
					sleep.ignoreOffscreenSleep 						=	true;
					
					spatial 										= 	_rollo.get( Spatial );
					
					
					_cameraEntity 									= 	getEntityById( "camera" );
					var shake:ShakeMotion 							=	new ShakeMotion( new RectangleZone( -10, -10, 10, 10 ));
					shake.active = false;
					_cameraEntity.add( shake ).add( new SpatialAddition());
					
					if( !shellApi.checkEvent( _events.FREED_ROLLO ))
					{
						CharUtils.setDirection( _rollo, false );
						_logoTimeline.gotoAndStop( 0 );
						
						validHit.inverse 							=	false;
							
						spatial.x 									=	850;
						spatial.y 									=	590;
						
					//	_totalUpSequence							=	BitmapTimelineCreator.createSequence( totalUpClip, true, PerformanceUtils.defaultBitmapQuality );
					//	_totalDownSequence							=	BitmapTimelineCreator.createSequence( totalDownClip, true, PerformanceUtils.defaultBitmapQuality );
						
					//	_totalClimb 								=	makeEntity( totalUpClip );//, _totalUpSequence );
						
						if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
						{
							super.convertContainer( totalUpClip, PerformanceUtils.defaultBitmapQuality + 1.0 );
						}
						_totalClimb									=	EntityUtils.createMovingTimelineEntity( this, totalUpClip, null, false );//=	makeEntity( _hitContainer[ _events.CAT ], null, "idle", true );
						
						display 									=	_totalClimb.get( Display );
						display.visible								=	false;
						
					//	_totalStuck 								=	makeEntity( totalDownClip );//, _totalDownSequence );
						if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
						{
							super.convertContainer( totalDownClip, PerformanceUtils.defaultBitmapQuality + 1.0 );
						}
						_totalStuck									=	EntityUtils.createMovingTimelineEntity( this, totalDownClip, null, false );//=	makeEntity( _hitContainer[ _events.CAT ], null, "idle", true );
						
						
						display 									=	handbookPage.get( Display );
						display.visible 							=	false;
						
						var fsmControl:FSMControl 					=	_rollo.get( FSMControl );
						var standState:MCStandState					=	fsmControl.getState( MovieclipState.STAND ) as MCStandState;
						standState.standLabel 						=	"stuck";
						
						var dialog:Dialog							=	_rollo.get( Dialog );
						dialog.faceSpeaker							=	false;
						
						DisplayUtils.moveToOverUnder( Display( _rollo.get( Display )).displayObject, Display( _totalStuck.get( Display )).displayObject, false );
					}
					
					// ROLLOS PUZZLE
					else if( !shellApi.checkEvent( _events.FREED_TOTAL ))
					{
						_hitContainer.removeChild( totalUpClip );
	//					_totalDownSequence							=	BitmapTimelineCreator.createSequence( totalDownClip, true, PerformanceUtils.defaultBitmapQuality );
						
	//					_totalStuck 								=	makeEntity( totalDownClip );//, _totalDownSequence, "idle", true );
						if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
						{
							super.convertContainer( totalDownClip, PerformanceUtils.defaultBitmapQuality + 1.0 );
						}
						_totalStuck									=	EntityUtils.createMovingTimelineEntity( this, totalDownClip, null, true );
						sceneInteraction							=	new SceneInteraction();
						sceneInteraction.reached.add( inspectTotal );
						Timeline( _totalStuck.get( Timeline )).gotoAndPlay( "idle" );
						_totalStuck.add( sceneInteraction );
						
						ToolTipCreator.addToEntity( _totalStuck, InteractionCreator.CLICK );
						InteractionCreator.addToEntity( _totalStuck, [ InteractionCreator.CLICK ]);
						
						display 									=	handbookPage.get( Display );
						display.visible 							=	false;
						
						_panic 										=	checkRolloFear();
						
						DisplayUtils.moveToOverUnder( Display( _rollo.get( Display )).displayObject, Display( _totalStuck.get( Display )).displayObject, true );
						setTotalAtSlide();
					}
					
					// TOTAL STUCK AS BITMAP OF THE LAST FRAME
					else
					{
						_hitContainer.removeChild( totalUpClip );
						totalDownClip.gotoAndStop( "end" );
						
						super.convertToBitmapSprite( totalDownClip, null, true, PerformanceUtils.defaultBitmapQuality );
						
						// SETUP HANDBOOK PAGE
						InteractionCreator.addToEntity( handbookPage, [ InteractionCreator.CLICK ]);
						ToolTipCreator.addToEntity( handbookPage );
						
						sceneInteraction							=	new SceneInteraction();
						sceneInteraction.reached.addOnce( getHandbookPage );
						handbookPage.add( sceneInteraction ).add( new Item());
						
						spatial 									=	handbookPage.get( Spatial );
						spatial.x 									-=	50;
						spatial.y 									=	700;
						
						DisplayUtils.moveToOverUnder( Display( _rollo.get( Display )).displayObject, Display( handbookPage.get( Display )).displayObject, false );
					}
					
					_totalMissle 									=	makeEntity( _hitContainer[ "totalMissle" ]);
					Display( _totalMissle.get( Display )).visible 	=	false;
					
					_hitContainer.removeChild( _hitContainer[ _events.CAT ]);
				}
				
				// MOLLY IS IN THE SCENE
				else
				{
					spatial 										=	_molly.get( Spatial );
					spatial.x 										=	550;
					
					sceneInteraction 								=	_molly.get( SceneInteraction );
					sceneInteraction.reached.add( talkToMolly );
					_hitContainer.removeChild( _hitContainer[ _events.HANDBOOK_PAGE ]);
					_hitContainer.removeChild( _hitContainer[ "totalMissle" ]);
					_hitContainer.removeChild( totalUpClip );
					
					totalDownClip.gotoAndStop( "end" );
					
					super.convertToBitmapSprite( totalDownClip, null, true, PerformanceUtils.defaultBitmapQuality );
					
					if( shellApi.checkItemEvent( _events.MONEY ))
					{
						display										=	_molly.get( Display );
						display.displayObject[ "shoes" ].alpha 		=	1;
						
						var truck:Entity 							=	makeAutomobile( this, _hitContainer[ GARBAGE_TRUCK ]);
	//					_catSequence 											=	BitmapTimelineCreator.createSequence( _hitContainer[ _events.CAT ], true, PerformanceUtils.defaultBitmapQuality );
						var cat:Entity;
						
						// CAT RETURNED
						if( !shellApi.checkEvent( _events.RETURNED_CAT ))
						{
							if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH){
								super.convertContainer( _hitContainer[_events.CAT], PerformanceUtils.defaultBitmapQuality + 1.0);
							}
							cat 												=	EntityUtils.createMovingTimelineEntity(this,_hitContainer[_events.CAT],null,false);
							Timeline( cat.get( Timeline )).gotoAndPlay( "drop" );
		//					cat 												=	makeEntity( _hitContainer[ _events.CAT ], _catSequence, "drop", false );	
							_audioGroup.addAudioToEntity( cat );
							Display( cat.get( Display )).visible 				=	false;
						}
						else
						{
							if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH){
								super.convertContainer( _hitContainer[_events.CAT], PerformanceUtils.defaultBitmapQuality + 1.0);
							}
							cat 												=	EntityUtils.createMovingTimelineEntity(this,_hitContainer[_events.CAT],null,true);
							Timeline( cat.get( Timeline )).gotoAndPlay( "idle" );
					//		cat 												=	makeEntity( _hitContainer[ _events.CAT ], _catSequence, "idle", true );
							_audioGroup.addAudioToEntity( cat );
							
							var mouth:Entity 									=	EntityUtils.getChildById( _molly, "mouth" );	
							var timeline:Timeline								=	mouth.get( Timeline );
							timeline.gotoAndStop( "happyIdle" );
							
							var talk:Talk 										=	_molly.get( Talk );
							talk.talkLabel 										=	"happyTalk";
							talk.mouthDefaultLabel								=	"happyIdle";
							
							_audioGroup.addAudioToEntity( cat );
							ToolTipCreator.addToEntity( cat, InteractionCreator.CLICK );
							InteractionCreator.addToEntity( cat, [ InteractionCreator.CLICK ]);
							
							sceneInteraction 									=	new SceneInteraction();
							sceneInteraction.reached.add( playWithKitty );
							cat.add( sceneInteraction );
						}
					}
					else
					{
						_hitContainer.removeChild( _hitContainer[ GARBAGE_TRUCK ]);
						_hitContainer.removeChild( _hitContainer[ _events.CAT ]);
					}
				}
			}
			else
			{
				removeEntity( _molly );
				_molly 												=	null;
				
				spatial												=	_rollo.get( Spatial );
				spatial.x 											=	1520;
				
				_hitContainer.removeChild( totalUpClip );
				_hitContainer.removeChild( _hitContainer[ _events.CAT ]);
				_hitContainer.removeChild( _hitContainer[ _events.HANDBOOK_PAGE ]);
				_hitContainer.removeChild( _hitContainer[ "totalMissle" ]);
				totalDownClip.gotoAndStop( "pop" );
				
				super.convertToBitmapSprite( totalDownClip, _hitContainer, true, PerformanceUtils.defaultBitmapQuality );
			}			
			
			DisplayUtils.moveToTop( Display( _total.get( Display )).displayObject );
			DisplayUtils.moveToTop( Display( player.get( Display )).displayObject );
			
			setupHorse();
			setupSlide();
		}
		
		public function addItemHitSystem():void
		{
			var itemHitSystem:ItemHitSystem 						=	getSystem( ItemHitSystem ) as ItemHitSystem;
			if( !itemHitSystem )	// items require ItemHitSystem, add system if not yet added
			{
				itemHitSystem 										=	new ItemHitSystem();
				addSystem( itemHitSystem, SystemPriorities.resolveCollisions );
			}	
			itemHitSystem.gotItem.removeAll();
			itemHitSystem.gotItem.add( itemHit );
		}
		
		public function itemHit( entity:Entity ):void
		{
			var id:Id 				=	entity.get( Id );
			
			if( id.id 			==	_events.HANDBOOK_PAGE )
			{
				getHandbookPage();
			}
			else
			{
				_itemGroup.showAndGetItem( _events.POLE, null, null, null, entity );
			}
		}
		
		private function getHandbookPage( player:Entity = null, handbookPage:Entity = null ):void
		{
			shellApi.completeEvent( _events.GOT_DETECTIVE_LOG_PAGE + "6" );
			showDetectivePage( 6, enterMolly );
			
			if( handbookPage )
			{
				removeEntity( getEntityById( _events.HANDBOOK_PAGE ));
			}
		}
		
		private function stopConversation( dialogData:DialogData = null ):void
		{
			// RETURN ROLLOs INTERACTION/TOOLTIP
			var sceneInteraction:SceneInteraction 					=	new SceneInteraction();
			sceneInteraction.reached.add( talkToRollo );
			_rollo.add( sceneInteraction );
			_quizing_rollo											=	false;
			
			ToolTipCreator.addToEntity( _rollo, InteractionCreator.CLICK );
			CharUtils.lockControls( player, false, false );
			
			// RETURN SLIDEs INTERACTION/TOOLTIP
			var slideInteraction:Entity 							=	getEntityById( "slideInteraction" );
			sceneInteraction 										=	new SceneInteraction();
			sceneInteraction.reached.add( canSlide );
			
			slideInteraction.add( sceneInteraction );
			ToolTipCreator.addToEntity( slideInteraction, InteractionCreator.CLICK );
			
			// RETURN TOTAL STUCK INTERACTION/TOOLTIP
			if( !shellApi.checkEvent( _events.FREED_TOTAL ))
			{
				ToolTipCreator.addToEntity( _totalStuck, InteractionCreator.CLICK );
				InteractionCreator.addToEntity( _totalStuck, [ InteractionCreator.CLICK ]);
				
				sceneInteraction							=	new SceneInteraction();
				sceneInteraction.reached.add( inspectTotal );
				_totalStuck.add( sceneInteraction );
			}
			
			// RETURN HUD
			var hud:Hud 											=	getGroupById( Hud.GROUP_ID ) as Hud;
			hud.show( true );
			
			//var dialog:Dialog 										=	player.get( Dialog );
			//dialog.allowOverwrite 									=	false;
		}
		
		private function checkRolloFear():Number
		{
			var displayObject:DisplayObject 						=	Display( _rollo.get( Display )).displayObject;
			var panic:Number 										=	0;
			var audio:Audio											=	_rollo.get( Audio );
			
			for( var number:int = 3; number > 0; number -- )
			{
				if( shellApi.checkEvent( _events.SCARED_ROLLO + number ) )
				{
					if( panic == 0 )
					{ 
						displayObject[ "shake" + number ].alpha = 1;
					
						displayObject[ "face" ].alpha = 0;
						displayObject[ "hair" ].alpha = 0;
						displayObject[ "pupils" ].alpha = 0;
						displayObject[ "head" ].alpha = 0;
					
						panic 										=	number;
					}
					
					audio.playCurrentAction( PANIC + number );
				}
			}
			
			if( panic >= 2 && !shellApi.checkEvent( _events.FREED_TOTAL ))
			{
				var totalTimeline:Timeline 							=	_totalStuck.get( Timeline );
				totalTimeline.gotoAndPlay( "shake" );
			}
			
			return panic;
		}
		
		private function playWithKitty( $player:Entity, $cat:Entity ):void
		{
			var molly:Entity 						=	getEntityById( "molly" );
			var dialog:Dialog						=	molly.get( Dialog );
			dialog.sayById( "likes_you" );
			
			var audio:Audio							=	$cat.get( Audio );
			audio.playCurrentAction( TRIGGER );
		}
		
		// HORSE LOGIC
		private function setupHorse():void
		{
			var clip:MovieClip 								=	_hitContainer[ "horseVis" ];
			var entity:Entity 								=	makeEntity( clip );
			
			var horse:Entity 								=	getEntityById( "horse" );
			Display( horse.get( Display )).isStatic 		=	false;
			EntityUtils.followTarget( entity, horse );
			
			_audioGroup.addAudioToEntity( horse );
			
			var triggerHit:TriggerHit						=	new TriggerHit( null, new <String>[ "player" ]);
			triggerHit.triggered							= 	new Signal();
			triggerHit.triggered.add( onHorse );
			triggerHit.offTriggered							=	new Signal();
			triggerHit.offTriggered.add( offHorse );
			horse.add( triggerHit ).add( new Tween());
		}
		
		private function onHorse():void
		{
			var horse:Entity 								=	getEntityById( "horse" );
			var audio:Audio 								=	horse.get( Audio );
			var tween:Tween 								=	horse.get( Tween );
			var spatial:Spatial 							=	horse.get( Spatial );

			audio.playCurrentAction( TRIGGER );
			tween.to( spatial, 1, { y : 565, ease : Quadratic.easeOut });
		}
		
		private function offHorse():void
		{
			var horse:Entity 								=	getEntityById( "horse" );
			var audio:Audio 								=	horse.get( Audio );
			var tween:Tween 								=	horse.get( Tween );
			var spatial:Spatial 							=	horse.get( Spatial );
			
			audio.playCurrentAction( TRIGGER_OUT );
			tween.to( spatial, 1, { y : 548, ease : Quadratic.easeOut });
		}
		
		// SLIDE LOGIC
		private function setupSlide():void
		{
			var slideInteraction:Entity 						=	getEntityById( "slideInteraction" );
			var sceneInteraction:SceneInteraction 				=	slideInteraction.get( SceneInteraction );
			sceneInteraction.reached.add( canSlide );
			 
			var triggerHit:TriggerHit			=	new TriggerHit( null, new <String>[ "player" ]);
			triggerHit.triggered 				=	new Signal();
			triggerHit.triggered.add( moveBehindTotal );
			triggerHit.offTriggered				=	new Signal();
			triggerHit.offTriggered.add( addNpcToTotal );
			
			var stairs:Entity 					=	getEntityById( "stairs" );
			stairs.add( triggerHit );
		}
		
		private function moveBehindTotal():void
		{
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING ) || shellApi.checkEvent( _events.TOTAL_PRESENT ))
			{
				Npc( _total.get( Npc )).ignoreDepth = true;
				DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _total.get( Display )).displayObject, false );
			}
		}
		
		private function addNpcToTotal():void
		{
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING ) || shellApi.checkEvent( _events.TOTAL_PRESENT ))
			{
				Npc( _total.get( Npc )).ignoreDepth = false;
			}
		}
		
		private function canSlide( player:Entity, slideInteraction:Entity ):void
		{
			if( !shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "5" ) || ( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "5" ) && shellApi.checkEvent( _events.FREED_TOTAL )))
			{
				var currentHit:CurrentHit 						=	player.get( CurrentHit );
				var topStair:Entity 							=	getEntityById( "stairs" );
				
				if( currentHit.hit && currentHit.hit == topStair )
				{
					CharUtils.moveToTarget( player, 1200, 486, true, startSlide );
				}
				else
				{
					var motionControl:CharacterMotionControl 	=	player.get( CharacterMotionControl );
					motionControl.spinning						=	false;
					
					var motion:Motion 							=	player.get( Motion );
					motion.rotationAcceleration = motion.rotationVelocity = motion.previousRotation = 0;
					
					var spatial:Spatial							=	player.get( Spatial );
					spatial.rotation 							=	0;
					
					MotionUtils.zeroMotion( player );
					CharUtils.setState( player, CharacterState.STAND );
					CharUtils.position( player, 1235, 480 );
					var timeline:Timeline						=	player.get( Timeline );
					
					timeline.handleLabel( CharacterState.STAND, startSlide );
				}
			}
			else
			{
				var dialog:Dialog 								=	player.get( Dialog );
				dialog.sayById( "clogged" );
			}
		}
		
		private function startSlide( $player:Entity = null ):void
		{
			toggleNpcs( false );
			MotionUtils.zeroMotion( player );
			CharUtils.lockControls( player );
			CharUtils.setDirection( player, false );
			
			var slideInteraction:Entity 					=	getEntityById( "slideInteraction" );
			var spatial:Spatial 							=	player.get( Spatial );
			spatial.x 										=	1200;
			
			var validHit:ValidHit 							=	player.get( ValidHit );
			validHit.inverse								=	false;
			
			CharUtils.setAnim( player, Sit );
			DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( slideInteraction.get( Display )).displayObject, false );
			
			var timeline:Timeline 							=	player.get( Timeline );
			timeline.handleLabel( "loop", goDownSlide );
		}
		
		private function goDownSlide():void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "smooth_surface_drag_02.mp3" );
			var display:Display 							=	player.get( Display );
			display.visible 								=	false;
			var spatial:Spatial 							=	player.get( Spatial );
			
			var tween:Tween	 								=	player.get( Tween );
			if( !tween )
			{
				tween 										=	new Tween();
				player.add( tween );
			}
			
			tween.to( spatial, 1, { x : 886, y : 630, onComplete : exitSlide, onCompleteParams : [ player, 2000, landedFromSlide ]});
		}
		
		private function exitSlide( character:Entity, velocityX:Number, handler:Function ):void
		{		
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "whoosh_09.mp3" );
			var validHit:ValidHit 							=	character.get( ValidHit );
			if( validHit )
			{
				validHit.inverse								=	true;	
			}
			
			var display:Display 							=	character.get( Display );
			display.visible  								=	true;
			
			var motion:Motion 								=	character.get( Motion );
			motion.maxVelocity.x						 	=	velocityX;
			motion.velocity.x 								=	- velocityX;
			motion.velocity.y 								=	-200;
			
			var ground:Entity 								=	getEntityById( "ground" );
			var triggerHit:TriggerHit 						=	ground.get( TriggerHit );
			if( !triggerHit )
			{
				triggerHit 									=	new TriggerHit( null, new <String>[ "player" ]);
				triggerHit.triggered 						=	new Signal();
				ground.add( triggerHit );
			}
			
			triggerHit.validEntities 						=	new <String>[ Id( character.get( Id )).id ];
			triggerHit.active = false;
			triggerHit.triggered.addOnce( handler );
			CharUtils.stateDrivenOn( character );
		}
		
		private function landedFromSlide():void
		{
			var motion:Motion 								=	player.get( Motion );
			motion.velocity.x 								=	0;
			motion.maxVelocity.x 							=	400;
			
			CharUtils.lockControls( player, false, false );
			toggleNpcs( true );
		}
		
		private function toggleNpcs( addNpc:Boolean ):void
		{
			if( addNpc )
			{
				Npc( _total.get( Npc )).ignoreDepth = false;
			}
			else
			{
				Npc( _total.get( Npc )).ignoreDepth = true;
			}
		}
		
		/**
		 * EVENT HANDLER
		 */
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var dialog:Dialog								=	player.get( Dialog );
			var audio:Audio 								=	_rollo.get( Audio );
			
			if( _totalStuck )
			{
				var totalTimeline:Timeline 					=	_totalStuck.get( Timeline );
			}
			var displayObject:DisplayObject 				=	Display( _rollo.get( Display )).displayObject;
			
			switch( event )
			{
				case HIGHER:
					// increase shake
					_panic ++;
					
					audio.playCurrentAction( PANIC + _panic );
					if( !shellApi.checkEvent( _events.SCARED_ROLLO + _panic ))
					{	
						shellApi.completeEvent( _events.SCARED_ROLLO + _panic );
						displayObject[ "shake" + _panic ].alpha = 1;
						if( _panic > 1 )
						{
							displayObject[ "shake" + ( _panic - 1 )].alpha = 0;
							
						}
						else
						{
							displayObject[ "face" ].alpha = 0;
							displayObject[ "hair" ].alpha = 0;
							displayObject[ "pupils" ].alpha = 0;
							displayObject[ "head" ].alpha = 0;
						}
					}
					
					if( _panic == 2 )
					{
						totalTimeline.gotoAndPlay( "shake" );
					}
					else if( _panic == 3 )
					{
						shakeScene();
						CharUtils.setAnim( player, Grief );
					}
					
					break;
			
				case OVER:
					dialog.sayById( "wait" );
					dialog.complete.addOnce( stopConversation );
					break;
				
				case END_TEST:
					if( shellApi.checkEvent( _events.SCARED_ROLLO + "3" ))
					{
						shellApi.completeEvent(_events.KEY_EATEN);
					
						// free total
						SceneUtil.lockInput( this );
						totalTimeline.gotoAndStop( "end" );
						
						Display( _totalMissle.get( Display )).visible 	=	true;
						Display( _totalStuck.get( Display )).displayObject.mouseEnabled = false;
						Display( _totalStuck.get( Display )).displayObject.mouseChildren = false;
						
						var motion:Motion 								=	new Motion();
						motion.maxVelocity.x						 	=	4000;
						motion.velocity.x 								=	-800;
						motion.velocity.y 								=	-500;
						motion.acceleration.y 							=	MotionUtils.GRAVITY;
						
						var threshold:Threshold 						=	new Threshold( "y", ">" );
						threshold.threshold								=	680;
						threshold.entered.addOnce( totalFreed );
						_totalMissle.add( threshold ).add( motion );
					}
					else
					{
						stopConversation();
					}
					
					break;
				
				case _events.USE_TREATS_SCHOOL:
					CharUtils.moveToTarget( player, 1240, 450, false, inTreatPosition );
					break;
				
				case _events.CALL_TOTAL:
					if(( shellApi.checkEvent( _events.FREED_TOTAL ) && !shellApi.checkEvent( _events.TOTAL_FOLLOWING )) || ( !shellApi.checkEvent( _events.FREED_ROLLO ) && !shellApi.checkEvent( _events.TOTAL_FOLLOWING )))
					{
						totalFollow();
					}
					else if( !_quizing_rollo )
					{
						dialog.sayById( "cant_use_treats" );
					}
					break;
				
				case _events.USE_SHOES:
					if( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "6" ))
					{
						CharUtils.moveToTarget( player, 460, 690, false, positionForShoes );
					}
					else
					{
						dialog.sayById( "cant_use_shoes" );
					}
					break;
				
				case _events.TRADE_SHOES:
					_itemGroup.takeItem( _events.SHOES, "molly", "timmy", null, putOnShoes );
					break;
				
				case _events.USE_CAT:
					if( shellApi.checkItemEvent( _events.SHOES ))
					{
						CharUtils.moveToTarget( player, 430, 690, false, positionForCat );
					}
					else
					{
						dialog.sayById( "no_use_cat" );
					}
					break;
				
				case _events.SUCH_RELIEF:
					CharUtils.lockControls( player, false, false );
					SceneUtil.lockInput( this, false );
					shellApi.completeEvent( _events.FREED_TOTAL );
					shellApi.completeEvent( _events.TOTAL_FOLLOWING );
					endShake();
					
					// reset rollos head
					displayObject[ "face" ].alpha = 1;
					displayObject[ "hair" ].alpha = 1;
					displayObject[ "pupils" ].alpha = 1;
					displayObject[ "head" ].alpha = 1;
					displayObject[ "shake3" ].alpha = 0;
					break;
				
				case UNLOCK:
					SceneUtil.lockInput( this, false );
					break;
				
				case ON_TOWER:
					chaseThePants();
					break;
				
				default:
					super.eventTriggered( event, makeCurrent, init, removeEvent );
					break;
			}
		}
	
		private function beginFollow(...p):void
		{
			this.totalFollow();
		}
		
		/**
		 * TOTAL IN SLIDE
		 */
		private function talkToRollo( player:Entity, rollo:Entity ):void
		{
			var dialog:Dialog 										=	player.get( Dialog );
			//dialog.allowOverwrite 									=	true;
			
			dialog 													=	_rollo.get( Dialog );
			
			
			if( _totalDistraction )
			{
				dialog.sayById( "distracted" );	
			}
			else if( !shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "5" ))
			{
				dialog.sayById( "school" );
			}
			 
			else if( !shellApi.checkEvent( _events.FREED_ROLLO ))
			{
				dialog.sayById( "help" );
			}
			
			else if( !shellApi.checkEvent( _events.FREED_TOTAL ))
			{
				var skinPart:SkinPart 									=	SkinUtils.getSkinPart( player, SkinUtils.FACIAL );
				_rollo.remove( SceneInteraction );
				ToolTipCreator.removeFromEntity( _rollo );
				
				CharUtils.lockControls( player );
				
				var slideInteraction:Entity 							=	getEntityById( "slideInteraction" );
				slideInteraction.remove( SceneInteraction );
				ToolTipCreator.removeFromEntity( slideInteraction );
				
				_totalStuck.remove( SceneInteraction );
				ToolTipCreator.removeFromEntity( _totalStuck );
								
				var hud:Hud 											=	getGroupById( Hud.GROUP_ID ) as Hud;
				hud.show( false );
				_quizing_rollo 											=	true;
				
				if( skinPart.value 	==	GARBANZO )
				{
					dialog.sayById( "garbanzo" );
					dialog.complete.addOnce( removeMask );
				}
				else
				{
					startTheChirps();					
				}
			}
			else
			{
				dialog.sayById( "relief" );
			}
			
			if( dialog.faceSpeaker )
			{
				var frame:Number = Spatial( player.get( Spatial )).x < Spatial( _rollo.get( Spatial )).x ? 0 : 1;
				_logoTimeline.gotoAndStop( frame );
				
				var faceRight:Boolean 		= 	frame == 0 ? false : true;
				CharUtils.setDirection( _rollo, faceRight );
			}
		}
		
		private function removeMask( dialogData:DialogData = null ):void
		{
			SkinUtils.setSkinPart( player, SkinUtils.FACIAL, "empty", true, startTheChirps );
		}
		
		private function startTheChirps( part:SkinPart = null ):void
		{
			var dialog:Dialog 											=	player.get( Dialog );
			if( _panic != 0 )
			{
				dialog.sayById( "round" + ( _panic ));
			}
			else
			{
				dialog.sayById( "quiz" );
			}
		}
		
		private function inTreatPosition( player:Entity ):void
		{
			SceneUtil.lockInput( this );
			
			var timeline:Timeline 									=	player.get( Timeline );
			timeline.handleLabel( "startBreath", faceRollo );
		}
		
		private function faceRollo():void
		{			
			MotionUtils.zeroMotion( player );
			var motion:Motion 										=	player.get( Motion );
			motion.rotationAcceleration = motion.rotationVelocity = motion.previousRotation = 0;
			
			var spatial:Spatial										=	player.get( Spatial );
			spatial.rotation										=	0;
			
			var characterMotion:CharacterMotionControl 				=	player.get( CharacterMotionControl );
			characterMotion.spinning								=	false;
			
			CharUtils.position( player, 1240, 480 );
			
			CharUtils.setDirection( player, false );
			CharUtils.setAnim( player, Throw );
			var timeline:Timeline 									=	player.get( Timeline );
			timeline.handleLabel( "ending", targetSlide );
		}
		
		private function targetSlide():void
		{		
			SceneUtil.setCameraTarget( this, getEntityById( "slide" ));
			DisplayUtils.moveToOverUnder( Display( _total.get( Display )).displayObject, Display( _totalStuck.get( Display )).displayObject, true );
			
			CharUtils.moveToTarget( _total, TOTAL_SLIDE_X, 560, true, totalClimbsSlide );
		}
		
		private function totalClimbsSlide( total:Entity ):void
		{
			var display:Display										=	_totalClimb.get( Display );
			display.visible 										=	true;
			setTotalAtSlide();
			
			var spatial:Spatial 									=	_total.get( Spatial );
			spatial.x 												=	100;
			
			var timeline:Timeline 									=	_totalClimb.get( Timeline );
			timeline.gotoAndPlay( "climb" );
			timeline.labelReached.add( handleTotalSlideSounds );
			
			var fsmControl:FSMControl 								=	_rollo.get( FSMControl );
			var standState:MCStandState								=	fsmControl.getState( MovieclipState.STAND ) as MCStandState;
			standState.standLabel 									=	"eject";
			
			Sleep( player.get( Sleep )).ignoreOffscreenSleep 		=	true;
			CharUtils.moveToTarget( player, 580, 600 );
		}
		
		private function setTotalAtSlide():void
		{
			var display:Display										=	_total.get( Display );
			display.visible 										=	false;
		}
		
		private function handleTotalSlideSounds( label:String ):void
		{
			if( label.indexOf( SoundAction.IMPACT ) > -1 )
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "ls_metal_shelf_01.mp3" );
			}
			
			if( label.indexOf( "slide" ) > -1 )
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "rubber_stretch_01.mp3" );		
				totalInSlide();
			}
		}
		
		private function totalInSlide():void
		{
			var timeline:Timeline 									=	_totalClimb.get( Timeline );
			timeline.stop();
			setHideTotal(true);
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, totalIncoming ));
		}

		private function totalIncoming():void
		{			
			CharUtils.setDirection( player, true );
			SceneUtil.setCameraTarget( this, _rollo );
			
			var timeline:Timeline 									=	_totalStuck.get( Timeline );
			timeline.gotoAndPlay( "pop" );
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "rubber_stretch_14.mp3" );	
			
			var sceneInteraction:SceneInteraction					=	new SceneInteraction();
			sceneInteraction.reached.add( inspectTotal );
			_totalStuck.add( sceneInteraction );
			
			ToolTipCreator.addToEntity( _totalStuck, InteractionCreator.CLICK );
			InteractionCreator.addToEntity( _totalStuck, [ InteractionCreator.CLICK ]);
			
			var fsmControl:FSMControl 								=	_rollo.get( FSMControl );
			var standState:MCStandState								=	fsmControl.getState( MovieclipState.STAND ) as MCStandState;
			standState.standLabel 									=	"stand";
			
			timeline 												=	_rollo.get( Timeline );
			timeline.gotoAndPlay( "stand" );
			
			exitSlide( _rollo, 500, rolloLands );
		}
		
		private function rolloLands():void
		{
			var motion:Motion 										=	_rollo.get( Motion );
			motion.velocity.x 										=	0;
			motion.maxVelocity.x 									=	400;
			
			DisplayUtils.moveToOverUnder( Display( _totalStuck.get( Display )).displayObject, Display( _rollo.get( Display )).displayObject, false );
			
			var dialog:Dialog 										=	_rollo.get( Dialog );
			dialog.faceSpeaker										=	true;
			dialog.sayById( "thanks" );
			dialog.complete.addOnce( rolloInPlace );
			
			SceneUtil.setCameraTarget( this, player );
			CharUtils.setDirection( _rollo, true );
		}
		
		private function rolloInPlace( dialogData:DialogData ):void
		{			
			var dialog:Dialog										=	player.get( Dialog );
			dialog.sayById( "bear" );
			dialog.complete.addOnce( rolloIsOkay );
		}
		
		private function rolloIsOkay( dialogData:DialogData ):void
		{			
			shellApi.completeEvent( _events.FREED_ROLLO );
			this.shellApi.takePhoto( "19046" );
			shellApi.removeEvent( _events.TOTAL_FOLLOWING );
			shellApi.removeEvent( _events.TOTAL_PRESENT );
			
			SceneUtil.lockInput( this, false );
		}
		
		private function inspectTotal( $player:Entity, $totalStuck:Entity ):void
		{
			var dialog:Dialog 										=	player.get( Dialog );
			dialog.sayById( "total_stuck" );
		}
		
		/** 
		 * LOGIC FOR SHAKING THE SCENE WHEN ROLLO PANICS
		 */
		private function shakeScene():void
		{
			var shake:ShakeMotion = _cameraEntity.get( ShakeMotion );
			shake.active = true;
		}
		
		private function endShake():void
		{
			var shake:ShakeMotion = _cameraEntity.get( ShakeMotion );
			shake.active = false;
			
			var spatialAddition:SpatialAddition = _cameraEntity.get( SpatialAddition );
			spatialAddition.x = 0;
			spatialAddition.y = 0;
			spatialAddition.rotation = 0;
		}
		
		/**
		 * TOTAL OUT OF SLIDE
		 */
		private function totalFreed():void
		{
			var timeline:Timeline 									=	_totalStuck.get( Timeline );
			timeline.gotoAndStop( "end" );
			
			var handbookPage:Entity 								=	getEntityById( _events.HANDBOOK_PAGE );
			var display:Display 									=	handbookPage.get( Display );
			display.visible 										=	true;
			
			// move rollo behind the handbook page
			DisplayUtils.moveToOverUnder( Display( _rollo.get( Display )).displayObject, display.displayObject, false );
			
			// place the handbook in scene
			var spatial:Spatial 									=	handbookPage.get( Spatial );
			var tween:Tween 										=	new Tween();
			tween.to( spatial, 1.2, { x : spatial.x - 50, y : 700, ease : Quadratic.easeInOut }); //x : spatial.x - 100,
			
			InteractionCreator.addToEntity( handbookPage, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( handbookPage );
			handbookPage.add( tween );
			
			// remove the total stuck dialog
			_totalStuck.remove( Interaction );
			_totalStuck.remove( SceneInteraction );
			ToolTipCreator.removeFromEntity( _totalStuck );
			
			var dialog:Dialog 										=	_rollo.get( Dialog );
			dialog.sayById( "must_study" );
			dialog.complete.addOnce( rolloRelaxed );
			
			// set total to follow you
			spatial 												=	_totalMissle.get( Spatial );
			Spatial( _total.get( Spatial )).x 						=	spatial.x;
			totalFollow();
			
			removeEntity( _totalMissle );
			_totalMissle 											=	null;
		}
		
		private function rolloRelaxed( dialogData:DialogData = null ):void
		{
			shellApi.completeEvent( _events.FREED_TOTAL );
			
			var handbookPage:Entity 								=	getEntityById( _events.HANDBOOK_PAGE );
			var sceneInteraction:SceneInteraction					=	new SceneInteraction();
			sceneInteraction.reached.addOnce( getHandbookPage );
			handbookPage.add( sceneInteraction ).add( new Item());
			stopConversation();
			
			var audio:Audio 										=	_rollo.get( Audio );
			for( var number:int = 1; number < 4; number ++ )
			{
				audio.stopActionAudio( PANIC + number );
			}
		}
		
		/**
		 * MOLLY PUZZLE
		 */
		private function enterMolly():void
		{
			var display:Display 									=	_molly.get( Display );
			display.visible 										=	true;
			
			var charMotion:CharacterMotionControl					=	_molly.get( CharacterMotionControl );
			charMotion.maxVelocityX 								=	300;
			_molly.add( charMotion );
			
			DisplayUtils.moveToBack( Display( _molly.get( Display )).displayObject );
			CharUtils.moveToTarget( _molly, 550, 690, true, mollyArrived );
		}
		
		private function mollyArrived( $molly:Entity ):void
		{			
			var sceneInteraction:SceneInteraction 					=	_molly.get( SceneInteraction );
			sceneInteraction.reached.add( talkToMolly );
		}
		
		private function talkToMolly( player:Entity, molly:Entity ):void
		{
			var onRight:Boolean									 	=	Spatial( _molly.get( Spatial )).x > Spatial( player.get( Spatial )).x ? true : false;
			positionTotal( onRight, chooseMollyDialog )
		}
		
		private function chooseMollyDialog():void
		{
			var dialog:Dialog 										=	_molly.get( Dialog );
			
			if( _totalDistraction )
			{
				dialog.sayById( "distracted" );	
			}
			else if( shellApi.checkItemEvent( _events.MONEY ))
			{
				if( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "9" ))
				{
					dialog.sayById( "tired" );	
				}
				else if( shellApi.checkEvent( _events.RETURNED_CAT ))
				{
					dialog.sayById( "tower" );
				}
				else
				{
					dialog.sayById( "wheres_the_cat" );
				}
			}
			
			else
			{
				if( !shellApi.checkEvent( _events.MOLLYS_ONTO_YOU ))
				{
					SceneUtil.lockInput( this );
					dialog.sayById( "where" );				
				}
				else
				{
					dialog.sayById( "spend_cash" );
				}
			}
		}
		
		private function positionForShoes( player:Entity ):void
		{
		//	var onLeft:Boolean = Spatial( _molly.get( Spatial )).x > Spatial( player.get( Spatial )).x ? true : false;
		//	CharUtils.setDirection( player, onLeft );
			CharUtils.lockControls( player );
			super.positionTotal( true, solicitMolly );
		}
		
		private function solicitMolly():void
		{
			CharUtils.setDirection( player, true );
			CharUtils.setDirection( _molly, false );
			
			SceneUtil.lockInput( this );
			CharUtils.setState( player, CharacterState.STAND );
			
			var dialog:Dialog 						=	player.get( Dialog );
			dialog.sayById( "buy_these" );
		}
		
		private function putOnShoes():void
		{
			var display:Display 					=	_molly.get( Display );
			display.displayObject[ "shoes" ].alpha 	=	1;
			_itemGroup.showItem( _events.MONEY, "timmy" );
			
			shellApi.getItem( _events.MONEY );
			SceneUtil.lockInput( this, false );
			CharUtils.lockControls( player, false, false );
			shellApi.removeItem( _events.SHOES );
		}		
		
		// RETURN MR. BURRITO
		private function positionForCat( $player:Entity ):void
		{
			SceneUtil.lockInput( this );
			CharUtils.lockControls( player );
			var spatial:Spatial 				=	player.get( Spatial );
			spatial.x 							=	430;
			
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING ))
			{
				super.positionTotal( true, explainTheSituation );
			}
			else
			{
				explainTheSituation();
			}
		}
		
		private function explainTheSituation():void
		{			
			var dialog:Dialog 				=	player.get( Dialog );
			dialog.sayById( "this_yours" );
			dialog.complete.addOnce( catReturnted );
			
			CharUtils.setDirection( player, true );
			CharUtils.setAnim( player, Place );
			
			var timeline:Timeline 						=	player.get( Timeline );
			timeline.handleLabel( "trigger", dropCat );
		}
		
		private function dropCat():void
		{
			var cat:Entity 								=	getEntityById( "cat" );
			var audio:Audio 							=	cat.get( Audio );
			
			Display( cat.get( Display )).visible 		=	true;
			var timeline:Timeline 						=	cat.get( Timeline );
			timeline.play();
			
			ToolTipCreator.addToEntity( cat, InteractionCreator.CLICK );
			InteractionCreator.addToEntity( cat, [ InteractionCreator.CLICK ]);
			
			var sceneInteraction:SceneInteraction 				=	new SceneInteraction();
			sceneInteraction.reached.add( playWithKitty );
			cat.add( sceneInteraction );
		}
		
		private function catReturnted( dialogData:DialogData ):void
		{
			var dialog:Dialog 							=	_molly.get( Dialog );
			dialog.sayById( "the_best" );
			dialog.complete.addOnce( sendInTruck ); 
			
			// set mollys smile
			var mouth:Entity 									=	EntityUtils.getChildById( _molly, "mouth" );	
			var timeline:Timeline								=	mouth.get( Timeline );
			timeline.gotoAndStop( "happyIdle" );
			
			var talk:Talk 										=	_molly.get( Talk );
			talk.talkLabel 										=	"happyTalk";
			talk.mouthDefaultLabel								=	"happyIdle";
			
			// bring truck up to the right y
			var truck:Entity 									=	getEntityById( GARBAGE_TRUCK );
			var spatial:Spatial 								=	truck.get( Spatial );
			
			// position truck
			spatial.x 											=	Spatial( player.get( Spatial )).x + shellApi.viewportWidth * .5 + spatial.width;
			spatial.y 											=	770;
		}
		
		private function sendInTruck( dialogData:DialogData ):void
		{
			var truck:Entity 									=	getEntityById( GARBAGE_TRUCK );
			DisplayUtils.moveToTop( Display( truck.get( Display )).displayObject );
			super.moveVehicle( truck, -400, -300, truckPassed );
		}
		
		private function truckPassed( truck:Entity ):void
		{
			CharUtils.setDirection( player, false );
			CharUtils.setAnim( player, Grief );
			
			var timeline:Timeline 								=	player.get( Timeline );
			timeline.handleLabel( "ending", foundHisPants );
		}
		
		private function foundHisPants():void
		{
			var dialog:Dialog 									=	player.get( Dialog );
			dialog.sayById( "found_them" );
			
			CharUtils.setDirection( player, true );
		}
		
		private function chaseThePants():void
		{
			shellApi.completeEvent( _events.RETURNED_CAT );
			shellApi.removeItem( _events.CAT );
			
			CharUtils.moveToTarget( player, -100, Spatial( player.get( Spatial )).y, true, runToTimmysStreet );
		}
		
		private function runToTimmysStreet( player:Entity ):void
		{
			shellApi.loadScene( TimmysStreet, 4000, 940, "left" );
		}
	}
}
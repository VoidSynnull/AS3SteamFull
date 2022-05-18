package game.scenes.timmy.timmysStreet
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Talk;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.hit.Item;
	import game.components.motion.FollowTarget;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.SitSleepLoop;
	import game.data.scene.characterDialog.DialogData;
	import game.data.text.TextStyleData;
	import game.scene.template.SceneUIGroup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.timmy.TimmyScene;
	import game.scenes.timmy.chase.Chase;
	import game.scenes.timmy.mainStreet.MainStreet;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ItemHitSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class TimmysStreet extends TimmyScene
	{
		private var _corrina:Entity; 
		private var _timmy:Entity;
		private var _crocus:Entity;
		
//		private var _catSequence:BitmapSequence;
		private const GARBAGE_TRUCK:String			=	"garbageTruck";
		
//		private var _stinkSequence:BitmapSequence;
		private var _intro:Boolean 					=	false;
		private var _truck:Entity;
		
		private var flashbackText:Entity;
		private var customScreenEffects:ScreenEffects;
		
		public function TimmysStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/timmysStreet/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			if(!shellApi.checkEvent(_events.INTRO_COMPLETE))
				SceneUtil.removeIslandParts(this);
			super.load();
		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new TriggerHitSystem());
			super.addBaseSystems();
		}
		
		override public function destroy():void
		{
//			if( _stinkSequence )
//			{
//				_stinkSequence.destroy();
//				_stinkSequence 			= 	null;
//			}
//			if( _catSequence )
//			{
//				_catSequence.destroy();
//				_catSequence= null;
//			}
			if(flashbackText){
				flashbackText.remove(Tween);
				flashbackText.remove(Display);
				removeEntity(flashbackText);
				flashbackText = null;
			}
			super.destroy();
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
			var dialog:Dialog;
			var display:Display;
			var entity:Entity;
			var sceneInteraction:SceneInteraction;
			var spatial:Spatial;
			
			// CHARACTER NPCs
			_timmy			 					= 	getEntityById( "timmy" );
			_corrina		 					=	getEntityById( "corrina" );
			_crocus 							=	getEntityById( "crocus" );
			var molly:Entity 					=	getEntityById( "molly" );
			
			if( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "6" ))
			{
				removeEntity( molly );
				molly = null;
				
				_hitContainer.removeChild( _hitContainer[ _events.CAT ]);
			}
			else
			{
				DisplayUtils.moveToBack( Display( molly.get( Display )).displayObject );
				
				var mouth:Entity 									=	EntityUtils.getChildById( molly, "mouth" );	
				var timeline:Timeline								=	mouth.get( Timeline );
				timeline.gotoAndStop( "happyIdle" );
				
				var talk:Talk 										=	molly.get( Talk );
				talk.talkLabel 										=	"happyTalk";
				talk.mouthDefaultLabel								=	"happyIdle";
				
				var clip:MovieClip									=	_hitContainer[ _events.CAT ];
				if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
				{
					super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
				}
				var cat:Entity 										=	EntityUtils.createMovingTimelineEntity( this, clip, null, true );//=	makeEntity( _hitContainer[ _events.CAT ], null, "idle", true );
				
				_audioGroup.addAudioToEntity( cat );
				ToolTipCreator.addToEntity( cat, InteractionCreator.CLICK );
				InteractionCreator.addToEntity( cat, [ InteractionCreator.CLICK ]);
				
				sceneInteraction 									=	new SceneInteraction();
				sceneInteraction.minTargetDelta = new Point(30,100);
				sceneInteraction.reached.add( playWithKitty );
				sceneInteraction.validCharStates 					= 	new <String>[ CharacterState.STAND ];
				
				cat.add( sceneInteraction );
			}
			
			if( _crocus && _crocus.has( Npc ))
			{
				DisplayUtils.moveToBack( Display( _crocus.get( Display )).displayObject );
			}
			if( _corrina )
			{
				DisplayUtils.moveToOverUnder( Display( _corrina.get( Display )).displayObject, Display( _total.get( Display )).displayObject, false );
			}
			
			// SET MAILBOX
			var mailboxClip:MovieClip 			=	_hitContainer[ "mailbox2" ];
			if( !shellApi.checkEvent( _events.INTRO_COMPLETE ))
			{
				intro();
			}
			else if( shellApi.checkEvent( _events.CHASE_COMPLETE ) && !shellApi.checkItemEvent( _events.MEDAL_TIMMY ))
			{
				intro( false );
			}
			else if( shellApi.checkItemEvent( _events.MEDAL_TIMMY ))
			{
				removeExtraAssets([ "garbanzo", "garbanzoWindow", _events.HANDBOOK_PAGE, "mailbox" ]);
				removeEntity( _corrina );
				
				spatial 					=	_timmy.get( Spatial );
				spatial.x 					=	2410;
//				
//				display 					=	_timmy.get( Display );
//				display.displayObject[ 
				totalEatingTrash();
			}
			else
			{
				if( shellApi.checkEvent( _events.CRASHED_CAR ) && !shellApi.checkEvent( _events.CHASE_COMPLETE ))// && shellApi.checkEvent( _events.GOT_ALL_TOTALMOBILE_PARTS ))
				{
					introChase();
				}
				else
				{
					introChase( false );
					removeEntity( _corrina );
				}
				removeExtraAssets([ "trash", "mailbox2" ]);
				mailboxClip 					=	_hitContainer[ "mailbox" ];
				// GARBANZO MAN MASK
				if( !shellApi.checkEvent( _events.GARBANZO_DROPPED ))
				{
					removeExtraAssets([ "garbanzo" ]);	
				}
				else if( !shellApi.checkItemEvent( _events.GARBANZO_MAN_HEAD ))
				{
					removeExtraAssets([ "garbanzoWindow" ]);
					entity 						=	makeEntity( _hitContainer[ "garbanzo" ]);
					
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					ToolTipCreator.addToEntity( entity );
					
					sceneInteraction			=	new SceneInteraction();
					sceneInteraction.reached.addOnce( getGarbanzoMask );
					entity.add( sceneInteraction ).add( new Item());
				}
				else
				{
					removeExtraAssets([ "garbanzoWindow", "garbanzo" ]);					
				}
				
				// HANDBOOK PAGE AND CAR CRASH
				if( !shellApi.checkEvent( _events.RETURNED_CAT ) || shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "7" ))
				{
					removeExtraAssets([ _events.HANDBOOK_PAGE ]);
				}
				else
				{
					if( !shellApi.checkEvent( _events.SAW_GARBAGE_TRUCK ))
					{
						SceneUtil.lockInput( this );
						dialog					=	player.get( Dialog );
						dialog.sayById( "lost_them" );
						dialog.complete.addOnce( lookAtPants );
					}
					entity 						=	makeEntity( _hitContainer[ _events.HANDBOOK_PAGE ]);
					
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					ToolTipCreator.addToEntity( entity );
					
					sceneInteraction			=	new SceneInteraction();
					sceneInteraction.reached.addOnce( getHandbookPage );
					entity.add( sceneInteraction ).add( new Item());
				}
				
				if( !shellApi.checkEvent( _events.CRASHED_CAR ))
				{
					removeEntity( _timmy );
					_timmy = null;
				}
			}
			
			setCarCrash();
			
			// BRING MAILBOX CLIP TO FRONT
			var mailBox:Entity 					=	makeEntity( mailboxClip );
			display 							=	mailBox.get( Display );
			DisplayUtils.moveToTop( display.displayObject );
			
			if( _intro )
			{
				var garbageTruck:Entity 		=	getEntityById( GARBAGE_TRUCK );
				display							=	garbageTruck.get( Display );
				display.displayObject[ "pants" ].alpha = 0;
				
				DisplayUtils.moveToTop( Display( _total.get( Display )).displayObject );
				DisplayUtils.moveToTop( display.displayObject );
			}
			
			var triggerHit:TriggerHit			=	new TriggerHit( null, new <String>[ "player" ]);
			triggerHit.triggered 				=	new Signal();
			triggerHit.triggered.add( moveAboveTotal );
			
			var ground:Entity 					=	getEntityById( "ground" );
			ground.add( triggerHit );
			
			// garbanzo window
			//var windowDoor:Entity 			=	getEntityById( "doorTimmysRoom" );
			//sceneInteraction 				=	windowDoor.get( SceneInteraction );
//			if( !shellApi.checkEvent( _events.GARBANZO_DROPPED ))
//			{
//				sceneInteraction.reached.removeAll();
//				sceneInteraction.reached.add( cantEnterHere );
//			}
			
			if( _timmy && _timmy.has( SceneInteraction ))
			{
				sceneInteraction 				=	_timmy.get( SceneInteraction );
				sceneInteraction.reached.add( talkToTimmy );
				
				DisplayUtils.moveToOverUnder(  Display( player.get( Display )).displayObject, Display( _timmy.get( Display )).displayObject, true );
			}
		}
		
		private function cantEnterHere( $player:Entity, doorWindow:Entity ):void
		{
			var dialog:Dialog 			=	player.get( Dialog );
			dialog.sayById( "too_tight" );
		}
		
		private function moveAboveTotal():void
		{
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING ) || shellApi.checkEvent( _events.TOTAL_PRESENT ))
			{
				DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _total.get( Display )).displayObject, true );
			}
		}
		
		private function playWithKitty( $player:Entity, $cat:Entity ):void
		{
			var molly:Entity 						=	getEntityById( "molly" );
			var dialog:Dialog						=	molly.get( Dialog );
			
			CharUtils.setAnim(player, PointItem);
			
			dialog.sayById( "likes_you" );
			
			var audio:Audio							=	$cat.get( Audio );
			audio.playCurrentAction( TRIGGER );
		}
		
		private function setCarCrash():void
		{
			if( !shellApi.checkEvent( _events.CRASHED_CAR ))
			{					
				removeExtraAssets([ "crashedCar" ]);//, "stink0", "stink1", "stink2" ]);	
				makeEntity( _hitContainer[ "window" ]);
				makeEntity( _hitContainer[ "bush" ]);
				removeEntity( getEntityById( "car" ));
			}
			else
			{
				removeExtraAssets([ "window", "bush" ]);
				removeEntity( getEntityById( "broke_window" ));
				var car:Entity 			=	makeAutomobile( this, _hitContainer[ "crashedCar" ], false );
				DisplayUtils.moveToOverUnder( Display( _crocus.get( Display )).displayObject, Display( car.get( Display )).displayObject );
				
				if( !shellApi.checkEvent( _events.CROCUS_MAD ))
				{										
					var spatial:Spatial 			=	_timmy.get( Spatial );
					spatial.x 						=	4250;
					
					MotionUtils.zeroMotion(player);
					CharUtils.setAnim( player, Dizzy );
					
					SceneUtil.lockInput( this );
					rotateWheels( car, -55 );
					vehicleSmoke( car, new Point( -115, -46 ), new Point( -150, -100 ));
					
					var dialog:Dialog				=	_crocus.get( Dialog );
					dialog.sayById( "what_the" );
					dialog.complete.addOnce( getAwayFromCrocus );
				}
				
				// hide timmys unused assets
				var displayObject:DisplayObject 			=	Display( _timmy.get( Display )).displayObject;
				if( !shellApi.checkEvent( _events.CHASE_COMPLETE ))
				{
					displayObject[ "shorts" ].alpha				=	0;
					displayObject[ "shirt_garbage" ].alpha		=	0;
					displayObject[ "head_garbage" ].alpha		=	0;
				}
				else if( !shellApi.checkItemEvent( _events.MEDAL_TIMMY ))
				{
					displayObject[ "undies" ].alpha				=	0;					
				}
				else
				{
					displayObject[ "shirt_garbage" ].alpha		=	0;
					displayObject[ "head_garbage" ].alpha		=	0;
					displayObject[ "undies" ].alpha				=	0;	
				}
				
				var sceneInteraction:SceneInteraction 			=	_crocus.get( SceneInteraction );
				sceneInteraction.reached.add( talkToCrocus );
			}
		}
		
		private function talkToCrocus( $player, $crocus ):void
		{
			var dialog:Dialog 									=	_crocus.get( Dialog );
			
			if( _totalDistraction )
			{
				dialog.sayById( "distracted" );
			}
			else
			{
				dialog.sayById( "random" );
			}
		}
		
		private function introChase( addTruck:Boolean = true ):void
		{
			if( addTruck )
			{
				_truck = makeAutomobile( this, _hitContainer[ GARBAGE_TRUCK ]);
				var spatial:Spatial						=		_truck.get( Spatial );
				spatial.x 								=	Spatial( player.get( Spatial )).x + shellApi.viewportWidth * .5 + spatial.width;
				
				Display(_corrina.get(Display)).visible = false;
				Display(_truck.get(Display)).visible = false;
				EntityUtils.position(_corrina, _truck.get(Spatial).x + 700, _corrina.get(Spatial).y);
				var follow:FollowTarget = new FollowTarget(_truck.get(Spatial),0.05);
				follow.offset = new Point(400,-10);
				_corrina.add(follow);
			}
			
			// timmy waiting near crash site
			// talk to timmy with all total mobile parts
			_timmy.add( new Sleep(false ));
			Display( _timmy.get( Display )).visible = true;
		}
		
		private function talkToTimmy( $player:Entity, $timmy ):void
		{
			var dialog:Dialog 		=	_timmy.get( Dialog );
			
			if( _totalDistraction )
			{
				dialog.sayById( "distracted" );
			}
			else if( shellApi.checkItemEvent( _events.MEDAL_TIMMY ))
			{
				dialog.sayById( "got_medal" );
			}
			else if( shellApi.checkEvent( _events.GOT_ALL_TOTALMOBILE_PARTS ))
			{
				SceneUtil.lockInput( this );
				var onLeft:Boolean 		=	Spatial( player.get( Spatial )).x < Spatial( _timmy.get( Spatial )).x ? true : false;
				CharUtils.setDirection( player, onLeft );
				
				positionTotal( onLeft, beginCorrinaDriveBy );
			}
			else
			{
				dialog.sayById( "gather_equipment" );
			}
		}
		
		private function beginCorrinaDriveBy(...p):void
		{
			Display(_corrina.get(Display)).visible = true;
			Display(_truck.get(Display)).visible = true;
			
			DisplayUtils.moveToTop( Display( _corrina.get( Display )).displayObject );
			DisplayUtils.moveToTop( Display( _truck.get( Display )).displayObject );
			// talk, drive by, talk, start chase
			var actions:ActionChain = new ActionChain(this);
			
			actions.lockInput = true;
			
	//		actions.addAction(new MoveAction(player,target));
	//		actions.addAction(new SetDirectionAction(player, true));
			actions.addAction(new TalkAction(player,"ready"));
			actions.addAction(new TalkAction(_timmy,"one_problem"));
			actions.addAction(new TalkAction(player,"what_now"));
			actions.addAction(new CallFunctionAction(rollBy));
			actions.addAction(new WaitAction(2.0));
			actions.addAction(new TalkAction(_timmy,"she"));
			actions.addAction(new TalkAction(player,"effort"));
			actions.addAction(new TalkAction(_timmy,"lets_go"));
			actions.addAction(new CallFunctionAction(Command.create(shellApi.loadScene,Chase)));

			actions.execute();
		}
		
		private function rollBy(...p):void
		{
			Timeline(_corrina.get(Timeline)).gotoAndPlay("bike");
			var pos:Point =  EntityUtils.getPosition(player);
			EntityUtils.position(_truck, pos.x + 950,pos.y + 100);
			this.moveVehicle(_truck,pos.x - 1200, -410, hideTruck );//1.5, hideTruck);
		}
		
		private function hideTruck(...p):void
		{
			Timeline(_corrina.get(Timeline)).gotoAndPlay("stand");
			Display(_corrina.get(Display)).visible = false;
			Display(_truck.get(Display)).visible = false;
		}
		
		private function celebratePantsRetrieval( truck:Entity ):void
		{
			shellApi.removeItem( _events.CHICKEN_NUGGETS );
			shellApi.removeItem( _events.POLE );
			shellApi.removeItem( _events.ROPE );
			shellApi.removeItem( _events.WAGON );
			
			removeEntity( truck );
			CharUtils.stateDrivenOn( player );
			
			Dialog(_timmy.get(Dialog)).faceSpeaker = false;
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new CallFunctionAction(Command.create(face,false)));
			actions.addAction(new TalkAction(_timmy,"got_pants"));
			actions.addAction(new TalkAction(_corrina,"drama"));
			actions.addAction(new CallFunctionAction(Command.create(face,true)));
			actions.addAction(new TalkAction(_timmy,"innocent"));
			actions.addAction(new TalkAction(_corrina,"excuse"));
			actions.addAction(new TalkAction(_timmy,"clearly"));
			actions.addAction(new TalkAction(_timmy,"huckster"));
			actions.addAction(new TalkAction(_corrina,"help"));
			actions.addAction(new TalkAction(_timmy,"magistrate2"));
			actions.addAction(new TalkAction(_corrina,"good_luck2"));
			actions.addAction(new MoveAction( _corrina, new Point(1700, 970), new Point(50,100), NaN, true));
			actions.addAction(new CallFunctionAction(Command.create(face,false)));
			actions.addAction(new TalkAction(_timmy,"got_her2" ));
			actions.addAction(new TalkAction(player,"not_again" ));
			actions.addAction(new TalkAction(_timmy,"medal" ));
			actions.addAction(new GetItemAction(_events.MEDAL_TIMMY));
			actions.addAction(new CallFunctionAction(completeIsland));
			
 			actions.execute();
		}
		
		private function face(right:Boolean = true):void
		{
			CharUtils.setDirection(_timmy,right);
		}
		
		private function completeIsland():void
		{
			removeEntity( _corrina );
			shellApi.completedIsland("", null);
			SceneUtil.lockInput(this, false);
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
		}
		
		private function removeExtraAssets( assets:Array ):void
		{	
			var asset:String;
			
			for each( asset in assets )
			{
				_hitContainer.removeChild( _hitContainer[ asset ]);
			}
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
		
		public function itemHit(entity:Entity):void
		{
			var id:Id 				=	entity.get( Id );
			
			if( id.id 			==	_events.HANDBOOK_PAGE )
			{
				getHandbookPage();
			}
			else
			{
				_itemGroup.showAndGetItem( _events.GARBANZO_MAN_HEAD, null, null, null, entity );
			}
		}
		
		// GET ITEMS
		private function getGarbanzoMask( player:Entity, garbanzoMask:Entity ):void
		{
			removeEntity( garbanzoMask );
			shellApi.getItem( _events.GARBANZO_MAN_HEAD, null, true );
		}
		
		private function getHandbookPage( player:Entity = null, handbookPage:Entity = null ):void
		{
			removeEntity( handbookPage );
			shellApi.completeEvent( _events.GOT_DETECTIVE_LOG_PAGE + "7" );
			showDetectivePage( 7 );
			//shellApi.showItem( _events.DETECTIVE_LOG, "timmy", Command.create( showDetectivePage, 7 ));
		}
		
		/**
		 * EVENT HANDLER
		 */
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{	
			var charMotion:CharacterMotionControl;
			
			switch( event )
			{
				case _events.EXIT_CORRINA:					
					CharUtils.moveToTarget( _corrina, Spatial( player.get( Spatial )).x + ( shellApi.viewportWidth * shellApi.viewportScale ), 970, true, corrinaLeft );
					break;
								
				case _events.INTRO_COMPLETE:
					if( !shellApi.checkEvent( _events.REMINISCE ) && !shellApi.checkItemEvent( _events.DETECTIVE_LOG ) && !shellApi.checkItemEvent( _events.CHASE_COMPLETE ) && !shellApi.checkItemEvent(_events.MEDAL_TIMMY))
					{
						var sceneUIGroup:SceneUIGroup 		=	this.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
						sceneUIGroup.hud.show(false);
						
						customScreenEffects = new ScreenEffects(container,shellApi.viewportWidth,shellApi.viewportHeight,1,0,new Point(-shellApi.viewportWidth/2,-shellApi.viewportHeight/2));
						customScreenEffects.fadeToBlack(2.0, showFlashbackText);
						shellApi.completeEvent( _events.REMINISCE );
						//shellApi.loadScene( MainStreet, 3150, 1555, "left", NaN, 1);
					}
					break;
				
				case "dramatic_pause":
					SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, announceTotalmobile, true));
					break;
				
				case "get_page_9":
					shellApi.triggerEvent( _events.GOT_DETECTIVE_LOG_PAGE + "9", true );
					showDetectivePage( 9, goGetEm );
					break;
				
				case _events.GOT_ALL_TOTALMOBILE_PARTS:
					if( _timmy && _timmy.has( SceneInteraction ))
					{
						var sceneInteraction:SceneInteraction 	=	_timmy.get( SceneInteraction );
						sceneInteraction.reached.add( talkToTimmy );
						
						DisplayUtils.moveToOverUnder(  Display( player.get( Display )).displayObject, Display( _timmy.get( Display )).displayObject, true );
					}
					break;
				
				default:
					super.eventTriggered( event, makeCurrent, init, removeEvent );
					break;
			}
		}
		
		private function announceTotalmobile():void 
		{
			Dialog( _timmy.get( Dialog )).sayById( "totalmobile" );
		}
		
		private function showFlashbackText(...p):void
		{
			var styleData:TextStyleData = shellApi.textManager.getStyleData( TextStyleData.UI, "tutorialwhite" );
			styleData.alignment = TextFormatAlign.CENTER;
			styleData.size = 42;
			var textfield:TextField = new TextField();
			textfield.alwaysShowSelection = false;
			textfield.selectable = false;
			textfield.text = "Earlier.....";
			textfield.width = shellApi.viewportWidth;
			textfield.height = 200;
			TextUtils.applyStyle(styleData,textfield);
			textfield.embedFonts = true;
			textfield.x = 0;
			textfield.y = shellApi.viewportHeight/2;
			textfield.alpha = 0;
			flashbackText = EntityUtils.createSpatialEntity(this,textfield, overlayContainer);
			var display:Display = flashbackText.get(Display);
			display.alpha = 0;
			TweenUtils.entityTo(flashbackText, Display, 2.0, {alpha:1.0, onComplete:Command.create(SceneUtil.delay,this,1.5,concludeFlashBack)} ,"er", 1.0);
		}
		private function concludeFlashBack(...p):void
		{
			shellApi.loadScene( MainStreet, 4550, 1555, "left", NaN, NaN);
		}

		// INTRO SEQUENCE
		private function intro( inMediasRes:Boolean = true ):void
		{		
			_intro = true;
			
			// REMOVE ELEMENTS NOT USED IN INTRO AND SETUP GARBAGE TRUCK
			var display:Display							=	_timmy.get( Display );
			
			removeExtraAssets([ "garbanzo", "garbanzoWindow", _events.HANDBOOK_PAGE, "mailbox" ]);
			var garbageTruck:Entity						=	makeAutomobile( this, _hitContainer[ GARBAGE_TRUCK ]);
			
			display 									=	garbageTruck.get( Display );
			display.displayObject[ "pants" ].alpha 		=	0;
			
			// RUN INTRO
			_characterGroup.addFSM( _timmy, true, null, "", true );
			_characterGroup.addFSM( _corrina, true, null, "", true );
			
			SceneUtil.lockInput( this);
			
			var handler:Function 						=	inMediasRes ? accuseCorrina : celebratePantsRetrieval;
			super.moveVehicle( garbageTruck, -400, -300, handler );
			
			var spatial:Spatial 						=	garbageTruck.get( Spatial );
			spatial.x									=	450;
			spatial.y									=	1000;
			
			spatial 									=	_timmy.get( Spatial );
			spatial.x 									=	640;
			
			totalEatingTrash();
			
			spatial = player.get(Spatial);
			spatial.y =	1230;
			spatial.x =	510;
			MotionUtils.zeroMotion(player);
			CharUtils.setDirection(player, true);
			CharUtils.setAnim( player, SitSleepLoop );
			
			setupStink( this, _hitContainer[ "stink1" ], onStinkLoaded );
		}
		
		private function onStinkLoaded():void
		{
			// CREATE STINK FLIES
			var clip:MovieClip;
			var stink:Entity;
			var targetSpatial:Spatial;
			var targets:Array  							=	[ player, _timmy, _corrina ];
			var timeline:Timeline;
			
			for( var number:int = 0; number < 3; number ++ )
			{				
				clip 									=	_hitContainer[ "stink" + number ];
				stink 									=	createTimelineStink( this, clip, null, true, targets[ number ]);
				
				timeline 								=	stink.get( Timeline );
				timeline.gotoAndPlay( Math.round( Math.random() * ( timeline.data.duration - 1 )));
			}
		}
		
		// AFTER YOU SAW THE GARBAGE TRUCK
		private function lookAtPants( dialogData:DialogData ):void
		{
			SceneUtil.setCameraTarget( this, getEntityById( _events.HANDBOOK_PAGE ));
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, returnCameraToPlayer ));
			
			shellApi.completeEvent( _events.SAW_GARBAGE_TRUCK );
		}
		
		private function returnCameraToPlayer():void
		{
			SceneUtil.setCameraTarget( this, player );
			SceneUtil.lockInput( this, false );			
		}
		
		private function totalEatingTrash():void
		{
			var trash:Entity 					=	getEntityById( "trashInteraction" );
			var trashBounce:Entity 				=	getEntityById("trashBounce");
			
			var trashSpatial:Spatial 			=	trashBounce.get(Spatial);
			var totalSpatial:Spatial 			=	_total.get( Spatial );
			
			var sleep:Sleep		=	_total.get( Sleep );
			if( !sleep )
			{
				sleep 												=	new Sleep();
				_total.add( sleep );
			}
			sleep.sleeping 		=	false;
			
			var display:Display	=	_total.get( Display );
			display.visible 	=	true;
			CharUtils.setDirection( _total, false );
			
			display 										=	trashBounce.get( Display );
			display.isStatic								=	false;
			
			trashSpatial.x 						= 	280;
			
			totalSpatial.x 						=	trashSpatial.x;
			totalSpatial.y 						=	trashSpatial.y;
			showTrash( false );
			
			CharUtils.stateDrivenOff(_total);
			Timeline( _total.get( Timeline )).gotoAndPlay( "trash_idle" );
		}
		
		private function accuseCorrina( truck:Entity ):void
		{	
			removeEntity( truck );
			CharUtils.stateDrivenOn( player );
			
			var motionControl:CharacterMotionControl 			=	_corrina.get( CharacterMotionControl );
			motionControl.maxVelocityX 							=	300;
			
			var dialog:Dialog 					=	_timmy.get( Dialog );
			dialog.faceSpeaker 					=	false;
			dialog.sayById( "nefarious" );
		}
		
		private function corrinaLeft( corrina:Entity ):void
		{
			removeEntity( corrina );
			
			var dialog:Dialog 					=	_timmy.get( Dialog );
			dialog.faceSpeaker 					=	true;
			dialog.sayById( "got_her" );
		}
		
		// AFTER CAR ACCIDENT
		private function getAwayFromCrocus( dialogData:DialogData ):void
		{
			var dialog:Dialog 					=	player.get( Dialog );
			dialog.sayById( "must_see_timmy" );
			dialog.complete.addOnce( mustSeeTimmy );
			
			CharUtils.stateDrivenOn( player );
		}
		
		private function mustSeeTimmy( dialogData:DialogData ):void
		{
			shellApi.completeEvent( _events.CROCUS_MAD );
			this.shellApi.takePhoto( "19044" );
			
			var eyeEntity:Entity 					=	SkinUtils.getSkinPartEntity( player, SkinUtils.EYES );
			var eyes:Eyes							=	eyeEntity.get( Eyes );
			
			SkinUtils.setEyeStates( player, eyes.permanentState );
			
			CharUtils.moveToTarget( _timmy, Spatial( player.get( Spatial )).x + 200, Spatial( _timmy.get( Spatial )).y, true, timmyOnTheScene );
		}
		
		private function timmyOnTheScene( $timmy:Entity ):void
		{
			CharUtils.setDirection( player, true );
			var dialog:Dialog 						=	_timmy.get( Dialog );
			dialog.sayById( "mishap" );
		}
		
		private function goGetEm( ...args ):void
		{
			SceneUtil.lockInput( this, false );
			
//			var sceneInteraction:SceneInteraction =	_timmy.get( SceneInteraction );
//			sceneInteraction.reached.removeAll();
//			sceneInteraction.reached.add( timmyPreChase );
		}
	}
}
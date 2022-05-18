package game.scenes.viking.diningHall
{
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
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Npc;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.SkinPart;
	import game.components.hit.Door;
	import game.components.hit.Item;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.FrameEvent;
	import game.data.animation.entity.character.Drink;
	import game.data.animation.entity.character.Eat;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Hammer;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Sing;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Think;
	import game.data.animation.entity.character.Wave;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scenes.viking.VikingScene;
	import game.scenes.viking.shared.balanceGame.BalanceGameGroup;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.entity.EyeSystem;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class DiningHall extends VikingScene
	{		
		private const SERVED:String			=	"served_";
		private const CANDLE:String			=	"candle";
		private const MEAT:String			=	"viking_meat";
		private const CHANDELIER:String		=	"chandelier";
		private const ENDING:String			=	"ending";
		private const LIGHT:String			= 	"light";
		private const FLAME:String			=	"flame";
		private const JOKE_SETUP:String 	= 	"joke_setup";
		private const TRIGGER:String 		=   "trigger";
		private const CHEW:String 			= 	"chew";
		
		private var _chaliceScale:Number = 1;
		private var _finalCup:Boolean = false;
		private var _firstItem:Boolean = true;
		private var _giantPlacated:Boolean = false;
		private var _chewing:Boolean = false;
		private var _cook:Entity = null;
		private var _currentUnderling:Entity = null;
		private var _cookTimer:TimedEvent;
		private var _giantTimer:TimedEvent;
//		private var _jokeTimer:TimedEvent;
		
		override public function destroy():void 
		{
			if( _cookTimer )
			{
				_cookTimer.stop();
				_cookTimer = null;
			}
			
			if( _giantTimer )
			{
				_giantTimer.stop();
				_giantTimer = null;
			}
			
//			if( _jokeTimer )
//			{
//				_jokeTimer.stop();
//				_jokeTimer = null;
//			}
			super.destroy();
		}
		override protected function addCharacters():void
		{
			super.addCharacters();
			
			// PRELOAD ANIMATIONS FOR SNEAKING
			var characterGroup:CharacterGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			characterGroup.preloadAnimations( new <Class>[ Hammer, Think, Laugh, Drink, Sing, Eat ], this );
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/diningHall/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			if( shellApi.checkEvent( _events.GOBLET_PLACED )
				&& !shellApi.checkEvent( _events.HAS_DRINK + "1" )
				&& !shellApi.checkEvent( _events.HAS_DRINK + "2" )
				&& !shellApi.checkEvent( _events.HAS_DRINK + "3" ))
			{
				shellApi.removeEvent( _events.GOBLET_PLACED );
			}
			
			if( shellApi.checkEvent( _events.BALANCE_GAME_STARTED ))
			{
				if( !shellApi.checkEvent( _events.BALANCE_GAME_COMPLETE ))
				{
					setupAssets();
					setupBalanceGame();
				}
				else
				{
					removeEntity( getEntityById( "oliver" ));
					removeEntity( getEntityById( "jorge" ));
					removeEntity( getEntityById( "mya" ));
					removeEntity( getEntityById( "giant" ));
					removeEntity( getEntityById( "giant2" ));
					
					sceneReady();
				}
			}
				
			else
			{
				sceneReady();
			}
		}
		
		private function sceneReady( ...args ):void
		{
			super.loaded();
			
			editEat();
			setupAssets();
			
			if( !shellApi.checkEvent( _events.START_SERVE_DRINKS ))
			{
				SceneUtil.lockInput( this );
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, serveTheDrinks ));
			}
			else
			{
				var delay:Number = GeomUtils.randomInRange( 3, 5 );
				
				_cookTimer = new TimedEvent( delay, 1, moveToCauldron );
				SceneUtil.addTimedEvent( this, _cookTimer );
				
//				nextJoker();
			}
		}
		
		private function setupBalanceGame():void
		{
			var balanceGame:BalanceGameGroup = this.addChildGroup(new BalanceGameGroup(_hitContainer)) as BalanceGameGroup;
			// remove all interactions for npcs and doors
			var characterGroup:CharacterGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			var characters:Vector.<Entity> = characterGroup.getCharactersInScene(true);
			for each (var ent:Entity in characters) 
			{
				ToolTipCreator.removeFromEntity(ent);
				ent.remove(Interaction);
				ent.remove(SceneInteraction);
				Display(ent.get(Display)).disableMouse();
			}
			removeEntity(getEntityById("doorPen"));
			removeEntity(getEntityById("doorThroneRoom"));
			var chute:Entity = getEntityById("doorRiver");
			SceneInteraction(chute.get(SceneInteraction)).reached.removeAll();
			if(_cookTimer){
				_cookTimer.stop();
			}
			if(_giantTimer){
				_giantTimer.stop();
			}
//			if(_jokeTimer){
//				_jokeTimer.stop();
//			}
			
			var hud:Hud = super.getGroupById( Hud.GROUP_ID ) as Hud;
			hud.disableButton( Hud.COSTUMIZER );
			hud.disableButton( Hud.INVENTORY );
			
			balanceGame.balanceGameGroupReady.addOnce( super.loaded );
		}
		
		public function pauseJokers():void
		{
//			if(_jokeTimer){
//				_jokeTimer.stop();
//			}
			
			EntityUtils.removeAllWordBalloons(this);
		}
		
		private function editEat():void
		{
			var animLoaderSys:AnimationLoaderSystem = getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
			var eat:Eat = animLoaderSys.animationLibrary.getAnimation( Eat ) as Eat;
			
			var frameEvent:FrameEvent = new FrameEvent( "setPart" );
			frameEvent.args = new Array( "mouth", "talk" );
			eat.data.frames[ 15 ].addEvent( frameEvent );
			
			frameEvent = new FrameEvent( "setPart" );
			frameEvent.args = new Array( "mouth", "chew" );
			eat.data.frames[ 20 ].addEvent( frameEvent );
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.USE_GOBLET )
			{
				if( !shellApi.checkEvent( _events.GOBLET_PLACED ))
				{
					if( !shellApi.checkEvent( _events.HOLDING_TRAY ))
					{
						var traySpatial:Spatial = getEntityById( "tray" ).get( Spatial );
						SceneUtil.lockInput( this );
						
						var destination:Destination = CharUtils.moveToTarget( player, traySpatial.x, 744, true, placeGoblet );
						destination.ignorePlatformTarget = true;			
					}
					else
					{
						super.placeGobletOnTray();
					}
				}
			}
			if( event == "pointing" )
			{
				showTheService();
			}
			super.eventTriggered( event, makeCurrent, init, removeEvent );
		}
		
		private function placeGoblet( player:Entity ):void
		{
			//		var goblet:Entity = getEntityById( "goblet" );
			var display:Display = getEntityById( "tray" ).get( Display );
			display.displayObject[ "inners" ][ "goblet" ].visible = true;
			
			SceneUtil.lockInput( this, false );
			shellApi.completeEvent( _events.GOBLET_PLACED );
		}
		
		private function setupAssets():void
		{
			var chair:Entity;
			var clip:MovieClip;
			var entity:Entity;
			var flameSequence:BitmapSequence;
			var furs:Entity;
			var number:int;
			var sceneInteraction:SceneInteraction;
			var sequence:BitmapSequence;
			var spatial:Spatial;
			var underling:Entity;
			var wrapper:BitmapWrapper;
			
			clip = _hitContainer[ FLAME + "1" ];
			flameSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			if( !_audioGroup )
			{
				_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			}
			for( number = 1; number < 4; number ++ )
			{
				DisplayUtils.convertToBitmapSprite( _hitContainer[ CHANDELIER + number ], null, PerformanceUtils.defaultBitmapQuality );
								
				// FLAME ANIMATION
				clip = _hitContainer[ FLAME + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				entity.add( new AudioRange( 400 ));
				_audioGroup.addAudioToEntity( entity );
				Audio( entity.get( Audio )).playCurrentAction( TRIGGER );
				
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, flameSequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).playing = true;
			}
			
			// SETUP CHAIRS
			clip = _hitContainer[ "chair" ];
			BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			chair = EntityUtils.createSpatialEntity( this, clip );
			chair.add( new Id( clip.name )).add( new Edge( -50, -50, 100, 100 )).add( new Npc());
			
			clip = _hitContainer[ "table" ];
			BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			var table:Entity = EntityUtils.createSpatialEntity( this, clip );
			table.add( new Id( clip.name )).add( new Edge( -50, -50, 100, 100 )).add( new Npc());
			
			// SETUP UNDERLINGS
			for( number = 1; number < 4; number ++ )
			{ 
				underling = getEntityById( UNDERLING + number );
				
				if( number == 1)
				{
					DisplayUtils.moveToOverUnder( Display( chair.get( Display )).displayObject, underling.get( Display ).displayObject );
				}
				else
				{
					Display( underling.get( Display )).moveToBack();
					underling.remove( Npc );	
				}
				
				SkinUtils.setEyeStates( underling, "", EyeSystem.FRONT, true );
				Dialog( underling.get( Dialog )).faceSpeaker = false;
				Sleep( underling.get( Sleep )).ignoreOffscreenSleep = true;
				
				if( number < 3 && shellApi.checkEvent( _events.SERVED_UNDERLING + number ))
				{
					SkinUtils.setSkinPart( underling, SkinUtils.ITEM, CHALICE );
					Dialog( underling.get( Dialog )).setCurrentById( "thanks" );
				}	
				else if( number == 3 )
				{
					Dialog( underling.get( Dialog )).setCurrentById( "thanks" );
				}
			}
			
			// SETUP COOK
			_cook = getEntityById( "cook" );
			Dialog( _cook.get( Dialog )).faceSpeaker = false;
			var motionControl:CharacterMotionControl = _cook.get( CharacterMotionControl );
			if( !motionControl )
			{
				motionControl = new CharacterMotionControl();
				_cook.add( motionControl );
			}
			
			motionControl.maxVelocityX = WALK_SPEED;
			
			// SETUP FUR
			furs = getEntityById( _events.FURS );
			if( furs )
			{
				Display( furs.get( Display )).moveToBack();
				furs.remove( Item );
				sceneInteraction = furs.get( SceneInteraction );
				sceneInteraction.reached.add( isGiantPlacated );
			}
			
			// SETUP GIANT
			if( !shellApi.checkEvent( _events.BALANCE_GAME_COMPLETE ))
			{
				underling = getEntityById( GIANT );
				Sleep( underling.get( Sleep )).ignoreOffscreenSleep = true;
				underling.add( new AudioRange( 500 ));
				_audioGroup.addAudioToEntity( underling );
				
				if( shellApi.checkEvent( _events.SERVED_GIANT ))
				{
					spatial = underling.get( Spatial );
					spatial.x = 1840;
					spatial.y = 650;
					
					SkinUtils.setSkinPart( underling, SkinUtils.ITEM, CHALICE );
					
					CharUtils.setAnim( underling, Sit, false, 0, 0, true );
					CharUtils.setDirection( underling, true );
					
					CharacterGroup( getGroupById( CharacterGroup.GROUP_ID )).removeFSM( underling );
					
					var playerSpatial:Spatial = player.get( Spatial );
					var underlingSpatial:Spatial = underling.get( Spatial );
					
					Dialog( underling.get( Dialog )).faceSpeaker = false;
					_chaliceScale = playerSpatial.scale / underlingSpatial.scale;
					
					_giantTimer = new TimedEvent( 3, 1, giantTookDrink );
					SceneUtil.addTimedEvent( this, _giantTimer );
					
					_giantPlacated = true;
				}
				else
				{
					CharacterGroup( getGroupById( CharacterGroup.GROUP_ID )).addFSM( underling );
				}
			}
			
			// COALS ANIMATION
			clip = _hitContainer[ "coals" ];
			sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( clip.name ));
			
			BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
			Timeline( entity.get( Timeline )).playing = true;
			
			// SETUP GOBLET AND TRAY
			clip = _hitContainer[ "tray" ];
			if( !shellApi.checkEvent( _events.BALANCE_GAME_STARTED ))
			{
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				ToolTipCreator.addToEntity( entity );
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				sceneInteraction = new SceneInteraction();
				sceneInteraction.minTargetDelta = new Point( 50, 100 );
				sceneInteraction.offsetY = 100;
				entity.add( sceneInteraction );
				var on:Boolean = shellApi.checkEvent( _events.HOLDING_TRAY ) ? false : true;
				toggleTray( on );
				
				// SETUP DOORS
				var door:Entity;
				var doors:Vector.<Entity> = new <Entity>[ getEntityById( "doorRiver" ), getEntityById( "doorPen" )];
				
				for each( door in doors )
				{
					sceneInteraction = door.get( SceneInteraction );
					sceneInteraction.reached.removeAll();
					sceneInteraction.reached.add( checkDoor );
				} 
			}
			else
			{
				_hitContainer.removeChild( clip );
			}
		}
		
		private function checkDoor( player:Entity, doorEntity:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			var door:Door = doorEntity.get( Door );
			
			if( !shellApi.checkEvent( _events.HOLDING_TRAY ))
			{	
				door.open = true;
			}
			else
			{
				if( doorEntity.get( Id ).id == "doorPen" )
				{
					SceneUtil.lockInput( this );
					dialog.sayById( "leave_tray" );
					dialog.complete.add( gotoPen );
				}
				else
				{
					dialog.sayById( "sneaky" );
				}
			}
		}
		
		private function gotoPen( dialogData:DialogData ):void
		{
			shellApi.removeEvent( _events.HOLDING_TRAY );
			shellApi.removeEvent( _events.HAS_DRINK + "1" );
			shellApi.removeEvent( _events.HAS_DRINK + "2" );
			shellApi.removeEvent( _events.HAS_DRINK + "3" );
			shellApi.removeEvent( _events.GOBLET_PLACED );
			
			//		super.hideGoblet( false );
			var door:Door = getEntityById( "doorPen" ).get(Door);
			door.open = true;
		}
		
		// VIKINGS AT TABLE LOGIC
//		private function nextJoker():void
//		{			
//			var delay:Number = GeomUtils.randomInRange( 3, 5 );
//			
//			_jokeTimer = new TimedEvent( delay, 1, vikingJoke );
//			SceneUtil.addTimedEvent( this, _jokeTimer );
//		}
		
		private function vikingJoke():Entity
		{
//			_joking = true;
			var underlingNumber:int = GeomUtils.randomInRange( 1, 3 );
			var underling:Entity = getEntityById( UNDERLING + underlingNumber );
			
			var dialog:Dialog = underling.get( Dialog );
			dialog.sayById( JOKE_SETUP );
			dialog.complete.addOnce( awaitResponse );
			
			var underling3:Entity = getEntityById( UNDERLING + "3" );
			var spatial:Spatial = underling3.get( Spatial );
			
			if( underlingNumber == 1 )
			{
				spatial.x = 2825;
				CharUtils.setDirection( underling3, false );
			}
			else if( underlingNumber == 2 )
			{
				spatial.x = 2875;
				CharUtils.setDirection( underling3, true );
			}
			
			return underling;
		}
		
		private function awaitResponse( dialogData:DialogData ):void
		{
			var underling:Entity = getEntityById( dialogData.entityID );
			var dialog:Dialog = underling.get( Dialog );
			
			dialog.complete.addOnce( laughItUp );
		}
		
		private function laughItUp( dialogData:DialogData ):void
		{
			var id:Id;
			var timeline:Timeline;
			var underling:Entity;
			var underlings:Vector.<Entity> = new <Entity>[ getEntityById( UNDERLING + "1" )
				, getEntityById( UNDERLING + "2" )
				, getEntityById( UNDERLING + "3" )];
			
			var joint:String;
			var joints:Vector.<String> = new <String>[ CharUtils.ARM_BACK, CharUtils.ARM_FRONT
				, CharUtils.HAND_BACK, CharUtils.HAND_FRONT
				, CharUtils.NECK_JOINT ]; 
			
			for each( underling in underlings )
			{
				id = underling.get( Id );
				
				var rigAnim:RigAnimation = CharUtils.getRigAnim( underling, 2 );
				if( rigAnim == null )
				{
					var animationSlot:Entity = AnimationSlotCreator.create( underling );
					rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
				}
				
				for each( joint in joints )
				{
					rigAnim.addParts( joint );
				}
				
				if( id.id != dialogData.entityID )
				{
					rigAnim.next = Laugh;
				}
				else 
				{
					var itemPart:SkinPart = SkinUtils.getSkinPartEntity( underling, SkinUtils.ITEM ).get( SkinPart );
					if( itemPart.value == CHALICE )
					{
						rigAnim.next = Drink;
					}
				}
				
				timeline = underling.get( Timeline );
				timeline.handleLabel( ENDING, Command.create( setSit, underling ));
			}
			
			if( !shellApi.checkEvent( _events.START_SERVE_DRINKS ))
			{
				shellApi.triggerEvent( _events.START_SERVE_DRINKS, true );
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, finishServerInstructions ));
			}
			
//			nextJoker();
		}
		
		private function setSit( underling:Entity ):void
		{
//			if( _joking )
//			{
//				_joking = false;
//				
//				if( _givingDrink )
//				{
//					underlingReachesForDrink();
//				}
//			}
			
			CharUtils.setAnim( underling, Sit );
		}
		
		// COOK ANIMATIONS
		private function moveToCauldron():void
		{
			CharUtils.moveToTarget( _cook, 860, 744, true, stirCauldron );
		}
		
		private function stirCauldron( cook:Entity ):void
		{
			CharUtils.setAnim( _cook, Think, false, 120 );
			Timeline( _cook.get( Timeline )).handleLabel( "ending", endStir );
		}
		
		private function endStir():void
		{
			var delay:Number = GeomUtils.randomInRange( 5, 25 );
			
			_cookTimer = new TimedEvent( delay, 1, moveToMeat );
			SceneUtil.addTimedEvent( this, _cookTimer );
		}
		
		private function moveToMeat():void
		{
			CharUtils.moveToTarget( _cook, 1050, 744, true, chopMeat );
		}
		
		private function chopMeat( cook:Entity ):void
		{
			CharUtils.setAnim( _cook, Hammer, false, 120 );
			Timeline( _cook.get( Timeline )).handleLabel( "ending", endChop );
		}
		
		private function endChop():void
		{
			var delay:Number = GeomUtils.randomInRange( 10, 50 );
			
			_cookTimer = new TimedEvent( delay, 1, moveToCauldron );
			SceneUtil.addTimedEvent( this, _cookTimer );
		}
		
		// GIANT LOGIC
		private function isGiantPlacated( player:Entity, furs:Entity ):void
		{
			if( !_giantPlacated )
			{
				var dialog:Dialog = getEntityById( GIANT ).get( Dialog );
				dialog.sayById( "myFurs" );
			}
			else
			{
				removeEntity( getEntityById( _events.FURS ));
				shellApi.getItem( _events.FURS, null, true );
			}
		}
		
		// COOK PRESSING YOU INTO SERVICE CINEMATIC
		private function serveTheDrinks():void
		{
			var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			motionControl.maxVelocityX = WALK_SPEED;
			
			var cook:Entity = getEntityById( "cook" );
			var timeline:Timeline = cook.get( Timeline );
			
			SceneUtil.setCameraTarget( this, cook );
			
			CharUtils.setAnim( cook, Grief );
			timeline.handleLabel( ENDING, meetTheChef );
		}
		
		private function meetTheChef():void
		{
			SceneUtil.setCameraTarget( this, player );
			
			CharUtils.moveToTarget( player, 855, 744, true, beTheServer );
		}
		
		private function beTheServer( player:Entity ):void
		{
			var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			motionControl.maxVelocityX = NORMAL_SPEED;
			
			var cook:Entity = getEntityById( "cook" );
			var dialog:Dialog = cook.get( Dialog );
			dialog.sayById( "youThere" );
			
			CharUtils.setDirection( _cook, false );
		}
		
		private function showTheService():void
		{			
			CharUtils.setDirection( _cook, true );
			CharUtils.setAnim( _cook, Wave );
			
			var timeline:Timeline = _cook.get( Timeline );
			timeline.handleLabel( "ending", panToVikings );
		}
		
		private function panToVikings():void
		{
			SceneUtil.setCameraTarget( this, getEntityById( UNDERLING + 3 ), false, .02 );
			
			var underling:Entity = vikingJoke();
		}
		
		private function finishServerInstructions():void
		{
			SceneUtil.setCameraTarget( this, player, false, .02 );
			
			CharUtils.setDirection( _cook, false );
			var dialog:Dialog = getEntityById( "cook" ).get( Dialog );
			dialog.sayById( "serveNow" );
			dialog.complete.addOnce( agreeToServe );
		}
		
		private function agreeToServe( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
			SceneUtil.setCameraTarget( this, player, false, .2 );
			
			var delay:Number = GeomUtils.randomInRange( 3, 5 );
			_cookTimer = new TimedEvent( delay, 1, moveToCauldron );
			SceneUtil.addTimedEvent( this, _cookTimer );
		}
		
		// EQUIP THE SERVER TRAY
		private function toggleTray( on:Boolean = true ):void
		{
			var tray:Entity = getEntityById( "tray" );
			var display:Display = tray.get( Display );
			var sceneInteraction:SceneInteraction;
			
			if( shellApi.checkEvent( _events.THORLAK_FRAMED ) 
				&& shellApi.checkEvent( _events.SERVED_UNDERLING + "1" )
				&& shellApi.checkEvent( _events.SERVED_UNDERLING + "2" )
				&& shellApi.checkEvent( _events.SERVED_GIANT ))
			{
				display.displayObject[ "inners" ].alpha = 1;
				
				var clip:MovieClip = display.displayObject as MovieClip;
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				
				ToolTipCreator.removeFromEntity( tray );
				tray.remove( Interaction );
				tray.remove( SceneInteraction );
			}
			else
			{
				if( on )
				{
					sceneInteraction = tray.get( SceneInteraction );
					sceneInteraction.reached.removeAll();
					sceneInteraction.reached.addOnce( pickUpTray );
					
					display.displayObject[ "inners" ].alpha = 1;
					display.displayObject[ "inners" ][ "goblet" ].visible = shellApi.checkEvent( _events.GOBLET_PLACED );
				}
				else
				{
					sceneInteraction = tray.get( SceneInteraction );
					sceneInteraction.reached.removeAll();
					sceneInteraction.reached.addOnce( putDownTray );
					
					display.displayObject[ "inners" ].alpha = 0;
				}
			}
			
			if( !shellApi.checkItemEvent( _events.GOBLET, true ))
			{
				display.displayObject[ "inners" ][ "goblet" ].visible = false;
			}
		}
		
		private function pickUpTray( player:Entity, tray:Entity ):void
		{
			super.equipTray();
			shellApi.completeEvent( _events.HOLDING_TRAY );
			
			for( var number:int = 1; number < 4; number ++ )
			{
				shellApi.completeEvent( _events.HAS_DRINK + number );
			}
			
			toggleTray( false );
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "metal_shake_02.mp3" );
		}
		
		private function putDownTray( player:Entity, tray:Entity ):void
		{
			super.hideGobletTray( false );
			shellApi.removeEvent( _events.HOLDING_TRAY );
			
			for( var number:int = 1; number < 4; number ++ )
			{
				shellApi.removeEvent( _events.HAS_DRINK + number );
			}
			
			toggleTray( true );
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "metal_shake_02.mp3" );
		}
		
		override protected function adjustTraySize( itemPart:SkinPart ):void
		{
			super.adjustTraySize( itemPart );
			
			var underling:Entity;
			var sceneInteraction:SceneInteraction;
			
			for( var number:int = 1; number < 4; number ++ )
			{
				underling = getEntityById( UNDERLING + number );
				
				sceneInteraction = underling.get( SceneInteraction );
				sceneInteraction.reached.add( approachViking );
			}
			
			// GIVE GIANT A GLASS INTERACTION SETUP
			underling = getEntityById( GIANT );
			if( !shellApi.checkEvent( _events.SERVED_GIANT ))
			{
				sceneInteraction = underling.get( SceneInteraction );
				sceneInteraction.reached.add( approachViking );			
				
				Dialog( underling.get( Dialog )).faceSpeaker = false;
			}
		}
		
		override protected function approachViking(player:Entity, viking:Entity):void
		{
			var id:Id = viking.get( Id );
			var item:SkinPart = SkinUtils.getSkinPartEntity( getEntityById( GIANT ), SkinUtils.ITEM ).get( SkinPart );
			var item2:SkinPart = SkinUtils.getSkinPartEntity( getEntityById( GIANT ), SkinUtils.ITEM2 ).get( SkinPart );
			if( shellApi.checkEvent( _events.HOLDING_TRAY ) && ( id.id != GIANT || ( id.id == GIANT && item.value != CHALICE && item2.value != CHALICE )))
			{	
		//		super.approachViking( player, viking );
				var spatial:Spatial = viking.get( Spatial );
				var playerSpatial:Spatial = player.get( Spatial );
				
				// TO THE LEFT AND VIKING FACING LEFT
				if( playerSpatial.x < spatial.x && spatial.scaleX > 0 )
				{
					CharUtils.moveToTarget( player, spatial.x - 100, spatial.y, false, Command.create( giveDrink, viking ), new Point( 30, 100 ));
				}
					// ON THE RIGHT AND VIKING FACING LEFT
				else if( playerSpatial.x > spatial.x && spatial.scaleX > 0 )
				{
					CharUtils.moveToTarget( player, spatial.x - 100, spatial.y, false, Command.create( faceViking, viking ), new Point( 30, 100 ));
				}
					// VIKING FACING RIGHT
				else
				{
					CharUtils.moveToTarget( player, spatial.x + 100, spatial.y, false, Command.create( giveDrink, viking ), new Point( 30, 100 ));
				}
			}
			else
			{
				var dialog:Dialog = viking.get( Dialog );
				dialog.sayById( "thanks" );
			}
		}
		
		private function faceViking( player:Entity, viking:Entity ):void
		{
			var spatial:Spatial = viking.get( Spatial );
			var playerSpatial:Spatial = player.get( Spatial );
			
			if( playerSpatial.x < spatial.x )
			{
				CharUtils.setDirection( player, true );
			}
			else
			{
				CharUtils.setDirection( player, false );
			}
			
			giveDrink( player, viking );
		}
		
		override protected function giveDrink( player:Entity, underling:Entity ):Boolean
		{
			if( !super.giveDrink( player, underling ))
			{
				super.approachViking( player, underling );
			}
			else{
				// joke after getting cup
				
			}
			
			return true;
		}
		
		override protected function hideGobletTray( didNotHandDrink:Boolean = true ):void
		{
			super.hideGobletTray();
			toggleTray( true );
		}
		
		override protected function underlingHasDrink( itemPart:SkinPart ):Entity
		{
			var underling:Entity = super.underlingHasDrink( itemPart );
			var id:Id = underling.get( Id );
			var dialog:Dialog = underling.get( Dialog );
			var item:SkinPart = SkinUtils.getSkinPartEntity( getEntityById( GIANT ), SkinUtils.ITEM ).get( SkinPart );
			var item2:SkinPart = SkinUtils.getSkinPartEntity( getEntityById( GIANT ), SkinUtils.ITEM2 ).get( SkinPart );
			
			if( id.id == GIANT && !shellApi.checkEvent( _events.SERVED_GIANT )) 
			{
				dialog.sayById( "finally" );
				dialog.complete.addOnce( giantMovesToChair );
				
				var chalice:Entity = CharUtils.getPart( underling, SkinUtils.ITEM );
				var spatial:Spatial = chalice.get( Spatial );
				_chaliceScale = spatial.scale;
				
				CharUtils.setAnim( underling, Stand, false, 0, 0, true );
			}
			else
			{
				SceneUtil.lockInput( this, false );
				dialog.sayById( "thanks" );
				dialog.allowOverwrite = true;
			}
			
			shellApi.triggerEvent( SERVED + id.id, true );
			_givingDrink = false;
			
			if( shellApi.checkEvent( _events.SERVED_GIANT ) && shellApi.checkEvent( _events.SERVED_UNDERLING + "1" )
				&& shellApi.checkEvent( _events.SERVED_UNDERLING + "2" ) && shellApi.checkEvent( _events.THORLAK_FRAMED ))
			{
				shellApi.removeEvent( _events.HOLDING_TRAY );
				super.hideGobletTray( false );
			}
			
			var on:Boolean = shellApi.checkEvent( _events.HOLDING_TRAY ) ? false : true;
			toggleTray( on );
			
			return underling;
		}
		
		private function giantMovesToChair( dialogData:DialogData ):void
		{
			CharUtils.moveToTarget( getEntityById( GIANT ), 1840, 730, true, giantSitsDown );
		}
		
		private function giantSitsDown( giant:Entity ):void
		{
			CharUtils.setAnim( giant, Sit, false );
			CharUtils.setDirection( giant, true );
			
			CharacterGroup( getGroupById( CharacterGroup.GROUP_ID )).removeFSM( giant );
			Spatial( giant.get( Spatial )).y -= 40;
			
			takeASwig();
			
			SceneUtil.lockInput( this, false );
			_giantPlacated = true;
		}
		
		// LOOPING GIANT PLACATED ANIMATIONS
		private function takeASwig():void
		{
			var giant:Entity = getEntityById( GIANT );
			var animControl:AnimationControl = giant.get( AnimationControl );
			var rigAnim:RigAnimation = CharUtils.getRigAnim( giant, animControl.numSlots - 1 );
			
			if( rigAnim == null )
			{
				var animationSlot:Entity = AnimationSlotCreator.create( giant );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			rigAnim.next = Drink;
			rigAnim.addParts( CharUtils.HAND_FRONT, CharUtils.NECK_JOINT );
			
			var timeline:Timeline = CharUtils.getTimeline( giant, animControl.numSlots - 1 );
			timeline.handleLabel( "ending", giantTookDrink );
			
			Audio( giant.get( Audio )).stopActionAudio( CHEW );
			Audio( giant.get( Audio )).playCurrentAction( "drink" );
		}
		
		private function giantTookDrink():void
		{
			_chewing = false;
			SkinUtils.setSkinPart( getEntityById( GIANT ), SkinUtils.ITEM, MEAT, true, switchItemHands );
			SkinUtils.setSkinPart( getEntityById( GIANT ), SkinUtils.ITEM2, CHALICE, true, switchItemHands );
		}
		
		private function switchItemHands( itemPart:SkinPart ):void
		{
			var giant:Entity = getEntityById( GIANT );
			
			if( itemPart.value == MEAT )
			{
				var meat:Entity = SkinUtils.getSkinPartEntity( giant, itemPart.id );
				Spatial( meat.get( Spatial )).scale = 1;
			}
			else if( itemPart.value == CHALICE )
			{
				var chalice:Entity = SkinUtils.getSkinPartEntity( giant, itemPart.id );
				Spatial( chalice.get( Spatial )).scale = _chaliceScale;
			}
			
			if( _firstItem )
			{
				_firstItem = false;
				var delay:Number = GeomUtils.randomInRange( 3, 5 );
				var handler:Function = takeABite;
				if( _chewing )
				{
					delay = GeomUtils.randomInRange( 20, 25 );
					handler = takeASwig;
					
					SkinUtils.setSkinPart( getEntityById( GIANT ), SkinUtils.MOUTH, "chew", false );
					Audio( getEntityById( GIANT ).get( Audio )).playCurrentAction( CHEW );
				}
				
				_giantTimer = new TimedEvent( delay, 1, handler );
				SceneUtil.addTimedEvent( this, _giantTimer );
			}
			else
			{
				_firstItem = true;
			}
		}
		
		private function takeABite():void
		{
			var animationSlot:Entity;
			var giant:Entity = getEntityById( GIANT );
			var animControl:AnimationControl = giant.get( AnimationControl );
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim( giant, animControl.numSlots - 2 );
			if( rigAnim == null )
			{
				animationSlot = AnimationSlotCreator.create( giant );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			rigAnim.next = Eat;
			rigAnim.addParts( CharUtils.NECK_JOINT );
			
			rigAnim = CharUtils.getRigAnim( giant, animControl.numSlots - 1 );
			if( rigAnim == null )
			{
				animationSlot = AnimationSlotCreator.create( giant );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			rigAnim.next = Sing;
			rigAnim.addParts( CharUtils.HAND_FRONT );
			
			var timeline:Timeline = CharUtils.getTimeline( giant, animControl.numSlots - 1 );
			timeline.handleLabel( "ending", giantTookBite );
			
			Audio( giant.get( Audio )).playCurrentAction( "eat" );
		}
		
		private function giantTookBite():void
		{
			_chewing = true;
			SkinUtils.setSkinPart( getEntityById( GIANT ), SkinUtils.ITEM2, MEAT, true, switchItemHands );
			SkinUtils.setSkinPart( getEntityById( GIANT ), SkinUtils.ITEM, CHALICE, true, switchItemHands );
		}
	}
}
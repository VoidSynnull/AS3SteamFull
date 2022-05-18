package game.scenes.ghd.arena
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.SpatialOffset;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.FrameEvent;
	import game.data.animation.entity.character.Crowbar;
	import game.data.animation.entity.character.Stomp;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.CharacterGroup;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.motion.ProximitySystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class Arena extends GalacticHotDogScene
	{
		private var chef:Entity;
		private var dagger:Entity;
		
		private var jack0:Entity;
		private var jack1:Entity;
		
		private var chemStand:Entity;
		private var barrel:Entity;
		//private var pellet:Entity;
		private var radio:Entity;		
		
		private var guardsDistracted:Boolean = false;
		
		private var charGroup:CharacterGroup;
		private var guardTimer:TimedEvent;
		private var radioIdle:Boolean = true;
		private var radioTimer:TimedEvent;
		
		private var _animationLoader:AnimationLoaderSystem;
		private var _characterGroup:CharacterGroup;
		private var spatula:Entity;
		
		private const SPATULA:String	= "ghd_spatula";
		private const RADIO:String = SoundManager.EFFECTS_PATH + "microphone_feedback_01.mp3";
		private const POP:String = SoundManager.EFFECTS_PATH + "big_pop_01.mp3";
		private const PRY:String = SoundManager.EFFECTS_PATH + "pry_lid_01.mp3";
		
		
		public function Arena()
		{
			super();
		}
		
		override protected function addCharacters():void
		{
			super.addCharacters();
			
			// PRELOAD ANIMATIONS FOR SNEAKING
			_characterGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			_characterGroup.preloadAnimations( new <Class>[ Crowbar ], this );
			
			_animationLoader = super.getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/arena/";
			
			super.init(container);
		}
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function destroy():void
		{
			if(guardTimer){
				guardTimer.stop();
				guardTimer = null;
			}
			if(radioTimer){
				radioTimer.stop();
				radioTimer = null;
			}
			super.destroy();
		}
		
		// all assets ready
		override public function loaded():void
		{
			addSystem( new TimelineVariableSystem() );
			
			switchInSpoon();
			super.loaded();
			shellApi.eventTriggered.add(handleEventTriggered);
			charGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			setupNpcs();
			//setupFloatingStands();
			setupNukeCart();
			correctAlienDialogPositioning();
			// queen yelling at dagger on player's first visit
			runQueenDialog();
		}
		
		private function runQueenDialog():void
		{
			var queen:Entity = getEntityById("queen");
			if(!shellApi.checkEvent(_events.SAW_QUEEN)){
				// lock, pan to queen, queen talks, queen leaves, unlock
				SceneUtil.lockInput(this, true);
				SceneUtil.setCameraTarget(this, queen);
				SceneUtil.addTimedEvent(this, new TimedEvent(1.2, 1, Command.create(queen.get(Dialog).sayById,"evil")));
			}
			else{
				removeEntity(queen);
			}
			if(shellApi.checkEvent(_events.COOKED_DOG)){
				removeEntity(dagger);
			}
		}
		
		private function switchInSpoon():void
		{
			var crowbarAnimation:Crowbar = _animationLoader.animationLibrary.getAnimation( Crowbar ) as Crowbar;
			
			while( crowbarAnimation.data.frames[ 0 ].events.length > 0 )
			{
				crowbarAnimation.data.frames[ 0 ].events.pop();
			}
			
			var frameEvents:Vector.<FrameEvent> = new <FrameEvent>[ new FrameEvent( "setPart", "eyeState", "casual" )];// new FrameEvent( "setPart", "item", "ghd_spatula")
			
			for( var number:int = 0; number < frameEvents.length; number ++ )
			{
				crowbarAnimation.data.frames[ 0 ].events.push( frameEvents[ number ]);
			}
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			setupRadio();
			setupFloatingStands();
			// setup dialog for aliens here too?
			
			super.addCharacterDialog(container);
		}
		
		private function setupNpcs():void
		{
			dagger = getEntityById("dagger");
			var sleep:Sleep = dagger.get( Sleep );
			if( sleep )
			{
				sleep.ignoreOffscreenSleep = true;
			}
			jack0 = getEntityById("jack0");
			charGroup.addFSM(jack0);
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(jack0));
			CharacterMotionControl(jack0.get(CharacterMotionControl)).maxVelocityX = 500;
			Character(jack0.get(Character)).costumizable = false;
			sleep = jack0.get( Sleep );
			if( sleep )
			{
				sleep.ignoreOffscreenSleep = true;
			}
			
			jack1 = getEntityById("jack1");
			charGroup.addFSM(jack1);
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(jack1));
			CharacterMotionControl(jack1.get(CharacterMotionControl)).maxVelocityX = 500;
			Character(jack1.get(Character)).costumizable = false;
			sleep = jack1.get( Sleep );
			if( sleep )
			{
				sleep.ignoreOffscreenSleep = true;
			}
			
			Character(getEntityById("alien3").get(Character)).costumizable = false;
		}
		
		private function setupNukeCart():void
		{
			var clip:MovieClip = _hitContainer["chems"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
				var TL:BitmapSequence = BitmapTimelineCreator.createSequence(clip["barrel"]);
			}
			// cart
			chemStand = EntityUtils.createMovingEntity(this, clip, _hitContainer);
			MotionUtils.addWaveMotion( chemStand, new WaveMotionData( "y", 6, 0.03, "cos" ), this );
			var inter:Interaction = InteractionCreator.addToEntity(chemStand,[InteractionCreator.CLICK]);
			inter.click.add(cartDialog);
			ToolTipCreator.addToEntity(chemStand,"click",null,new Point(150,-40));
			// platform
			var plat:Entity = getEntityById("chemsPlat");
			//MotionUtils.addWaveMotion( plat, new WaveMotionData( "y", 6, 0.03, "cos" ), this );
			plat.get(Display).visible = false;
			plat.add(chemStand.get(SpatialAddition));
			// tipping  barrel
			if(TL){
				//barrel = EntityUtils.createSpatialEntity(this, clip["barrel"], clip);
				barrel = BitmapTimelineCreator.convertToBitmapTimeline(barrel, clip["barrel"], true, TL, PerformanceUtils.defaultBitmapQuality);
				addEntity(barrel);
			}
			else{
				barrel = EntityUtils.createMovingTimelineEntity(this, clip["barrel"], clip);
			}
			// pellets on ground
			if(shellApi.checkEvent(_events.BROKE_NUKE_CART)){
				if(shellApi.checkEvent(_events.GOT_NUCLEAR_PELLET)){
					Timeline(barrel.get(Timeline)).gotoAndStop("removedPellet");
				}else{
					Timeline(barrel.get(Timeline)).gotoAndStop("end");
					if(chemStand.has(SpatialOffset)){
						SpatialOffset(chemStand.get(SpatialOffset)).x = 135;
					}
				}
				removeEntity(jack0);
				removeEntity(jack1);
			}else{
				var cartZone:Entity = getEntityById("zone0");
				var zone:Zone = cartZone.get(Zone);
				zone.entered.add(catchPlayer);
			}
		}
		
		private function correctAlienDialogPositioning():void
		{	
			var alien:Entity = getEntityById( "alien3" );
			var dialog:Dialog = alien.get( Dialog );
			
			dialog.dialogPositionPercents = new Point( 0, .7 );
		}
		
		private function cantTouch(...p):void
		{
			Dialog(player.get(Dialog)).sayById("nuke");
		}
		
		private function cartDialog(...p):void
		{
			if(!shellApi.checkEvent(_events.BROKE_NUKE_CART) && !shellApi.checkHasItem(_events.FUEL_CELL)){
				Dialog(player.get(Dialog)).sayById("spoon");
			}
			else if(!shellApi.checkEvent(_events.BROKE_NUKE_CART) && shellApi.checkHasItem(_events.FUEL_CELL)){
				Dialog(player.get(Dialog)).sayById("spoon2");
			}
			else if(!shellApi.checkEvent(_events.GOT_NUCLEAR_PELLET)){
				Dialog(player.get(Dialog)).sayById("nuke");
			}else{
				Dialog(player.get(Dialog)).sayById("thereIsNoSpoon");
			}
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.USE_GIANT_SPATULA){
				positionForSpatula();
			}
			else if(event == _events.USE_FUEL_CELL){
				if(shellApi.checkEvent(_events.BROKE_NUKE_CART) && !shellApi.checkEvent(_events.GOT_NUCLEAR_PELLET)){
					moveToPellet();
				}else{
					// fuel cell comment
					shellApi.triggerEvent(_events.NO_USE_FULL_FUEL_CELL);
				}
			}
			else if(event == "guards_distracted"){
				if(!guardsDistracted && !shellApi.checkEvent(_events.BROKE_NUKE_CART)){
					SceneUtil.addTimedEvent(this, new TimedEvent(0.3,1,Command.create(SceneUtil.setCameraTarget,this,jack0)));
					lock();
					Dialog(jack0.get(Dialog)).sayById("radio0");
					Dialog(jack1.get(Dialog)).complete.addOnce(Command.create(moveGuardsToRadio,guardReachedRadio));
				}
			}
			else if(event == _events.USE_SEED_POD){
				giveIngredient(_events.SEED_POD);
			}
			else if(event == _events.USE_FRUIT){
				giveIngredient(_events.FRUIT);
			}
			else if(event == "see_queen"){
				queenLeaves();
			}
		}
		
		private function queenLeaves():void
		{
			var queen:Entity = getEntityById("queen");
			if(queen){
				SceneUtil.setCameraTarget(this, player);
				CharUtils.moveToTarget(queen, 1000, 1300, false, removeQueen, new Point(100, 100));
			}
		}
		
		private function removeQueen(queen:Entity):void
		{
			removeEntity(queen);
			unlock();
			shellApi.completeEvent(_events.SAW_QUEEN);
		}
		
		private function giveIngredient(ingredient:String):void
		{
			CharUtils.moveToTarget(player, chef.get(Spatial).x,chef.get(Spatial).y+120, false, Command.create(handItem,ingredient),new Point(30,200));
		}
		
		private function handItem(junk:*, ingredient:String):void
		{
			Dialog(chef.get(Dialog)).sayById(ingredient);
		}
		
		private function moveToPellet():void
		{
			var targ:Point = new Point(_hitContainer["nav2"].x,_hitContainer["nav2"].y);
			CharUtils.moveToTarget(player,targ.x,targ.y,false,getPellet, new Point(30,100));
		}
		
		private function getPellet(...p):void
		{
			shellApi.completeEvent(_events.GOT_NUCLEAR_PELLET);
			shellApi.showItem(_events.FUEL_CELL,null);
			Timeline(barrel.get(Timeline)).gotoAndStop("removedPellet");
			unlock();
		}
		
		private function setupRadio():void
		{
			var clip:MovieClip = _hitContainer[ "radio" ];			
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				//radio = EntityUtils.createSpatialEntity(this,clip);
				radio = BitmapTimelineCreator.convertToBitmapTimeline(radio,clip,true,null,PerformanceUtils.defaultBitmapQuality);
				addEntity(radio);
			}
			else{
				radio = EntityUtils.createMovingTimelineEntity( this, clip );
			}
			var dialog:Dialog = new Dialog();
			dialog.faceSpeaker = false;
			dialog.dialogPositionPercents = new Point( -1, 6.2 );
			// mouth control
			dialog.start.add(Command.create(runTalk,radio));
			dialog.complete.add(Command.create(runIdle,radio));
			dialog.balloonPath = "ui/elements/wordBalloonRadio.swf";
			
			radio.add( dialog );
			radio.add( new Id( "radio" ));
			
			radio.add( new Edge( 50, 50, 50, 50 ));
			var character:Character = new Character();
			character.costumizable = false;
			radio.add(character);			
			
			InteractionCreator.addToEntity( radio, [ InteractionCreator.CLICK ]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.autoSwitchOffsets = false;
			sceneInteraction.offsetDirection = true;
			sceneInteraction.offsetX = 5;
			sceneInteraction.offsetY = 180;
			
			ToolTipCreator.addToEntity( radio,"click",null,new Point(35,0) );
			sceneInteraction.reached.removeAll();
			sceneInteraction.reached.add(useRadio);
			radio.add( sceneInteraction );		
			
			radioTimer = SceneUtil.addTimedEvent(this,new TimedEvent(8, 1, Command.create(startRadioDialog,dialog)),"radioTimer");
		}
		
		private function startRadioDialog(dialog:Dialog):void
		{	
			if(radioIdle){
				var randComment:int = GeomUtils.randomInt(0, 4);
				dialog.sayById("comment"+randComment);
				dialog.complete.addOnce(delayNextRadioTalk);
				// SOUND
				AudioUtils.playSoundFromEntity(radio, RADIO, 700, 0.5, 1.5);
			}
		}
		
		private function delayNextRadioTalk(...p):void
		{	
			var randDelay:Number = GeomUtils.randomInRange(7, 10);
			radioTimer = SceneUtil.addTimedEvent(this,new TimedEvent(randDelay, 1, Command.create(startRadioDialog,radio.get(Dialog))),"radioTimer");
		}
		
		private function useRadio(...p):void
		{	
			var PDialog:Dialog = player.get(Dialog);
			if(!guardsDistracted && !PDialog.speaking)
			{	
				EntityUtils.removeAllWordBalloons(this, radio);
				EntityUtils.removeAllWordBalloons(this, jack0);
				EntityUtils.removeAllWordBalloons(this, jack1);
				
				radioIdle = false;
				runIdle(null, radio);
				var RDialog:Dialog = radio.get(Dialog);
				
				//				if( !shellApi.checkEvent( _events.GOT_NUCLEAR_PELLET ))
				//				{
				//					RDialog.start.addOnce(lock);
				//				}
				RDialog.complete.addOnce(resumeIdleRadio);
				PDialog.sayById("loudspeaker");
				PDialog.complete.addOnce(Command.create(radioOptions,PDialog,RDialog));
			}
		}
		
		private function radioOptions(d:*, PDialog:Dialog, RDialog:Dialog):void
		{
			// start conver
			RDialog.sayById("heyRadio");
			if( !shellApi.checkEvent( _events.BROKE_NUKE_CART))
			{
				PDialog.start.addOnce(Command.create(radioLock));
			}
		}		
		
		
		private function radioLock(data:DialogData):void
		{
			if(data.id.substr(0,"heyRadio".length) == "heyRadio" ){
				lock();
				// SOUND
				AudioUtils.playSoundFromEntity(radio, RADIO, 700, 0.5, 1.5);
			}
		}
		
		private function resumeIdleRadio(...p):void
		{
			radioIdle = true;
			delayNextRadioTalk();
			//startRadioDialog(radio.get(Dialog));
		}	
		
		private function runIdle(junk:*, char:Entity):void
		{
			var timeline:Timeline = char.get(Timeline);
			timeline.gotoAndPlay("idle");
		}
		
		private function runTalk(junk:*, char:Entity):void
		{
			var timeline:Timeline = char.get(Timeline);
			timeline.gotoAndPlay("talk");
		}
		
		private function moveGuardsToRadio(junk:*,reached:Function):void
		{
			CharUtils.moveToTarget(jack0,2250,jack0.get(Spatial).y,false)
			CharUtils.moveToTarget(jack1,2520,jack1.get(Spatial).y,false,reached);
		}
		
		private function moveGuardsToBarrel(reached:Function):void
		{
			CharUtils.moveToTarget(jack0,600,jack0.get(Spatial).y,false)
			CharUtils.moveToTarget(jack1,450,jack1.get(Spatial).y,false,reached);
		}		
		
		private function guardReachedRadio(...p):void
		{
			// guards talk to dagger/player
			guardsDistracted = true;
			CharUtils.setAnim(jack1, Stomp);
			SceneUtil.setCameraTarget(this, player);
			//guards stop to check on dagger
			Dialog(jack1.get(Dialog)).sayById("radio2");
			Dialog(jack1.get(Dialog)).complete.addOnce(moveBackRadio);
			Dialog(jack0.get(Dialog)).complete.addOnce(checkReturn);
		}
		
		private function moveBackRadio(...p):void
		{
			CharUtils.moveToTarget(player, 2000, 1300, true, unlock);
		}
		
		private function checkReturn(...p):void
		{
			Dialog(jack1.get(Dialog)).complete.addOnce(delayReturn);
		}
		
		private function delayReturn(...p):void
		{
			if(guardTimer){
				guardTimer.stop();
				guardTimer = null;
			}
			guardTimer = SceneUtil.addTimedEvent(this, new TimedEvent(15,1,guardsReturn),"guardTimer");
		}
		
		private function guardsReturn(...p):void
		{
			EntityUtils.removeAllWordBalloons(this);
			moveGuardsToBarrel(checkBarrels);
		}
		
		private function checkBarrels(...p):void
		{
			// if destroyed, run away! else go back to work
			if(shellApi.checkEvent(_events.BROKE_NUKE_CART)){
				// flee
				Dialog(jack0.get(Dialog)).complete.removeAll()
				Dialog(jack1.get(Dialog)).complete.removeAll()
				Dialog(jack0.get(Dialog)).sayById("leave");
				Dialog(jack1.get(Dialog)).complete.addOnce(guardsLeave);
			}
			else if(EntityUtils.getPosition(player).x < 600){
				guardsDistracted = false;
				catchPlayer("","player");
			}
			else{
				// resume guarding
				guardsDistracted = false;
				CharUtils.setDirection(jack0, true);
				CharUtils.setDirection(jack1, true);
			}
		}
		
		private function guardsLeave(...p):void
		{
			// guards run away
			CharUtils.moveToTarget(jack0,-100,jack0.get(Spatial).y,false);
			CharUtils.moveToTarget(jack1,-100,jack1.get(Spatial).y,false);
			
			EntityUtils.removeAllWordBalloons(this, jack0);
			EntityUtils.removeAllWordBalloons(this, jack1);
			
			SceneUtil.lockInput( this, false, false );
		}		
		
		private function positionForSpatula(...p):void
		{
			if(!shellApi.checkEvent(_events.BROKE_NUKE_CART)){
				SceneUtil.lockInput( this );
				var targ:Point = new Point(_hitContainer["nav"].x,_hitContainer["nav"].y);
				CharUtils.moveToTarget(player, targ.x, targ.y,false,attemptSpatulaUse,new Point(20,30));
			}else{
				// no use comment
				shellApi.triggerEvent(_events.NO_USE_GIANT_SPATULA);
			}
		}
		
		private function attemptSpatulaUse(...p):void
		{
			// try to tip fuel rods over, only works when guards are gone
			if(guardsDistracted){
				// sucess!
				breakNukeCart();
			}
			else{
				// get yelled at
				catchPlayer("","player");
			}
		}
		
		private function catchPlayer(z:String = "", p:String = ""):void
		{
			// say something, then move player back
			if(!guardsDistracted && p == "player"){
				lock();
				if(Dialog(jack0.get(Dialog)).speaking)
				{
					EntityUtils.removeAllWordBalloons(this, jack0);
				}
				Dialog(jack0.get(Dialog)).sayById("back");
				Dialog(jack1.get(Dialog)).complete.addOnce(moveBack);
			}
		}
		
		private function moveBack(...p):void
		{
			CharUtils.moveToTarget(player, 900, 1300, true, unlock, new Point(30,500)).ignorePlatformTarget = true;
		}
		
		private function breakNukeCart(...p):void
		{
			// break
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, SPATULA, true, pryOpenSetPart );
		}
		
		private function pryOpenSetPart(...p):void
		{
			
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, SPATULA, true, pryOpen );
		}
		
		private function pryOpen(...p):void
		{
			var barrelTl:Timeline = Timeline(barrel.get(Timeline));
			var playerTl:Timeline = Timeline(player.get(Timeline));
			
			EntityUtils.position(player, 380, EntityUtils.getPosition(chemStand).y-20);
			CharUtils.setDirection(player,true);
			CharUtils.setAnim(player, Crowbar);
			playerTl.handleLabel("trigger",Command.create(barrelTl.gotoAndPlay,"tip"));
			playerTl.handleLabel("trigger",Command.create(AudioUtils.playSoundFromEntity, chemStand, POP, 700, 0.5, 1.5));
			playerTl.handleLabel("ending", regainControl );
			
			//kill timer
			if(guardTimer && guardTimer.running){
				guardTimer.stop();
				guardTimer = null;
				barrelTl.handleLabel("end",guardsReturn);
			}
			
			shellApi.triggerEvent(_events.BROKE_NUKE_CART, true);
			
			// SOUND
			AudioUtils.playSoundFromEntity(chemStand, PRY, 700, 0.5, 1.5);
		}
		
		private function regainControl():void
		{
			SceneUtil.lockInput( this, false );
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "empty", true );
		}
		
		// make food stands float and embed npcs in them
		private function setupFloatingStands():void
		{
			var stand:Entity;
			var plat:Entity;
			var clip:MovieClip;
			var rateOffset:Number = 0;
			for (var i:int = 0; i < 4; i++) 
			{
				rateOffset = 0.04 + i / 100;
				clip = _hitContainer["stand"+i];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
				}
				stand = EntityUtils.createMovingEntity(this, clip, _hitContainer);
				MotionUtils.addWaveMotion( stand, new WaveMotionData( "y", 6, rateOffset , "cos" ), this );
				plat = getEntityById("stand"+i+"Plat");
				plat.get(Display).visible = false;
				plat.add(stand.get(SpatialAddition));
				// put npc aliens at stands
				if(i==0){
					insertAlienNpc(stand, "cook0");
				}
				else if(i==1){
					insertAlienNpc(stand, "chef");
					floatSpatula(stand);
				} 
				else if(i==2){
					insertAlienNpc(stand, "cook1");
				}
				else if(i==3){
					insertAlienNpc(stand, "cook2");
				}
				
			}
		}
		
		private function floatSpatula(stand:Entity):void
		{
			spatula = EntityUtils.createMovingEntity(this, _hitContainer["giant_spatula"],_hitContainer);//this.getEntityById("giant_spoon");
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(EntityUtils.getDisplayObject(spatula),PerformanceUtils.defaultBitmapQuality);
			}
			if(spatula){
				if(shellApi.checkHasItem(_events.GIANT_SPATULA)){
					removeEntity(spatula);
				}
				else{	
					super.addSystem(new ProximitySystem());
					
					// float spoon
					ToolTipCreator.addToEntity(spatula);
					spatula.add(stand.get(SpatialAddition));
					var prox:Proximity = new Proximity(160,player.get(Spatial));
					prox.entered.addOnce(getSpatula);
					spatula.add(prox);
				}
			}
		}
		
		private function getSpatula(...p):void
		{
			shellApi.getItem(_events.GIANT_SPATULA,null,true);
			removeEntity(spatula);
		}
		
		// make custom dialog alien
		private function insertAlienNpc(stand:Entity, charID:String):void
		{
			var clip:MovieClip = _hitContainer[ charID ];
			var char:Entity;
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				//char = EntityUtils.createSpatialEntity(this,clip);
				char = BitmapTimelineCreator.convertToBitmapTimeline(char, clip, true, null, PerformanceUtils.defaultBitmapQuality, 28);
				addEntity(char);
			}
			else{
				char = EntityUtils.createMovingTimelineEntity( this, clip, null, false, 28 );
			}
			var dialog:Dialog = new Dialog();
			dialog.faceSpeaker = false;
			dialog.dialogPositionPercents = new Point( 0.1, 2 );
			// mouth control
			dialog.start.add(Command.create(runTalk,char));
			dialog.complete.add(Command.create(runIdle,char));
			runIdle(null,char);
			
			char.add( dialog );
			char.add( new Id( charID ));
			
			char.add( new Edge( 50, 50, 50, 50 ));
			var character:Character = new Character();
			character.costumizable = false;
			char.add(character);				
			
			InteractionCreator.addToEntity( char, [ InteractionCreator.CLICK ]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = -100;
			sceneInteraction.offsetY = 200;
			
			ToolTipCreator.addToEntity( char );
			char.add( sceneInteraction );	
			char.add(stand.get(SpatialAddition));
			if(charID == "chef"){
				chef = char;
			}
		}	
		
		private function lock(...p):void
		{
			SceneUtil.lockInput(this, true);
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false, false);
			SceneUtil.setCameraTarget(this, player);
		}
		
	}
}
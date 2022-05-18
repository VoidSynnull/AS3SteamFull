package game.scenes.carnival.ridesEvening{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Skin;
	import game.components.motion.MotionTarget;
	import game.components.motion.Proximity;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.SledgeHammer;
	import game.scenes.carnival.CarnivalEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.SwarmingFlies;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.ridesDay.GearSparks;
	import game.scenes.carnival.ridesEvening.components.CarouselHorse;
	import game.scenes.carnival.ridesEvening.systems.CarouselSystem;
	import game.scenes.carnival.shared.ferrisWheel.FerrisWheelGroup;
	import game.scenes.carnival.shared.ferrisWheel.components.StickToEntity;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.ActionExecutionSystem;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.motion.ProximitySystem;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class RidesEvening extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		
		private var gears:Entity;
		private var lever:Entity;
		private var strengthTarget:Entity;
		private var strengthTarget2:Entity;
		private var fist:Entity;
		private var strengthWorker:Entity;
		private var ferrisWorker:Entity;
		private var loverGirl:Entity;
		private var loverBoy:Entity;
		private var tunnelLoveWorker:Entity;
		private var man:Entity;
		private var woman:Entity;
		private var currStrengthTarget:Entity;
		
		private var strengthTargetToolTip:ToolTip;
		private var strengthTargetInteraction:Interaction;
		
		private var _fliesEntity:Entity;
		private var sparksEmitter:GearSparks;
		private var sparksEmitterEntity:Entity;
		
		private var triedHammer:Boolean = false;

		private var ferrisGroup:FerrisWheelGroup;

		public function RidesEvening()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/ridesEvening/";
			
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
			super.loaded();
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			this.ferrisWorker = this.getEntityById("ferrisWheelWorker");
			this.strengthWorker = this.getEntityById("strengthWorker");
			this.loverGirl = this.getEntityById("loverGirl");
			this.loverBoy = this.getEntityById("loverBoy");
			this.tunnelLoveWorker = this.getEntityById("tunnelLoveWorker");
			this.man = this.getEntityById("man");
			this.woman = this.getEntityById("woman");

			this.initFerrisWheel();
			setupFlies();
			setupAnimations();
			
			if(this.shellApi.checkEvent( this._events.WON_STRENGTH_GAME)){
				Dialog(strengthWorker.get(Dialog)).setCurrentById("suchStrength");
				setupBall();
				var skin:Skin = strengthWorker.get(Skin) as Skin;
				skin.getSkinPart( SkinUtils.ITEM ).remove();
				fist.get(Timeline).gotoAndStop("broken");
			}else if(this.shellApi.checkEvent( this._events.USED_BALL )){
				setupBall();
				Dialog(strengthWorker.get(Dialog)).setCurrentById("letsSee");
				Dialog(strengthWorker.get(Dialog)).start.add(checkDialogStart);
			}else{
				Dialog(strengthWorker.get(Dialog)).setCurrentById("letsSee");
				Dialog(strengthWorker.get(Dialog)).start.add(checkDialogStart);
			}
			
			if ( this.shellApi.checkEvent( this._events.TEENS_FRIGHTENED ) ) {
				this.removeEntity( this.getEntityById("loverGirl" ) );
				this.removeEntity( this.getEntityById("loverBoy" ) );
				this.removeEntity( this.getEntityById("ferrisWheelWorker" ) );
				this.removeEntity( this.getEntityById("strengthWorker" ) );
				this.removeEntity( this.getEntityById("tunnelLoveWorker" ) );
				gears.get(Timeline).gotoAndStop(0);
				if(super.shellApi.sceneManager.previousScene == "game.scenes.carnival.tunnelLove::TunnelLove"){ //coming from tunnel
					SceneUtil.lockInput(this);
					super.shellApi.camera.target = man.get(Spatial);
					Dialog(man.get(Dialog)).sayById("carniesGo");
				}
				
			}else if(this.shellApi.checkHasItem( this._events.HUMAN_FLY_MASK)){
				Dialog(tunnelLoveWorker.get(Dialog)).setCurrentById("haveFlyMask");	
				this.removeEntity( this.getEntityById("loverGirl" ) );
				this.removeEntity( this.getEntityById("loverBoy" ) );
				
			}else if(this.shellApi.checkEvent( this._events.TEENS_IN_TUNNEL)){
				setupAnnoyedAtTeens();
				this.removeEntity( this.getEntityById("loverGirl" ) );
				this.removeEntity( this.getEntityById("loverBoy" ) );
			}
			
			if(this.shellApi.checkEvent( this._events.GOT_BLUNTED_DART) && this.shellApi.checkHasItem( this._events.HAMMER) && !this.shellApi.checkEvent( this._events.TEENS_IN_TUNNEL)){

				Dialog(ferrisWorker.get(Dialog)).start.add( this.workerDialogStart );
				setFerrisWheelStuck();

			} else {

				if(this.getEntityById("ferrisWorker") != null){
					Dialog(ferrisWorker.get(Dialog)).setCurrentById("fixedFerrisWheel");
				}

				var sp:Spatial = this.loverBoy.get( Spatial );
				// spatial will be empty if kids were removed earlier. need to test.
				if ( sp ) {
					sp.x = -300;
					loverGirl.get(Spatial).x = -300;
				}

			}
			
			super.addSystem(new CarouselSystem());
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			if( event == "tryStrengthGame" ) {
				CharUtils.moveToTarget(player, strengthTarget.get(Spatial).x - 90, 1758, false, swingHammer);
			}else if( event == "ball_used" ) {
				if(Math.abs(player.get(Spatial).x - strengthTarget.get(Spatial).x) < 300 && Math.abs(player.get(Spatial).y - strengthTarget.get(Spatial).y) < 300){
					SceneUtil.lockInput(this);				
					CharUtils.moveToTarget(player, strengthTarget.get(Spatial).x - 100, 1758, false, setBall);
				}
				this.shellApi.completeEvent( this._events.REPLACED_LEVER);
			}else if( event == "giveHammer" ) {
				var skin2:Skin = strengthWorker.get(Skin) as Skin;
				skin2.getSkinPart( SkinUtils.ITEM ).remove();
				shellApi.getItem(_events.HAMMER,null,true );
				SceneUtil.lockInput(this, false);
				Dialog(strengthWorker.get(Dialog)).setCurrentById("suchStrength");
				this.shellApi.triggerEvent( this._events.WON_STRENGTH_GAME, true);
				if(this.shellApi.checkEvent( this._events.GOT_BLUNTED_DART) && !this.shellApi.checkEvent( this._events.TEENS_IN_TUNNEL)){
					setFerrisWheelStuck();
				}
				
			} else if( event == "oil_used" ) {
				if(this.shellApi.checkEvent( this._events.GOT_BLUNTED_DART) && this.shellApi.checkHasItem( this._events.HAMMER) && !this.shellApi.checkEvent( this._events.TEENS_IN_TUNNEL)){
					if(Math.abs(player.get(Spatial).x - gears.get(Spatial).x) < 300 && Math.abs(player.get(Spatial).y - gears.get(Spatial).y) < 300){
						SceneUtil.lockInput(this);				
						CharUtils.moveToTarget(player, ferrisWorker.get(Spatial).x - 100, 1758, false, useOil);
						this.shellApi.completeEvent( this._events.REPLACED_LEVER);
						Dialog(ferrisWorker.get(Dialog)).setCurrentById("fixedFerrisWheel");
					}
				}else{
					super.shellApi.triggerEvent("no_reason_to_use_item_default", false);
				}

			}else if( event == "loversToTunnel" ) {
				CharUtils.followPath(loverGirl, new <Point> [new Point(loverGirl.get(Spatial).x + 1000, loverGirl.get(Spatial).y)], removeLovers, true);
				CharUtils.followPath(loverBoy, new <Point> [new Point(loverBoy.get(Spatial).x + 1000, loverBoy.get(Spatial).y)], null, true);
			}else if( event == "giveFlashlight" ) {
				shellApi.getItem(_events.FLASHLIGHT,null,true );
				var te:TimedEvent = new TimedEvent(1.5, 1, unlock, true);
				SceneUtil.addTimedEvent(this, te);
			}else if( event == "needGrease" ) {

				this.shellApi.completeEvent( this._events.SPOKE_ABOUT_GREASE );
				this.showStuckKids();

			}else if( event == "takeLookOver" ) {
				SceneUtil.lockInput(this, false);
				super.shellApi.camera.target = player.get(Spatial);
			}else if( event == "intoWoods" ) {
				super.shellApi.camera.target = player.get(Spatial);
			}else if( event == "turnAround" ) {
				CharUtils.setDirection(player, false);
			}
		}
		
		private function setFerrisWheelStuck():void {
			Dialog(ferrisWorker.get(Dialog)).setCurrentById("greaseGears");
			gears.get(Timeline).gotoAndPlay("superfast");
			
			//add sparks...
			setupSparks();
			this.ferrisGroup.setAngularVelocity( 0 );
			this.putTeensOnWheel();
		}
		
		private function swingHammer(entity:Entity):void {
			CharUtils.setDirection(player, true);
			CharUtils.setDirection(strengthWorker, false);
			var skin:Skin = strengthWorker.get(Skin) as Skin;
			skin.getSkinPart( SkinUtils.ITEM ).remove();
			
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "mc_hammer", false );
			CharUtils.setAnim(player, SledgeHammer);
			player.get(Timeline).handleLabel("trigger", hammerSwing, false);
		}
		
		private function setupSparks():void {
			sparksEmitter = new GearSparks();
			sparksEmitter.init();
			
			sparksEmitterEntity = EmitterCreator.create( this, super._hitContainer, sparksEmitter, -9, -35, player, "mEmitterEntity", gears.get(Spatial), false );
			
			sparksEmitter.start();
		}
		
		private function unlock():void {
			SceneUtil.lockInput(this, false);	
		}
		
		private function useOil(entity:Entity):void {

			CharUtils.setDirection(player, true);
			var itemGroup:ItemGroup = super.getGroupById( "itemGroup" ) as ItemGroup;
			itemGroup.takeItem( _events.FRY_OIL, "gears" );

			SceneUtil.addTimedEvent(this, new TimedEvent(.7, 1, makeGreasy, true));
		
			/**
			 * If the teens are put on the 0-index platform (top of wheel)
			 * then stopping at 180 degrees should bring them to the ground.
			 */
			this.ferrisGroup.rotateTo( 180, this.dropTeens );

			SceneUtil.setCameraTarget( this, this.loverGirl );

			//var te:TimedEvent = new TimedEvent(0.5, 1, fixFerrisWheel, true);
			//SceneUtil.addTimedEvent(this, te);

		}
		
		private function makeGreasy():void {
			gears.get(Timeline).gotoAndPlay("afterfryoil");
			sparksEmitter.stop();
		}

		/**
		 * Teens drop to the ground.
		 */
		private function dropTeens( e:Entity ):void {

			var s:Spatial = this.player.get( Spatial ) as Spatial;

			this.loverBoy.remove( StickToEntity );
			this.loverGirl.remove( StickToEntity );

			CharUtils.moveToTarget( this.loverGirl, s.x - 100, this.sceneData.bounds.bottom, true, fixFerrisWheel );
			CharUtils.moveToTarget( this.loverBoy, s.x - 130, this.sceneData.bounds.bottom, true, null );

		} //

		private function fixFerrisWheel( e:Entity ):void { //ferris wheel is fixed

			SceneUtil.setCameraTarget( this, this.player );

			//loverGirl.get(Spatial).x = player.get(Spatial).x - 100;
			//loverBoy.get(Spatial).x = player.get(Spatial).x - 130;
			CharUtils.setDirection(loverGirl, true);
			CharUtils.setDirection(loverBoy, true);
			Dialog(loverGirl.get(Dialog)).sayById("getOffFerrisWheel");

		}
		
		private function removeLovers(entity:Entity):void {

			super.shellApi.removeItem( _events.FRY_OIL );
			this.shellApi.completeEvent( this._events.TEENS_IN_TUNNEL);
			this.removeEntity( this.getEntityById("loverGirl" ), true );
			this.removeEntity( this.getEntityById("loverBoy" ), true );
			SceneUtil.lockInput(this, false);
			setupAnnoyedAtTeens();
		} //
		
		private function setupAnnoyedAtTeens():void {
			Dialog(tunnelLoveWorker.get(Dialog)).setCurrentById("annoyedAtTeens");
			Dialog(tunnelLoveWorker.get(Dialog)).start.add(checkDialogStart);
			this.addSystem(new ProximitySystem());
			
			var proximity:Proximity = new Proximity(1500, this.player.get(Spatial));
			proximity.entered.addOnce(handleNearTunnelLoveWorker);
			this.tunnelLoveWorker.add(proximity);
		}
		
		private function handleNearTunnelLoveWorker(entity:Entity):void
		{
			//SceneUtil.lockInput(this);
			//CharUtils.moveToTarget(player, focusTester.get(Spatial).x - 100, focusTester.get(Spatial).y, false, reachedFocusTester);
			CharUtils.setAnim(tunnelLoveWorker, Grief);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, sayHelpLine, true));
		}
		
		private function sayHelpLine():void {
			Dialog(tunnelLoveWorker.get(Dialog)).sayById("giveHand");
		}

		private function setBall(entity:Entity):void {
			CharUtils.setDirection(player, true);
			var itemGroup:ItemGroup = super.getGroupById( "itemGroup" ) as ItemGroup;
			itemGroup.takeItem( _events.SUPER_BOUNCY_BALL, "strengthTarget" );

			shellApi.removeItem( _events.SUPER_BOUNCY_BALL );
			var te:TimedEvent = new TimedEvent(0.5, 1, setupBall, true);
			SceneUtil.addTimedEvent(this, te);
			//var showItem:ShowItem = super.getGroupById( "showItem" ) as ShowItem;
			//showItem.transitionComplete.addOnce( setupBall );
		}
		
		private function setupBall():void {
			this.shellApi.completeEvent( this._events.USED_BALL);
			strengthTarget2.get(Display).alpha = 1;
			strengthTarget.get(Display).alpha = 0;
			trace(strengthTarget.getAll());
			strengthTarget.remove(ToolTip);
			currStrengthTarget = strengthTarget2;
			SceneUtil.lockInput(this, false);
		}

		private function workerDialogStart( dialogData:DialogData ):void {

			if ( dialogData.id == "greaseGears" ) {
				SceneUtil.lockInput( this );
			} //

		} //

		private function checkDialogStart(dialogData:DialogData):void
		{
			if(dialogData.id == "letsSee" && dialogData.entityID == "strengthWorker"){
				SceneUtil.lockInput(this);
			}
			if(dialogData.id == "annoyedAtTeens" && dialogData.entityID == "tunnelLoveWorker"){
				SceneUtil.lockInput(this);
			}
		}
		
		private function hammerSwing():void {
			player.get(Timeline).removeLabelHandler(hammerSwing);
			currStrengthTarget.get(Timeline).gotoAndPlay(1);
			super.shellApi.triggerEvent("hammerSound");
			if(currStrengthTarget == strengthTarget2){
				fist.get(Timeline).gotoAndPlay("hitHard");
				var te:TimedEvent = new TimedEvent(1, 1, suchStrength, true);
				SceneUtil.addTimedEvent(this, te);
			}else{
				fist.get(Timeline).gotoAndPlay(1);
				var te2:TimedEvent = new TimedEvent(1, 1, laugh, true);
				SceneUtil.addTimedEvent(this, te2);
			}
		}
		
		private function suchStrength():void {
			var skin:Skin = player.get(Skin) as Skin;
			skin.revertAll();
			SkinUtils.setSkinPart( strengthWorker, SkinUtils.ITEM, "mc_hammer", false );
			Dialog(strengthWorker.get(Dialog)).sayById("wonStrength");
			//give hammer
		}
		
		private function laugh():void {
			var skin:Skin = player.get(Skin) as Skin;
			skin.revertAll();
			SkinUtils.setSkinPart( strengthWorker, SkinUtils.ITEM, "mc_hammer", false );
			Dialog(strengthWorker.get(Dialog)).sayById("cantWinStrength");
			SceneUtil.lockInput(this, false);
			CharUtils.setAnim(strengthWorker, Laugh);
			if(!triedHammer){
				triedHammer = true;
				strengthTargetInteraction = strengthTarget.get(Interaction);
				strengthTargetInteraction.downNative.add( Command.create( onStrengthTargetDown ));
				strengthTarget.add(strengthTargetToolTip);
			}
		}
		
		private function onStrengthTargetDown(event:Event):void {
			if ( !this.shellApi.checkEvent( this._events.USED_BALL ) ) {
				Dialog(player.get(Dialog)).sayById("clickShockAbsorber");
			}
		}
		
		private function setupFlies():void {
			var fliesEmitter:SwarmingFlies = new SwarmingFlies();
			_fliesEntity = EmitterCreator.create(this, super._hitContainer, fliesEmitter, 0, 0);
			fliesEmitter.init(new Point(590, 1570), 8);
			
			//positional flies sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "insect_flies_02_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			//entity.add(new Display(super._hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial(590, 1612));
			entity.add(new AudioRange(500, 0, 0.3, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
		}
		
		private function setupAnimations():void {
			
			var leverClip:MovieClip = _hitContainer["lever"];
			lever = new Entity();
			lever = TimelineUtils.convertClip( leverClip, this, lever );
			super.addEntity(lever);
			lever.get(Timeline).gotoAndStop(1);
			
			var gearsClip:MovieClip = _hitContainer["gears"];
			gears = new Entity();
			gears = TimelineUtils.convertClip( gearsClip, this, gears );
			gears.add(new Spatial(gearsClip.x, gearsClip.y));
			gears.add(new Display(gearsClip));
			super.addEntity(gears);
			gears.get(Timeline).gotoAndPlay("runNormal");
			
			var strengthTarget2Clip:MovieClip = _hitContainer["strengthTarget2"];
			strengthTarget2 = new Entity();
			strengthTarget2 = TimelineUtils.convertClip( strengthTarget2Clip, this, strengthTarget2 );
			
			strengthTarget2.add(new Display(strengthTarget2Clip));
			strengthTarget2.add(new Spatial(strengthTarget2Clip.x, strengthTarget2Clip.y));
			super.addEntity(strengthTarget2);
			strengthTarget2.get(Timeline).gotoAndStop(0);
			strengthTarget2.get(Display).alpha = 0;
			
			strengthTarget = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["strengthTarget"]), this);
			strengthTarget.get(Timeline).gotoAndStop(0);
			strengthTargetToolTip = strengthTarget.get(ToolTip);
			strengthTarget.remove(ToolTip);

			currStrengthTarget = strengthTarget;
			
			var fistClip:MovieClip = _hitContainer["fist"];
			fist = new Entity();
			fist = TimelineUtils.convertClip( fistClip, this, fist );
			fist.get(Timeline).handleLabel("ding", playDing, false);
			
			super.addEntity(fist);
			fist.get(Timeline).gotoAndStop(0);
			
			//horses
			for (var i:uint=1;i<4;i++){
				var horseClip:MovieClip = _hitContainer["horse"+i];
				var horse:Entity = new Entity();
				horse = TimelineUtils.convertClip( horseClip, this, horse );
				horse.add(new Spatial(horseClip.x, horseClip.y));
				horse.add(new Display(horseClip));
				horse.add(new Tween());
				horse.add(new CarouselHorse());
				if (i==1){
					horse.get(Timeline).gotoAndPlay(1);
				}else if (i==2){
					horse.get(Timeline).gotoAndPlay(33);
				}else if (i==3){
					horse.get(Timeline).gotoAndPlay(66);
				}
				super.addEntity(horse);
				
			}
			
			//Carousel Music
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.MUSIC_PATH + "carousel_dusk.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			//entity.add(new Display(super._hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial(3720, 1550));
			entity.add(new AudioRange(1000, 0, .8, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
		}
		
		private function playDing():void {
			super.shellApi.triggerEvent("dingSound");
		}

		/**
		 * gurrghk
		 */
		private function putTeensOnWheel():void {

			var plat:Entity = this.ferrisGroup.getPlatform( 0 );
			var sp:Spatial = plat.get( Spatial ) as Spatial;

			/*var charGroup:CharacterGroup = super.getGroupById( "characterGroup" ) as CharacterGroup;
			charGroup.addFSM( this.loverBoy );
			charGroup.addFSM( this.loverGirl );*/

			var pSpatial:Spatial = this.loverGirl.get( Spatial  ) as Spatial;
			pSpatial.x = sp.x - 16;
			pSpatial.y = sp.y - pSpatial.height/2;

			pSpatial = this.loverBoy.get( Spatial ) as Spatial;
			pSpatial.x = sp.x + 16;
			pSpatial.y = sp.y - pSpatial.height/2;

			this.loverBoy.remove( MotionTarget );
			this.loverGirl.remove( MotionTarget );

			var stick:StickToEntity = new StickToEntity( plat, -16, -pSpatial.height/2 );
			this.loverGirl.add( stick, StickToEntity );

			stick = new StickToEntity( plat, 16, -pSpatial.height/2 );
			this.loverBoy.add( stick, StickToEntity );

			//SimpleUtils.setPosition( this.loverGirl, sp.x - 8, sp.y );
			//SimpleUtils.setPosition( this.loverBoy, sp.x + 8, sp.y );

			SimpleUtils.disableSleep( this.loverBoy );
			SimpleUtils.disableSleep( this.loverGirl );

		} //

		private function showStuckKids():void {

			var acts:ActionChain = new ActionChain( this );
			acts.lockInput = true;

			acts.addAction( new PanAction( this.loverBoy, 0.15 ) );

			var a:AnimationAction = new AnimationAction( this.loverGirl, Grief );
			a.noWait = true;

			acts.addAction( a );
			acts.addAction( new AnimationAction( this.loverBoy, Grief ) );
			acts.addAction( new PanAction( this.player, 0.15 ) );

			acts.execute();

		} //

		private function initFerrisWheel():void {

			this.addSystem( new ActionExecutionSystem(), SystemPriorities.update );

			var grp:FerrisWheelGroup = this.ferrisGroup = new FerrisWheelGroup();
			super.addChildGroup( grp );

			var center:MovieClip = super._hitContainer[ "ferrisAxle" ];

			grp.beginCreate( super._hitContainer as MovieClip, center, 10 );
			grp.addArms( "arm" );
			grp.addSwings( "seat", true, "ferrisPlat" );

			grp.start();

		} //

	}
}
package game.scenes.poptropolis.weightLift{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.entity.character.CharacterMovement;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Wave;
	import game.data.animation.entity.character.WeightLifting;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.scenes.poptropolis.weightLift.components.Target;
	import game.scenes.poptropolis.weightLift.components.Weight;
	import game.scenes.poptropolis.weightLift.particles.StarBlast;
	import game.scenes.poptropolis.weightLift.systems.TargetSystem;
	import game.scenes.poptropolis.weightLift.systems.WeightSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	
	public class WeightLift extends PoptropolisScene
	{
		private var db:MovieClip;
		public var sb:MovieClip;
		private var dumbbell:Entity;
		private var panTarget:Entity;
		private var hud:Entity;
		private var target:Entity;
		private var red:Entity;
		private var green:Entity;
		private var targetButton:Entity;
		private var backgroundButton:Entity;
		private var go:Entity;
		private var congrats:Entity;
		private var more:Entity;
		private var stand:Entity;
		private var scoreboard:Entity;
		private var hand:DisplayObject;
		
		private var playerTimeline:Timeline;
		private var playerTargetFrame:Number = 27;
		public var counterText:TextField;
		private var dumbbellStartY:Number = 0;
		private var handStartY:Number;
		private var globalPoint:Point;
		private var localPoint:Point;
		
		private var gameState:String = "practice2";
		private var currLevel:Number = 1;
		private var dumbbellTargetY:Number = 0;
		private var dummbellStartY:Number = 0;
		private var score:Number = 0;
		
		public var _interaction:Interaction;
		
		private var starEmitter:StarBlast;
		
		private var _hud:WeightLiftHud;
		
		public function WeightLift()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/weightLift/";
			
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
			
			super._hitContainer["hud"]["arch"].mouseEnabled = false;
			super._hitContainer["hud"].mouseChildren = true;
			hand = CharUtils.getPart(player, "hand1").get(Display).displayObject;
			sb = super._hitContainer["scoreboard"];
			
			//apply tribe look
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) ); // apply tribal jersey to look
			SkinUtils.applyLook( super.player, playerLook, false ); 
			
			// TODO :: Really shouldn't be using the player, but a Dummy npc instead. - Bard
			CharUtils.removeCollisions(player);
			player.remove(Motion);
			player.remove( CharacterMovement );
			player.remove( FSMControl );
			player.remove( FSMMaster );
			CharUtils.setAnim(player, Stand, false);
			
			counterText = _hitContainer["hud"]["counterText"];
			counterText.mouseEnabled = false;
			
			CharUtils.lockControls( super.player );
			player.get(Spatial).scaleX *= -1;
			player.get(Spatial).y = 1460;
			player.add(new Tween());
			
			_hud = super.addChildGroup(new WeightLiftHud(super.overlayContainer)) as WeightLiftHud;
			_hud.exitClicked.add(onExitPracticeClicked)
			
			setupPanTarget();
			setupHud();
			setupTarget();
			setupDumbell();
			setupMessages();
			setupStand();
			
			var _startTimer:Timer = new Timer(1000,1.5);
			_startTimer.addEventListener(TimerEvent.TIMER_COMPLETE, instructionsIn);
			_startTimer.start();
		}
		
		private function instructionsIn(event:TimerEvent):void {
			openInstructionsPopup();
		}
		
		private function onExitPracticeClicked (): void {
			super.shellApi.loadScene(WeightLift);
		}
		
		override protected function onStartClicked (): void {
			setPracticeMode(false)
			startMatch();
		}
		
		override protected function onPracticeClicked (): void {
			setPracticeMode(true)
			_hud.setupExitBtn();
			_hud.exitClicked.add(onExitPracticeClicked);
			startMatch();
		}
		
		private function setPracticeMode (b:Boolean):void {
			_practice = b
		}
		
		private function startMatch():void {
			player.add(new Motion());
			setup(); 
			starEmitter = new StarBlast();
			starEmitter.init();
			EmitterCreator.create( this, super._hitContainer, starEmitter, 870, 1480, null, "", null, false );
		}
		
		private function setup():void {
			Target(target.get(Target)).countSound = 11;
			var speedVariable:Number = Target(target.get(Target)).speedVariable;
			if(gameState == "practice"){
				Target(target.get(Target)).speed = 0.015;
				Target(target.get(Target)).speedVariable = 90;
				Target(target.get(Target)).speedVariable2 = randRange(speedVariable-(speedVariable/2), speedVariable+(speedVariable/2));
				Target(target.get(Target)).counter = 30 * 99;
			}else{
				trace(currLevel+"CURRLEVEL");
				switch(currLevel){
					
					case 1:
						dumbbellTargetY = 1472;
						dumbbellStartY = dumbbellTargetY;
						dumbbell.get(Spatial).y = dumbbellTargetY;
						Target(target.get(Target)).speed = 0.0075;
						Target(target.get(Target)).speedVariable = 90;
						Target(target.get(Target)).speedVariable2 = randRange(speedVariable-(speedVariable/2), speedVariable+(speedVariable/2));
						Target(target.get(Target)).counter = 60 * 99;
						goIn();
						break;
					case 2:
						dumbbell.get(Tween).to(dumbbell.get(Display), 1, { alpha:0, ease:Sine.easeInOut, onComplete:dumbbellIn });
						player.get(Tween).to(player.get(Spatial), 1, { y:1454, ease:Sine.easeInOut });
						stand.get(Tween).to(stand.get(Spatial), 1, { y:3, ease:Sine.easeInOut });
						dumbbellTargetY = 1466;
						Target(target.get(Target)).speed = 0.01;
						Target(target.get(Target)).speedVariable = 90;
						Target(target.get(Target)).speedVariable2 = randRange(speedVariable-(speedVariable/2), speedVariable+(speedVariable/2));
						Target(target.get(Target)).counter = 60 * 80;
						break;
					case 3:
						dumbbell.get(Tween).to(dumbbell.get(Display), 1, { alpha:0, ease:Sine.easeInOut, onComplete:dumbbellIn });
						player.get(Tween).to(player.get(Spatial), 1, { y:1448, ease:Sine.easeInOut });
						stand.get(Tween).to(stand.get(Spatial), 1, { y:-5, ease:Sine.easeInOut });
						dumbbellTargetY = 1459;
						Target(target.get(Target)).speed = 0.0125;
						Target(target.get(Target)).speedVariable = 90;
						Target(target.get(Target)).speedVariable2 = randRange(speedVariable-(speedVariable/2), speedVariable+(speedVariable/2));
						Target(target.get(Target)).counter = 60 * 60;
						break;
					case 4:
						dumbbell.get(Tween).to(dumbbell.get(Display), 1, { alpha:0, ease:Sine.easeInOut, onComplete:dumbbellIn });
						player.get(Tween).to(player.get(Spatial), 1, { y:1442, ease:Sine.easeInOut });
						stand.get(Tween).to(stand.get(Spatial), 1, { y:-11, ease:Sine.easeInOut });
						dumbbellTargetY = 1453;
						Target(target.get(Target)).speed = 0.015;
						Target(target.get(Target)).speedVariable = 90;
						Target(target.get(Target)).speedVariable2 = randRange(speedVariable-(speedVariable/2), speedVariable+(speedVariable/2));
						Target(target.get(Target)).counter = 60 * 50;
						break;
					case 5:
						dumbbell.get(Tween).to(dumbbell.get(Display), 1, { alpha:0, ease:Sine.easeInOut, onComplete:dumbbellIn });
						player.get(Tween).to(player.get(Spatial), 1, { y:1436, ease:Sine.easeInOut });
						stand.get(Tween).to(stand.get(Spatial), 1, { y:-17, ease:Sine.easeInOut });
						dumbbellTargetY = 1447;
						Target(target.get(Target)).speed = 0.0175;
						Target(target.get(Target)).speedVariable = 90;
						Target(target.get(Target)).speedVariable2 = randRange(speedVariable-(speedVariable/2), speedVariable+(speedVariable/2));
						Target(target.get(Target)).counter = 60 * 40;
						break;
				}
			}
			counterText.text = ""+Math.ceil(Target(target.get(Target)).counter / 60);
		}
		
		private function dumbbellIn():void {
			dumbbellStartY = dumbbellTargetY;
			dumbbell.get(Spatial).y = dumbbellTargetY;
			db.dumbbell.gotoAndStop(currLevel);
			dumbbell.get(Tween).to(dumbbell.get(Display), 1, { alpha:1, ease:Sine.easeInOut, onComplete:goIn });
		}
		
		private function goIn():void {
			go.get(Tween).to(go.get(Display), 0.5, { alpha:1, ease:Sine.easeInOut, onComplete:goOut });
		}
		
		private function goOut():void {
			go.get(Tween).to(go.get(Display), 0.5, { alpha:0, delay: 1, ease:Sine.easeInOut, onComplete:startRound });
		}
		
		private function startRound():void {
			CharUtils.setAnim(player, WeightLifting, false);
			playerTimeline = player.get(Timeline) as Timeline;
			
			player.get(Timeline).handleLabel("lift", labelLift, false);
			playerTimeline.gotoAndPlay(1);
			
			var tween:Tween = hud.get(Tween);
			tween.to(hud.get(Display), 1, { alpha:1, ease:Sine.easeInOut });
			_interaction.downNative.add( Command.create( onTargetDown ));
			Target(target.get(Target)).lifting = true;
			
			super.addSystem(new TargetSystem());
			super.addSystem(new WeightSystem());
		}
		
		private function labelLift():void {
			playerTimeline.gotoAndStop("lift");
			Weight(dumbbell.get(Weight)).lifting = true;
		}
		
		private function labelDrop():void {
			starEmitter.start();
			playSound("success");
			
			dumbbell.get(Tween).to(dumbbell.get(Spatial), 0.5, { y:dumbbellStartY, ease:Bounce.easeOut });
			hud.get(Tween).to(hud.get(Display), 0.5, { alpha:0, ease:Sine.easeInOut });
			
			sb["score"].text = "Score = "+((currLevel-1)*100);
			Target(target.get(Target)).currWeight = (currLevel-1)*100;
			Target(target.get(Target)).finalScore = (currLevel-1)*100 + Math.ceil(Target(target.get(Target)).counter / 60);
			
			congrats.get(Tween).to(congrats.get(Display), 0.5, { alpha:1, ease:Sine.easeInOut });
			scoreboard.get(Tween).to(scoreboard.get(Display), 0.5, { alpha:1, ease:Sine.easeInOut, onComplete:showTimeBonus });
			
			var te:TimedEvent = new TimedEvent(1, 1, startWave, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function startWave():void
		{
			CharUtils.setAnim(player, Wave, false);
			var te:TimedEvent = new TimedEvent(1, 1, startStand, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function startStand():void {
			CharUtils.setAnim(player, Stand, false);
		}
		
		private function showTimeBonus():void {
			Target(target.get(Target)).showBonus = true;
		}
		
		public function hideCongrats():void {
			var moreAlpha:Number = 0;
			if(currLevel < 6){
				moreAlpha = 1;
			}else{
				moreAlpha = 0;
			}
			scoreboard.get(Tween).to(scoreboard.get(Display), 0.5, { alpha:0, delay:3, ease:Sine.easeInOut});
			more.get(Tween).to(more.get(Display), 0.5, { alpha:moreAlpha, delay:3.5, ease:Sine.easeInOut, onComplete:hideCongrats2});
		}
		
		private function hideCongrats2():void {
			if(_practice){
				super.shellApi.loadScene(WeightLift);
			}else{
				if(currLevel < 6){
					congrats.get(Tween).to(congrats.get(Display), 0.5, { alpha:0, delay:3, ease:Sine.easeInOut });	
					more.get(Tween).to(more.get(Display), 0.5, { alpha:0, delay:3, ease:Sine.easeInOut, onComplete:setup});
				}else{
					congrats.get(Tween).to(congrats.get(Display), 0.5, { alpha:0, ease:Sine.easeInOut, onComplete:gameOver });	
					more.get(Tween).to(more.get(Display), 0.5, { alpha:0, ease:Sine.easeInOut});
				}
			}
		}
		
		public function gameOver():void {
			if(_practice){
				super.shellApi.loadScene(WeightLift);
			}else{
				trace("Game Over");
				Weight(dumbbell.get(Weight)).lifting = false;
				Target(target.get(Target)).lifting = false;
				_interaction.downNative.removeAll();
				hud.get(Display).alpha = 0;
				
				var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
				pop.setup();
			}
		}
		
		private function dataLoaded( pop:Poptropolis ):void {
			pop.reportScore( Matches.POWER_LIFTING, Target(target.get(Target)).finalScore );
		}
		
		private function handleRedEnd():void {
			red.get(Timeline).gotoAndStop(1);
			red.get(Display).alpha = 0;
			if(green.get(Display).alpha == 0){
				target.get(Display).displayObject["swirl"].alpha = 1;
			}
		}
		
		private function handleGreenEnd():void {
			green.get(Timeline).gotoAndStop(1);
			green.get(Display).alpha = 0;
			if(red.get(Display).alpha == 0){
				target.get(Display).displayObject["swirl"].alpha = 1;
			}
		}
		
		public function movePlayer():void {
			if(playerTimeline.currentIndex < playerTargetFrame){
				playerTimeline.gotoAndStop(playerTimeline.currentIndex+1);
				moveDumbbell();
			}
			if(playerTimeline.currentIndex > playerTargetFrame){
				playerTimeline.gotoAndStop(playerTimeline.currentIndex-1);
				moveDumbbell();
			}
		}
		
		public function dropFromWait():void {
			if(playerTargetFrame > 27){
				onBackgroundDown();
			}
		}
		
		private function onTargetDown(event:Event):void
		{
			green.get(Display).alpha = 1;
			red.get(Display).alpha = 0;
			green.get(Timeline).gotoAndPlay("start");
			target.get(Display).displayObject["swirl"].alpha = 0;
			
			if(playerTargetFrame < 89){
				playerTargetFrame += 4;
			}else{
				trace("WIN");
				currLevel++;
				playerTargetFrame = 27;
				_interaction.downNative.removeAll();
				playerTimeline.gotoAndPlay("highPoint");
				player.get(Timeline).handleLabel("drop", labelDrop, false);
				Weight(dumbbell.get(Weight)).lifting = false;
				Target(target.get(Target)).lifting = false;
			}
			Target(target.get(Target)).waitForDrop = 0;
			playSound("lift");
		}
		
		private function moveDumbbell():void
		{
			globalPoint = hand.localToGlobal(new Point(0,0));
			localPoint = dumbbell.get(Display).displayObject.parent.globalToLocal(globalPoint);
			dumbbell.get(Spatial).y = localPoint.y;
		}
		
		private function onBackgroundDown(event:Event=null):void
		{	
			playSound("drop");
			red.get(Timeline).gotoAndPlay("start");
			red.get(Display).alpha = 1;
			green.get(Display).alpha = 0;
			target.get(Display).displayObject["swirl"].alpha = 0;
			
			if(playerTargetFrame > 27){
				playerTargetFrame -= 4;
				if(playerTargetFrame < 27){
					playerTargetFrame = 27;
				}
			}	
			Target(target.get(Target)).waitForDrop = 0;
		}
		
		private function setupStand():void
		{
			var clip:MovieClip = super._hitContainer["stand"]["rock"];
			stand = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			stand.add(spatial);
			stand.add(new Display(clip));
			stand.add(new Tween());
			
			super.addEntity(stand);
		}
		
		private function setupHud():void
		{
			var clip:MovieClip = _hitContainer["hud"];
			hud = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			hud.add(spatial);
			hud.add(new Display(clip));
			hud.add(new Tween());
			
			hud.get(Display).alpha = 0;
			
			super.addEntity(hud);
			
		}
		
		private function setupMessages():void
		{
			//GO
			var goClip:MovieClip = _hitContainer["go"];
			go = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = goClip.x;
			spatial.y = goClip.y;
			
			go.add(spatial);
			go.add(new Display(goClip));
			go.add(new Tween());
			
			go.get(Display).alpha = 0;
			
			super.addEntity(go);
			
			//CONGRATS
			var congratsClip:MovieClip = _hitContainer["congrats"];
			congrats = new Entity();
			var congratsSpatial:Spatial = new Spatial();
			congratsSpatial.x = congratsClip.x;
			congratsSpatial.y = congratsClip.y;
			
			congrats.add(congratsSpatial);
			congrats.add(new Display(congratsClip));
			congrats.add(new Tween());
			
			congrats.get(Display).alpha = 0;
			
			super.addEntity(congrats);
			
			//SCOREBOARD
			var scoreboardClip:MovieClip = _hitContainer["scoreboard"];
			scoreboard = new Entity();
			var scoreboardSpatial:Spatial = new Spatial();
			scoreboardSpatial.x = scoreboardClip.x;
			scoreboardSpatial.y = scoreboardClip.y;
			
			scoreboard.add(scoreboardSpatial);
			scoreboard.add(new Display(scoreboardClip));
			scoreboard.add(new Tween());
			
			scoreboard.get(Display).alpha = 0;
			
			super.addEntity(scoreboard);
			
			//MORE
			var moreClip:MovieClip = _hitContainer["more"];
			more = new Entity();
			var moreSpatial:Spatial = new Spatial();
			moreSpatial.x = moreClip.x;
			moreSpatial.y = moreClip.y;
			
			more.add(moreSpatial);
			more.add(new Display(moreClip));
			more.add(new Tween());
			
			more.get(Display).alpha = 0;
			super.addEntity(more);
		}
		
		private function setupTarget():void
		{
			var vClip:MovieClip = _hitContainer["hud"]["target"];
			target = new Entity();
			target = TimelineUtils.convertClip( vClip, this, target );
			
			var vSpatial:Spatial = new Spatial();
			vSpatial.x = vClip.x;
			vSpatial.y = vClip.y;
			
			target.add(vSpatial);
			target.add(new Display(vClip)); 
			target.add( new Target());
	
			super.addEntity(target);
			target.get(Timeline).gotoAndStop(0);
			
			//red indicator
			var r:MovieClip = _hitContainer["hud"]["target"]["redCircle"];
			red = new Entity();
			red = TimelineUtils.convertClip( r, this, red );
			var spatial:Spatial = new Spatial();
			spatial.x = r.x;
			spatial.y = r.y;
			
			red.add(spatial);
			red.add(new Display(r));
			red.get(Display).alpha = 0;
			
			super.addEntity(red);
			red.get(Timeline).handleLabel("end", handleRedEnd, false);
			red.get(Timeline).gotoAndStop(1);
			
			//green indicator
			var g:MovieClip = _hitContainer["hud"]["target"]["greenCircle"];
			green = new Entity();
			green = TimelineUtils.convertClip( g, this, green );
			var spatial2:Spatial = new Spatial();
			spatial2.x = g.x;
			spatial2.y = g.y;
			
			green.add(spatial2);
			green.add(new Display(g));
			green.get(Display).alpha = 0;
			
			super.addEntity(green);
			green.get(Timeline).handleLabel("end", handleGreenEnd, false);
			green.get(Timeline).gotoAndStop(1);
			
			//target button
			targetButton = ButtonCreator.createButtonEntity(MovieClip(vClip.getChildByName("swirl")), this);
			//super.addEntity(targetButton);
			targetButton.remove(Timeline);
			_interaction = targetButton.get(Interaction);
						
			//background button
			backgroundButton = ButtonCreator.createButtonEntity(_hitContainer["hud"]["gameGrad"], this);
			//super.addEntity(backgroundButton);
			backgroundButton.remove(Timeline);
			
			ToolTipCreator.addToEntity(backgroundButton, ToolTipType.TARGET);
			ToolTipCreator.addToEntity(targetButton, ToolTipType.CLICK);
			
			var _interaction2:Interaction; 
			_interaction2 = backgroundButton.get(Interaction);
			_interaction2.downNative.add( Command.create( onBackgroundDown ));
		}
		
		private function setupPanTarget():void
		{
			var clip:MovieClip = _hitContainer["panTarget"];
			panTarget = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			panTarget.add(spatial);
			panTarget.add(new Display(clip));
			panTarget.get(Display).alpha = 0;
			
			super.addEntity(panTarget);	
			panTarget.get(Spatial).y -= 100;
			super.shellApi.camera.target = panTarget.get(Spatial);
		}
		
		private function setupDumbell():void
		{
			db = super.getAsset("dumbbell.swf", true) as MovieClip;
			db.y = 150;
			db.x = 0;
			super._hitContainer.addChild(db);
			db.dumbbell.gotoAndStop(1);
			
			dumbbell = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = 870;
			spatial.y = 1470;
			
			dumbbell.add(spatial);
			dumbbell.add(new Display(db));
			dumbbell.get(Display).alpha = 1;
			//dumbbellStartY = dumbbell.get(Spatial).y;
			dumbbell.add(new Tween());
			dumbbell.add( new Weight());
			
			super.addEntity(dumbbell);
			
		}
		
		public function playSound(sound:String):void {
			switch(sound){
				case "lift":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "lift_up_01.mp3");
					break;
				case "drop":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "gears_12.mp3");
					break;
				case "success":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "achievement_02.mp3");
					break;
				case "countdown":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "countdown_02.mp3");
					break;
			}
		}
		
		private function randRange(min:Number, max:Number):Number {
			var randomNum:Number = Math.floor(Math.random()*(max-min+1))+min;
			return randomNum;
		}
	}
}
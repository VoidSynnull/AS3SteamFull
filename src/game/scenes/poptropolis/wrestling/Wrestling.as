package game.scenes.poptropolis.wrestling{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.entity.collider.HazardCollider;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.components.ui.ToolTip;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.poptropolis.WrestleAnim;
	import game.data.character.LookData;
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.data.ui.ToolTipType;
	import game.scenes.poptropolis.coliseum.Coliseum;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.scenes.poptropolis.wrestling.components.AttackBtn;
	import game.scenes.poptropolis.wrestling.systems.WrestlingSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	import game.util.Utils;
	
	public class Wrestling extends PoptropolisScene
	{
		private var panTarget:Entity;
		private var hud:Entity;
		private var attackBtns:Entity;
		private var btn1:Entity;
		private var btn2:Entity;
		private var btn3:Entity;
		private var btn1Interaction:Interaction;
		private var btn2Interaction:Interaction;
		private var btn3Interaction:Interaction;
		private var l1:Entity;
		private var l2:Entity;
		private var l3:Entity;
		private var l4:Entity;
		private var w1:Entity;
		private var w2:Entity;
		private var w3:Entity;
		private var w4:Entity;
		private var go:Entity;
		private var round:Entity;
		private var winner:Entity;
		private var opponent:Entity;
		private var buttonToolTip:ToolTip;
		
		private var _playerTarget:MovieClip;
		private var _opponentTarget:MovieClip;
		private var buttonArray:Array = [1, 2, 3];
		private var inputEntity:Entity;
		
		private var buttonsVisible:Boolean = false;
		private var wins:Number = 0;
		private var losses:Number = 0;
		private var currRound:int = 1;
		
		private var charging:Boolean = false;
		private var pushingRight:Boolean = false;
		private var pushingLeft:Boolean = false;
		private var pushingSpeed:Number = 0;
		private var opponentSpeed:Number = 0;
		
		private var hudLayer:Entity;
		private var hudContainer:DisplayObjectContainer;
		
		private var _hud:WrestlingHud;
		private var popEvents:PoptropolisEvents;
		
		public function Wrestling()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/wrestling/";
			
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

			popEvents = super.events as PoptropolisEvents;
			_playerTarget = _hitContainer["charTarget"];
			_opponentTarget = _hitContainer["char1Target"];
			opponent = super.getEntityById("char1");
			opponent.remove(Interaction);
			super.player.remove(Interaction);
						
			CharUtils.lockControls( super.player, true );
			CharUtils.setDirection(super.player, true);
			//apply tribe look
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) ); // apply tribal jersey to look
			SkinUtils.applyLook( super.player, playerLook, false ); 
			
			hudLayer = super.getEntityById("hudInterface");
			hudContainer = Display(hudLayer.get(Display)).displayObject;
			
			_hud = super.addChildGroup(new WrestlingHud(super.overlayContainer)) as WrestlingHud;
			_hud.exitClicked.add(onExitPracticeClicked)
			
			setupPanTarget();
			setupHud();
			setupBtns();
			setupIndicators();
			
			//ToolTipCreator.addToEntity(super.getEntityById("foreground"), ToolTipType.TARGET);
			
			super.addSystem(new WrestlingSystem());

			inputEntity = shellApi.inputEntity;
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.TARGET;
			
			SceneUtil.delay( this, 1, super.openInstructionsPopup);
		}
		
		private function onExitPracticeClicked (): void {
			super.shellApi.loadScene(Wrestling);
		}
		
		override protected function onStartClicked (): void {
			_practice = false;
			initGame();
		}
		
		override protected function onPracticeClicked (): void {
			_practice = true;
			_hud.setupExitBtn();
			_hud.exitClicked.add(onExitPracticeClicked);
			initGame();
		}
		
		private function initGame():void 
		{	
			CharUtils.moveToTarget(super.player, _playerTarget.x, _playerTarget.y, true, completeInitialWalk);
			CharUtils.moveToTarget(opponent, _opponentTarget.x, _opponentTarget.y);
		}
		
		private function completeInitialWalk(params:Object):void
		{
			CharUtils.lockControls( super.player );
			startRound();			
		}
		
		private function startRound():void
		{
			hud.get(Display).alpha = 1;
			if(_practice){
				round.get(Display).displayObject["roundTxt"].text = "Practice";
			}else{
				round.get(Display).displayObject["roundTxt"].text = "Round "+currRound;
			}
			round.get(Tween).to(round.get(Display), 0.5, { alpha:1, ease:Sine.easeInOut });
			go.get(Tween).to(go.get(Display), .1, { alpha:1, delay: 2, ease:Sine.easeInOut, onComplete:startRound2 });			
		}
		
		private function startRound2():void
		{
			CharUtils.setDirection(opponent, false );
			CharUtils.setDirection(player, true );
			player.get(Spatial).x = 440;
			opponent.get(Spatial).x = 470;
			CharUtils.setAnim(player, WrestleAnim);
			CharUtils.setAnim(opponent, WrestleAnim);
			round.get(Tween).to(round.get(Display), 0.5, { alpha:0, ease:Sine.easeInOut });
			go.get(Tween).to(go.get(Display), 1, { alpha:0, delay: 1, ease:Sine.easeInOut });	
			attackBtns.get(Display).alpha = 1;
			AttackBtn(attackBtns.get(AttackBtn)).wait = getWaitNum();
			AttackBtn(attackBtns.get(AttackBtn)).counter = 0;
			AttackBtn(attackBtns.get(AttackBtn)).spinning = true;
		}
		
		public function attackPicked():void {
			var te:TimedEvent = new TimedEvent(1, 1, showButtons, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function showButtons():void {
			arrayShuffle(buttonArray);
			attackBtns.get(Display).alpha = 0;
			
			this["btn"+buttonArray[0]].get(Display).displayObject.y = -63;
			this["btn"+buttonArray[1]].get(Display).displayObject.y = 49;
			this["btn"+buttonArray[2]].get(Display).displayObject.y = 160;
			
			btn1.get(Display).alpha = 1;
			btn2.get(Display).alpha = 1;
			btn3.get(Display).alpha = 1;
			
			btn1.add(buttonToolTip);
			btn2.add(buttonToolTip);
			btn3.add(buttonToolTip);		
		
			buttonsVisible = true;
			var te:TimedEvent = new TimedEvent(1, 1, timeOutButtons, true);
			SceneUtil.addTimedEvent(this, te);
			
		}
		
		private function timeOutButtons():void
		{
			if(buttonsVisible){
				buttonsVisible = false;
				btn1.remove(ToolTip);
				btn2.remove(ToolTip);
				btn3.remove(ToolTip);
				btn1.get(Display).alpha = 0;
				btn2.get(Display).alpha = 0;
				btn3.get(Display).alpha = 0;
				if(attackBtns.get(Timeline).currentIndex == 0){ //square
					loseRound(2);
				}else if(attackBtns.get(Timeline).currentIndex == 1){ //octagon
					loseRound(4);
				}else if(attackBtns.get(Timeline).currentIndex == 2){ //circle
					loseRound(6);
				}
			}
		}
		
		private function onBtnDown(event:Event):void
		{
			if(buttonsVisible){
				buttonsVisible = false;
				btn1.remove(ToolTip);
				btn2.remove(ToolTip);
				btn3.remove(ToolTip);
				switch(event.currentTarget.parent.name){
					case "btn1":
						if(attackBtns.get(Timeline).currentIndex == 0){ //square
							//trace("win square");
							
							var te:TimedEvent = new TimedEvent(1, 1, turnOffBtn1, true);
							SceneUtil.addTimedEvent(this, te);
							btn2.get(Display).alpha = 0;
							btn3.get(Display).alpha = 0;
							
							winRound(1);
						}else{
							//trace("lose square");
							
							btn1.get(Display).alpha = 0;
							btn2.get(Display).alpha = 0;
							btn3.get(Display).alpha = 0;

							loseRound(2);
						}
						break;
					case "btn2":
						if(attackBtns.get(Timeline).currentIndex == 1){ //octagon
							//trace("win octagon");
							
							btn1.get(Display).alpha = 0;
							var te1:TimedEvent = new TimedEvent(1, 1, turnOffBtn2, true);
							SceneUtil.addTimedEvent(this, te1);
							btn3.get(Display).alpha = 0;
							
							winRound(3);
						}else{
							//trace("lose octagon");
							btn1.get(Display).alpha = 0;
							btn2.get(Display).alpha = 0;
							btn3.get(Display).alpha = 0;
							
							loseRound(4);
						}
						break;
					case "btn3":
						if(attackBtns.get(Timeline).currentIndex == 2){ //circle
							//trace("win circle");
							
							btn1.get(Display).alpha = 0;
							btn2.get(Display).alpha = 0;
							var te2:TimedEvent = new TimedEvent(1, 1, turnOffBtn3, true);
							SceneUtil.addTimedEvent(this, te2);
							
							winRound(5);
						}else{
							//trace("lose circle");
							btn1.get(Display).alpha = 0;
							btn2.get(Display).alpha = 0;
							btn3.get(Display).alpha = 0;
							
							loseRound(6);
						}
						break;
				}
			}
		}
		
		private function turnOffBtn1():void {
			btn1.get(Display).alpha = 0;
		}
		private function turnOffBtn2():void {
			btn2.get(Display).alpha = 0;
		}
		private function turnOffBtn3():void {
			btn3.get(Display).alpha = 0;
		}
		
		private function winRound(moveNum:int):void
		{
			if(wins < 4){
				wins++;
			}
			currRound++;
			showRound(moveNum);
		}
		
		private function loseRound(moveNum:int):void
		{
			if(losses < 4){
				losses++;
			}
			currRound++;
			var currAttack:Number = 0;
			if(attackBtns.get(Timeline).currentIndex == 0){
				currAttack = 2;
			}else if(attackBtns.get(Timeline).currentIndex == 1){
				currAttack = 4;
			}else if(attackBtns.get(Timeline).currentIndex == 2){
				currAttack = 6;
			}
			showRound(currAttack);
		}
		
		private function showRound(moveNum:int):void
		{
			//highCounter();
			switch(moveNum){
				case 1:
					highCounter();
					playSound("squareWin");
					break;
				case 2:
					highFail();
					playSound("squareFail");
					break;
				case 3:
					mediumCounter();
					playSound("hex");
					break;
				case 4:
					mediumFail();
					playSound("hex");
					break;
				case 5:
					chargeCounter();
					playSound("circleWin");
					break;
				case 6:
					chargeFail();
					playSound("circleFail");
					break;
			}
			
		}
		
		private function highCounter():void { //hit and duck
			CharUtils.setAnim(opponent, game.data.animation.entity.character.PushHigh);
			
			var te1:TimedEvent = new TimedEvent(1.5, 1, duck, true);
			SceneUtil.addTimedEvent(this, te1);
			
			var te:TimedEvent = new TimedEvent(2, 1, highCounterFinish, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function duck():void {
			CharUtils.lockControls(player, true, true);
			CharUtils.setAnim(player, game.data.animation.entity.character.DuckDown);
		}
		
		private function highCounterFinish():void {
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Cry);
			CharUtils.setAnim(player, game.data.animation.entity.character.Proud);
			startWin("char");
			var te:TimedEvent = new TimedEvent(3, 1, nextRound, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function highFail():void { //hit and knock back
			CharUtils.setAnim(opponent, game.data.animation.entity.character.PushHigh);
			CharUtils.setAnim(player, game.data.animation.entity.character.PushMedium);
			opponent.get(Timeline).handleLabel("hitPoint", startKnockBack, true);
			
			var te:TimedEvent = new TimedEvent(4, 1, highFailFinish, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function startKnockBack():void {
			prepareKnockBack();
			var te1:TimedEvent = new TimedEvent(0.2, 1, knockBack, true);
			SceneUtil.addTimedEvent(this, te1);
		}
		
		private function prepareKnockBack():void {
			player.get(MotionTarget).targetX = player.get(Spatial).x;
			player.get(MotionTarget).targetY = player.get(Spatial).y - 400;
			
			CharUtils.setState(player, CharacterState.JUMP);
		}
		
		private function knockBack():void {
			CharUtils.lockControls(player, true, true);
			var collider:HazardCollider = player.get(HazardCollider);
			collider.velocity = new Point(-1150, -900);
			CharUtils.setState(player, CharacterState.HURT);
		}
		
		private function highFailFinish():void {
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Proud);
			CharUtils.setAnim(player, game.data.animation.entity.character.Cry);
			startWin("char1");
			var te:TimedEvent = new TimedEvent(2, 1, nextRound, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function mediumCounter():void { //push and push to right
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Push);
			CharUtils.setAnim(player, game.data.animation.entity.character.Push);
			
			var te:TimedEvent = new TimedEvent(1, 1, setPushingRight, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function setPushingRight():void {
			pushingSpeed = 0;
			pushingRight = true;
		}
		
		private function mediumCounterFinish():void	{
			pushingRight = false;
			pushingLeft = false;
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Cry);
			CharUtils.setAnim(player, game.data.animation.entity.character.Proud);
			startWin("char");
			var te:TimedEvent = new TimedEvent(2, 1, nextRound, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function mediumFail():void { //push and push to left
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Push);
			CharUtils.setAnim(player, game.data.animation.entity.character.Push);
			var te:TimedEvent = new TimedEvent(1, 1, setPushingLeft, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function setPushingLeft():void {
			pushingSpeed = 0;
			pushingLeft = true;
		}
		
		private function mediumFailFinish():void {
			pushingRight = false;
			pushingLeft = false;
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Proud);
			CharUtils.setAnim(player, game.data.animation.entity.character.Cry);
			startWin("char1");
			var te:TimedEvent = new TimedEvent(2, 1, nextRound, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function chargeCounter():void { //charge and jump
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Charge);
			opponent.get(Timeline).handleLabel("run", labelRunCounter, true);
			
			var te:TimedEvent = new TimedEvent(4, 1, chargeCounterFinish, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function chargeCounterFinish():void	{
			charging = false;
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Cry);
			CharUtils.setAnim(player, game.data.animation.entity.character.Proud);
			startWin("char");
			var te:TimedEvent = new TimedEvent(2, 1, nextRound, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function chargeFail():void { //charge and knock back
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Charge);
			CharUtils.setAnim(player, game.data.animation.entity.character.PushMedium);
			opponent.get(Timeline).handleLabel("run", labelRunFail, true);
			
			var te:TimedEvent = new TimedEvent(4, 1, chargeFailFinish, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function chargeFailFinish():void {
			charging = false;
			CharUtils.setAnim(opponent, game.data.animation.entity.character.Proud);
			CharUtils.setAnim(player, game.data.animation.entity.character.Cry);
			startWin("char1");
			var te:TimedEvent = new TimedEvent(2, 1, nextRound, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function labelRunCounter():void {
			charging = true;
			CharUtils.lockControls(player, true, true);
			player.get(MotionTarget).targetX = player.get(Spatial).x;
			player.get(MotionTarget).targetY = player.get(Spatial).y - 400;
			CharUtils.setState(player, CharacterState.JUMP);
		}
		
		private function labelRunFail():void {
			charging = true;
			startKnockBack();
		}
		
		public function moveOpponent():void {
			if(charging){
				if(opponent.get(Timeline).currentIndex > 38){
					if(opponent.get(Timeline).currentIndex < 66){
						if(opponentSpeed < 4){
							opponentSpeed+=0.25;
						}else{
							if(opponent.get(Spatial).x < 270){
								if(opponent.get(Timeline).currentIndex < 66){
									opponent.get(Timeline).gotoAndPlay(66);
								}
							}
						}
					}else{
						if(opponentSpeed > 0){
							opponentSpeed-=0.15;
						}else{
							charging = false;
						}
					}
				}
					opponent.get(Spatial).x -= opponentSpeed;
			}else if(pushingRight){
				if(pushingSpeed < 2){
					pushingSpeed += .1;
				}
				player.get(Spatial).x += pushingSpeed;
				opponent.get(Spatial).x = player.get(Spatial).x + 30;
				if(opponent.get(Spatial).x > 700){
					pushingRight = false;
					mediumCounterFinish();
				}
			}else if(pushingLeft){
				if(pushingSpeed < 2){
					pushingSpeed += .1;
				}
				player.get(Spatial).x -= pushingSpeed;
				opponent.get(Spatial).x = player.get(Spatial).x + 30;
				if(player.get(Spatial).x < 230){
					pushingLeft = false;
					mediumFailFinish();
				}
			}
		}
		
		private function nextRound(event:TimerEvent=null):void {
			charging = false;
			pushingRight = false;
			pushingLeft = false;
			if(_practice){
				super.shellApi.loadScene(Wrestling);
			}else{
				if(wins == 4){
					gameOverWin();
				}else if(losses == 4){
					gameOverLose();
				}else{
					if(Math.abs(_playerTarget.x - player.get(Spatial).x) > 20){
						CharUtils.moveToTarget(player, _playerTarget.x, _playerTarget.y-10, true, setPlayerDirection);
					}
					CharUtils.moveToTarget(opponent, _opponentTarget.x, _opponentTarget.y, true, nextRound2);
				}
			}
		}
		
		private function gameOverWin():void {
			//trace("Game Over Win");
			//var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
			super.shellApi.completeEvent(popEvents.WRESTLING_COMPLETED);
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, loadColiseum, true));
		}
		
		private function loadColiseum():void
		{
			super.shellApi.loadScene(Coliseum);
		}
		
		private function gameOverLose():void {
			//trace("Game Over Lose");
			//var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, loadWrestling, true));
		}
		
		private function loadWrestling():void
		{
			super.shellApi.loadScene(Wrestling);
		}
		
		private function dataLoaded( pop:Poptropolis ):void {
			pop.reportScore( Matches.WRESTLING, wins );
		}
		
		private function setPlayerDirection(params:Object):void {
			CharUtils.setDirection(player, true );
			player.get(Spatial).x = 440;
		}
		
		private function nextRound2(params:Object):void
		{
			startRound();
			CharUtils.setDirection(opponent, false );
			opponent.get(Spatial).x = 470;
		}
		
		private function startWin(win:String):void {
			if(win == "char"){
				winner.get(Spatial).x = -241;
				switch(wins){
					case 1:
						playSound("ping1");
						break;
					case 2:
						playSound("ping2");
						break;
					case 3:
						playSound("ping3");
						break;
					case 4:
						playSound("ping4");
						break;
				}
			}else{
				winner.get(Spatial).x = 238;
				switch(losses){
					case 1:
						playSound("ping1");
						break;
					case 2:
						playSound("ping2");
						break;
					case 3:
						playSound("ping3");
						break;
					case 4:
						playSound("ping4");
						break;
				}
			}
			if(wins > 0){
				this["w"+wins].get(Timeline).gotoAndStop(1);
			}
			if(losses > 0){
				this["l"+losses].get(Timeline).gotoAndStop(1);
			}
			winner.get(Display).alpha = 1;
			var te:TimedEvent = new TimedEvent(3, 1, turnOffWinner, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function turnOffWinner():void {
			winner.get(Display).alpha = 0;
		}
		
		private function getWaitNum():int {
			var waitNum:int = 0;
			switch(currRound){
				case 1:
					waitNum = 180 + Utils.randInRange(1, 9);
					break;
				case 2:
					waitNum = 150 + Utils.randInRange(1, 9);
					break;
				case 3:
					waitNum = 120 + Utils.randInRange(1, 9);
					break;
				case 4:
					waitNum = 90 + Utils.randInRange(1, 9);
					break;
				case 5:
					waitNum = 60 + Utils.randInRange(1, 9);
					break;
				case 6:
					waitNum = 60 + Utils.randInRange(1, 9);
					break;
				case 7:
					waitNum = 60 + Utils.randInRange(1, 9);
					break;
			}
			return waitNum;
		}
		
		private function setupIndicators():void
		{
			//win / loss indicators
			for (var i:uint=0;i<4;i++){
				var win:MovieClip = MovieClip(hudContainer)["hud"]["w"+(i+1)];
				var lose:MovieClip = MovieClip(hudContainer)["hud"]["l"+(i+1)];
				this["w"+(i+1)] = new Entity();
				this["l"+(i+1)] = new Entity();
				this["w"+(i+1)] = TimelineUtils.convertClip( win, this, this["w"+(i+1)] );
				this["l"+(i+1)] = TimelineUtils.convertClip( lose, this, this["l"+(i+1)] );
				
				var wSpatial:Spatial = new Spatial();
				var lSpatial:Spatial = new Spatial();
				
				wSpatial.x = win.x;
				wSpatial.y = win.y;
				lSpatial.x = lose.x;
				lSpatial.y = lose.y;
				
				this["w"+(i+1)].add(wSpatial);
				this["w"+(i+1)].add(new Display(win));
				this["w"+(i+1)].add(new Tween());
				this["l"+(i+1)].add(lSpatial);
				this["l"+(i+1)].add(new Display(lose));
				this["l"+(i+1)].add(new Tween());
				
				this["w"+(i+1)].get(Display).alpha = 1;
				this["l"+(i+1)].get(Display).alpha = 1;
				
				super.addEntity(this["w"+(i+1)]);
				super.addEntity(this["l"+(i+1)]);
				this["w"+(i+1)].get(Timeline).gotoAndStop(0);
				this["l"+(i+1)].get(Timeline).gotoAndStop(0);
				
			}
			
			//go
			var goMC:MovieClip = MovieClip(hudContainer)["hud"]["go"];
			go = new Entity();
			var goSpatial:Spatial = new Spatial();
			goSpatial.x = goMC.x;
			goSpatial.y = goMC.y;
			
			go.add(goSpatial);
			go.add(new Display(goMC));
			go.add(new Tween());
			
			go.get(Display).alpha = 0;
			
			super.addEntity(go);
			
			//round
			var roundMC:MovieClip = MovieClip(hudContainer)["hud"]["round"];
			round = new Entity();
			var roundSpatial:Spatial = new Spatial();
			roundSpatial.x = roundMC.x;
			roundSpatial.y = roundMC.y;
			
			round.add(roundSpatial);
			round.add(new Display(roundMC));
			round.add(new Tween());
			
			round.get(Display).alpha = 0;
			
			super.addEntity(round);
			
			//winner
			var winnerMC:MovieClip = MovieClip(hudContainer)["hud"]["winner"];
			winner = new Entity();
			var winnerSpatial:Spatial = new Spatial();
			winnerSpatial.x = winnerMC.x;
			winnerSpatial.y = winnerMC.y;
			
			winner.add(winnerSpatial);
			winner.add(new Display(winnerMC));
			winner.add(new Tween());
			
			winner.get(Display).alpha = 0;
			
			super.addEntity(winner);
		}
		
		private function setupHud():void
		{
			var hudMC:MovieClip = MovieClip(hudContainer)["hud"];
			hudMC.mouseChildren = true;
			hud = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = hudMC.x;
			spatial.y = hudMC.y;
			
			hud.add(spatial);
			hud.add(new Display(hudMC));
			hud.add(new Tween());
			
			hud.get(Display).alpha = 0;
			
			super.addEntity(hud);
			hudMC.name1.text = "hello turtle";
			
			hudMC.name1.text = shellApi.profileManager.active.avatarName;
		}
		
		private function setupBtns():void
		{
			
			//attackBtns
			var attackClip:MovieClip = MovieClip(hudContainer)["hud"]["attackBtns"];
			attackBtns = new Entity();
			attackBtns = TimelineUtils.convertClip( attackClip, this, attackBtns );
			
			var spatial:Spatial = new Spatial();
			spatial.x = attackClip.x;
			spatial.y = attackClip.y;
			
			attackBtns.add(spatial);
			attackBtns.add(new Display(attackClip));
			attackBtns.add(new Tween());
			attackBtns.add(new AttackBtn());
			
			attackBtns.get(Display).alpha = 0;
			
			super.addEntity(attackBtns);
			attackBtns.get(Timeline).gotoAndStop(1);
			
			//btn1
			btn1 = ButtonCreator.createButtonEntity(MovieClip(MovieClip(hudContainer)["hud"]["btn1"]), this);
			btn1.remove(Timeline);
			//btn1.add(new Tween());
			btn1.get(Display).alpha = 0;
			buttonToolTip = btn1.get(ToolTip);
			//super.addEntity(btn1);
			
			btn1Interaction = btn1.get(Interaction);
			btn1Interaction.downNative.add( Command.create( onBtnDown ))
			
			//btn2.get(Display).displayObject.alpha = 0;
			
			//btn2
			btn2 = ButtonCreator.createButtonEntity(MovieClip(MovieClip(hudContainer)["hud"]["btn2"]), this);
			btn2.remove(Timeline);
			//btn2.add(new Tween());
			btn2.get(Display).alpha = 0;
			
			//super.addEntity(btn2);
			
			btn2Interaction = btn2.get(Interaction);
			btn2Interaction.downNative.add( Command.create( onBtnDown ))
			
			//btn2.get(Display).displayObject.alpha = 0;
			
			//btn3
			btn3 = ButtonCreator.createButtonEntity(MovieClip(MovieClip(hudContainer)["hud"]["btn3"]), this);
			btn3.remove(Timeline);
			//btn3.get(Display).isStatic = false;
			//btn3.add(new Tween());
			//btn3.get(Display).isStatic = false;
			btn3.get(Display).alpha = 0;
			//btn3.get(Tween).to(btn3.get(Display).displayObject, 5, { alpha:1, ease:Sine.easeInOut });
			
			//super.addEntity(btn3);
			
			btn3Interaction = btn3.get(Interaction);
			btn3Interaction.downNative.add( Command.create( onBtnDown ))
			
			//btn3.get(Display).displayObject.alpha = 0;
			btn1.remove(ToolTip);
			btn2.remove(ToolTip);
			btn3.remove(ToolTip);
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
		
		public function playSound(sound:String):void {
			switch(sound){
				case "hex":
					super.shellApi.triggerEvent("hex");
					break;
				case "circleWin":
					super.shellApi.triggerEvent("circleWin");
					break;
				case "circleFail":
					super.shellApi.triggerEvent("circleFail");
					break;
				case "squareWin":
					super.shellApi.triggerEvent("squareWin");
					break;
				case "squareFail":
					super.shellApi.triggerEvent("squareFail");
					break;
				case "ping1":
					super.shellApi.triggerEvent("ping1");
					break;
				case "ping2":
					super.shellApi.triggerEvent("ping2");
					break;
				case "ping3":
					super.shellApi.triggerEvent("ping3");
					break;
				case "ping4":
					super.shellApi.triggerEvent("ping4");
					break;
			}
		}
		
		private function arrayShuffle(array_arr:Array):Array {
			for(var i:Number = 0; i < array_arr.length; i++){
				var randomNum_num:Number = Math.floor(Math.random() * array_arr.length)
				var arrayIndex:Number = array_arr[i];
				array_arr[i] = array_arr[randomNum_num];
				array_arr[randomNum_num] = arrayIndex;
			}
			return array_arr;
		}
	}
}
package game.scenes.poptropolis.volleyball{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.RotateControl;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Walk;
	import game.data.character.LookData;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.scenes.poptropolis.volleyball.components.Ball;
	import game.scenes.poptropolis.volleyball.systems.VolleyballSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.ui.NavigationArrowSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	
	public class Volleyball extends PoptropolisScene
	{
		private var ball:Entity;
		public var score1:Entity;
		public var score2:Entity;
		public var scoreboard:Entity;
		public var net:Entity;
		public var t1:Entity;
		public var t1bot:Entity;
		public var t2:Entity;
		public var t2bot:Entity;
		public var eyeLeft:Entity;
		public var eyeRight:Entity;
		public var panTarget:Entity;
		private var sb:MovieClip;
		
		private var _hud:VolleyballHud;
		
		private var playerScore:Number;
		private var opponentScore:Number;
		private var playersPoint:Boolean = false;
		
		public function Volleyball()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/volleyball/";
			
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
			
			//apply tribe look
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) ); // apply tribal jersey to look
			SkinUtils.applyLook( super.player, playerLook, false ); 
			
			_hud = super.addChildGroup(new VolleyballHud(super.overlayContainer)) as VolleyballHud;
			_hud.exitClicked.add(onExitPracticeClicked)
			
			//player.get(Display).alpha = 0;
			setupTentacles();
			setupBall();
			setupScoreboard();
			setupNet();
			setupEyes();
			setupPanTarget();
			
			super.addSystem( new NavigationArrowSystem() );
			
			this.addSystem( new BitmapSequenceSystem(), SystemPriorities.animate);
			CharUtils.lockControls( super.player );
			player.get(Spatial).x = 580;
			player.get(Spatial).y = 800;
			CharUtils.setAnim(player, game.data.animation.entity.character.Stand);
			
			var _startTimer:Timer = new Timer(1000,1.5);
			_startTimer.addEventListener(TimerEvent.TIMER_COMPLETE, instructionsIn);
			_startTimer.start();
		}
		
		private function instructionsIn(event:TimerEvent):void {
			openInstructionsPopup();
		}
		
		private function onExitPracticeClicked (): void {
			super.shellApi.loadScene(Volleyball);
		}
		
		override protected function onStartClicked (): void {
			setPracticeMode(false);
			initGame();
		}
		
		override protected function onPracticeClicked (): void {
			setPracticeMode(true);
			_hud.setupExitBtn();
			_hud.exitClicked.add(onExitPracticeClicked);
			initGame();
		}
		
		private function setPracticeMode (b:Boolean):void {
			_practice = b
		}
		
		private function initGame():void {
			var te:TimedEvent = new TimedEvent(2, 1, startMatch, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function startMatch():void {
			Ball(ball.get(Ball)).playing = true;
			if(player.get(Display).container.getChildIndex(player.get(Display).displayObject) > player.get(Display).container.getChildIndex(ball.get(Display).displayObject)){
				player.get(Display).container.swapChildren(player.get(Display).displayObject, ball.get(Display).displayObject);
			}
			super.addSystem(new VolleyballSystem());
		}
		
		public function walk():void {
			CharUtils.setAnim(player, game.data.animation.entity.character.Walk);
			//trace('walk');
		}
		
		public function run():void {
			CharUtils.setAnim(player, game.data.animation.entity.character.Run);
			//trace('run');
		}
		
		public function stand():void {
			CharUtils.setAnim(player, game.data.animation.entity.character.Stand);
			//trace('stand');
		}
		
		public function hitBall():void {
			CharUtils.setAnim(player, game.data.animation.entity.character.Score);
			player.get(Timeline).gotoAndPlay(10);
			if(player.get(Display).container.getChildIndex(player.get(Display).displayObject) > player.get(Display).container.getChildIndex(ball.get(Display).displayObject)){
				player.get(Display).container.swapChildren(player.get(Display).displayObject, ball.get(Display).displayObject);
			}
			playBallSound();
		}
		
		public function t1HitBall():void {
			t1.get(Timeline).gotoAndPlay(13);
			playBallSound();
		}
		
		public function t2HitBall():void {
			t2.get(Timeline).gotoAndPlay(1);
			playBallSound();
		}
		
		public function playBallSound():void {
			super.shellApi.triggerEvent("ballHit");
		}
		
		public function gameOver(ps:Number, os:Number):void {
			playerScore = ps;
			opponentScore = os;
			if(_practice){
				super.shellApi.loadScene(Volleyball);
			}else{
				//trace("Player Score = "+pScore+" :: Opposition Score = "+oScore);
				var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
				pop.setup();
			}
		}
		
		private function dataLoaded( pop:Poptropolis ):void {
			//trace(playerScore);
			pop.reportScore( Matches.VOLLEYBALL, playerScore );
		}
		
		public function showScore(isPlayer:Boolean, score:Number):void {
			super.shellApi.camera.target = scoreboard.get(Spatial);
			
			if(isPlayer){
				playerScore = score;
				playersPoint = true;
			}else{
				opponentScore = score;
				playersPoint = false;
			}
			
			var te:TimedEvent = new TimedEvent(1, 1, runScore, true);
			SceneUtil.addTimedEvent(this, te);
			
			eyeRight.get(TargetSpatial).target = scoreboard.get(Spatial);
		}
		
		public function runScore():void {
			if(playersPoint){
				sb["flip1"].visible = true;
				sb["flip1"]["num"+playerScore].visible = true;
			}else{
				sb["flip2"].visible = true;
				sb["flip2"]["num"+opponentScore].visible = true;
			}
			scoreboard.get(Timeline).gotoAndPlay(2);
			super.shellApi.triggerEvent("point");
			
		}
		
		private function setScoreboardScore():void {
			if(playersPoint){
				score1.get(Timeline).gotoAndStop(playerScore);
			}else{
				score2.get(Timeline).gotoAndStop(opponentScore);
			}
		}
		
		private function setScoreboardPartsOff():void {
			
			sb = MovieClip(scoreboard.get(Display).displayObject);
			
			sb["flip1"].visible = false;
			sb["flip1"]["num1"].visible = false;
			sb["flip1"]["num2"].visible = false;
			sb["flip1"]["num3"].visible = false;
			sb["flip1"]["num4"].visible = false;
			sb["flip1"]["num5"].visible = false;
			sb["flip1"]["num6"].visible = false;
			sb["flip2"].visible = false;
			sb["flip2"]["num1"].visible = false;
			sb["flip2"]["num2"].visible = false;
			sb["flip2"]["num3"].visible = false;
			sb["flip2"]["num4"].visible = false;
			sb["flip2"]["num5"].visible = false;
			sb["flip2"]["num6"].visible = false;
			
			var te:TimedEvent = new TimedEvent(1, 1, serveBall, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function serveBall():void
		{
			eyeRight.get(TargetSpatial).target = ball.get(Spatial);
			Ball(ball.get(Ball)).playing = true;
			super.shellApi.camera.target = panTarget.get(Spatial);
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
			super.shellApi.camera.target = panTarget.get(Spatial);
		}
		
		private function setupEyes():void
		{			
			var clip:MovieClip = _hitContainer["eyeLeft"];
			eyeLeft = new Entity();
			eyeLeft = TimelineUtils.convertClip( clip, this, eyeLeft );
			
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			eyeLeft.add(spatial);
			eyeLeft.add(new Display(clip));
			
			super.addEntity(eyeLeft);
			eyeLeft.get(Timeline).gotoAndStop(0);
			
			var clip2:MovieClip = _hitContainer["eyeRight"];
			eyeRight = new Entity();
			eyeRight = TimelineUtils.convertClip( clip2, this, eyeRight );
			
			var spatial2:Spatial = new Spatial();
			spatial2.x = clip2.x;
			spatial2.y = clip2.y;
			
			eyeRight.add(spatial2);
			eyeRight.add(new Display(clip2));
			
			super.addEntity(eyeRight);
			eyeRight.get(Timeline).gotoAndStop(0);
			
			//rotate eyes
			var targetSpatial:TargetSpatial =  new TargetSpatial( ball.get( Spatial ) );
			eyeRight.add( targetSpatial );
			eyeLeft.add(targetSpatial);
			
			var rotateControl:RotateControl = new RotateControl();
			eyeRight.add( rotateControl );
			eyeLeft.add(rotateControl);
			
			this.addSystem( new RotateToTargetSystem );
			
			
		}
		
		private function setupTentacles():void
		{
			var clip:MovieClip = _hitContainer["t1"];
			t1 = BitmapTimelineCreator.createBitmapTimeline( clip );
			
			super.addEntity(t1);
			t1.get(Timeline).gotoAndPlay(1);
			
			var clip2:MovieClip = _hitContainer["t2"];
			t2 = BitmapTimelineCreator.createBitmapTimeline( clip2 );
			
			super.addEntity(t2);
			t2.get(Timeline).gotoAndPlay(1);
			
			var clip3:MovieClip = _hitContainer["t1bot"];
			t1bot = new Entity();
			var spatial3:Spatial = new Spatial();
			spatial3.x = clip3.x;
			spatial3.y = clip3.y;
			
			t1bot.add(spatial3);
			t1bot.add(new Display(clip3));
			
			super.addEntity(t1bot);
			
			var clip4:MovieClip = _hitContainer["t2bot"];
			t2bot = new Entity();
			var spatial4:Spatial = new Spatial();
			spatial4.x = clip4.x;
			spatial4.y = clip4.y;
			
			t2bot.add(spatial4);
			t2bot.add(new Display(clip4));
			
			super.addEntity(t2bot);
			
			EntityUtils.getDisplay(t1).setIndex(1);
		}
		
		private function t1HitComplete():void {
			t1.get(Timeline).stop();
		}
		
		private function setupNet():void
		{
			var clip:MovieClip = _hitContainer["net"];
			net = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			net.add(spatial);
			net.add(new Display(clip));
			
			super.addEntity(net);
		}
		
		private function setupScoreboard():void
		{
			//scorebard
			var clip0:MovieClip = _hitContainer["scoreboard"];
			scoreboard = new Entity();
			scoreboard = TimelineUtils.convertClip( clip0, this, scoreboard );
			
			var spatial0:Spatial = new Spatial();
			spatial0.x = clip0.x;
			spatial0.y = clip0.y;
			
			scoreboard.add(spatial0);
			scoreboard.add(new Display(clip0));
			
			super.addEntity(scoreboard);	
			
			scoreboard.get(Timeline).gotoAndStop(0);
			//stop numbers
			clip0.flip1.num1.gotoAndStop(1);
			clip0.flip1.num2.gotoAndStop(1);
			clip0.flip1.num3.gotoAndStop(1);
			clip0.flip1.num4.gotoAndStop(1);
			clip0.flip1.num5.gotoAndStop(1);
			clip0.flip1.num6.gotoAndStop(1);
			clip0.flip2.num1.gotoAndStop(1);
			clip0.flip2.num2.gotoAndStop(1);
			clip0.flip2.num3.gotoAndStop(1);
			clip0.flip2.num4.gotoAndStop(1);
			clip0.flip2.num5.gotoAndStop(1);
			clip0.flip2.num6.gotoAndStop(1);
			clip0.flip1.gotoAndStop(1);
			clip0.flip2.gotoAndStop(1);
			clip0.backFlip1.gotoAndStop(1);
			clip0.backFlip2.gotoAndStop(1);
			
			scoreboard.get(Timeline).handleLabel("starter", setScoreboardPartsOff, false);
			scoreboard.get(Timeline).handleLabel("start", setScoreboardScore, false);
			
			//score1 - player side
			var clip1:MovieClip = _hitContainer["scoreboard"]["score1"];
			score1 = new Entity();
			score1 = TimelineUtils.convertClip( clip1, this, score1 );
			
			var spatial1:Spatial = new Spatial();
			spatial1.x = clip1.x;
			spatial1.y = clip1.y;
			
			score1.add(spatial1);
			score1.add(new Display(clip1));
			
			super.addEntity(score1);	
		
			score1.get(Timeline).gotoAndStop(0);
			
			//score2 - player side
			var clip2:MovieClip = _hitContainer["scoreboard"]["score2"];
			score2 = new Entity();
			score2 = TimelineUtils.convertClip( clip2, this, score2 );
			
			var spatial2:Spatial = new Spatial();
			spatial2.x = clip2.x;
			spatial2.y = clip2.y;
			
			score2.add(spatial2);
			score2.add(new Display(clip2));
			
			super.addEntity(score2);	
			
			score2.get(Timeline).gotoAndStop(0);
		}
		
		private function setupBall():void
		{
			var clip:MovieClip = _hitContainer["ball"];
			ball = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			ball.add(spatial);
			ball.add(new Display(clip));
			ball.add(new Ball());
			
			super.addEntity(ball);
		}
	}
}
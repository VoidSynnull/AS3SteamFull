package game.scenes.poptropolis.longJump
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.character.Skin;
	import game.components.input.Input;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.LongJumpRun;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.common.StateString;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.MatchType;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TribeUtils;
	
	public class LongJump extends PoptropolisScene
	{
		public var _interaction:Interaction;
		private var _jumping:Boolean;
		private var _initPlayerX:Number;
		private var _initPlayerY:Number
		
		private var _charControlSystem:LongJumpCharControlSystem
		private var _hud:LongJumpHud;
		private var _jumpNum:int;
		private var _bestScore:Number;
		private var _input:Input;
		private var _leanedThisJump:Boolean;
		private var _mudSplash:Entity;

		private var _mudSplashMc:MovieClip;
		
		public function LongJump()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/longJump/";
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
			
			super.shellApi.defaultCursor = ToolTipType.TARGET;
			
			_playerDummy = super.getEntityById( "playerDummy" );
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) ); // apply tribal jersey to look
			_playerDummy.get(Skin).applyLook( playerLook );
			addMotion (_playerDummy)
			
			_initPlayerX = _playerDummy.get(Spatial).x
			_initPlayerY = _playerDummy.get(Spatial).y
			
			var inputEntity:Entity = shellApi.inputEntity;
			_input = inputEntity.get( Input ) as Input;
			
			_charControlSystem = new LongJumpCharControlSystem
			_charControlSystem.init(_playerDummy)
			_charControlSystem.jumpComplete.add(onJumpComplete);
			_charControlSystem.foul.add(onFoul);
			
			_playerDummy.add(new StateString("startingLine"))
			
			_hud = super.addChildGroup(new LongJumpHud(super.overlayContainer)) as LongJumpHud;
			_hud.resultDisplayComplete.add(onResultDisplayComplete)
			_hud.exitPracticeClicked.add(onExitPracticeClicked)
			_hud.ready.addOnce(initHud);
			
			SceneUtil.addTimedEvent( this, new TimedEvent(1, 1, onSceneAnimateInComplete));
			
			//hideActualPlayer()
			super.removeEntity( super.player );
			
			setupSpectators();
			
			_mudSplashMc = super._hitContainer["mudSplash"]
		//	_mudSplash = BitmapTimelineCreator.convertToBitmapTimeline(mc,true,true )
			_mudSplash = new Entity()
			_mudSplash.add(new Display(_mudSplashMc))
			_mudSplash.add(new Spatial(_mudSplashMc.x,_mudSplashMc.y))
			addEntity(_mudSplash)
			_mudSplashMc.stop()
				
			SceneUtil.setCameraTarget( this, _playerDummy );
		}
		
		private function onExitPracticeClicked():void
		{
			_hud.clear()
			openInstructionsPopup();
			stopEntityMotion(_playerDummy)
		}
		
		private function initHud(hud:LongJumpHud):void
		{
			_hud.setMode("clear")
		}
		
		private function onSceneAnimateInComplete ():void {
			openInstructionsPopup()
		}
		
		override protected function onStartClicked (): void {
			setPracticeMode(false)
			_jumpNum = 1
			_bestScore = 0
			setupJump()
		}
		
		override protected function onPracticeClicked (): void {
			setPracticeMode(true)
			setupJump()
		}
		
		private function setPracticeMode (b:Boolean):void {
			_practice = b
			if (!_practice) {
				_hud.setMode("race")
			} else {
				_hud.setMode("practice")
			}
		}
		
		private function onMouseDown( input:Input ):void
		{
			if (_playerDummy.get(StateString).state == "prerun") startRun()
		}
		
		private function onMouseUp( input:Input ):void
		{
			if (_playerDummy.get(StateString).state == "running"){
				_charControlSystem.jump(_playerDummy)
				playSoundEffect ("hurl_01")
			} else if (_playerDummy.get(StateString).state == "jumping" && ! _leanedThisJump ) {
				_charControlSystem.boost(_playerDummy)
				_leanedThisJump = true
				playSoundEffect ("hurl_01")
			}
		}
		
		private function startRun():void {
			trace ("[LongJump] run! player.x:" + _playerDummy.get(Spatial).x)
			CharUtils.setAnim(_playerDummy,LongJumpRun)
			CharUtils.setAnim(_playerDummy,LongJumpRun)
			SceneUtil.addTimedEvent( this, new TimedEvent(.6, 1, setPlayerInMotion));	
		}
		
		private function setPlayerInMotion (): void {
			var m:Motion 
			m = _playerDummy.get(Motion) as Motion
			m.acceleration.x = LongJumpConstants.RUN_ACCEL
			
			_playerDummy.get(StateString).state = "running"
			
			super.addSystem( _charControlSystem, SystemPriorities.autoAnim );
		}
		
		private function setupJump():void {
			trace ("[LongJump] setupJump")
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.Stand)
			var sp:Spatial = _playerDummy.get(Spatial)
			sp.x = _initPlayerX
			sp.y = _initPlayerY
			
			_playerDummy.get(StateString).state = "prerun"
			
			var m:Motion = _playerDummy.get(Motion)
			m.acceleration.x = m.acceleration.y = 0
			m.velocity.x = m.velocity.y = 0
			
			if (!_practice) _hud.setAttemptNum (_jumpNum)
			
			_leanedThisJump = false
			
			_input.inputDown.add( onMouseDown );
			_input.inputUp.add( onMouseUp );
		}
		
		private function onJumpComplete ():void {
			_playerDummy.get (StateString).state = "jumpComplete"
			var sp:Spatial = _playerDummy.get(Spatial)
			
			var x1:Number = 1558 
			var y1:Number = 0
			var x2:Number = 3236 
			var y2:Number = 100
			
			var m:Number = (y2-y1)/(x2-x1)
			var b:Number = y2 - m*x2
			
			var score:Number = (sp.x) * m + b + 3
			score = Math.round(score * 100 )/100
			score = Math.max (0,score)
			
			if (!_practice) {
				if (score > _bestScore) playSoundEffect ("achievement_01")	
				_bestScore = Math.max (score,_bestScore)
				_hud.showResult(score,_bestScore,(_jumpNum == 1))
			} else {
				_hud.showPracticeResult(score)
			}
			
			_input.inputDown.remove( onMouseDown );
			_input.inputUp.remove( onMouseUp );
			
			playSoundEffect ("ls_sand_02")
			
			_mudSplashMc.gotoAndPlay(1)
			_mudSplashMc.parent.addChild(_mudSplashMc)
			_mudSplash.get(Spatial).x = _playerDummy.get(Spatial).x+10
			
			if (score > 0) AudioUtils.play(this, SoundManager.EFFECTS_PATH +"CrowdCheer_01.mp3");
		}
		
		private function onFoul():void {
			_playerDummy.get (StateString).state = "foul"
			_hud.showFoul()
			SceneUtil.addTimedEvent( this, new TimedEvent(2, 1, checkNextJump));
			playSoundEffect ("buzzer_02")
		}
		
		private function onResultDisplayComplete():void
		{
			checkNextJump()
		}
		
		private function reportResults( gameInfo:Poptropolis ):void {
			gameInfo.reportScore( Matches.LONG_JUMP, _bestScore, false );
		} 
		
		private function checkNextJump ():void {
			if (_practice) {
				openInstructionsPopup()
			} else {
				if  (_jumpNum == 3) {
					var pop:Poptropolis = new Poptropolis( this.shellApi, this.reportResults );
					var curMatch:MatchType = Matches.getMatchType(Matches.LONG_JUMP);
					pop.onResultsDone.addOnce(Command.create(onResultsDone, curMatch.eventName));
					pop.setup();
				}
					
				else {
					_jumpNum++;
					setupJump()
				}
			}
		}
	}
}
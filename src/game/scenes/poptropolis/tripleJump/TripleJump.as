package game.scenes.poptropolis.tripleJump{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.input.Input;
	import game.components.entity.Sleep;
	import game.components.entity.character.Skin;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.LongJumpLand;
	import game.data.animation.entity.character.poptropolis.LongJumpRun;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.common.StateString;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TribeUtils;
	
	public class TripleJump extends PoptropolisScene
	{
		public var _interaction:Interaction;
		private var _jumping:Boolean;
		private var _initPlayerX:Number;
		private var _initPlayerY:Number
		private var _charControlSystem:TripleJumpCharControlSystem
		
		private static const RUN_ACCEL:Number = 1300
		public static const GROUND_Y:Number = 746
		public static const FALL_MAX_Y:Number = 950
		public static const ZERO_METERS_X:Number = 3500
		public static const ACCEL_X_AFTER_FOUL:Number = -500
		public static var JUMP_ACCELS:Array = [{velY:-500,accelY:1400},{velY:-500,accelY:1400},{velY:-900,accelY:1100}]
		
		public static const DEBUG_SHOW_PLAYER_DOTS:Boolean = false
		
		private var _hud:TripleJumpHud;
		private var _hopNum:int;
		private var _attemptNum:int;
		private var _bestScore:Number;
		private var _input:Input;
		
		public function TripleJump()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/tripleJump/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
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
			
			_charControlSystem = new TripleJumpCharControlSystem
			_charControlSystem.init(_playerDummy,this)
			_charControlSystem.hopComplete.add(onHopComplete);
			_charControlSystem.fallStarted.add(onFallStarted);
			_charControlSystem.fallComplete.add(onFallComplete);
			_charControlSystem.foul.add(onFoul);
			
			var holes:Array = [[1540,1780],[2230,2480],[2851,3220]]
			_charControlSystem.holes = holes
			
			_playerDummy.add(new StateString("startingLine"))
			
			_hud = super.addChildGroup(new TripleJumpHud(super.overlayContainer)) as TripleJumpHud;
			_hud.resultDisplayComplete.add(onResultDisplayComplete);
			_hud.exitPracticeClicked.add(onExitPracticeClicked);
			_hud.ready.addOnce(initHud);
			
			SceneUtil.addTimedEvent( this, new TimedEvent(1, 1, onSceneAnimateInComplete));
			
			super.removeEntity( super.player );
			
			var sleep:Sleep = _playerDummy.get(Sleep);
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = false
			
			setupSpectators();
			
			var _debugEntity:Entity = new Entity()
			_debugEntity.add(new Display(super._hitContainer["mcDebug"]));
			_debugEntity.add(new Spatial(0,0))
			this.addEntity(_debugEntity);
		}
		
		private function onSceneAnimateInComplete ():void {
			openInstructionsPopup()
			SceneUtil.setCameraTarget( this, _playerDummy );
		}
		
		private function initHud(hud:TripleJumpHud):void
		{
			_hud.setMode("clear")
			debugClip = _hud.debugClip
		}
		
		override protected function onStartClicked (): void {
			setPracticeMode(false)
			_attemptNum = 1
			_bestScore = 0
			setupJump()
		}
		
		private function onExitPracticeClicked():void
		{
			_hud.clear()
			openInstructionsPopup();
			stopEntityMotion(_playerDummy)
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
			//trace ("[TripleJump] onMouseDown: player.y:" + _playerDummy.get(Spatial).y )
			
			var st:String = _playerDummy.get(StateString).state
			switch (st) {
				case "prerun": 
					startRun()
					break
				case  "runAfterHop":
					if ( _hopNum  < 3) {
						_charControlSystem.jump(_playerDummy,_hopNum)
						trace ("[TripleJump]------------ player.y:" + _playerDummy.get(Spatial).y)
						playSoundEffect("jump_from_gravel_01")
						_hopNum++
					}
					break
				case "jumping":
					_lastMouseDownTime = getTimer()
					break
			}
		}
		
		private function onMouseUp( input:Input ):void
		{
			trace ("[TripleJump] onMouseUp. state:" + _playerDummy.get(StateString).state)
			var st:String = _playerDummy.get(StateString).state
			// "running is initial run, not the run after a hop
			switch (st) {
				case "running":
					if  (_hopNum  < 3) {_charControlSystem.jump(_playerDummy,_hopNum)
						trace ("[TripleJump]------------ player.y:" + _playerDummy.get(Spatial).y)
						playSoundEffect("jump_from_gravel_01")
						_hopNum++
					}
					break
				//case "prerun":
				//	stopPlayer()
				//
				break
				
			}
		}
		
		// Just shows the little prerun move
		private function startRun():void {
			trace ("[TripleJump] run! player.x:" + _playerDummy.get(Spatial).x)
			CharUtils.setAnim(_playerDummy,LongJumpRun)
			SceneUtil.addTimedEvent( this, new TimedEvent(.6, 1, setPlayerInMotion));	
		}
		
		// Actually sends player in motion
		private function setPlayerInMotion():void {
			var m:Motion 
			m = _playerDummy.get(Motion) as Motion
			m.acceleration.x = RUN_ACCEL
			_playerDummy.get(StateString).state = "running"
			super.addSystem( _charControlSystem, SystemPriorities.autoAnim );
		}
		
		private function setupJump():void {
			trace ("[TripleJump] setupJump")
			_hopNum = 0
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.Stand)
			var sp:Spatial = _playerDummy.get(Spatial)
			sp.x = _initPlayerX
			sp.y = _initPlayerY
			
			_playerDummy.get(StateString).state = "prerun"
			
			stopPlayer()
			
			if (!_practice) _hud.setAttemptNum (_attemptNum)
			
			_input.inputDown.add( onMouseDown );
			_input.inputUp.add( onMouseUp );
			
			trace ("[TripleJump] setupJump: player.y:" + _playerDummy.get(Spatial).y + "  _initPlayerY:" + _initPlayerY)
			
			if (DEBUG_SHOW_PLAYER_DOTS) {
				while (super._hitContainer["mcDebug"].numChildren > 0) {
					super._hitContainer["mcDebug"].removeChildAt(0)
				}
			}
			
			_lastMouseDownTime = 0
		}
		
		private function stopPlayer():void
		{
			var m:Motion = _playerDummy.get(Motion)
			m.acceleration.x = m.acceleration.y = 0
			m.velocity.x = m.velocity.y = 0			
		}
		
		private function onHopComplete():void {
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.poptropolis.LongJumpLand)
			playSoundEffect("light_gritty_push_01")
			if (_hopNum < 3) {
				_playerDummy.get(StateString).state = "runAfterHop" 
				// if they clicked right at end of jump, count it as a click.	
				if (_lastMouseDownTime != 0) {
					if ((getTimer() - _lastMouseDownTime) < 200) {
						//	_charControlSystem.jump(_playerDummy,_hopNum)
						_lastMouseDownTime = 0
					}
				}
				
			} else {
				attemptComplete()
			}
		}
		
		private function attemptComplete ():void {
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.poptropolis.LongJumpLand)
			var motion:Motion = _playerDummy.get(Motion)
			stopAndStand()
			SceneUtil.addTimedEvent( this, new TimedEvent(.1, 1, stopAndStand));
			
			_playerDummy.get (StateString).state = "jumpComplete"
			var sp:Spatial = _playerDummy.get(Spatial)
			trace ("[TripleJump] jump complete!!!!!!!!!!!")
			var x1:Number = 3248 
			var y1:Number = 30
			var x2:Number = 4565 
			var y2:Number = 120
			
			var m:Number = (y2-y1)/(x2-x1)
			var b:Number = y2 - m*x2
			
			var score:Number = sp.x * m + b + 6
			score = Math.round(score * 100 )/100
			
			if (score > _bestScore) playSoundEffect ("achievement_01")	
			
			_bestScore = Math.max (score,_bestScore)
			
			if (!_practice) {
				if (score > _bestScore) playSoundEffect ("achievement_01")	
				_bestScore = Math.max (score,_bestScore)
				_hud.showResult(score,_bestScore,(_attemptNum == 1))
			} else {
				_hud.showPracticeResult(score)
			}
			
			_input.inputDown.remove( onMouseDown );
			_input.inputUp.remove( onMouseUp );
			
			if (score > 0) AudioUtils.play(this, SoundManager.EFFECTS_PATH +"CrowdCheer_01.mp3");
			
			var mc:MovieClip = 	super._hitContainer["mcDebug"]
			mc.scaleX = .3
			mc.scaleY = .3
			
		}
		
		private function onFoul():void {
			_playerDummy.get (StateString).state = "foul"
			_hud.showFoul()
			SceneUtil.addTimedEvent( this, new TimedEvent(2, 1, checkNextJump));
		}
		
		private function onFallComplete():void {
			_hud.showFell()
			SceneUtil.addTimedEvent( this, new TimedEvent(2, 1, checkNextJump));
			stopPlayer()
		}
		
		private function onFallStarted():void {
			playSoundEffect("trip_01")
		}
		
		private function onResultDisplayComplete():void
		{
			checkNextJump()
		}

		private function checkNextJump ():void 
		{
			if (_practice) 
			{
				_hud.setMode ("clear")
				openInstructionsPopup()
			} 
			else
			{
				if  (_attemptNum == 3) 
				{
					var pop:Poptropolis = new Poptropolis( this.shellApi, this.reportResults );
					pop.setup();
				}
				else 
				{
					_attemptNum++;
					setupJump()
				}
			}
		}
		
		private function reportResults( gameInfo:Poptropolis ):void 
		{
			gameInfo.reportScore( Matches.TRIPLE_JUMP, _bestScore, true );
		} 
	}
}
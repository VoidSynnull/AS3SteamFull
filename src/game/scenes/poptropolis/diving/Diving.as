package game.scenes.poptropolis.diving{

	import com.greensock.easing.Back;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stomp;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.diving.particles.Splash;
	import game.scenes.poptropolis.diving.states.DiveJumpState;
	import game.scenes.poptropolis.diving.ui.DivingRoutine;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.MatchType;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.FollowTargetSystem;
	import game.util.ArrayUtils;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;

	
	public class Diving extends PoptropolisScene
	{
		// audio
		private var _spinSoundEntity:Entity;
		private var _audio:Audio;

		// huds
		private var _routineHud:DivingRoutine;
		private var _curveEntity:Entity;				// entity for curve hud
		private var _starEntity:Entity;					// entity for star score
		
		// game stats
		private var _difficultyLevel:Number;			// difficulty level, level 0 has 2 spins, level 1 has 3 spins, level 2 has 4 spins.
		private var _round:Number;
		private var _playerScore:Number;
		private var _roundScore:Number;
		
		// routine
		private var _routines:Vector.<Vector.<Vector.<int>>>;	// 2D Vector, first vector is difficulty, second is possible routine combinations
		private var _currentRoutine:Vector.<int>;		// Vector of integers representing routine combination
		private var _currentSpinDirection:int;			// current spin routine, either -1 of 1 (left or right)
		private var _currentSpinIndex:int;				// index of current spin within current routine

		public function Diving()
		{
			super();
			super.defaultCursor = ToolTipType.TARGET;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/diving/";
			super.init(container);
		}

		// all assets ready
		override public function loaded():void
		{
			this.initGame();		// initialize game	

			// add systems
			super.addSystem( new FollowTargetSystem() );
			// create default exit button for exiting from practice or game
			super.createExitBtn( false, "bottomRight");	

			// TODO :: this look apply should happen earlier
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) );
			SkinUtils.applyLook( player, playerLook, false, onLookApplied );
		}
		
		/**
		 * Setup that only happens once on initialization.
		 * Anything that needs ot reset each play through happens in reset()
		 */
		private function initGame():void 
		{
			// set up player
			DisplayUtils.moveToOverUnder( player.get(Display).displayObject, super._hitContainer['front_mc'], false );	// move character below front_mc	
			CharUtils.lockControls( player, true, true );	// lock player controls
			CharUtils.stateDrivenOff( player );
			var stateCreator:FSMStateCreator = new FSMStateCreator();
			stateCreator.createCharacterState( DiveJumpState, player, CharacterState.JUMP );
			var fsm:FSMControl = player.get(FSMControl);
			fsm.stateChange = new Signal();
			
			// create routine hud
			_routineHud = super.addChildGroup(new DivingRoutine(super.overlayContainer)) as DivingRoutine;

			// create routine 2D vector
			_routines = new Vector.<Vector.<Vector.<int>>>();
			_routines[0] = new Vector.<Vector.<int>>();
			_routines[1] = new Vector.<Vector.<int>>();
			_routines[2] = new Vector.<Vector.<int>>();
			
			_routines[0][0] = new <int>[-1,-1];
			_routines[0][1] = new <int>[1,1];
			_routines[0][2] = new <int>[-1,1];
			_routines[0][3] = new <int>[1,-1];
			
			_routines[1][0] = new <int>[-1,-1,1];
			_routines[1][1] = new <int>[1,1,-1];
			_routines[1][2] = new <int>[-1,1,-1];
			_routines[1][3] = new <int>[1,-1,1];
			
			_routines[2][0] = new <int>[-1,1,1,-1];
			_routines[2][1] = new <int>[1,-1,-1,1];
			_routines[2][2] = new <int>[-1,1,-1,1];
			_routines[2][3] = new <int>[1,-1,1,-1];
			
			// create curve ui, set to follow player
			var clip:MovieClip = super._hitContainer["curve_mc"];
			_curveEntity = EntityUtils.createSpatialEntity(this, clip);
			displayCurve( false );
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			
			// create star ui
			clip = super._hitContainer["star_mc"];
			_starEntity = EntityUtils.createSpatialEntity(this, clip);
			_starEntity.add( new Tween() );
			displayStar( false );
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			
			// create spectators
			setupSpectators();
			
			// create audio
			_spinSoundEntity = AudioUtils.createSoundEntity("_spinSoundEntity");	
			_audio = new Audio();
			_spinSoundEntity.add(_audio);			
			super.addEntity(_spinSoundEntity);
		}
		
		private function onLookApplied( entity:Entity = null ):void 
		{
			super.ready.addOnce( onReady );
			super.loaded();
		}
		
		private function onReady( ...args ):void 
		{
			// slight delay before opening instructions
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, resetGame ) );	 // give instructions popup time to animate in
		}
		
		/**
		 * Resets game
		 */
		private function resetGame():void 
		{
			//reset scores
			_playerScore = 0;
			_difficultyLevel = 0;	
			_round = 1;	

			// do we need to reset anything else? probably
			super.openInstructionsPopup();
		}
		
		override protected function onStartClicked (): void 
		{
			super._practice = false;
			startRound();
		}
		
		override protected function onPracticeClicked (): void 
		{
			super._practice = true;
			// display exit practive button
			super.showExitBtn();
			startRound();
		}
		
		override protected function exitPractice(): void 
		{
			super.shellApi.loadScene(Diving);
		}
		
		/**
		 * Reset round
		 */
		private function startRound():void 
		{
			// reset score
			_roundScore = 0;
			
			// reset huds
			displayStar( false );
			displayCurve( false );
			
			// reset player
			CharUtils.lockControls( player, true, true );	// lock player controls & input targeting
			CharUtils.setDirection( player, true );
			CharUtils.setState( player, CharacterState.STAND );
			var spatial:Spatial = super.player.get(Spatial);
			if( spatial.y > super.sceneData.startPosition.y + 50 )
			{
				CharUtils.position( player, super.sceneData.startPosition.x, super.sceneData.startPosition.y );
			}
			SceneUtil.setCameraTarget( this, super.player );
			
			// reset routine
			_currentRoutine =  ArrayUtils.getRandomElementVector( _routines[_difficultyLevel] ) as Vector.<int>;
			_currentSpinIndex = 0;
			_currentSpinDirection = _currentRoutine[_currentSpinIndex];
			
			// display routine hud, on complete start dive
			_routineHud.resetRoutine( _difficultyLevel, _currentRoutine ); 
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, _routineHud.fadeIn));
			_routineHud.routineDisplayComplete.add( startDive );
		}
		
		/**
		 * Start jump sequence
		 */
		public function startDive():void
		{				
			CharUtils.setState( player, CharacterState.JUMP );

			// start routine once animation has transitioned to curl
			Timeline(CharUtils.getTimeline(player)).handleLabel("enterCurl", startSpinCheck );
		}
		
		private function startSpinCheck():void
		{
			CharUtils.lockControls( player, false, false );	// unlock input for targeting & clicks
			// listen for current spin hud to complete
			_routineHud.arrowComplete.add( onArrowComplete )
			_routineHud.setCurrentArrow( _currentSpinIndex );
			
			// listen for change in state (used to determine when dive haas completed)
			var fsm:FSMControl = player.get(FSMControl);
			fsm.stateChange.addOnce( onLand );
			
			// listen to DiveJumpState to determine if rotation has changed
			var state:DiveJumpState = FSMControl(player.get(FSMControl)).getState( CharacterState.JUMP ) as DiveJumpState;
			state.spinChanged.add( onSpinChange );
			onSpinChange( state.spinDirection );
		}
		
		// determine which side mouse is on
		public function onSpinChange( direction:int ):void
		{	
			if( _currentSpinDirection == direction )
			{
				_routineHud.fillCurrentArrow(true);
				_audio.play(SoundManager.EFFECTS_PATH + "fill_up_rotation.mp3");
			}
			else
			{
				_routineHud.fillCurrentArrow(false);
				_audio.stop(SoundManager.EFFECTS_PATH + "fill_up_rotation.mp3");
			}
		}
		
		/**
		 * Spin complete
		 */
		public function onArrowComplete():void
		{	
			_currentSpinIndex++;
			_roundScore += 5;
			_playerScore += 5;
			displayCurve( true, _currentSpinDirection );
			var state:DiveJumpState = FSMControl(player.get(FSMControl)).getState( CharacterState.JUMP ) as DiveJumpState;
			
			_audio.stop(SoundManager.EFFECTS_PATH + "fill_up_rotation.mp3");
			super.shellApi.triggerEvent("completeRotation"+(_currentSpinIndex)+"SFX");

			if( _currentSpinIndex < _currentRoutine.length )	// setup next spin
			{
				_currentSpinDirection = _currentRoutine[_currentSpinIndex];
				_routineHud.setCurrentArrow( _currentSpinIndex );

				onSpinChange( state.spinDirection );
			}
			else												// routine is complete
			{
				// deactivate spin routine
				_routineHud.arrowComplete.remove( onArrowComplete );
				
				// update state to check for click, which causes transition into dive
				state.spinsComplete = true;
				state.spinChanged.remove( onSpinChange );
			}
		}
		
		//////////////////////////////////////////////////////////////////////////
		////////////////////////////////// HUDS //////////////////////////////////
		//////////////////////////////////////////////////////////////////////////
		
		private function displayCurve( isVisible:Boolean = true, direction:int = 0 ):void 
		{
			var display:Display = _curveEntity.get(Display );
			if( isVisible )
			{
				// make curve follow player
				EntityUtils.followTarget( _curveEntity, super.player );
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, Command.create( displayCurve, false ) ) );	// turn off after duration	
				display.visible = true;
				if( direction == 1 )
				{
					MovieClip(display.displayObject).gotoAndStop("spinRight");
				}
				else if( direction == -1 )
				{
					MovieClip(display.displayObject).gotoAndStop("spinLeft");
				}
			}
			else
			{
				display.visible = false;
				MovieClip(display.displayObject).stop();
				EntityUtils.stopFollowTarget( _curveEntity );
			}
		}
		
		private function displayStar( isVisible:Boolean = true, score:Number = NaN ):void 
		{
			var display:Display = _starEntity.get(Display );
			var spatial:Spatial = _starEntity.get(Spatial );
			if( isVisible )
			{
				spatial.scale = .1;
				display.alpha = 1;
				Tween(_starEntity.get(Tween)).to( spatial, .5, { scale : 1, ease:Back.easeOut });
				display.visible = true;
				if( !isNaN(score) )
				{
					MovieClip(display.displayObject).gotoAndStop("score_" + score);
				}
			}
			else
			{
				display.visible = false;
				MovieClip(display.displayObject).stop();
			}
		}
		
		private function exitStar():void 
		{
			var display:Display = _starEntity.get(Display );
			var spatial:Spatial = _starEntity.get(Spatial );
			Tween(_starEntity.get(Tween)).to( spatial, .25, { scale : .1, ease:Back.easeIn });
			Tween(_starEntity.get(Tween)).to( display, .25, { alpha : 0, ease:Back.easeIn });
		}
		
		//////////////////////////////////////////////////////////////////////////
		///////////////////////////// ROUND COMPLETE /////////////////////////////
		//////////////////////////////////////////////////////////////////////////
		
		private function onLand( stateType:String, entity:Entity ):void
		{
			// force velocity so player goes farther into water
			Motion(player.get(Motion)).velocity.y = 800;
			CharUtils.lockControls( player, true, true );
			
			// stop spin controls and hud
			displayCurve( false );
			_routineHud.fillCurrentArrow(false);
			_routineHud.fadeOut();
			
			// play extra splash
			var playerSpatial:Spatial = super.player.get(Spatial);
			var splashEmitter:Splash = new Splash(); 
			EmitterCreator.create(this, super._hitContainer, splashEmitter, playerSpatial.x, playerSpatial.y); 
			splashEmitter.init();

			// check if dive was straigh on entry, add points
			var fsm:FSMControl = player.get(FSMControl);
			var inDivePose:Boolean = DiveJumpState(fsm.getState( CharacterState.JUMP )).isDivePose;
			if( inDivePose )
			{
				super.shellApi.triggerEvent("goodDiveSFX");
			}
			else
			{
				super.shellApi.triggerEvent("cannonBallSFX");
			}
			
			// show round score
			if (_roundScore > 0)
			{
				displayStar( true, _roundScore );
			}
			
			//if dive success increase _difficultyLevel
			if( _roundScore == (_difficultyLevel + 2) * 5 && inDivePose )
			{
				_difficultyLevel++;
				SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, Command.create( playEmotion, true )));
			}
			else
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, Command.create( playEmotion, false )));
			}
		}
		
	
		private function playEmotion( isSuccess:Boolean ):void
		{
			if( isSuccess )
			{
				CharUtils.setAnim(player,Score);
			}
			else
			{
				CharUtils.setAnim(player,Stomp);
			}
			
			exitStar();
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, onRoundComplete));
		}
		
		private function onRoundComplete():void
		{
			_round++;
			
			if( _practice )
			{
				resetGame();
				return;
			}
			else if ( _round <= 3 ) 
			{
				startRound()
				return;
			}
	
			// game is complete
			var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
			var curMatch:MatchType = Matches.getMatchType(Matches.DIVING);
			pop.onResultsDone.addOnce(Command.create(onResultsDone, curMatch.eventName));
			pop.setup();
		}
		
		public function dataLoaded( pop:Poptropolis ):void 
		{
			pop.reportScore( Matches.DIVING, _playerScore, false);
		}

		//////////////////////////////////////////////////////////////////////////
		//////////////////////////////// SPECTATORS //////////////////////////////
		//////////////////////////////////////////////////////////////////////////

		protected override function setupSpectators():void
		{
			var emotions:Array = ["cheer", "ooh", "angry", "sad", "clap"];
			
			for(var i:int = 1; i <= 5; i++)
			{
				var clip:MovieClip = this._hitContainer["crowd" + i];
				clip.gotoAndStop(1);
				
				var skin:int = Utils.randInRange(1, 3);
				var integer:int = Utils.randInRange(0, emotions.length - 1);
				var emotion:String = emotions[integer];
				
				clip["head"]["expression"].gotoAndStop(integer + 1);
				clip["body"]["shirt"].gotoAndStop(Utils.randInRange(1, 5));
				clip["hair"].gotoAndStop(Utils.randInRange(1, 5));
				
				//Skin Color
				clip["feet"].gotoAndStop(skin);
				clip["hand1"].gotoAndStop(skin);
				clip["hand2"].gotoAndStop(skin);
				clip["head"]["head"].gotoAndStop(skin);
				clip["head"]["expression"]["eyeLids"].gotoAndStop(skin);
				
				var spectator:Entity = TimelineUtils.convertClip(clip, this);
				changeExpression(spectator, emotions, skin);
			}
		}

	}
}
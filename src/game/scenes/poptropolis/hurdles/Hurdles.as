package game.scenes.poptropolis.hurdles
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.HurdleRun;
	import game.data.animation.entity.character.poptropolis.HurdleStart;
	import game.data.character.CharacterData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.hurdles.components.Hurdle;
	import game.scenes.poptropolis.hurdles.components.Hurdler;
	import game.scenes.poptropolis.hurdles.systems.HurdleLoopSystem;
	import game.scenes.poptropolis.hurdles.systems.HurdlerSystem;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.scenes.poptropolis.shared.data.Opponent;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	
	public class Hurdles extends PoptropolisScene
	{
		private var _runner1:Entity;
		private var _runner2:Entity;
		private var _runnerPlayer:Entity;
		private var _winner:Entity;
		private var _finishLineForeground:Entity;
		private var _runners:Vector.<Entity>;
		private var _numRunnersInRace:int;
		private var _numCharsCompletedRace:int;
		private var _hurdlerSystem:HurdlerSystem;
		private var _hurdleSystem:HurdleLoopSystem;
		private var _hud:HurdlesHud;
		private var _hurdleGroups:Vector.<Vector.<Entity>>;
		
		private const DEBUG_SHORT_RACES:Boolean = false;
		
		private const START_X:int = 440;
		private const RUNNER_SPACING_Y:int = 35;
		private const RUN_ACCEL:Number = 800;
		private const HURDLE_DISTANCE:Number = 1000;
		private const FINISH_LINE_X:Number = 12600;
		private const ACCEL_AFTER_PASS_FINISH:int = -450;
		private const GROUND_Y:int = 335;
		private const NUM_RUNNERS:int = 3;
		
		public static const RUN_VELOCITY_MAX:Number = 550
		public static const RUNNER_SPACING_X:int = 33
		public static const NPC_JUMP_INACCURACY:int = 300;
		public static const JUMP_VEL_Y:int = -750;
		public static const JUMP_ACCEL_Y:int = 1830;
		
		private var _finishLine:Entity;
		private var _raceStartTime:Number;
		private var _playerTime:Number;
		
		private var _pop:Poptropolis;
		
		private var _opponents:Vector.<Opponent>;
		
		private function get finishLineX():Number { return (DEBUG_SHORT_RACES) ? 3000 : FINISH_LINE_X; }
		
		public function Hurdles()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/hurdles/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			_pop = new Poptropolis( super.shellApi, onPoptropolisLoaded );	// load Poptropolis data before calling init
			_pop.setup();
		}
		
		private function onPoptropolisLoaded(gameInfo:Poptropolis):void
		{
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupScene( this, super.hitContainer);
			
			_opponents = gameInfo.getNpcLeaders();
			
			var runner1:CharacterData = new CharacterData();
			runner1.init( "runner1", new Point( START_X - RUNNER_SPACING_X * 2, GROUND_Y - RUNNER_SPACING_Y * 2 ), _opponents[0].getLook() );
			
			var runner2:CharacterData = new CharacterData();
			runner2.init( "runner2", new Point( START_X - RUNNER_SPACING_X, GROUND_Y - RUNNER_SPACING_Y ), _opponents[1].getLook() );
			
			var runner3:CharacterData = new CharacterData();
			//var playerLook:LookData = SkinUtils.getLook( super.player );
			var playerLook:LookData = (new LookConverter).lookDataFromPlayerLook(shellApi.profileManager.active.look)
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) ); // apply tribal jersey to look
			runner3.init( "runner3", new Point( START_X, GROUND_Y), playerLook );
			
			// load npcs & listen for complete
			characterGroup.createNpcsFromData(new <CharacterData>[runner1, runner2, runner3], npcsLoaded );
		}
		
		private function npcsLoaded(...args):void
		{
			initGame();
			
			super.loaded();
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, onSceneAnimateInComplete ));	// delay before 
		}
		
		/////////////////////////////// INIT  ///////////////////////////////
		
		private function initGame():void
		{
			// runners
			
			_runner1 = super.getEntityById( "runner1" );
			_runner2 = super.getEntityById( "runner2" );
			_runnerPlayer = super.getEntityById( "runner3" );
			
			DisplayUtils.moveToOverUnder( _runner2.get(Display).displayObject, _runner1.get(Display).displayObject, true );
			DisplayUtils.moveToOverUnder( _runnerPlayer.get(Display).displayObject, _runner2.get(Display).displayObject, true );
			
			createHurdler( _runner1, 0 );
			createHurdler( _runner2, 1 );
			createHurdler( _runnerPlayer, 2, true );
			
			_runners = new <Entity>[ _runner1, _runner2, _runnerPlayer];
			
			// create finish line
			var finishX:int = finishLineX - super._hitContainer["finishLine"].x;
			
			var finishLineBack:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer["finishLineBackground"] );
			Spatial(finishLineBack.get(Spatial)).x += finishX;
			DisplayUtils.moveToOverUnder( finishLineBack.get(Display).displayObject, _runner1.get(Display).displayObject, false);
			
			_finishLine  = EntityUtils.createSpatialEntity( this, super._hitContainer["finishLine"] );
			Spatial(_finishLine.get(Spatial)).x += finishX;
			TimelineUtils.convertClip( super._hitContainer["finishLine"], this, _finishLine, null, false );
			DisplayUtils.moveToOverUnder( _finishLine.get(Display).displayObject, finishLineBack.get(Display).displayObject);
			_finishLine.add( new Sleep( false, true ) );
			
			_finishLineForeground = EntityUtils.createSpatialEntity( this, super._hitContainer["finishLineForeground"] );
			Spatial(_finishLineForeground.get(Spatial)).x += finishX;
			DisplayUtils.moveToOverUnder( _finishLineForeground.get(Display).displayObject, _runnerPlayer.get(Display).displayObject);
			
			// add sytem for looping hurdle positions
			_hurdleSystem = new HurdleLoopSystem();
			_hurdleSystem.init ( finishLineX - 500, _runnerPlayer.get(Spatial), HURDLE_DISTANCE );
			super.addSystem( _hurdleSystem, SystemPriorities.update );
			
			// add system to control hurdlers & detect collisions
			_hurdlerSystem = new HurdlerSystem();
			_hurdlerSystem.init( HURDLE_DISTANCE, finishLineX - 500, finishLineX )
			_hurdlerSystem.passedFinishLine.add(onCharPassedFinish);
			_hurdlerSystem.stoppedRunningAfterFinish.add(onStoppedRunningAfterFinish);
			super.addSystem( _hurdlerSystem, SystemPriorities.autoAnim );
			
			// create hud
			_hud = super.addChildGroup(new HurdlesHud(super.overlayContainer)) as HurdlesHud;
			_hud.exitClicked.add(onExitPracticeClicked);
			_hud.startGunFire.add(startRace); 	// dispatched from HurdlesHud when countdown completes;
			
			// add systems
			super.addSystem( new BitmapSequenceSystem(), SystemPriorities.animate );
			
			AudioUtils.play(this, SoundManager.AMBIENT_PATH +"arena_crowd_01_L.mp3",1,true);
			
			super.shellApi.defaultCursor = ToolTipType.TARGET;
		}
		
		private function createHurdler( charEntity:Entity, trackIndex:int, isPlayer:Boolean = false ):void
		{
			ToolTipCreator.removeFromEntity( charEntity );
			var displayObject:MovieClip = CharUtils.getDisplayObject(charEntity) as MovieClip;
			displayObject.mouseEnabled = false;
			displayObject.mouseChildren = false;
			
			CharUtils.setAnim( charEntity, Stand );
			
			addMotion(charEntity);
			
			var hurdler:Hurdler = new Hurdler();
			hurdler.state = "startingLine";
			hurdler.isPlayer = isPlayer;
			hurdler.trackIndex = trackIndex;
			hurdler.startPosX = START_X - (2 - trackIndex) * RUNNER_SPACING_X;
			hurdler.groundPosY = GROUND_Y + trackIndex * RUNNER_SPACING_Y;
			EntityUtils.position( charEntity, hurdler.startPosX, hurdler.groundPosY );
			charEntity.add( hurdler );
			
			charEntity.add( new Sleep( false, true )  );
			
			if( isPlayer )	// setup input to trigger jump
			{
				SceneUtil.getInput( this ).inputDown.add( hurdler.onActiveInput );
			}
			
			// create hurdles
			var children:Children = new Children();
			charEntity.add( children );
			
			var hurdleEntiy:Entity;
			var mc:MovieClip
			var hurdle:Hurdle;
			var spatial:Spatial;
			for (var i:int = 0; i < 2 ; i++) 
			{
				mc = super._hitContainer["hurdle" + trackIndex + "_" + i];
				hurdleEntiy = BitmapTimelineCreator.convertToBitmapTimeline(null, mc);
				hurdleEntiy.add(new Spatial(mc.x, mc.y));
				//hurdleEntiy = BitmapTimelineCreator.convertFromStage( mc,true,true );
				hurdle = new Hurdle();
				hurdleEntiy.add( hurdle );
				hurdleEntiy.add( new Audio() );
				DisplayUtils.moveToOverUnder( hurdleEntiy.get(Display).displayObject, charEntity.get(Display).displayObject, false );
				spatial = hurdleEntiy.get(Spatial);
				spatial.y = hurdler.groundPosY - 78;
				
				hurdleEntiy.add( new Sleep( false, true ) );
				
				this.addEntity(hurdleEntiy);
				
				children.children.push( hurdleEntiy );
			}
		}
		
		protected override function addMotion (entity:Entity):void 
		{
			var motion:Motion = entity.get( Motion )
			if ( !motion )
			{
				motion = new Motion();
				entity.add( motion );
			}
			motion.friction 	= new Point(0, 0);
			motion.maxVelocity 	= new Point(1000,1000);
			motion.minVelocity 	= new Point(0, 0);
		}
		
		/////////////////////////////// START  ///////////////////////////////
		
		private function onSceneAnimateInComplete ():void 
		{
			openInstructionsPopup()
			SceneUtil.setCameraTarget( this, _runnerPlayer );
		}
		
		private function resetRace():void 
		{
			shellApi.defaultCursor = ToolTipType.TARGET;
			var spatial:Spatial;
			var motion:Motion;
			var char:Entity;
			var hurdler:Hurdler;
			var children:Vector.<Entity>;
			var hurdle:Entity
			
			for (var i:int = 0; i < _runners.length; i++ )
			{
				// reset runners
				char = _runners[i]
				CharUtils.setAnim( char, HurdleStart );
				
				hurdler = Hurdler (char.get(Hurdler));
				hurdler.crossedFinish = false;
				
				EntityUtils.position( char, hurdler.startPosX, hurdler.groundPosY );
				
				motion = Motion (char.get(Motion))
				motion.acceleration.x = 0	
				motion.acceleration.y = 0	
				motion.velocity.x = 0	
				motion.velocity.y = 0
				motion.maxVelocity.x = Hurdles.RUN_VELOCITY_MAX;
				
				if (char != _runnerPlayer) 
				{
					hurdler.nextJumpX = hurdler.nextHurdleX = HURDLE_DISTANCE;
				}
				
				//reset hurdles
				children = Children(char.get(Children)).children;
				for (var j:int = 0; j < children.length; j++) 
				{
					hurdle = children[j];
					spatial = hurdle.get(Spatial);
					spatial.x = 1200 + j * HURDLE_DISTANCE + hurdler.trackIndex * RUNNER_SPACING_X;
					
					Timeline(hurdle.get(Timeline)).gotoAndStop ("stand");
				}
			}
			
			// reset finish line
			Timeline(_finishLine.get(Timeline)).gotoAndStop(0);
			
			_winner = null
			_numCharsCompletedRace = 0;
		}
		
		private function startRace():void 
		{
			var char:Entity;
			var hurdler:Hurdler;
			var motion:Motion ;
			for (var i:int = 0; i < _runners.length; i++) 
			{
				char = _runners[i];
				hurdler = char.get(Hurdler);
				
				// continue hurdle start
				CharUtils.setAnim( char, HurdleRun);
				hurdler.state = "running";
				
				if( !_practice || hurdler.isPlayer  )
				{
					motion = char.get(Motion);
					motion.acceleration.x = RUN_ACCEL
				}
			}
			
			_raceStartTime = getTimer();
		}
		
		private function setPracticeMode ( isPractice:Boolean):void
		{
			super._practice = isPractice;
			if (!_practice) 
			{
				_runner1.get(Display).visible = true;
				_runner2.get(Display).visible = true;
				_hud.showExitPractice(false);
				_numRunnersInRace = 3;
			} 
			else 
			{
				_runner1.get(Display).visible = false;
				EntityUtils.getDisplayObject(_runner1).visible = false;
				_runner2.get(Display).visible = false;
				EntityUtils.getDisplayObject(_runner2).visible = false;
				_hud.showExitPractice(true);
				_numRunnersInRace = 1;
			}
		}
		
		private function abortRace ():void 
		{
			_hud.showExitPractice(false);
			openInstructionsPopup();
			stopRunners();
		}
		
		private function stopRunners():void 
		{
			var motion:Motion
			
			for (var i:int = 0; i < _runners.length; i++ )
			{
				CharUtils.getTimeline(_runners[i]).stop();
				Motion (_runners[i].get(Motion)).zeroMotion();
			}
		}
		
		/////////////////////////////// CHARACTER FINISHED  ///////////////////////////////
		
		private function onCharPassedFinish (char:Entity):void 
		{
			trace ("===========================[Hurdles]onFinishLineHit:" + char)
			
			if (!_winner) 
			{
				_winner = char;
				Timeline(_finishLine.get(Timeline)).play();
				super.playSoundEffect("rip_tape_01");
			}
			
			var raceScore:Number = (getTimer() - _raceStartTime) / 1000;
			
			if (char == _runnerPlayer) 
			{
				_playerTime = raceScore;
			} 
			else 
			{
				if (char == _runner1) 
				{
					_opponents[0].setScore( raceScore );
				}
				else if (char == _runner2) 
				{
					_opponents[1].setScore( raceScore );
				}
			}
		}
		
		private function onStoppedRunningAfterFinish(char:Entity):void 
		{
			CharUtils.setAnim(char,Stand);
			SceneUtil.addTimedEvent( this, new TimedEvent( .3, 1, Command.create(setAfterRaceAnim, char) ));
		}
		
		private function setAfterRaceAnim (char:Entity):void 
		{
			if (char == _winner) 
			{
				CharUtils.setAnim(char, Proud);
			} 
			else 
			{
				CharUtils.setAnim(char, Cry);
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, checkRaceComplete ));
		}
		
		/////////////////////////////// RACE END  ///////////////////////////////
		
		private function checkRaceComplete():void
		{
			_numCharsCompletedRace++;
			if (_numCharsCompletedRace == _numRunnersInRace)
			{
				trace ("[Hurdles] RACE COMPLETE!")
				
				if (_practice) 
				{
					_hud.showExitPractice(false);
					openInstructionsPopup()
				} 
				else 
				{
					reportResults()
				}
			}
		}
		
		private function reportResults( ):void {
			_pop.reportScore(Matches.HURDLES, _playerTime, true );
		} 
		
		override protected function onStartClicked (): void {
			trace ("[Hurdles] ---------------- start!")
			setPracticeMode(false);
			
			super._instructionsPopup.popupRemoved.addOnce( resetRace );
			super._instructionsPopup.popupRemoved.addOnce( _hud.startCountdown );
		}
		
		override protected function onPracticeClicked (): void {
			trace ("[Hurdles] ---------------- practice!!")
			setPracticeMode(true);
			
			super._instructionsPopup.popupRemoved.addOnce( resetRace );
			super._instructionsPopup.popupRemoved.addOnce( _hud.startCountdown );
		}
		
		private function onExitPracticeClicked (): void {
			trace ("[Hurdles] ---------------- stop practice!!")
			abortRace();
		}
	}
}
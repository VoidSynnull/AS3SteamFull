package game.scenes.hub.balloons
{
	import com.smartfoxserver.v2.entities.SFSUser;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.character.Skin;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.scene.template.HeadToHeadGame;
	import game.scenes.hub.balloons.components.BalloonsGrid;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.TimelineUtils;
	
	public class Balloons extends HeadToHeadGame
	{
		public static const GRID_ID:String					= "grid";
		public static const PUMPS_ID:String					= "pumps";
		public static const TXT_LAUNCH_ID:String			= "launchTxt";
		public static const TXT_WAIT_ID:String				= "waitTxt";
		
		private var _balloonsGroup:BalloonsGroup;
		private var _balloonRed:Entity;
		private var _balloonBlue:Entity;
		private var _myBalloon:Entity;
		
		private var _pumps:Entity;
		private var _pump1:Entity;
		private var _pump2:Entity;
		private var _pump3:Entity;
		private var _pump4:Entity;
		private var _pump5:Entity;
		
		private var _grid:Entity;
		private var _launchTxt:Entity;
		private var _waitTxt:Entity;
		
		public function Balloons()
		{
			super();
			gameID 		= "Balloons";
			endDelay 	= 4;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/hub/balloons/";
			super.init(container);
		}
		
		override protected function setupUI():void
		{
			super.setupUI();
			
			// create balloons group
			_balloonsGroup = new BalloonsGroup(groupPrefix);
			_balloonsGroup.setupGroup(this, smartFoxGroup);
			
			// grid
			_grid = EntityUtils.createSpatialEntity(this, _hitContainer["grid"], _hitContainer);
			_grid.add(new BalloonsGrid(_grid));
			_grid.add(new Id(GRID_ID));
			
			// launch text
			_launchTxt = EntityUtils.createSpatialEntity(this, _hitContainer["launchTxt"]);
			_launchTxt.add(new Id(TXT_LAUNCH_ID));
			
			// wait text
			_waitTxt = EntityUtils.createSpatialEntity(this, _hitContainer["waitTxt"]);
			_waitTxt.add(new Id(TXT_WAIT_ID));
			
			// pumps
			_pumps = EntityUtils.createSpatialEntity(this, _hitContainer["pumps"], _hitContainer);
			_pumps.add(new Id(PUMPS_ID));
			var pumpsDisplay:Display = _pumps.get(Display);
			pumpsDisplay.displayObject.mouseEnabled = true;
			pumpsDisplay.displayObject.mouseChildren = true;			
			_pump1 = ButtonCreator.createButtonEntity(_hitContainer["pumps"]["pump1"], this, onPump);
			_pump1.add(new Id("pump1"));
			_pump2 = ButtonCreator.createButtonEntity(_hitContainer["pumps"]["pump2"], this, onPump);
			_pump2.add(new Id("pump2"));
			_pump3 = ButtonCreator.createButtonEntity(_hitContainer["pumps"]["pump3"], this, onPump);
			_pump3.add(new Id("pump3"));
			_pump4 = ButtonCreator.createButtonEntity(_hitContainer["pumps"]["pump4"], this, onPump);
			_pump4.add(new Id("pump4"));
			_pump5 = ButtonCreator.createButtonEntity(_hitContainer["pumps"]["pump5"], this, onPump);
			_pump5.add(new Id("pump5"));
			
			// balloons
			_balloonRed = EntityUtils.createMovingEntity(this, _hitContainer["balloonRed"], _hitContainer);
			BitmapUtils.convertContainer(_hitContainer["balloonRed"]);
			MotionUtils.addWaveMotion(_balloonRed, new WaveMotionData("y", 15, 0.02, "sin", 1), this);
			MotionUtils.addWaveMotion(_balloonRed, new WaveMotionData("x", 8, 0.008, "sin", 1), this);
			TimelineUtils.convertClip(_hitContainer["balloonRed"], this, _balloonRed);
			
			_balloonBlue = EntityUtils.createMovingEntity(this, _hitContainer["balloonBlue"], _hitContainer);
			BitmapUtils.convertContainer(_hitContainer["balloonBlue"]);
			MotionUtils.addWaveMotion(_balloonBlue, new WaveMotionData("y", 15, 0.02), this);
			MotionUtils.addWaveMotion(_balloonBlue, new WaveMotionData("x", 8, 0.008), this);
			TimelineUtils.convertClip(_hitContainer["balloonBlue"], this, _balloonBlue);
		}
		
		override protected function doStart():void
		{
			super.doStart();
			
			_waitTxt.get(Display).displayObject["txt"].text = "wait for your turn";
		}
		
		override protected function hideUI(restartGame:Boolean = false):void
		{
			super.hideUI();
			
			// if restarting, don't hide balloons
			if (!restartGame)
			{
				_balloonRed.get(Display).visible = false;
				_balloonBlue.get(Display).visible = false;
			}
			_grid.get(Display).visible = false;
			_balloonRed.get(Timeline).gotoAndStop(0);
			_balloonBlue.get(Timeline).gotoAndStop(0);
			_launchTxt.get(Display).visible = false;
			_waitTxt.get(Display).visible = false;
		}
		
		private function onPump(pump:Entity):void
		{
			if(_balloonsGroup.whosTurn == shellApi.smartFox.mySelf.playerId){
				
				var id:String = Id(pump.get(Id)).id;
				var column:int = int(id.slice(4));
				if(_balloonsGroup.columnAvailable(column))
				{
					_balloonsGroup.fillBalloon(column);
				}
			}
		}
		
		public function playerTurn($playerId:int):void
		{
			// check if your turn
			if ($playerId == shellApi.smartFox.mySelf.playerId)
			{
				updateLaunchTxt();
				_launchTxt.get(Display).visible = true;
				_waitTxt.get(Display).visible = false;
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"selection_03.mp3");
			}
			// someone elses turn
			else if ($playerId > 0)
			{
				_launchTxt.get(Display).visible = false;
				_waitTxt.get(Display).visible = true;
			}
		}
		
		private function updateLaunchTxt():void
		{
			var display:Display = _launchTxt.get(Display);
			
			// turns off arrows of unavailable columns
			for (var c:int = 1; c < BalloonsGrid.COLUMN_NUM; c++)
			{
				if(!_balloonsGroup.columnAvailable(c))
				{
					display.displayObject["col"+c].visible = false;
				}
				else
				{
					display.displayObject["col"+c].visible = true;
				}
			}
		}
		
		override protected function activatePlayer($user:SFSUser):void
		{
			var avatar:Entity;
			var skin:Skin = new Skin();
			var balloonSpatial:Spatial;
			var pumpSpatial:Spatial = _pumps.get(Spatial);
			
			if ($user.playerId == 1)
			{
				_balloonRed.get(Display).visible = true;
				_balloonRed.get(Timeline).gotoAndStop(0);
				balloonSpatial = _balloonRed.get(Spatial);
				if ($user.isItMe)
				{
					shellApi.player.get(Spatial).x = balloonSpatial.x;
					shellApi.player.get(Spatial).y = pumpSpatial.y;
					CharUtils.setAnim(shellApi.player, Stand);
					CharUtils.setDirection(shellApi.player, true);
					shellApi.player.get(Display).visible = true;
				}
				else
				{
					_opponentAvatar = createOpponentAvatar($user, balloonSpatial.x, pumpSpatial.y+32, CharUtils.DIRECTION_RIGHT);
				}
			}
			else
			{
				_balloonBlue.get(Display).visible = true;
				_balloonBlue.get(Timeline).gotoAndStop(0);
				balloonSpatial = _balloonBlue.get(Spatial);
				if ($user.isItMe)
				{
					shellApi.player.get(Spatial).x = balloonSpatial.x;
					shellApi.player.get(Spatial).y = pumpSpatial.y;
					CharUtils.setAnim(shellApi.player, Stand);
					CharUtils.setDirection(shellApi.player, false);
					shellApi.player.get(Display).visible = true;
				}
				else
				{
					_opponentAvatar = createOpponentAvatar($user, balloonSpatial.x, pumpSpatial.y+32, CharUtils.DIRECTION_LEFT);
				}
			}
		}
		
		override protected function deactivatePlayer($user:SFSUser):void
		{
			super.deactivatePlayer($user);
			
			if($user.playerId == 1)
			{
				if($user.isItMe)
					_myBalloon = _balloonRed;
				_balloonRed.get(Display).visible = false;
			}
			else
			{
				if($user.isItMe)
					_myBalloon = _balloonBlue;
				_balloonBlue.get(Display).visible = false;
			}
			
			_balloonsGroup.endGame();
		}
		
		override protected function startGame(firstTurn:int):void
		{
			playerTurn(firstTurn);
			_balloonsGroup.playerTurn(firstTurn);
			
			// show grid
			_grid.get(Display).visible = true;
		}

		override protected function restartGame():void
		{
			super.restartGame();
			
			// reset grid
			_grid.remove(BalloonsGrid);
			_grid.add(new BalloonsGrid(_grid));
			_balloonsGroup.endGame();
		}
		
		override protected function concludeGame($winnerId:int):void
		{
			super.concludeGame($winnerId);
			
			_launchTxt.get(Display).visible = false;
			_waitTxt.get(Display).visible = true;
		}
		
		override protected function playAgain(buttonEntity:Entity):void
		{
			super.playAgain(buttonEntity);
			
			_balloonsGroup.endGame();
		}
		
		override protected function youWin():void
		{
			_waitTxt.get(Display).displayObject["txt"].text = "You win!";
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"puzzle_complete_01.mp3");
			CharUtils.setAnim(shellApi.player, Score);
			if(_opponentAvatar)
				CharUtils.setAnim(_opponentAvatar, Grief);
		}
		
		override protected function draw():void
		{
			_waitTxt.get(Display).displayObject["txt"].text = "It's a draw!";
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"puzzle_complete_01.mp3");
		}
		
		override protected function youLose():void
		{
			_waitTxt.get(Display).displayObject["txt"].text = "You lose!"
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"retro_loss_01.mp3");
			CharUtils.setAnim(shellApi.player, Grief);
			if(_opponentAvatar)
				CharUtils.setAnim(_opponentAvatar, Score);
		}

		public function popLastBalloon():void
		{
			if (_whoWon == 1)
			{
				// pop blue balloon
				_balloonBlue.get(Timeline).play();
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"balloon_pop_03.mp3", 0.7);
			}
			else
			{
				_balloonRed.get(Timeline).play();
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"balloon_pop_03.mp3", 0.7);
			}
			
			if (_whoWon == _myPlayerID)
			{
				CharUtils.setAnim(shellApi.player, Laugh);
				if(_opponentAvatar)
					CharUtils.setAnim(_opponentAvatar, Cry);
			}
			else
			{
				CharUtils.setAnim(shellApi.player, Cry);
				if(_opponentAvatar)
					CharUtils.setAnim(_opponentAvatar, Laugh);
			}
		}	
	}
}
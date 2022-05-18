package game.scenes.hub.starLink
{
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.Room;
	import com.smartfoxserver.v2.entities.SFSUser;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.character.Skin;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Stand;
	import game.scene.template.HeadToHeadGame;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	public class StarLink extends HeadToHeadGame
	{		
		private var _starLinkGroup:StarLinkGroup;
		
		private var _ship1:Entity;
		private var _ship2:Entity;
		private var _score1:Entity;
		private var _score2:Entity;
		private var _myShip:Entity;
		
		private var _turn:Entity;
		private var _turnCenter:Spatial;

		public function StarLink()
		{
			super();
			gameID = "StarLink";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/hub/starLink/";
			super.init(container);
		}
		
		override protected function setupUI():void
		{
			super.setupUI();
			
			// setup board
			_starLinkGroup = this.addChildGroup(new StarLinkGroup(this, _hitContainer["board"], smartFoxGroup)) as StarLinkGroup;
			
			// setup ships
			_ship1 = EntityUtils.createSpatialEntity(this, _hitContainer["ship1"], _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(_ship1, _hitContainer["ship1"]);		
			_ship2 = EntityUtils.createSpatialEntity(this, _hitContainer["ship2"], _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(_ship2, _hitContainer["ship2"]);
			
			// setup scores
			_score1 = EntityUtils.createSpatialEntity(this, _hitContainer["scoreP1"], _hitContainer);			
			_score2 = EntityUtils.createSpatialEntity(this, _hitContainer["scoreP2"], _hitContainer);
			
			_turn = EntityUtils.createSpatialEntity(this, _hitContainer["turn"], _hitContainer);
			var turnSpatial:Spatial = _turn.get(Spatial);
			_turnCenter = new Spatial(turnSpatial.x, turnSpatial.y);
		}
		
		override protected function hideUI(restartGame:Boolean = false):void
		{
			super.hideUI();
			
			// if restarting, don't hide ships
			if (!restartGame)
			{
				_ship1.get(Display).visible = false;
				_ship2.get(Display).visible = false;
			}
			Timeline(_ship1.get(Timeline)).gotoAndStop(0);
			Timeline(_ship2.get(Timeline)).gotoAndStop(0);
			
			_score1.get(Display).visible = false;
			_score2.get(Display).visible = false;		
			_score1.get(Display).displayObject["score"].text = 0;
			_score2.get(Display).displayObject["score"].text = 0;
			
			_turn.get(Display).visible = false;	
			
			_starLinkGroup.container.visible = false;
		}
		
		override protected function startGame(firstTurn:int):void
		{
			_score1.get(Display).visible = true;
			_score2.get(Display).visible = true;
			_turn.get(Display).visible = true;
			
			_starLinkGroup.container.visible = true;
			_starLinkGroup.container.mouseEnabled = true;
			_starLinkGroup.container.mouseChildren = true;
			
			_starLinkGroup.playerTurn(firstTurn);
		}
		
		override protected function restartGame():void
		{
			super.restartGame();
			
			// reset board
			_starLinkGroup.endGame();
		}
		
		public function playerTurn($playerId:int):void
		{
			// check if your turn
			if($playerId == shellApi.smartFox.mySelf.playerId)
			{
				_turn.get(Display).displayObject["message"].text = "your turn!"
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"selection_03.mp3");
			}
			// their turn
			else
			{
				_turn.get(Display).displayObject["message"].text = "their turn"
			}
			
			if($playerId == 1)
			{
				Timeline(_ship1.get(Timeline)).gotoAndStop(1);
				Timeline(_ship2.get(Timeline)).gotoAndStop(0);
				Spatial(_turn.get(Spatial)).x = Spatial(_ship1.get(Spatial)).x;
			}
			else
			{
				Timeline(_ship1.get(Timeline)).gotoAndStop(0);
				Timeline(_ship2.get(Timeline)).gotoAndStop(1);
				Spatial(_turn.get(Spatial)).x = Spatial(_ship2.get(Spatial)).x;
			}
		}
		
		override protected function activatePlayer($user:SFSUser):void
		{
			var avatar:Entity;
			var skin:Skin = new Skin();
			var shipSpatial:Spatial;
			if($user.playerId == 1)
			{
				_ship1.get(Display).visible = true;
				if($user.isItMe)
				{
					// move player to this ship
					_myShip = _ship1;
					Spatial(shellApi.player.get(Spatial)).x = Spatial(_ship1.get(Spatial)).x;
					Spatial(shellApi.player.get(Spatial)).y = Spatial(_ship1.get(Spatial)).y-10;
					CharUtils.setAnim(shellApi.player, Stand);
					CharUtils.setDirection(shellApi.player, true);
					shellApi.player.get(Display).visible = true;
				}
				else
				{
					_ship2.get(Display).visible = true;
					shipSpatial = _ship1.get(Spatial);
					_opponentAvatar = createOpponentAvatar($user, shipSpatial.x, shipSpatial.y+25, CharUtils.DIRECTION_RIGHT);
				}
			}
			else
			{
				_ship2.get(Display).visible = true;
				if($user.isItMe)
				{
					// move player to this ship
					_myShip = _ship2;
					Spatial(shellApi.player.get(Spatial)).x = Spatial(_ship2.get(Spatial)).x;
					Spatial(shellApi.player.get(Spatial)).y = Spatial(_ship2.get(Spatial)).y-10;
					CharUtils.setAnim(shellApi.player, Stand);
					CharUtils.setDirection(shellApi.player, false);
					shellApi.player.get(Display).visible = true;
				}
				else
				{
					_ship1.get(Display).visible = true;
					shipSpatial = _ship2.get(Spatial);
					_opponentAvatar = createOpponentAvatar($user, shipSpatial.x, shipSpatial.y+25, CharUtils.DIRECTION_LEFT);
				}
			}
			
			DisplayUtils.moveToTop(_ship1.get(Display).displayObject);
			DisplayUtils.moveToTop(_ship2.get(Display).displayObject);
			DisplayUtils.moveToTop(_turn.get(Display).displayObject);
		}
				
		override protected function deactivatePlayer($user:SFSUser):void
		{
			super.deactivatePlayer($user);
			
			if($user.playerId == 1)
			{
				_ship1.get(Display).visible = false;
			}
			else
			{
				_ship2.get(Display).visible = false;
			}
			// hide UI
			_starLinkGroup.endGame();
		}
		
		override protected function concludeGame($winnerId:int):void
		{
			super.concludeGame($winnerId);
			
			Spatial(_turn.get(Spatial)).x = _turnCenter.x;
			Timeline(_ship1.get(Timeline)).gotoAndStop(0);
			Timeline(_ship2.get(Timeline)).gotoAndStop(0);
		}
		
		override protected function playAgain(buttonEntity:Entity):void
		{
			super.playAgain(buttonEntity);
			
			// reset board
			_starLinkGroup.endGame();
		}
		
		override protected function youWin():void
		{
			if (checkTie())
			{
				draw();
			}
			else
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"puzzle_complete_01.mp3");
				_turn.get(Display).displayObject["message"].text = "you win!";
				CharUtils.setAnim(shellApi.player, Laugh);
				if(_opponentAvatar)
					CharUtils.setAnim(_opponentAvatar, Cry);
			}
		}
		
		override protected function draw():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"puzzle_complete_01.mp3");
			_turn.get(Display).displayObject["message"].text = "it's a draw!";
		}
		
		override protected function youLose():void
		{
			if (checkTie())
			{
				draw();
			}
			else
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"retro_loss_01.mp3");
				_turn.get(Display).displayObject["message"].text = "you lose!";
				CharUtils.setAnim(shellApi.player, Cry);
				if(_opponentAvatar)
					CharUtils.setAnim(_opponentAvatar, Laugh);
			}
		}
		
		private function checkTie():Boolean
		{
			return (_score1.get(Display).displayObject["score"].text == _score2.get(Display).displayObject["score"].text);
		}
		
		override protected function onSFSRoomVars($event:SFSEvent):void
		{
			// update score
			var room:Room = $event.params.room as Room;
			var changedVars:Array = $event.params.changedVars as Array;
			if ((changedVars.indexOf("scoreP1") != -1) || (changedVars.indexOf("scoreP2") != -1))
			{
				_score1.get(Display).displayObject["score"].text = room.getVariable("scoreP1").getIntValue();
				_score2.get(Display).displayObject["score"].text = room.getVariable("scoreP2").getIntValue();
			}
		}
		
		public function score($playerId:int):void
		{
			if($playerId == shellApi.smartFox.mySelf.playerId)
			{
				CharUtils.setAnim(shellApi.player, Proud);
				if(_opponentAvatar)
					CharUtils.setAnim(_opponentAvatar, Grief);
			}
			else
			{
				CharUtils.setAnim(shellApi.player, Grief);
				if(_opponentAvatar)
					CharUtils.setAnim(_opponentAvatar, Proud);
			}
		}
	}
}
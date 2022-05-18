package game.scenes.hub.starcade
{
	import com.greensock.easing.Bounce;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.hit.HitTest;
	import game.creators.ui.ButtonCreator;
	import game.data.profile.ProfileData;
	import game.proxy.Connection;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.hub.arcadeGame.ArcadeGame;
	import game.scenes.hub.chooseGame.ChooseGame;
	import game.scenes.hub.town.Town;
	import game.systems.hit.HitTestSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class Starcade extends PlatformerGameScene
	{
		public static const TRACK_ARCADE_ENTER:String 		= "StarcadeEnter";
		public static const TRACK_ARCADE_EXIT:String 		= "StarcadeExit";
		public static const TRACK_ARCADE_DISCONNECT:String 	= "StarcadeDisconnected";
		
		public static const TRACK_ARCADE_GAME_SELECT:String = "ArcadeGameSelect";
		public static const TRACK_ARCADE_GAME_START:String 	= "ArcadeGameStart";
		public static const TRACK_ARCADE_GAME_REPLAY:String = "ArcadeGameReplay";
		public static const TRACK_ARCADE_GAME_WIN:String 	= "Win";
		public static const TRACK_ARCADE_GAME_LOSE:String 	= "Lose";
		
		private var _holdConnection:Boolean;
		private var _currentGame:String;

		public function Starcade()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/hub/starcade/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			// start multiplayer
			shellApi.smartFoxManager.disconnected.addOnce(onDisconnect);
			shellApi.sceneManager.enableMultiplayer(false, true, false);
			
			// track
			shellApi.track(TRACK_ARCADE_ENTER, null, null, "Starcade");
			
			// when adding new games, they have to be added to the database by Dan Franklin (along with new highscore rows)
			// Game Name: 		ID (IDs are lowercase in database)
			// Crash N Bash: 	CrashDerby
			// Poptastic: 		Poptastic
			// Blaster Attack: 	Blasteroids
			// Vampire Blitz:	VampireBlitz
			var games:Array = ["kiosk", "CrashDerby", "Poptastic", "Blasteroids"];
			for each (var game:String in games)
			{
				var entity:Entity = ButtonCreator.createButtonEntity(_hitContainer[game], this, Command.create(gotoGame, game));
				entity.get(Display).alpha = 0;
				getHighScores(game);
			}
			
			setupBouncyAnimations();
			
			// attach listener for whenever a new scene is loaded
			shellApi.sceneManager.sceneLoaded.add(checkCoins);
			
			super.loaded();
		}
		
		private function checkCoins(scene:Group):void
		{
			// if have point, then set delay
			if (shellApi.arcadePoints != 0)
			{
				SceneUtil.delay(this, 0.25, getCoins);
			}
		}
		
		private function getCoins():void
		{
			// apply arcade points to credits
			shellApi.profileManager.active.credits += shellApi.arcadePoints;
			shellApi.profileManager.save();
			// show coins
			SceneUtil.getCoins(this, Math.round(shellApi.arcadePoints/5));
			// clear arcade points
			shellApi.arcadePoints = 0;
		}
		
		private function setupBouncyAnimations():void
		{
			var bounceContainer:MovieClip = _hitContainer["bouncies"];
			if(bounceContainer)
			{
				addSystem(new HitTestSystem());
				var clip:MovieClip;
				for(var i:int = 0; i < bounceContainer.numChildren; i++)
				{
					clip = bounceContainer.getChildAt(i) as MovieClip;
					if (clip == null)
						continue;
					var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
					entity.add(new Id(clip.name));
					var hit:Entity = getEntityById(clip.name+"_hit");
					//trace(clip.name);
					if(hit)
					{
						//trace("add hit test to " + clip.name);
						hit.add(new HitTest(onBouncyHit));
					}
				}
			}
		}
		
		private function onBouncyHit(entity:Entity, id:String):void
		{
			var hitId:String = entity.get(Id).id;
			var anim:Entity = getEntityById(hitId.substr(0,hitId.length-4));
			//trace(hitId);
			TweenUtils.entityFromTo(anim, Spatial, .5, {scaleY:.7},{scaleY:1, ease:Bounce.easeInOut});
		}

		override public function destroy():void
		{
			// remove sceneLoaded listener
			shellApi.sceneManager.sceneLoaded.remove(checkCoins);
			
			shellApi.track(TRACK_ARCADE_EXIT, null, null, "Starcade");

			// leave room
			shellApi.smartFoxManager.leaveRoom();
			
			shellApi.smartFoxManager.disconnected.remove(onDisconnect);
			shellApi.smartFoxManager.loginError.removeAll();
			shellApi.smartFoxManager.loggedIn.removeAll();
			if(!_holdConnection)
			{
				shellApi.smartFox.disconnect();
			}
			super.destroy();
		}
		
		private function gotoGame(buttonEntity:Entity, game:String):void
		{
			_currentGame = game;
			var spatial:Spatial = buttonEntity.get(Spatial);
			CharUtils.followPath( player, new <Point>[new Point(spatial.x, spatial.y)], confirmGame, false, false, new Point(100,100), true  );
		}
		
		private function confirmGame($entity:Entity):void
		{
			if (_currentGame == "kiosk")
			{
				var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(2, "Leave the arcade to play other players?", chooseGames)) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= false;
				dialogBox.init(this.overlayContainer);
			}
			else
			{
				// if guest, then show dialog
				if (super.shellApi.profileManager.active.isGuest)
				{
					dialogBox = this.addChildGroup(new ConfirmationDialogBox(2, "Your high score won't be saved unless you register first.", selectArcadeGame)) as ConfirmationDialogBox;
					dialogBox.darkenBackground 	= true;
					dialogBox.pauseParent 		= false;
					dialogBox.init(this.overlayContainer);
				}
				else
				{
					selectArcadeGame();
				}
			}
		}
		
		// select single-player arcade game and play
		private function selectArcadeGame():void
		{
			shellApi.track(TRACK_ARCADE_GAME_SELECT, _currentGame, null, "Starcade");
			shellApi.arcadeGame = _currentGame;
			shellApi.loadScene(ArcadeGame);
		}
		
		// go to choose game screen
		private function chooseGames():void
		{
			_holdConnection = true;
			shellApi.loadScene(ChooseGame);
		}
		
		/**
		 * Get high scores per game
		 * @param score
		 */
		public function getHighScores(gameName:String):void
		{
			if (gameName == "kiosk")
				return;
			
			// clear fields
			_hitContainer[gameName + "_yours"].text = "0";
			_hitContainer[gameName + "_weekly"].text = "0";
			
			// set params to send to server
			var vars:URLVariables = new URLVariables();
			
			// if not guest and is not mobile
			if ((!super.shellApi.profileManager.active.isGuest) && (!AppConfig.mobile))
			{
				var profile:ProfileData = super.shellApi.profileManager.active;
				vars.username = profile.login;
				vars.passhash = profile.pass_hash;
				vars.dbid = profile.dbid;
			}
			else
			{
				vars.username = "";
				vars.passhash = "";
				vars.dbid = "";
			}
			vars.gamename = gameName.toLowerCase();
			
			// make php call to server
			var connection:Connection = new Connection();
			connection.connect(super.shellApi.siteProxy.secureHost + "/games/interface/get_highscores.php", vars, URLRequestMethod.POST, Command.create(getScoresCallback, gameName), getScoresError);
		
			if (AppConfig.mobile)
			{
				var gm:String = gameName.toLowerCase();
				var so:SharedObject = SharedObject.getLocal("arcade", "/");
				so.objectEncoding = ObjectEncoding.AMF0;
				var score:String = "0";
				if (so.data[gm] != null)
					score = String(so.data[gm]);
				_hitContainer[gameName + "_yours"].text = score;
			}
		}
		
		/**
		 * When win.php callback is received from server 
		 * @param e
		 */
		private function getScoresCallback(e:Event, gameName:String):void
		{
			// parse data
			var return_vars:URLVariables = new URLVariables(e.target.data);
			// check answer
			switch (return_vars.answer)
			{
				case "ok": // if successful
					//answer=ok&high_scores_json={"personal_highscore":{"highscore":"0"},"weekly_highscore":{"highscore":0,"look":"string","name":"playerName"}}
					trace("getScoresCallback Success: " + gameName);
					// trim data to what follows equals sign
					var index:int = e.target.data.indexOf("json=");
					var data:String = unescape(e.target.data.substr(index+5));
					trace("getScoresCallback Data: " + data);
					// convert to json object
					var json:Object = JSON.parse(data);
					
					// set personal high score on game console
					var personal:String = "0";
					if (data.indexOf("personal_highscore") != -1)
						personal = json.personal_highscore.highscore;
					
					// set weekly high score on game console
					var weekly:String = "370"; // default if errors or no one has played yet
					if (data.indexOf("weekly_highscore") != -1)
					{
						var wscore:String = json.weekly_highscore.highscore;
						// don't use zero
						if (wscore != "0")
							weekly = wscore;
					}
					
					// update text fields
					if (!AppConfig.mobile)
						_hitContainer[gameName + "_yours"].text = personal;
					_hitContainer[gameName + "_weekly"].text = weekly;
					break;
				
				default: // if errors
					trace("getScoresCallback Error: " + return_vars.answer);
					break;
			}
		}
		
		/**
		 * If error when calling win.php
		 * @param e
		 */
		private function getScoresError(e:IOErrorEvent):void
		{
			trace("getScores error: " + e.errorID)
		}

		private function onDisconnect():void
		{
			shellApi.track(TRACK_ARCADE_DISCONNECT, null, null, "Starcade");

			// display disconnect popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Disconnected from server!", leaveArcade)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		private function leaveArcade():void
		{
			shellApi.loadScene(Town, 4720, 880);
		}
		
		public function disconnect():void
		{
			shellApi.smartFoxManager.disconnect();
		}
	}
}
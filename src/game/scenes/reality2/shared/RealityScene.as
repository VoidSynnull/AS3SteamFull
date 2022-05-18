package game.scenes.reality2.shared
{
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.reality2.Reality2Events;
	import game.scenes.reality2.gameShow.GameShow;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	
	public class RealityScene extends GameScene
	{
		public static const FIRST_PLACE:int			= 10;
		public static const SECOND_PLACE:int		= 6;
		public static const THIRD_PLACE:int			= 3;
		public static const FOURTH_PLACE:int		= 1;
		
		public var contestants:Vector.<Contestant>;
		public var reality:Reality2Events = new Reality2Events();
		
		public var charGroup:CharacterGroup;
		
		public static const GAMES_PATH:String		= "scenes/reality2/shared/games.xml";
		public static const CONTESTANTS_PATH:String	= "scenes/reality2/shared/contestants.xml";
		public static const CONTEST_PREFIX:String	= "game.scenes.reality2.";
		public static const NUM_AIS:int 			= 3;
		
		public function RealityScene()
		{
			super();
		}
		
		override public function loaded():void
		{
			getContestantData();
		}
		
		protected function getContestantData():void
		{
			shellApi.getUserField(reality.CONTESTANTS_FIELD, shellApi.island, contestantsRetrieved,true);
		}
		
		protected function saveContestantData():void
		{
			var value:String = "";
			for(var i:int = 0; i < contestants.length; i++)
			{
				if(i > 0)
					value += ",";
				var contestant:Contestant = contestants[i];
				value += ""+contestant.index+":"+contestant.difficulty+":"+contestant.score;
			}
			shellApi.setUserField(reality.CONTESTANTS_FIELD, value, shellApi.island,true);
		}
		// id : difficulty : score
		//sample contestant player:1:26,drHare:.4:5,ninja:.6:7,drLange:.8:22
		protected function contestantsRetrieved(contest:String):void
		{
			if(DataUtils.validString(contest))
			{
				var contestData:Array = contest.split(",");
				contestants = new Vector.<Contestant>();
				var containsPlayer:Boolean = false;
				for(var i:int = 0; i < contestData.length; i++)
				{
					var contestantString:String = contestData[i];
					var contestantData:Array = contestantString.split(":");
					
					var contestant:Contestant = new Contestant(contestantData[0]);
					
					contestant.difficulty = DataUtils.getNumber(contestantData[1]);
					if(contestant.difficulty == Contestant.PLAYER)
						containsPlayer = true;
					
					if(contestantData.length > 2)
						contestant.score = DataUtils.getNumber(contestantData[2]);
					else
						contestant.score = 0;
					
					contestants.push(contestant);
				}
				
				if(!containsPlayer)
				{
					contestant = new Contestant(-1);
					contestant.difficulty = Contestant.PLAYER;
					contestant.id = shellApi.profileManager.active.avatarName;
					contestant.score = 0;
					contestants.push(contestant);
				}
			}
			
			loadContestants();
		}
		
		protected function loadContestants():void
		{
			charGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			if(charGroup == null)
			{
				charGroup = addChildGroup(new CharacterGroup()) as CharacterGroup;
				charGroup.setupGroup(this);
			}
			
			shellApi.loadFile(shellApi.dataPrefix+CONTESTANTS_PATH, contestantDataLoaded);
		}
		
		protected function contestantDataLoaded(xml:XML):void
		{
			
		}
		
		protected function contestantsPrepared(...args):void
		{
			super.loaded();
		}
		
		protected function formatId(id:String, possesive:Boolean = false):String
		{
			if(id == "your")
				return id;
			//add a space to names so that camelCased goes to camel Cased
			var comp:String = id.toLowerCase();
			for(var i:int = 0; i < id.length; i++)
			{
				if(id.charAt(i) != comp.charAt(i))
				{
					id = id.substr(0,i) + " " + id.substr(i);
					break;
				}
			}
			//Camel Case's
			// make sure first letter is upper case and suffix ends in the possesive correctly
			id = id.substr(0,1).toUpperCase() + id.substr(1);
			if(possesive)
			{
				var suffix:String = id.charAt(id.length-1) == 's'?"'":"'s";
				id += suffix;
			}
			
			return id;
		}
		
		public static function getNumGamesPlayed(shellApi:ShellApi, onComplete:Function = null):void
		{
			var games:String = shellApi.getUserField(Reality2Events.GAMES_PLAYED_FIELD, shellApi.island, Command.create(determineNumGamesPlayed,onComplete),true);
		}
		
		private static function determineNumGamesPlayed(games:String, onComplete:Function):void
		{
			var numGames:int = 0;
			if(DataUtils.validString(games))
			{
				var arr:Array = games.split(",");
				numGames = arr.length;
			}
			if(onComplete)
			{
				onComplete(numGames);
			}
		}
		
		public static function getNextContest(shellApi:ShellApi, last:Boolean = false):void
		{
			shellApi.getUserField(Reality2Events.GAMES_PLAYED_FIELD, shellApi.island, Command.create(gamesRetrieved, shellApi, last),true);
		}
		
		private static function gamesRetrieved(games:String, shellApi:ShellApi, last:Boolean):void
		{
			if(!DataUtils.validString(games))
			{
				games = "";//making sure its not null
				last = false;
			}
			if(last)
			{
				var arr:Array = games.split(",");
				var nextGame:String = arr[arr.length-1];
				
				var folderName:String = nextGame.substr(0,1).toLowerCase()+nextGame.substr(1);
				var className:String = CONTEST_PREFIX+folderName+"."+nextGame;
				
				var sceneClass:Class = ClassUtils.getClassByName(className);
				shellApi.loadScene(sceneClass);
			}
			else
			{
				shellApi.loadFile(shellApi.dataPrefix+GAMES_PATH, Command.create(gameDataLoaded, shellApi, games));
			}
		}
		
		private static function gameDataLoaded(xml:XML, shellApi:ShellApi, gamesPlayed:String):void
		{
			var numGamesPlayed:int = gamesPlayed.split(",").length;
			if(DataUtils.validString(gamesPlayed))
				shellApi.completeEvent(Reality2Events.COMPLETED_GAME + numGamesPlayed);
			
			var realityScene:RealityScene = shellApi.currentScene as RealityScene;
			
			if(realityScene)
			{
				realityScene.saveContestantData();
			}
			
			if(numGamesPlayed >= NUM_AIS || numGamesPlayed >= xml.children().length() || !realityScene)
			{
				shellApi.loadScene(GameShow);
				return;
			}
			
			var games:Array = [];
			for(var i:int = 0; i < xml.children().length(); i++)
			{
				var game:String = DataUtils.getString(xml.children()[i]);
				if(gamesPlayed.indexOf(game) == -1)
					games.push(game);
			}
			
			i = Math.floor(Math.random() * games.length);
			var nextGame:String = games[i];
			
			if(DataUtils.validString(gamesPlayed))
				gamesPlayed+=","+nextGame;
			else
				gamesPlayed = nextGame;
			
			shellApi.setUserField(Reality2Events.GAMES_PLAYED_FIELD, gamesPlayed,shellApi.island,true);
			
			var folderName:String = nextGame.substr(0,1).toLowerCase()+nextGame.substr(1);
			var className:String = CONTEST_PREFIX+folderName+"."+nextGame;
			
			var sceneClass:Class = ClassUtils.getClassByName(className);
			
			shellApi.loadScene(sceneClass);
		}
		
		public static function determineParticipantPlaces(participants:Vector.<Contestant>):void
		{
			var places:Array = [];
			for(var i:int = 0; i < participants.length; i++)
			{
				places.push(participants[i]);
			}
			places.sortOn("score", Array.NUMERIC);
			for(i = 0; i < places.length; i++)
			{
				var contestant:Contestant = places[i];
				contestant.place = places.length-i;
			}
		}
		
		public function getContestantFromParticipant(participant:Contestant):Contestant
		{
			for each(var contestant:Contestant in contestants)
			{
				if(participant.index == contestant.index)
					return contestant;
			}
			return null;
		}
		
		public static function getDifficultyStringFromAI(difficulty:Number):String
		{
			var val:String = "Easy";
			switch(difficulty)
			{
				case Contestant.NORMAL:
				{
					val = "Normal";
					break;
				}
				case Contestant.HARD:
				{
					val = "Hard";
					break;
				}
				default:
				{
					val = "Easy";
					break;
				}
			}
			
			return val;
		}
		
		public static function getScoreFromPlace(place:int):int
		{
			var val:int = 0;
			switch(place)
			{
				case 1:
				{
					val = FIRST_PLACE;
					break;
				}
				case 2:
				{
					val = SECOND_PLACE;
					break;
				}
				case 3:
				{
					val = THIRD_PLACE;
					break;
				}
				default:
				{
					val = FOURTH_PLACE;
					break;
				}
			}
			
			return val;
		}
		
		public static function getSuffixFromPlace(place:int):String
		{
			var suffix:String;
			switch(place)
			{
				case 1:
				{
					suffix = "st";
					break;
				}
				case 2:
				{
					suffix = "nd";
					break;
				}
				case 3:
				{
					suffix = "rd";
					break;
				}
				default:
				{
					suffix = "th";
					break;
				}
			}
			return suffix;
		}
	}
}
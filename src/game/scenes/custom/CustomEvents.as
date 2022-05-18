package game.scenes.custom
{
	import game.data.island.IslandEvents;
	import game.scenes.custom.AdInfoPopup;
	import game.scenes.custom.AdLoseGamePopup;
	import game.scenes.custom.AdLoseQuestPopup;
	import game.scenes.custom.AdStartGamePopup;
	import game.scenes.custom.AdStartQuestPopup;
	import game.scenes.custom.AdWinGamePopup;
	import game.scenes.custom.AdWinQuestPopup;
	import game.scenes.custom.AutoCardVideo;
	import game.scenes.custom.BeatGamePower;
	import game.scenes.custom.CardPlayMobileVideo;
	import game.scenes.custom.DropGame;
	import game.scenes.custom.InfoPopup;
	import game.scenes.custom.MazeGame;
	import game.scenes.custom.PuzzleGame;
	import game.scenes.custom.TargetShootingGamePower;
	import game.scenes.custom.TrackBuilderPopup;
	import game.scenes.custom.TwitchGamePower;
	import game.scenes.custom.WishlistPopup;
	import game.scenes.custom.ecInterior.ECInterior;
	import game.scenes.custom.partyRoom.PartyRoom;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.custom.questInterior.QuestInterior;
	
	public class CustomEvents extends IslandEvents
	{
		public function CustomEvents()
		{
			super();
			super.scenes = [PartyRoom,QuestInterior,QuestGame,ECInterior];
			var overlays:Array = [
								AdChoosePopup,
								AdInfoPopup,
								AdLoseGamePopup,
								AdLoseQuestPopup,
								AdStartGamePopup,
								AdStartQuestPopup,
								AdWinGamePopup,
								AdWinQuestPopup,
								AutoCardVideo,
								BeatGamePower,
								CardAnimPower,
								CardPlayMobileVideo,
								CardVideoPower,
								DropGame,
								FlyGame,
								InfoPopup,
								MazeGame,
								PuzzleGame,
								PhotoPopup,
								TargetShootingGamePower,
								TrackBuilderPopup,
								TwitchGamePower,
								WishlistPopup
								];
		}
	}
}
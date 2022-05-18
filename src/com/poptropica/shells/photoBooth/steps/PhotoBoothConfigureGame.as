package com.poptropica.shells.photoBooth.steps
{
	import com.poptropica.shellSteps.shared.ConfigureGame;
	
	import engine.managers.FileManager;
	
	import game.data.game.GameData;
	import game.data.game.GameParser;
	import game.managers.SceneManager;
	
	public class PhotoBoothConfigureGame extends ConfigureGame
	{
		public function PhotoBoothConfigureGame()
		{
			super();
		}

		override protected function configureGame():void
		{
			// Setup GameData
			var fileManager:FileManager = FileManager(this.shellApi.getManager(FileManager));
			var gameXml:XML = fileManager.getFile(fileManager.dataPrefix + this.gameConfigPath);
			
			var gameData:GameData = new GameParser().parse(gameXml);

			// Create manager to store gameData
			var sceneManager:SceneManager = this.shellApi.addManager(new SceneManager()) as SceneManager;
			sceneManager.gameData = gameData;
			
			built();
		}
		
		override protected function get gameConfigPath():String
		{
			return String("game/photobooth/game.xml");
		}
	}
}
package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	
	import engine.managers.FileManager;
	
	import game.data.game.GameData;
	import game.data.game.GameParser;
	import game.managers.SceneManager;
	import game.util.ClassUtils;
	
	/**
	 *  
	 * @author umckiba
	 * 
	 */
	public class ConfigureGame extends ShellStep
	{
		/**
		 * Loads XML file used to define GameData.
		 */
		public function ConfigureGame()
		{
			super();
			stepDescription = "Configuring game";
		}
		
		override protected function build():void
		{
			// NOTE :: Possibly this was already loaded with FileIO step, but that would only happen during debug
			var fileManager:FileManager = FileManager(this.shellApi.getManager(FileManager));
			var gameDataPath:String = fileManager.dataPrefix + this.gameConfigPath;
			trace( "ConfigureGame Step :: loading game config file at: " + gameDataPath );
			fileManager.loadFiles( [gameDataPath, fileManager.dataPrefix + toolTipPath, fileManager.contentPrefix + stylesPath], configureGame);
		}
		
		protected function configureGame():void
		{
			// Setup GameData
			var fileManager:FileManager = FileManager(this.shellApi.getManager(FileManager));
			var gameXml:XML = fileManager.getFile(fileManager.dataPrefix + this.gameConfigPath);
			
			var gameData:GameData = new GameParser().parse(gameXml);
			
			// NOTE :: This is sort of a hack, would like better solution in future.  Need these classes defined for use in Hud. -bard
			try
			{
				if (gameXml.sceneClass.length()) 
				{
					gameData.homeClass = ClassUtils.getClassByName(gameXml.sceneClass.(@id=='home'));
					gameData.mapClass = ClassUtils.getClassByName(gameXml.sceneClass.(@id=='map'));
					gameData.storeClass = ClassUtils.getClassByName(gameXml.sceneClass.(@id=='store'));
					
					if(!gameData.homeClass)
					{
						trace( this," :: Error : unable to define homeClass:", gameXml.sceneClass.(@id=='home'));
					}
					if(!gameData.mapClass)
					{
						trace( this," :: Error : unable to define mapClass:", gameXml.sceneClass.(@id=='map'));
					}
					if(!gameData.storeClass)
					{
						trace( this," :: Error : unable to define storeClass:", gameXml.sceneClass.(@id=='store'));
					}
				}
			} 
			catch(error:Error) 
			{
				trace( this," :: Error : undable to define class, error: ",error.message);
				
			}
			
			// Create manager to store gameData
			var sceneManager:SceneManager = this.shellApi.addManager(new SceneManager()) as SceneManager;
			sceneManager.gameData = gameData;
			
			built();
		}
		
		protected function get gameConfigPath():String
		{
			var filePrefix:String = ( AppConfig.mobile ) ? "mobile" : "browser";
			return String("game/" + filePrefix + "/game.xml");
		}
		
		protected var gameFilePrefix:String = "";
		protected var toolTipPath:String = "ui/toolTip.xml";
		protected var stylesPath:String = "style/styles.xml";
	}
}
package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.managers.SceneManager;
	import game.scenes.hub.town.Town;
	import game.util.ClassUtils;
	
	/**
	 * Lose game popup for quest game
	 */
	public class AdLoseQuestPopup extends AdLosePopup
	{
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set gametype to Quest
			_gameType= "Quest";
			super.init(container);
		}		
				
		/**
		 * Close popup 
		 * @param button
		 */
		protected override function closePopup(button:Entity):void
		{
			if(campaignData.popupScene)
			{
				var sceneManager:SceneManager = shellApi.sceneManager;
				var destScene:String = sceneManager.previousScene;
				var destX:Number = sceneManager.previousSceneX;
				var destY:Number = sceneManager.previousSceneY;
				
				if (destScene.indexOf('.') > -1) {
					shellApi.loadScene(ClassUtils.getClassByName(destScene), destX, destY, sceneManager.previousSceneDirection);
				}
				else
				{
					shellApi.loadScene(Town);
				}
			}
			else
			{
				// return to ad interior scene
				returnToInterior();
			}
			if(super.shellApi != null) {
				super.shellApi.arcadeGame = null;
			}
		}
	}
}
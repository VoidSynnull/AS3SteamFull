package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	/**
	 * Start game popup for quest
	 */
	public class AdStartQuestPopup extends AdStartPopup
	{
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set gametype to Quest
			_gameType= "Quest";
			super.init(container);
			// pause underlying scene
			super.shellApi.sceneManager.currentScene.pause(false, true);
		}
		
		override protected function closePopup(button:Entity):void
		{
			super.closePopup(button);
			// unpause underlying scene
			super.shellApi.sceneManager.currentScene.unpause(false, true);
		}
	}
}
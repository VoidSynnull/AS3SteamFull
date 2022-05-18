package game.scene.template.ads
{
	import game.managers.ads.AdManager;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * Group for billboards or main street buildings
	 * @author Rick Hocker
	 */
	public class AdSceneGroup3 extends AdSceneGroup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param adManager
		 * @param number of ad building (used for sponsored islands)
		 */
		public function AdSceneGroup3(container:DisplayObjectContainer=null, adManager:AdManager = null)
		{
			super(container, adManager);
			_num = 3;
			this.id = GROUP_ID;
		}

		public static const GROUP_ID:String = "AdSceneGroup3";
	}
}


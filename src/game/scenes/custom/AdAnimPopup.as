package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.data.ads.AdvertisingConstants;
	import game.data.animation.Animation;
	import game.scene.template.SFSceneGroup;
	import game.ui.popup.Popup;
	import game.util.TimelineUtils;
	
	/**
	 * Ad popup class for loading a popup in the ad interior or game
	 * @author Rick Hocker
	 */
	public class AdAnimPopup extends Popup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param swfPath full path to asset swf in assets directory
		 */
		public function AdAnimPopup(container:DisplayObjectContainer = null, swfPath:String = null)
		{
			_swfPath = swfPath;
			super();
		}
		
		/**
		 * Init popup 
		 * @param container
		 */
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			load();
		}
		
		/**
		 * Load campaign specific assets 
		 */
		override public function load():void
		{
			// add signal for completion
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array(_swfPath));
		}
		
		/**
		 * All assets ready 
		 */
		override public function loaded():void
		{
			// hide emotes in party room
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			if(sfSceneGroup != null)
				sfSceneGroup.emotes.getButton().get(Display).visible = false;

			// get swf
			super.screen = MovieClip(super.getAsset(_swfPath, true));
			
			// if clip not found, then error
			if (super.screen == null)
			{
				trace("Can't find popup: " + _swfPath);
			}
			else
			{
				// if found
				// convert content into timeline
				var vTimeline:Entity = TimelineUtils.convertClip(super.screen.content, super);
				// signal for when timeline animation reaches end
				TimelineUtils.onLabel( vTimeline, Animation.LABEL_ENDING, endpopup);
				
				// center screen
				super.screen.content.x = super.shellApi.viewportWidth/2;
				super.screen.content.y =super.shellApi.viewportHeight/2;
			}
			super.loaded();
		}
				
		/**
		 * When popup animation reaches end 
		 */
		private function endpopup():void
		{
			// unhide emots in party room
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			if(sfSceneGroup != null)
				sfSceneGroup.emotes.getButton().get(Display).visible = true;
			
			// restore user input and remove popup
			super.endPopupAnim();
		}
		
		private var _swfPath:String;
	}
}
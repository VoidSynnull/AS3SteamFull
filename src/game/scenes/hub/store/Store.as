package game.scenes.hub.store
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.data.display.BitmapWrapper;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ui.CardGroup;
	import game.ui.popup.ItemStorePopup;
	import game.util.DisplayUtils;
	import game.util.PlatformUtils;

	public class Store extends PlatformerGameScene
	{

		private var _loadingCardWrapper:BitmapWrapper;
		private var _loadingWheelWrapper:BitmapWrapper;
		private var _cardScale:Number = 1;


		public function Store()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/hub/store/";
			
			super.init(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			if(PlatformUtils.isMobileOS)
				super.shellApi.loadFiles([ super.shellApi.assetPrefix + "ui/general/load_wheel.swf", super.shellApi.assetPrefix + "items/ui/background_loading.swf"], loadedInitAssets);
			else
				super.shellApi.loadFiles( [ super.shellApi.assetPrefix + "ui/general/load_wheel.swf", super.shellApi.assetPrefix + "items/ui/background_loading.swf"], loadedInitAssets);

		}
		
		private function loadedInitAssets():void
		{
			// store references to loading assets
			var loadWheel:MovieClip = shellApi.getFile( shellApi.assetPrefix + "ui/general/load_wheel.swf" ) as MovieClip;
			_loadingWheelWrapper = DisplayUtils.convertToBitmapSprite( loadWheel, loadWheel.getBounds(loadWheel), _cardScale, false );
			var loadingCard:MovieClip = shellApi.getFile( shellApi.assetPrefix + "items/ui/background_loading.swf" ) as MovieClip;
			_loadingCardWrapper = DisplayUtils.convertToBitmapSprite( loadingCard, CardGroup.CARD_BOUNDS, _cardScale );
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			//TODO: SETUP THE STORE AS POPUP
			// load store popup
			var popup:ItemStorePopup = this.addChildGroup(new ItemStorePopup(this,false,_loadingWheelWrapper,_loadingCardWrapper)) as ItemStorePopup;
			popup.init( shellApi.sceneManager.currentScene.overlayContainer );
			
			//var popup:StorePopup = this.addChildGroup(new StorePopup(this)) as StorePopup;
			//popup.init(shellApi.sceneManager.currentScene.overlayContainer );
			
			
		}	
	}
}



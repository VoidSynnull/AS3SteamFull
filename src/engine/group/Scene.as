package engine.group
{
	/**
	 * The base class for a scene.
	 * 
	 * A scene is meant to exist as the core structure for gameplay.  It contains SceneData common 
	 * to all scenes (starting position, scene area, etc) as well as creating an interaction layer.
	 * 
	 * Scenes also serve as the point of creation for systems and entities.  Only one scene exists in the
	 * game at a time, and cleans up all associated systems and groups when it is removed.
	 */
	
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import game.data.island.IslandEvents;
	import game.data.scene.SceneData;
	import game.scene.template.PlatformerGameScene;
	import game.util.ScreenEffects;

	public class Scene extends DisplayGroup
	{
		public function Scene()
		{			
			super();
		}

		override public function destroy():void
		{
			if(_overlayContainer != null)
			{
				_overlayContainer.parent.removeChild(_overlayContainer);
				_overlayContainer = null;
			}
			
			if(_transitionContainer != null)
			{
				_transitionContainer.parent.removeChild(_transitionContainer);
				_transitionContainer = null;
			}
			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			_overlayContainer = new Sprite();
			_overlayContainer.name = 'sceneOverlayContainer';
			// add the overlay container and transition container to the sceneContainer so it isn't scaled with the camera zoom. 
			container.parent.addChild(_overlayContainer);
			
			_transitionContainer = new Sprite();
			_transitionContainer.name = 'transitionContainer';
			container.parent.addChild(_transitionContainer);
			// create an effects layer for fade-to-black
			_screenEffects = new ScreenEffects(_transitionContainer, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
			_screenEffects.box.mouseEnabled = false;
			
			super.init(container);
			// we want the elements within the containers to receive mouse events, not the containers themselves.
			super.groupContainer.mouseEnabled = false;
			_overlayContainer.mouseEnabled = false;
			_transitionContainer.mouseEnabled = false;
		}
		
		override public function loaded():void
		{
			// if ads are active and not PlatformerGameScene, then prep scene for possible ads
			if ((AppConfig.adsActive) && (!(this is PlatformerGameScene)))
			{
				super.shellApi.adManager.prepSceneForAds(this);
			}
			super.loaded();		
		}
		
		public function registrationSuccess():void
		{
			// need to override
		}
		
		/**
		 * 'overlayContainer' can be used for any popups or fixed display elements that overlay a group. For scenes this will hold popups.
		 */
		public function set overlayContainer(container:DisplayObjectContainer):void { _overlayContainer = container; }
		public function get overlayContainer():DisplayObjectContainer { return(_overlayContainer); }
		/**
		 * 'transitionContainer' can be used for fullscreen transitions that obscure anything in the scene.
		 */
		public function set transitionContainer(container:DisplayObjectContainer):void { _transitionContainer = container; }
		public function get transitionContainer():DisplayObjectContainer { return(_transitionContainer); }
		public function set sceneData(sceneData:SceneData):void { _sceneData = sceneData; }
		public function get sceneData():SceneData { return(_sceneData); }
		public function get events():IslandEvents { return(super.shellApi.islandEvents); }
		public function get screenEffects():ScreenEffects { return(_screenEffects); }
		
		private var _sceneData:SceneData;
		private var _overlayContainer:DisplayObjectContainer;
		private var _transitionContainer:DisplayObjectContainer;
		private var _screenEffects:ScreenEffects;
		public var fetchFromServer:Boolean = false;
	}
}

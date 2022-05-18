package game.scene.template.topDown.boatScene
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.creators.CameraLayerCreator;
	
	import game.managers.EntityPool;
	import game.scene.template.topDown.TopDownScene;
	import game.systems.SystemPriorities;
	
	public class BoatScene extends TopDownScene
	{
		public function BoatScene()
		{
			super();
		}
			
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.init(container);

			// the asset for the randomly placed waves that animate over the water.
			_waveAsset = super.groupPrefix + WAVE_ASSET;
		}
		
		// all assets ready
		override protected function addGroups():void
		{
			super.addGroups();
			
			var cameraLayerCreator:CameraLayerCreator = new CameraLayerCreator();
			var waterLayerContainer:Sprite = new Sprite();
			super.addEntity(cameraLayerCreator.create(waterLayerContainer, 1, WATER_LAYER));
			
			var waterIndex:Number = super.groupContainer.getChildIndex(super.hitContainer);
			var background:Entity = super.getEntityById("background");
			
			// for scenes w/o backgrounds (dynamic scenes) we place the water container at the interactive layer depth, otherwise bg depth so
			//  it is behind islands...
			if(background)
			{
				var backgroundDisplay:Display = background.get(Display);
				waterIndex = backgroundDisplay.container.getChildIndex(backgroundDisplay.displayObject);
			}
			
			super.groupContainer.addChildAt(waterLayerContainer, waterIndex);
			
			waterLayerContainer.mouseChildren = false;
			waterLayerContainer.mouseEnabled = false;
			
			_waterEffectsCreator = new WaterEffectsCreator();
			_waterEffectsCreator.createWaves(_waveAsset, this, waterLayerContainer, 10);
			
			_pool = new EntityPool();  // used to pool ripples.
			
			super.addSystem(new BoatWakeSystem(_pool), SystemPriorities.moveComplete);
			super.addSystem(new WaterWaveSystem(), SystemPriorities.moveComplete);
			super.addSystem(new WaterRippleSystem(_pool), SystemPriorities.moveComplete);
		}
	
		protected function addWake(entity, url:String = null, rippleScaleX:Number = 1.2, rippleScaleY:Number = 1.2):void
		{
			if(url == null)
			{
				url = super.groupPrefix + WAKE_ASSET;
			}
			
			var waterLayer:Entity = super.getEntityById(WATER_LAYER);
			var waterLayerContainer:Sprite = Display(waterLayer.get(Display)).displayObject as Sprite;

			_waterEffectsCreator.addWake(entity, waterLayerContainer, url, rippleScaleX, rippleScaleY);
		}
		
		private var _pool:EntityPool;
		private var _waterEffectsCreator:WaterEffectsCreator;
		protected const WATER_LAYER:String = "waterLayer";
		protected const WAVE_ASSET:String = "wave.swf";
		protected const WAKE_ASSET:String = "waterRipple.swf";
		protected var _waveAsset:String;
	}
}
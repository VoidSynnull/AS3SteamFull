package engine.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.CameraLayer;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.SpatialWrap;
	
	import game.data.display.BitmapWrapper;
	import game.util.DisplayUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	
	public class CameraLayerCreator
	{
		/**
		 * Creates a cameraLayer entity.
		 * 
		 * @param layerDisplay : The asset used for this layer.
		 * @param rate : The rate is the factor of layer movement as the camera follows its target.  .5 would move at half the speed of the primary player layer, while 2 would move twice as fast.
		 * @param [id] : An id to be assigned to a layer if it needs to be access later.
		 * @param [bitmapLayer] : Indicates if this layer should be bitmapped.
		 * @param [sceneWidth/sceneHeight] : The width/height of the scene using this layer.  Used for bitmapping and zoom scale offset.
		 * @param [offsetX/offsetY] : An offset that can be applied to this camera movement if it isn't at 0,0.
		 * @param [minCameraScale] : This is the minimum scale that this camera layer will ever reach.  An offset is applied if this is != 1 to prevent its top-left edge being visible when fully zoomed out.
		 */
		public function create(layerDisplay:DisplayObjectContainer, 
							   rate:Number = 1, 
							   id:String = "", 
							   bitmapLayer:Boolean = false, 
							   sceneWidth:Number = NaN, sceneHeight:Number = NaN, 
							   offsetX:Number = 0, offsetY:Number = 0, 
							   scale:Number = 1, 
							   wrapX:Number = 0, wrapY:Number = 0, 
							   quality:Number = 1,
							   overlap:Number = 0,
							   tileSize:int = 512,
							   viewportWidth:Number = 0, viewportHeight:Number = 0,
							   autoScale:Boolean = true,
							   matchViewportSize:Boolean = false,
							   allowGrid:Boolean = true,
							   sceneX:Number = 0, sceneY:Number = 0):Entity
		{
			var layer : Entity = new Entity();
			var cameraLayer:CameraLayer = new CameraLayer();
			
			cameraLayer.rate = rate;
			
			layer.add(cameraLayer);
			
			trace("Setting up " + id + " layer");
			
			var spatial:Spatial = new Spatial();
			spatial.x = 0;
			spatial.y = 0;
			layer.add(spatial);
			layer.add(new Id(id));
			var spatialOffset:SpatialOffset = new SpatialOffset();
			spatialOffset._baseX = offsetX;
			spatialOffset._baseY = offsetY;
			layer.add(spatialOffset);
			
			if(matchViewportSize)
			{
				autoScale = false;
				layerDisplay.width = viewportWidth;
				layerDisplay.height = viewportHeight;
			}

			var hasArea:Boolean				= (viewportWidth > 0) && (viewportHeight > 0);
			var doesntWrap:Boolean			= (wrapX == 0) && (wrapY == 0);
			var containerHasArea:Boolean	= (layerDisplay.width > 0) && (layerDisplay.height > 0);
			var needsAdjustment:Boolean		= autoScale && hasArea && doesntWrap && containerHasArea;
			// If the scene will be scaled, add an offset based on its movement rate so it does not move past its bounds.
			if (needsAdjustment)
			{
				adjustScaleForRate(spatial, scale, rate, viewportWidth, viewportHeight, sceneWidth, sceneHeight);
				adjustOffsetForScaleAndRate(spatialOffset, scale, rate, viewportWidth, viewportHeight);
			}
			else
			{
				spatialOffset.x = offsetX;
				spatialOffset.y = offsetY;
			}
			
			var display:Display = new Display();
			
			if(bitmapLayer)
			{
				var bitmapWrapper:BitmapWrapper;
				
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_LOW)
				{
					quality *= .5;
				}
				
				var bitmapScale:Number = scale * quality * spatial.scale;
				var sizeWidth:Number = sceneWidth;
				var sizeHeight:Number = sceneHeight;
				if(sceneX > 0)
					sceneX *= rate;
				if(sceneY > 0)
					sceneY *= rate;
				if(rate != 0 && !isNaN(rate))
				{
					sizeWidth = sizeWidth / rate;
					sizeHeight = sizeHeight / rate;
				}
				if(PlatformUtils.isMobileOS && allowGrid)
				{
					// need to tile bitmaps to stay within maximum image size for mobile.
					bitmapWrapper = DisplayUtils.convertToTiledBitmap(layerDisplay, tileSize, tileSize, bitmapScale, overlap, new Rectangle(sceneX, sceneY, sizeWidth, sizeHeight));
				}
				else
				{
					bitmapWrapper = DisplayUtils.convertToBitmapSprite(layerDisplay, new Rectangle(sceneX, sceneY, sizeWidth, sizeHeight), bitmapScale, true);
					
					if(!bitmapWrapper)
					{
						throw new Error("CameraLayerCreator :: create() :: Layer <" + id + "> has a width/height = 0. It's empty!");
					}
				}
				
				bitmapWrapper.sprite.mouseChildren = false;
				display.displayObject = bitmapWrapper.sprite;
				display.bitmapWrapper = bitmapWrapper;
			}
			else
			{
				display.displayObject = layerDisplay;
			}
			
			layer.add(display);
			
			// Spatial wrap x and y defines the point where a layer will repeat.
			if (wrapX || wrapY)
			{
				layer.add(new SpatialWrap(wrapX, wrapY));	
			}
			
			return(layer);
		}
		
		public static function adjustScaleForRate(spatial:Spatial, scale:Number, rate:Number, viewportWidth:Number, viewportHeight:Number, sceneWidth:Number, sceneHeight:Number):void
		{
			var viewBounds:Number = viewportWidth;
			var sceneBounds:Number = sceneWidth;
			
			// use the bigger ratio to determine width and height.
			if((viewportHeight / sceneHeight) > (viewportWidth / sceneWidth))
			{
				viewBounds = viewportHeight;
				sceneBounds = sceneHeight;
			}
			
			viewBounds /= scale;  // the viewport size must adjust to be bigger or smaller based on scale...ex : a lower scale will make more of the scene visible so the viewport gets bigger.
			
			spatial.scale = (viewBounds + sceneBounds * rate - viewBounds * rate) / sceneBounds; //the scale that the backdrop should be
		}
		
		public static function adjustOffsetForScaleAndRate(spatialOffset:SpatialOffset, scale:Number, rate:Number, viewportWidth:Number, viewportHeight:Number):void
		{
			spatialOffset.x = spatialOffset._baseX - ((viewportWidth / scale) * .5) * (1 - scale) * (1 - rate);
			spatialOffset.y = spatialOffset._baseY - ((viewportHeight / scale) * .5) * (1 - scale) * (1 - rate);
		}
	}
}



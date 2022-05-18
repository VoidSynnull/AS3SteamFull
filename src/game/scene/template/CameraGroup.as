/**
 * Contains shortcuts to camera setup and use.
 * 
 * Example 1:
 * 		
 * 		// most basic setup...create a CameraGroup and set it up based on the scene data.	
 * 		var cameraGroup:CameraGroup = new CameraGroup();
			
		cameraGroup.setupScene(this);
		
   Example 2:
 * 		
 * 		// manually setup the camera and layers in your group or scene
 * 		var cameraGroup:CameraGroup = new CameraGroup();
 *      cameraGroup.groupPrefix = scene.groupPrefix;
		cameraGroup.container = scene.container;
		cameraGroup.groupContainer = scene.groupContainer;
		// add it as a child group to give it access to systemManager.
		super.addChildGroup(this);
			
		create(super.shellApi.viewportWidth, shellApi.viewportHeight, scene.sceneData.cameraLimits.width, scene.sceneData.cameraLimits.height);
		// layers can be set manually as well by passing in a Vector of LayerData.
		setupLayers(scene.sceneData.layers);
			
		super.shellApi.camera = super.getSystem(CameraSystem) as CameraSystem;
 */

package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialWrap;
	import engine.creators.CameraLayerCreator;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.systems.CameraSystem;
	import engine.systems.CameraZoomSystem;
	import engine.systems.RenderSystem;
	import engine.systems.SpatialWrapSystem;
	
	import game.components.motion.TargetSpatial;
	import game.data.PlatformType;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.data.scene.CameraLayerData;
	import game.systems.SystemPriorities;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	
	public class CameraGroup extends Group
	{
		public function CameraGroup()
		{
			super();
			this.id = GROUP_ID;
		}
				
		/**
		 * For most scenes this is the only method you need to do setup.  Copies the appropriate container and asset/data prefixes, add the camera system and sets up layers.
		 * @param   scene : The Scene to pull layer data from and use for setup.  Defaults to the parent of this Group.
		 * @param   [minCameraScale] : If using camera zoom, this is the minimum scale the camera will zoom to.  If it is less than one, the camera layers are offset to prevent the layers from moving
		 *                                off the screen when the camera is fully zoomed out.
		 * @param   [offset] : This offsets the camera position by half the viewport to allow for simpler calculations when zooming.  Should be 'true' for any scenes that need panning.
		 */
		public function setupScene(scene:Scene, initialScale:Number = 1, offset:Boolean = true):void
		{
			// add it as a child group to give it access to systemManager.
			scene.addChildGroup(this);
			
			initialScale = create(scene, super.shellApi.viewportWidth, shellApi.viewportHeight, scene.sceneData.cameraLimits.width, scene.sceneData.cameraLimits.height, scene.sceneData.cameraLimits.x, scene.sceneData.cameraLimits.y, offset, initialScale);
			
			if(scene.sceneData.layers != null)
			{
				setupLayers(scene.sceneData.layers, scene.sceneData.cameraLimits.x, scene.sceneData.cameraLimits.y, scene.sceneData.cameraLimits.width, scene.sceneData.cameraLimits.height, initialScale);
			}
			
			super.shellApi.camera = super.getSystem(CameraSystem) as CameraSystem;
		}
		
		public function createCameraEntity(container:DisplayObjectContainer, viewportWidth:Number, viewportHeight:Number, areaWidth:Number, areaHeight:Number, areaX:Number, areaY:Number, scale:Number):Entity
		{
			var entity:Entity = new Entity();
			var camera:Camera = new Camera(viewportWidth, viewportHeight, areaWidth, areaHeight, areaX, areaY);
			var spatial:Spatial = new Spatial(0, 0);
			spatial.scale = scale;
			camera.updateLimits(scale);
			camera.scaleTarget = scale;
			
			entity.add(camera);
			entity.add(spatial);
			entity.add(new TargetSpatial(new Spatial(0, 0)));
			entity.add(new Id(CAMERA_ID));
			entity.add(new Display(container));
			
			return(entity);
		}
		
		/**
		 * Creates the camera system and render system and prepares the camera container.
		 */
		public function create(group:Group, viewportWidth:Number, viewportHeight:Number, areaWidth:Number, areaHeight:Number, areaX:Number, areaY:Number, offset:Boolean = true, initialScale:Number = 1):Number
		{
			// scene dimensions should not be smaller than viewport.  Zoom in if they are.
			if (areaWidth * initialScale < viewportWidth)
			{
				initialScale = viewportWidth / areaWidth;
			}
			
			if (areaHeight * initialScale < viewportHeight)
			{
				var heightRatio:Number = viewportHeight / areaHeight;
				
				if(!isNaN(initialScale))
				{
					if(heightRatio > initialScale)
					{
						initialScale = heightRatio;
					}
				}
				else
				{
					initialScale = heightRatio;
				}
			}
			
			var cameraSystem:CameraSystem = new CameraSystem();
			var parentGroup:DisplayGroup = super.parent as DisplayGroup;
			
			var cameraEntity:Entity = createCameraEntity(parentGroup.container, viewportWidth, viewportHeight, areaWidth, areaHeight, areaX, areaY, initialScale);
			var spatial:Spatial = cameraEntity.get(Spatial);
			spatial.scale = initialScale;
			// temporary direct reference to camera component so systems that access before the entity is available can still get it
			cameraSystem.camera = cameraEntity.get(Camera);
			
			
			// offset the camera container so its top-left registation point is centered.  This allows the scene to stay centered if the camera zoom changes.
			if ( offset )
			{
				spatial.x = viewportWidth * .5;
				spatial.y = viewportHeight * .5;
			}

			parentGroup.addSystem(new RenderSystem(), SystemPriorities.render);
			parentGroup.addSystem(new CameraZoomSystem(), SystemPriorities.cameraZoomUpdate);
			parentGroup.addSystem(cameraSystem, SystemPriorities.cameraUpdate);
			
			parentGroup.addEntity(cameraEntity);
			
			return(initialScale);
		}
		
		/**
		 * Adds camera layer entities.
		 */
		public function setupLayers(layers:Dictionary, x:Number, y:Number, areaWidth:Number, areaHeight:Number, initialScale:Number = 1):void
		{
			var layer:Entity;
			var display:Display;
			var layerCreator:CameraLayerCreator = new CameraLayerCreator();
			var layerData:CameraLayerData;			
			var width:Number;
			var height:Number;
			var orderedLayers:Array = getOrderedLayers(layers);
			var asset:DisplayObjectContainer;
			var bitmappedChildren:Array;

			compositeLayers(orderedLayers);
			
			for each( layerData in orderedLayers )
			{		
				if (!isNaN(layerData.width))
				{
					width = layerData.width;
				}
				else
				{
					width = areaWidth;
				}
				
				if (!isNaN(layerData.height))
				{
					height = layerData.height;
				}
				else
				{
					height = areaHeight;
				}
				
				asset = getCameraLayerAsset(layerData);
				
				//scaleRatio += (super.shellApi.viewportScale - 1);  // upscale bitmaps to native res...could run out of memory on high-res devices.

				bitmappedChildren = bitmapChildren(layerData, asset);
				
				var bitmapOverlap:Number = 1;   // the number of pixels to overlap the bitmap tiles.
				var bitmapQuality:Number = 1;   // the res of the bitmap. 
				
				layer = layerCreator.create(asset, 
										    layerData.rate, 
											layerData.id, 
											layerData.bitmap, 
											width, height, 
											layerData.offsetX, layerData.offsetY, 
											initialScale, 
											layerData.wrapX, layerData.wrapY, 
											bitmapQuality, 
											bitmapOverlap,
											layerData.tileSize,
											super.shellApi.viewportWidth, super.shellApi.viewportHeight,
											layerData.autoScale,
											layerData.matchViewportSize,
											this.allowLayerGrid,
											x, y);
				
				display = layer.get(Display);
				
				// sort and re-add the children after any tiling and scaling of the layer has taken place.
				sortBitmappedChildren(bitmappedChildren, display.displayObject);
				
				if(layer.get(SpatialWrap))
				{
					super.addSystem(new SpatialWrapSystem(), SystemPriorities.preRender);
				}
				
				DisplayGroup(super.parent).groupContainer.addChild(display.displayObject);
				super.parent.addEntity(layer);
			}
		}

		private function bitmapChildren(layerData:CameraLayerData, layerDisplay:DisplayObjectContainer):Array
		{
			var bitmappedChildren:Array = new Array();
			
			if(layerData.elementsToBitmap.length > 0)
			{
				var wrapper:BitmapWrapper;
				var nextAsset:DisplayObjectContainer;
				var nextScale:Number = 1;
				var maxSize:Number = 2800;
				
				for(var i:int = 0; i < layerData.elementsToBitmap.length; i++)
				{
					nextAsset = layerDisplay[layerData.elementsToBitmap[i]];
					// if asset is null then skip
					if (nextAsset == null)
						continue;
					
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_LOW)
					{
						nextScale = .5;
					}
					
					if(nextAsset.width * nextScale > maxSize || nextAsset.height * nextScale > maxSize)
					{
						if(nextAsset.width > nextAsset.height)
						{
							nextScale = maxSize / (nextAsset.width * nextScale);
						}
						else
						{
							nextScale = maxSize / (nextAsset.height * nextScale);
						}
					}
					
					wrapper = DisplayGroup(super.parent).convertToBitmapSprite(nextAsset, null, true, nextScale);
					
					if(!layerData.hit && PlatformUtils.isMobileOS)
					{
						bitmappedChildren.push(wrapper);
					}
				}
				
				// remove all children that shouldn't be tiled and store their depths.
				if(bitmappedChildren.length > 0)
				{
					for(i = 0; i < bitmappedChildren.length; i++)
					{
						bitmappedChildren[i].depth = layerDisplay.getChildIndex(bitmappedChildren[i].sprite);
					}
					
					for(i = 0; i < bitmappedChildren.length; i++)
					{
						layerDisplay.removeChild(bitmappedChildren[i].sprite);
					}
				}
			}
			
			return(bitmappedChildren);
		}
		
		private function sortBitmappedChildren(bitmappedChildren:Array, layerDisplay:DisplayObjectContainer):void
		{
			if(bitmappedChildren.length > 0)
			{
				// re-add the bitmapped children in order of depth.
				bitmappedChildren.sortOn("depth", Array.NUMERIC); 
				
				for(var i:int = 0; i < bitmappedChildren.length; i++)
				{
					layerDisplay.addChild(bitmappedChildren[i].sprite);
				}
			}
		}
		
		private function compositeLayers(orderedLayers:Array):void
		{
			var layerData:CameraLayerData;	
			var currentQuality:int = PerformanceUtils.qualityLevel;
			var baseAsset:DisplayObjectContainer;
			var mergeAsset:DisplayObjectContainer;
			var baseAssetPath:String;
			var condition:String;
			var value:*;
			var removeLayer:Boolean;
			var total:int = orderedLayers.length;
			var nextLayerData:CameraLayerData;
			var swap:DisplayObjectContainer;
			
			// we must reverse the layers before compositing so they get built up from the bottom of the stack.
			for(var n:int = total - 1; n >= 0; n--)
			{
				layerData = orderedLayers[n];
				condition = layerData.condition;
				value = layerData.conditionValue;
				removeLayer = false;
				
				// NOTE - in certain circumstances we want to prevent backdrop merge, regardless of quality
				// To do this, add a non-recognized conditional, such as 'blockMerge' to the layer, this prevents 'merge' from being assigned.
				if(layerData.id == "backdrop" && condition == null)
				{
					condition = "merge";
					value = "background";
				}
				// handling removing layers from hide and platform earlier
				if(condition == "merge" || condition == "alwaysMerge")
				{
					if(currentQuality < PerformanceUtils.QUALITY_MEDIUM || condition == "alwaysMerge")
					{
						mergeAsset = getCameraLayerAsset(layerData);
						
						for(var m:int = 0; m < orderedLayers.length; m++)
						{
							nextLayerData = orderedLayers[m];
							
							if(value.indexOf(nextLayerData.id) > -1)
							{
								baseAsset = getCameraLayerAsset(nextLayerData);
								if(nextLayerData.absoluteFilePaths)
								{
									baseAssetPath = nextLayerData.asset;
								}
								else
								{
									baseAssetPath = super.shellApi.assetPrefix + Scene(super.parent).groupPrefix + nextLayerData.asset;
								}
								break;
							}
						}
						
						if(baseAsset != null)
						{
							if(value.indexOf("placeOver") > -1)
							{
								swap = mergeAsset;
								mergeAsset = baseAsset;
								baseAsset = swap;
							}
							
							mergeAsset.addChild(baseAsset);
							super.shellApi.setCache(baseAssetPath, mergeAsset);
							removeLayer = true;
						}
					}
				}
				
				if(removeLayer)
				{
					orderedLayers.splice(orderedLayers.indexOf(layerData), 1);
				}
			}
		}
		
		public function setZoomByMotionTarget(motionTarget:Motion, maxZoom:Number = 1, minZoom:Number = 1):void
		{
			var cameraZoom:CameraZoomSystem = super.parent.getSystem(CameraZoomSystem) as CameraZoomSystem;
			
			if(cameraZoom == null)
			{
				cameraZoom = new CameraZoomSystem();
				super.addSystem(cameraZoom, SystemPriorities.cameraUpdate);
			}
			
			cameraZoom.maxCameraScale = maxZoom;
			cameraZoom.minCameraScale = minZoom;
			cameraZoom.target = motionTarget;
			cameraZoom.scaleByMotion = true;			
		}
		
		public function setTarget(spatial:Spatial, jumpToTarget:Boolean = false):void
		{
			var camera:CameraSystem = super.parent.getSystem(CameraSystem) as CameraSystem;
			
			camera.target = spatial;
			
			if(jumpToTarget)
			{
				var oldRate:Number = camera.rate;
				
				camera.rate = 1;
				
				camera.update(1);

				camera.rate = oldRate;
				
				camera.startUpdateCheck();
				camera.updateCheckComplete.addOnce(cameraUpdateDone);
			}
		}
		
		public function getOrderedLayers(layers:Dictionary):Array
		{
			var orderedLayers:Array = new Array();
			var layerData:CameraLayerData;
			var allLayerData:Dictionary;
			var events:Vector.<String> = super.shellApi.getEvents().slice();
			events.unshift(GameEvent.DEFAULT);
			
			for each(allLayerData in layers)
			{
				// get the layer data associated with the most recent event.
				for (var n:uint = 0; n < events.length; n++)
				{
					if(allLayerData[events[n]])
					{
						layerData = allLayerData[events[n]];
					}
				}
				
				if(layerData)
				{
					orderedLayers.push(layerData);
					
					// clear assets of unneeded layers.
					for each(var eventLayerData:CameraLayerData in allLayerData)
					{
						if(eventLayerData != layerData)
						{
							getCameraLayerAsset(eventLayerData);
						}
					}
					
					layerData = null;
				}
			}
			
			orderedLayers.sortOn("zIndex", Array.NUMERIC); 
			
			return(orderedLayers);
		}
		
		private function getCameraLayerAsset(layerData:CameraLayerData):DisplayObjectContainer
		{
			if(layerData.asset != null)
			{
				if(layerData.absoluteFilePaths)
				{
					return(super.shellApi.getFile(layerData.asset, true));
				}
				else
				{
					return(DisplayGroup(super.parent).getAsset(layerData.asset, true));
				}
			}
			else
			{
				return(new Sprite());
			}
		}
		
		private function cameraUpdateDone():void
		{
			super.groupReady();
		}
		
		public function set target(target:Spatial):void { CameraSystem(super.parent.getSystem(CameraSystem)).target = target; }
		public function get target():Spatial { return(CameraSystem(super.parent.getSystem(CameraSystem)).target); }
		public function set rate(rate:Number):void { CameraSystem(super.parent.getSystem(CameraSystem)).rate = rate; }
		public function get rate():Number { return(CameraSystem(super.parent.getSystem(CameraSystem)).rate); }
		public function set zoomTarget(zoomTarget:Number):void { CameraZoomSystem(super.parent.getSystem(CameraZoomSystem)).scaleTarget = zoomTarget; }
		public function get zoomTarget():Number { return(CameraZoomSystem(super.parent.getSystem(CameraZoomSystem)).scaleTarget); }
		public function set zoomRate(zoomRate:Number):void { CameraZoomSystem(super.parent.getSystem(CameraZoomSystem)).scaleRate = zoomRate; }
		public function get zoomRate():Number { return(CameraZoomSystem(super.parent.getSystem(CameraZoomSystem)).scaleRate); }
		public function set zoomByMotion(zoomByMotion:Boolean):void { CameraZoomSystem(super.parent.getSystem(CameraZoomSystem)).scaleByMotion = zoomByMotion; }
		public function get zoomByMotion():Boolean { return(CameraZoomSystem(super.parent.getSystem(CameraZoomSystem)).scaleByMotion); }
		public function set zoomMotionTarget(zoomMotionTarget:Motion):void { CameraZoomSystem(super.parent.getSystem(CameraZoomSystem)).target = zoomMotionTarget; }
		public function get zoomMotionTarget():Motion { return(CameraZoomSystem(super.parent.getSystem(CameraZoomSystem)).target); }
		public static const GROUP_ID:String = "cameraGroup";
		public static const CAMERA_ID:String = "camera";
		public static const LAYER_BACKGROUND:String = "background";
		public static const LAYER_BACKDROP:String = "backdrop";
		public static const LAYER_INTERACTIVE:String = "interactive";
		public var allowLayerGrid:Boolean = true;
	}
}
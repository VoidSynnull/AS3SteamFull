/**
 * Syncronizes display objects with their spatial properties.
 */

package engine.systems
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.SpatialOffset;
	import engine.nodes.RenderNode;
	
	import game.data.display.BitmapWrapper;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class RenderSystem extends System
	{		
		public function RenderSystem()
		{
			super._defaultPriority = SystemPriorities.render;
		}
		
		override public function addToEngine( systemsManager:Engine ) : void
		{
			_nodes = systemsManager.getNodeList( RenderNode );
			
			for( var node : RenderNode = _nodes.head; node; node = node.next )
			{
				addToDisplay( node );
			}
			
			_nodes.nodeAdded.add( addToDisplay );
			_nodes.nodeRemoved.add( removeFromDisplay );
		}
		
		private function addToDisplay( node:RenderNode ) : void
		{			
			//node.display.container.addChild( node.display.displayObject );
			//sync spatial component once to allow for sleep position check to work.
			if(node.display.displayObject != null)
			{
				// on add, update any NaN spatial values with the properties from the display object
				syncWithDisplay(node.display, node.spatial);
				
				// sync the displayObject with the spatial component
				if(!node.display.isStatic)
				{
					syncWithSpatial(node.display, node.spatial, node.spatialOffset, node.spatialAddition);
				}
				/*
				if(!Display(node.display).interactive)
				{
					node.display.displayObject.mouseEnabled = false;
					node.display.displayObject.mouseChildren = false;
				}
				*/
				if(node.display.container == null)
				{
					node.display.container = node.display.displayObject.parent;
				}
			}
			else
			{
				setSpatialDefaults(node.spatial);
			}
		}
		
		private function removeFromDisplay( node:RenderNode ) : void
		{
			var displayObject:DisplayObject = node.display.displayObject;
			var bitmapWrapper:BitmapWrapper = node.display.bitmapWrapper;
			
			if(displayObject)
			{
				if(displayObject.parent)
				{
					if(displayObject.parent is Loader)
					{
						Loader(displayObject.parent).unload();
					}
					else
					{
						displayObject.parent.removeChild(displayObject);
					}
				}
			}
			
			if (displayObject != null)
			{
				if(displayObject is Bitmap)
				{
					var data:BitmapData = Bitmap(displayObject).bitmapData;
					
					/**
					 * There's the possibility that a Bitmap's Bitmap Data might be null if something else (like a system)
					 * is modifying it, so make sure it's not null before disposing.
					 */
					if(data)
					{
						data.dispose();
						data = null;
					}
				}
			}
			
			if(bitmapWrapper != null)
			{
				bitmapWrapper.destroy();
			}
		}
		
		override public function update(time:Number):void
		{
			var node:RenderNode;
			
			for( node = _nodes.head; node; node = node.next )
			{
				updateNode(node, time);
			}
		}		

		[Inline]
		final private function updateNode(node:RenderNode, time:Number):void
		{						
			if(node.display.displayObject != null)
			{
				if (EntityUtils.sleeping(node.entity))
				{
					if(!EntityUtils.paused(node.entity))
					{
						node.display.displayObject.visible = false;
					}
					//node.display.displayObject.alpha = .5;
					return;
				}
				else
				{
					node.display.displayObject.visible = node.display.visible;
					node.display.displayObject.alpha = node.display.alpha;
					//node.display.displayObject.alpha = 1;
				}
				
				var invalidate:Boolean = node.spatial._invalidate;
				
				if(!invalidate)
				{
					if(node.spatialOffset)
					{
						if(node.spatialOffset._invalidate)
						{
							invalidate = true;
						}
					}
					
					if(node.spatialAddition)
					{
						if(node.spatialAddition._invalidate)
						{
							invalidate = true;
						}
					}
				}
				
				if(!node.display.isStatic && invalidate)
				{
					syncWithSpatial(node.display, node.spatial, node.spatialOffset, node.spatialAddition);
					
					if(node.spatial.componentManagers.length == 1)
					{
						node.spatial._invalidate = false;
					}
				}
			}
		}
		
		
		private function syncWithDisplay(display:Display, spatial:Spatial):void
		{
			var displayObject:* = display.displayObject;
			
			if(isNaN(spatial.x)) { spatial.x = displayObject.x; }
			if(isNaN(spatial.y)) { spatial.y = displayObject.y; }
			if(isNaN(spatial.rotation)) { spatial.rotation = displayObject.rotation; }
			if(isNaN(spatial.scaleX)) { spatial.scaleX = displayObject.scaleX; }
			if(isNaN(spatial.scaleY)) { spatial.scaleY = displayObject.scaleY; }
			if(isNaN(spatial.width)) { spatial.width = displayObject.width; spatial._updateWidth = false; }
			if(isNaN(spatial.height)) { spatial.height = displayObject.height; spatial._updateHeight = false; }
			//if(isNaN(display.alpha)) { display.alpha = displayObject.alpha; }
			//if(display.visible == null) { display.visible = displayObject.visible; }
		}
		
		[Inline]
		final private function syncWithSpatial(display:Display, spatial:Spatial, spatialOffset:SpatialOffset = null, spatialAddition:SpatialAddition = null):void
		{									
			var displayObject:* = display.displayObject;
			var x:Number = spatial.x;
			var y:Number = spatial.y;
			var rotation:Number = spatial.rotation;
			var scaleX:Number = spatial.scaleX;
			var scaleY:Number = spatial.scaleY;
						
			if(spatialOffset != null)
			{
				x += spatialOffset.x;
				y += spatialOffset.y;
				rotation += spatialOffset.rotation;
				scaleX += spatialOffset.scaleX;
				scaleY += spatialOffset.scaleY;
			}
			
			if(spatialAddition != null)
			{
				x += spatialAddition.x;
				y += spatialAddition.y;
				rotation += spatialAddition.rotation;
				scaleX += spatialAddition.scaleX;
				scaleY += spatialAddition.scaleY;
			}
			
			if (rotation < -180)
			{
				rotation += 360;
			}
			else if (rotation >= 180)
			{
				rotation -= 360;
			}
					
			displayObject.x = x;
			displayObject.y = y;
			displayObject.rotation = rotation;
			displayObject.scaleX = scaleX;
			displayObject.scaleY = scaleY;
			
			
			// width and height are special case spatial properties.  The displayObject is only updated with their values if it is told to.  Otherwise the 'private' _width/_height' values are updated 
			//   so the getters on the component report the correct values.
			if(spatial._updateWidth) 
			{ 
				displayObject.width = spatial.width; 
				spatial.scaleX = displayObject.scaleX;
				
			}
			else 
			{ 
				spatial.width = displayObject.width; 
			}
			spatial._updateWidth = false;
			
			if(spatial._updateHeight) 
			{ 
				displayObject.height = spatial.height;
				spatial.scaleY = displayObject.scaleY;
				
			}
			else 
			{ 
				spatial.height = displayObject.height; 
			}
			spatial._updateHeight = false;
			
			display.syncedWithSpatial = true;
		}
				
		private function setSpatialDefaults(spatial:Spatial):void
		{
			if(isNaN(spatial.x)) { spatial.x = 0; }
			if(isNaN(spatial.y)) { spatial.y = 0; }
			if(isNaN(spatial.rotation)) { spatial.rotation = 0; }
			if(isNaN(spatial.scaleX)) { spatial.scaleX = 1; }
			if(isNaN(spatial.scaleY)) { spatial.scaleY = 1; }
		}
		
		private function syncProperty(property:String, display:Display, spatial:Spatial):void
		{
			var prop:* = spatial[property];
			
			if (spatial[property] == null || isNaN(spatial[property]))
			{
				spatial[property] = display[property];
			}
			else
			{
				display[property] = spatial[property];
			}
		}
		
		override public function removeFromEngine(systemsManager:Engine) : void
		{
			systemsManager.releaseNodeList(RenderNode);
			_nodes = null;
		}
		
		private var _nodes:NodeList;
	}
}
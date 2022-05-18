package engine.systems
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Camera;
	import engine.components.Spatial;
	import engine.nodes.CameraLayerNode;
	import engine.nodes.CameraNode;
	
	import game.systems.SystemPriorities;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;

	/**
	 * Moves camera layers based on the distance from target.  Applies an ease based on 'rate'.
	 */
	
	public class CameraSystem extends System
	{
		public function CameraSystem()
		{
			super._defaultPriority = SystemPriorities.cameraUpdate;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_nodes = systemManager.getNodeList(CameraLayerNode);
			_cameraNodes = systemManager.getNodeList(CameraNode);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(CameraLayerNode);
			systemManager.releaseNodeList(CameraNode);
			_cameraNodes = null;
			_cameraNode = null;
			_camera = null;
			_nodes = null;
		}
		
		override public function update(time:Number):void
		{									
			// only one camera is supported at a time (primarily for legacy support) but this could be changed if we need multiple.
			_cameraNode = _cameraNodes.head;
			
			if(_cameraNode)
			{					
				if(_pendingCameraTarget)
				{
					_cameraNode.target.target = _pendingCameraTarget;
					_pendingCameraTarget = null;
				}
				
				var camera:Camera = _camera = _cameraNode.camera;
				var target:Spatial = _cameraNode.target.target;
				
				camera.update(target.x + _offsetX, target.y);

				var deltaX:Number = (-camera.viewportX - camera.viewportWidth * .5) - camera.layerOffsetX;
				var deltaY:Number = (-camera.viewportY - camera.viewportHeight * .5) - camera.layerOffsetY;
				var rate:Number = camera.rate;

				if (_jumpToTarget)
				{
					_jumpToTarget = false;
					rate = 1;
				}
				else
				{
					rate = Utils.getVariableTimeEase(camera.rate, time);
				}
				
				if (Math.abs(deltaX * rate) > rate)
				{
					deltaX *= rate;
				}
				else
				{
					deltaX = 0;
				}
				
				if (Math.abs(deltaY * rate) > rate)
				{
					deltaY *= rate;
				}
				else
				{
					deltaY = 0;
				}
				
				if (deltaX != 0 || deltaY != 0)
				{				
					camera.layerOffsetX += deltaX;
					camera.layerOffsetY += deltaY;
					
					updateNodes(time, _cameraNode);
				}
				
				if(_doUpdateCheck)
				{
					_totalUpdates--;
					
					if(_totalUpdates == 0)
					{
						_doUpdateCheck = false;
						this.updateCheckComplete.dispatch();
					}
				}
			}
		}
		
		public function updateNodes(time:Number, cameraNode:CameraNode):void
		{
			var node:CameraLayerNode;
			
			for( node = _nodes.head; node; node = node.next )
			{
				updateNode(node, cameraNode, time);
			}
		}
		
		public function updateNode(node:CameraLayerNode, cameraNode:CameraNode, time:Number):void
		{			
			var deltaX:Number = (1 - node.cameraLayer.rate) * cameraNode.camera.viewportWidth * .5;
			var deltaY:Number = (1 - node.cameraLayer.rate) * cameraNode.camera.viewportHeight * .5;
			var camera:Camera = cameraNode.camera;
						
			node.spatial.x = camera.layerOffsetX * node.cameraLayer.rate;
			node.spatial.y = camera.layerOffsetY * node.cameraLayer.rate;
				
			node.spatial.x -= deltaX;
			node.spatial.y -= deltaY;
		}
		
		public function startUpdateCheck():void
		{
			if(updateCheckComplete == null)
			{
				this.updateCheckComplete = new Signal();
			}
			_doUpdateCheck = true;
			_totalUpdates = 1;
		}
		
		public function resize(viewportWidth:Number, viewportHeight:Number, areaWidth:Number, areaHeight:Number):void
		{
			if(_cameraNode)
			{
				_cameraNode.camera.resize(viewportWidth, viewportHeight, areaWidth, areaHeight);
			}
		}		

		public function get x():Number { return(_camera.layerOffsetX); }
		public function get y():Number { return(_camera.layerOffsetY); }		
		public function get rate():Number { return(_camera.rate); }
		public function set rate(rate:Number):void { _camera.rate = rate; }
		public function get scale():Number 
		{ 
			if(_cameraNode) 
			{ 
				return(_cameraNode.spatial.scale);
			} 
			else 
			{ 
				return(1);
			} 
		}
		public function set scale(scale:Number):void 
		{ 
			if(_cameraNode)
			{
				if(_cameraNode.spatial.scale != scale)
				{
					_cameraNode.spatial.scale = scale;
					_cameraNode.camera.updateLimits(scale);
				}
			}
		}
		public function get target():Spatial 
		{ 
			if(_cameraNode) { return(_cameraNode.target.target); }
			else return(_pendingCameraTarget);
		}
		public function set target(target:Spatial):void 
		{ 
			if(_cameraNode == null)
			{
				_pendingCameraTarget = target;
			}
			else
			{
				_cameraNode.target.target = target;
			}
		}
		public function get viewportWidth():Number { return(_camera.viewportWidth); }
		public function get viewportHeight():Number { return(_camera.viewportHeight); }
		public function get areaWidth():Number { return(_camera.areaWidth); }
		public function get areaHeight():Number { return(_camera.areaHeight); }
		public function set jumpToTarget(jump:Boolean):void { _jumpToTarget = jump; }
		public function get center():Point { return(_camera.center); }
		public function get viewport():Rectangle { return(_camera.viewport); }
		public function get targetDeltaX():Number { return(_camera.targetDeltaX); }
		public function get targetDeltaY():Number { return(_camera.targetDeltaY); }
		public function get camera():Camera { return(_camera); }
		// temp holder for camera component, so scenes that need access before camera enity is added can get it.
		public function set camera(camera:Camera):void { _camera = camera; }
		public function set offsetX(offset:Number):void { _offsetX = offset; }
		
		public var updateCheckComplete:Signal;
		private var _totalUpdates:int = 0;
		private var _doUpdateCheck:Boolean = false;
		private var _nodes:NodeList;
		private var _cameraNodes:NodeList;
		private var _cameraNode:CameraNode;
		private var _camera:Camera;
		private var _pendingCameraTarget:Spatial;
		private var _jumpToTarget:Boolean = true;
		private var _offsetX:Number = 0;
	}
}
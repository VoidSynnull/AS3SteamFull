package engine.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Camera;
	import engine.components.Motion;
	import engine.creators.CameraLayerCreator;
	import engine.nodes.CameraLayerNode;
	import engine.nodes.CameraNode;

	public class CameraZoomSystem extends System
	{
		public function CameraZoomSystem()
		{

		}
		
		override public function addToEngine( game : Engine ) : void
		{
			_cameraLayerNodes = systemManager.getNodeList(CameraLayerNode);
			_cameraNodes = systemManager.getNodeList(CameraNode);
		}
		
		override public function removeFromEngine( game : Engine ) : void
		{
			_cameraNodes = null;
			_cameraNode = null;
			_cameraLayerNodes = null;
		}
		
		override public function update(time:Number):void
		{									
			_cameraNode = _cameraNodes.head;
			
			if(_cameraNode)
			{
				var camera:Camera = _cameraNode.camera;
				
				if(camera.scaleByMotion)
				{
					if (Math.abs(camera.scaleMotionTarget.acceleration.length) > 0)
					{
						if (_scaleDelay < _scaleWait)
						{
							_scaleDelay += time;
						}
						else 
						{
							camera.scaleTarget = this.minCameraScale;
						}
					}
					else if(camera.scaleMotionTarget.velocity.length <= camera.zoomInVelocity)
					{
						if (_scaleDelay > -_scaleWait)
						{
							_scaleDelay -= time;
						}
						else 
						{
							camera.scaleTarget = this.maxCameraScale;
						}
					}
				}
				
				if(_cameraNode.spatial.scale != camera.scaleTarget)
				{
					setScale(camera, camera.scaleTarget - _cameraNode.spatial.scale);
				}
			}
		}
		
		private function setScale(camera:Camera, scaleDelta:Number):void
		{
			var limitDelta:Number = 0;
			
			if (Math.abs(scaleDelta) > MINIMUM_SCALE_DELTA)
			{
				limitDelta = scaleDelta * camera.scaleRate
				
				_cameraNode.spatial.scale += limitDelta;
				
				// TEMP - compensate for layers getting pulled beyond edge due to camera pan easing.
				limitDelta *= 4;
			}
			else
			{
				_cameraNode.spatial.scale = camera.scaleTarget;
			}
			
			_cameraNode.camera.updateLimits(_cameraNode.spatial.scale + limitDelta);

			// update the position and scale of each camera layer based on its movement rate, dimensions and camera scale.
			var node:CameraLayerNode;
			
			for( node = _cameraLayerNodes.head; node; node = node.next )
			{
				CameraLayerCreator.adjustScaleForRate(node.spatial, _cameraNode.spatial.scale, node.cameraLayer.rate, _cameraNode.camera.viewportWidth, _cameraNode.camera.viewportHeight, _cameraNode.camera.areaWidth, _cameraNode.camera.areaHeight);
				CameraLayerCreator.adjustOffsetForScaleAndRate(node.spatialOffset, _cameraNode.spatial.scale, node.cameraLayer.rate, _cameraNode.camera.viewportWidth, _cameraNode.camera.viewportHeight);
			}
		}
		
		public function get target():Motion { return(_cameraNode.camera.scaleMotionTarget); }
		public function set target(target:Motion):void 
		{ 
			_cameraNode.camera.scaleMotionTarget = target;
			_cameraNode.camera.zoomInVelocity = target.minVelocity.length * 2;
		}
		
		public function set scaleTarget(scaleTarget:Number):void
		{
			_cameraNode.camera.scaleTarget = scaleTarget;
		}
		
		public function set scaleRate(scaleRate:Number):void
		{
			_cameraNode.camera.scaleRate = scaleRate;
		}
		
		public function set minCameraScale(minCameraScale:Number):void
		{
			_cameraNode.camera.minCameraScale = minCameraScale;
		}
		
		public function set maxCameraScale(maxCameraScale:Number):void
		{
			_cameraNode.camera.maxCameraScale = maxCameraScale;
		}
		
		public function set scaleByMotion(zoomByMotion:Boolean):void
		{
			_cameraNode.camera.scaleByMotion = zoomByMotion;
		}
		
		public function get minCameraScale():Number { return(_cameraNode.camera.minCameraScale); }
		public function get maxCameraScale():Number { return(_cameraNode.camera.maxCameraScale); }
		public function get scaleTarget():Number { return(_cameraNode.camera.scaleTarget); }
		public function get scaleRate():Number { return(_cameraNode.camera.scaleRate); }
		public function get scaleByMotion():Boolean { return(_cameraNode.camera.scaleByMotion); }
		
		private var _scaleDelay:Number = 0;
		private var _scaleWait:Number = .08;
		private var _cameraNodes:NodeList;
		private var _cameraNode:CameraNode;
		private var _cameraLayerNodes:NodeList;
		private const MINIMUM_SCALE_DELTA:Number = .002;
	}
}
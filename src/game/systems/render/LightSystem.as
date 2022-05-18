package game.systems.render
{
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	import engine.nodes.CameraNode;
	
	import game.nodes.render.LightNode;
	import game.nodes.render.LightOverlayNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class LightSystem extends System
	{
		public function LightSystem()
		{
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		private const THIRTY_FPS:Number = 1/30;
		
		override public function update(time:Number):void
		{
			if(time > THIRTY_FPS)
			{
				if(_timeSinceLastUpdate < time * 2)
				{
					_timeSinceLastUpdate += time;
					return;
				}
			}
			
			_timeSinceLastUpdate = 0;
			
			_lightOverlayNode = _lightOverlayNodes.head;
			_cameraNode = _cameraNodes.head;
			
			if(_lightOverlayNode != null)
			{
				var overlay:Sprite = _lightOverlayNode.display.displayObject;
				var overlaySpatial:Spatial = _lightOverlayNode.spatial;
				var lightRadius:Number;
				var darkAlpha:Number;
				var targetX:Number;
				var targetY:Number;
				var node:LightNode;
				var gradientMatrix:Matrix;
				
				overlay.graphics.clear();
				overlay.graphics.beginFill(_lightOverlayNode.lightOverlay.color, _lightOverlayNode.lightOverlay.darkAlpha);
				overlay.graphics.drawRect(0, 0, overlaySpatial.width, overlaySpatial.height);
				
				for( node = _lightNodes.head; node; node = node.next )
				{
					if (!EntityUtils.sleeping(node.entity))
					{
						lightRadius = node.light.radius;
						targetX = super.group.shellApi.sceneToGlobal(node.spatial.x, "x");
						targetY = super.group.shellApi.sceneToGlobal(node.spatial.y, "y");
						
						if(_cameraNode.spatial.scale != 1)
						{
							lightRadius *= _cameraNode.spatial.scale;
						}
						
						overlay.graphics.drawCircle(targetX, targetY, lightRadius);
					}
				}
				
				for( node = _lightNodes.head; node; node = node.next )
				{
					if (!EntityUtils.sleeping(node.entity))
					{
						if(node.light.gradient)
						{
							lightRadius = node.light.radius;
							darkAlpha = node.light.darkAlpha;
							if(node.light.matchOverlayDarkAlpha)
								darkAlpha = _lightOverlayNode.lightOverlay.darkAlpha;
							targetX = super.group.shellApi.sceneToGlobal(node.spatial.x, "x");
							targetY = super.group.shellApi.sceneToGlobal(node.spatial.y, "y");
							
							if(_cameraNode.spatial.scale != 1)
							{
								lightRadius *= _cameraNode.spatial.scale;
							}
							
							gradientMatrix = new Matrix();
							gradientMatrix.createGradientBox(lightRadius*2, lightRadius*2, 0, targetX - lightRadius, targetY - lightRadius);
							overlay.graphics.beginGradientFill("radial", [node.light.color, node.light.color2], [node.light.lightAlpha, darkAlpha], [0, 255], gradientMatrix);
							overlay.graphics.drawCircle(targetX, targetY, lightRadius);
						}
					}
				}
				
				overlay.graphics.endFill();
			}
		}
				
		override public function removeFromEngine(systemManager:Engine):void
		{
			super.removeFromEngine(systemManager);
			
			systemManager.releaseNodeList(LightNode);
			systemManager.releaseNodeList(LightOverlayNode);
			
			_lightOverlayNodes = null;
			_lightOverlayNode = null;
			_lightNodes = null;
			_cameraNodes = null;
			_cameraNode = null;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_lightOverlayNodes = systemManager.getNodeList(LightOverlayNode);
			_cameraNodes = systemManager.getNodeList(CameraNode);
			_lightNodes = systemManager.getNodeList(LightNode);
			
			super.addToEngine(systemManager);
		}
		
		private var _lightOverlayNodes:NodeList;
		private var _lightOverlayNode:LightOverlayNode;
		private var _cameraNodes:NodeList;
		private var _cameraNode:CameraNode;
		private var _lightNodes:NodeList;
		private var _timeSinceLastUpdate:Number = 0;
		
	}
}
package game.systems.scene
{
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.display.BitmapWrapper;
	import game.nodes.scene.RainRandomClipsNode;
	import game.scene.template.GameScene;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	public class RainRandomClipsSystem extends System
	{		
		/**
		 * Constructor 
		 * @param scene
		 * @param frequency (how many updates between new falling clip)
		 * 
		 */
		public function RainRandomClipsSystem(scene:GameScene, frequency:int = 10, speed:int = 900, removeSceneClips = true)
		{
			super._defaultPriority = SystemPriorities.lowest;
			
			// save variables
			_scene = scene;
			_hitContainer = _scene.hitContainer;
			if (frequency > 0)
				_frequency = frequency;
			if (speed > 0)
				_speed = speed;
			if(removeSceneClips == false)
				_removeSceneClips = removeSceneClips;
			
			// get rain clips in scene (clips that start with "rain")
			for (var i:int = _hitContainer.numChildren - 1; i!= -1; i--)
			{
				var clip:DisplayObject = _hitContainer.getChildAt(i);
				if (clip.name.substr(0,4) == "rain")
				{
					// convert to bitmap and add to vector
					var bitmapWrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite(clip);
					_rainClips.push(bitmapWrapper);
				}
			}
		}

		override public function update(time:Number):void
		{
			var node:RainRandomClipsNode;
			
			// if falling clips
			if (_fallingClips.length != 0)
			{
				// for each clip
				for (var i:int = _fallingClips.length-1; i!= -1; i--)
				{
					// get entity
					var entity:Entity = _fallingClips[i];
					// if now offscreen
					if (entity.get(Spatial).y >= _scene.shellApi.globalToScene(0, "y") + _scene.shellApi.viewportHeight)
					{
						// remove from scene group
						_scene.removeEntity(entity);
						// remove from list
						_fallingClips.splice(i,1);
						// dispose of bitmap
						_fallingBitmaps[i].destroy(false);
						// remove from list
						_fallingBitmaps.splice(i,1);
					}
				}
			}
			
			// increment counter
			_counter++;
			// if reach frequency, then add new falling clip
			if (_counter == _frequency)
			{
				// reset counter
				_counter = 0;
				// get random number
				var num:int = Math.floor(_rainClips.length * Math.random());
				// get copy of bitmap
				var bitmapWrapper:BitmapWrapper = _rainClips[num].duplicate();
				// create entity
				entity = EntityUtils.createMovingEntity( _scene, bitmapWrapper.sprite, _hitContainer );
				// set position and speed
				entity.get(Motion).velocity.y = _speed;
				entity.get(Spatial).x = _scene.shellApi.globalToScene(0, "x") + _scene.shellApi.viewportWidth * Math.random();
				entity.get(Spatial).y = _scene.shellApi.globalToScene(0, "y");
				// add to lists
				_fallingClips.push(entity);
				_fallingBitmaps.push(bitmapWrapper);
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_nodes = systemManager.getNodeList(RainRandomClipsNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(RainRandomClipsNode);
			
			_nodes = null;
			
			if(_removeSceneClips)
			{
				// clear rain clips
				for (var i:int = _rainClips.length -1; i!= -1; i--)
				{
					// dispose of bitmap
					_rainClips[i].destroy(true);
					// remove from list
					_rainClips.splice(i,1);
				}
				
				// clear falling clips
				for (i = _fallingClips.length -1; i!= -1; i--)
				{
					// remove from scene group
					_scene.removeEntity(_fallingClips[i]);
					// remove from list
					_fallingClips.splice(i,1);
					// dispose of bitmap
					_fallingBitmaps[i].destroy(true);
					// remove from bitmap list
					_fallingBitmaps.splice(i,1);
				}
			}
			else
			{
				for (i = _fallingClips.length -1; i!= -1; i--)
				{
					var entity:Entity = _fallingClips[i];
					entity.get(Spatial).y = _scene.sceneData.cameraLimits.height + entity.get(Spatial).height * 2;
				}
			}
		}
		
		private var _nodes:NodeList;
		private var _scene:GameScene;
		private var _hitContainer:DisplayObjectContainer;
		private var _frequency:int = 10;
		private var _speed:int = 900;
		private var _counter:int = 0;
		
		private var _rainClips:Vector.<BitmapWrapper> = new Vector.<BitmapWrapper>();
		private var _fallingClips:Vector.<Entity> = new Vector.<Entity>();
		private var _fallingBitmaps:Vector.<BitmapWrapper> = new Vector.<BitmapWrapper>();
		private var _removeSceneClips:Boolean = true;
	}
}

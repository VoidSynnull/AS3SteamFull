// Used by:
// Card 2897 using item in2_multiply

package game.data.specialAbility.character
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.data.display.SharedBitmapData;
	
	import game.data.TimedEvent;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	/**
	 * Create swarm of swfs moving across ground of scene
	 * 
	 * required params:
	 * swfPath			String		Path to swf file
	 * 
	 * optional params:
	 * numObjects		Number		Number of objects (default is 6)
	 * interval			Number		Interval for objects to multiply (default is 0.25)
	 * numIntervals		Number		Total number of intervals before end (default is 10)
	 * spacing			Number		Spacing between objects
	 */
	public class TransformMultiply extends SpecialAbility
	{				
		override public function activate( node:SpecialAbilityNode ):void
		{
			if(_swfPath)
				super.loadAsset(_swfPath, loadComplete);
			else
				loadComplete(Display(node.entity.get(Display)).displayObject);
		}	
		
		/**
		 * When swf has loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			if (clip != null)
			{
				super.setActive(true);
				SceneUtil.lockInput(super.group, true);
				
				_clip = clip;
				_counter = 0;
				_offset = 0;
				_objects = new Array();
				
				var bitmapData:BitmapData = BitmapUtils.createBitmapData(_clip);			
				_data = BitmapUtils.createBitmapData(_clip, 1);
				
				var timedEvent:TimedEvent = new TimedEvent( _interval, 0, createCopy);
				_timer = SceneUtil.addTimedEvent(super.group, timedEvent, "multiply");
				
				// make first copy
				createCopy();
			}
		}
		
		// create new copy
		private function createCopy():void
		{
			if (_counter <= _numObjects)
			{
				_data = BitmapUtils.createBitmapData(_clip, 1);
				var objectEntity:Entity = EntityUtils.createSpatialEntity(super.group, BitmapUtils.createBitmapSprite(_clip, 1, null, true, 0, _data), super.entity.get(Display).container);
				
				// player position
				var xPos:Number = super.entity.get(Spatial).x;
				var yPos:Number = super.entity.get(Spatial).y;
				
				if (_counter == 0)
				{
					// hide player
					super.entity.get(Display).visible = false;
					
					objectEntity.get(Spatial).x = xPos;
					objectEntity.get(Spatial).y = yPos;
				}
				else
				{
					// if odd
					if (_counter % 2 == 1)
					{
						_offset += _spacing;
						objectEntity.get(Spatial).x = xPos + _offset;
					}
					else
					{
						objectEntity.get(Spatial).x = xPos - _offset;
					}
					objectEntity.get(Spatial).y = yPos;
					//objectEntity.get(Spatial).y = super.shellApi.camera.viewport.y + Math.random() * super.shellApi.camera.viewport.height;		
				}
				
				_objects.push(objectEntity);
			}
			_counter++;
			
			// if reach end
			if (_counter == _numIntervals)
				endMultiply();
		}
		
		/**
		 * When multiplication ends 
		 */
		private function endMultiply():void
		{
			_data = null;
			
			// stop timer
			_timer.stop();
			
			// make player visible again
			super.entity.get(Display).visible = true;

			// unlock input
			SceneUtil.lockInput( super.group, false );
			
			// remove entities
			for(var i:Number=0; i != _objects.length; i++)
			{
				super.group.removeEntity(_objects[i]);
			}
			_objects = null;
			
			// make inactive
			super.setActive( false );
		}
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		public var _numObjects:Number = 6;
		public var _interval:Number = 0.25;
		public var _numIntervals:Number = 10;
		public var _spacing:Number = 150;
		
		private var _objects:Array = new Array();
		private var _counter:int = 0;
		private var _clip:MovieClip;
		private var _data:SharedBitmapData;
		private var _offset:Number = 0;
		private var _timer:TimedEvent;
	}
}
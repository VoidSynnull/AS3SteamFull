package game.scenes.custom.StarShooterSystem
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import engine.data.display.SharedBitmapData;
	
	import game.components.timeline.BitmapSequence;
	
	import org.osflash.signals.Signal;
	
	public class StarShooter extends Component
	{
		public var playing:Boolean = false;
		public var progressTime:Number = 0;
		public var endTime:Number = 30;
		//if(progressTime > a key in encounters and currentPatternTime < the key)
		// set currentPatternTime, spawn pattern and start pattern sequence
		public var currentPatterTime:Number = 0;
		// will be a dictionary with keys as time stamp,
		// and values as the name of the pattern to use
		public var encounters:Dictionary;
		//objects created that can be reused or referenced multiple times
		public var pool:Dictionary;
		
		public var done:Signal;
		
		public var hits:int = 0;
		
		public var score:int = 0;
		
		public var hud:MovieClip;
		
		public var alignment:String = "horizontal";
		
		public function StarShooter(endTime:Number)
		{
			encounters = new Dictionary();
			pool = new Dictionary();
			this.endTime = endTime;
			done = new Signal();
		}
		
		public function getPooledObject(type:String, ref:Boolean = false):*
		{
			if(pool == null)
				return;
			
			var obj:* = null;
			if(pool.hasOwnProperty(type))
			{
				var list:Array = pool[type];
				if(list.length > 0)
				{
					obj = ref?list[0] : list.pop();
				}
			}
			return obj;
		}
		
		public function poolObject(type:String, obj:*):void
		{
			if(pool == null)
				return;
			
			var list:Array = [];
			if(pool.hasOwnProperty(type))
			{
				list = pool[type];
			}
			list.push(obj);
			pool[type] = list;
		}
		
		override public function destroy():void
		{
			if(pool == null)
				return;
			
			for(var key:String in pool)
			{
				if(key.indexOf("bitmap")>=0)
				{
					if(getPooledObject(key, true) is BitmapSequence)
					{
						var bitmapSequence:BitmapSequence = getPooledObject(key);
						bitmapSequence.destroy();
					}
					else
					{
						var bitmap:SharedBitmapData = getPooledObject(key);
						bitmap.dispose();
					}
				}
				delete pool[key];
			}
			for(var time:Number in encounters)
			{
				delete pool[time];
			}
			encounters = null;
			pool = null;
			hud = null;
			done.removeAll();
			done = null;
		}
	}
}
package game.test
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.System;
	import flash.utils.setTimeout;

	public class GarbageCollectionCycle extends Sprite
	{
		public function GarbageCollectionCycle()
		{
		}
		
		public function start():void
		{
			_gcCount = 0;
			addEventListener(Event.ENTER_FRAME, doGC);
		}
		
		private function doGC(evt:Event):void
		{
			System.gc();
			System.gc();
			
			if(++_gcCount > 1)
			{
				removeEventListener(Event.ENTER_FRAME, doGC);
				setTimeout(lastGC, 100);
			}
		}
		
		private function lastGC():void
		{
			System.gc();
			System.gc();
			
			trace("GarbageCollectionCycle :: Last GC");
		}
		
		private var _gcCount:int;
	}
}
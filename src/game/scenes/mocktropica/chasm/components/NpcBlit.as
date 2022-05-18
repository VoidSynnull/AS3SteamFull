package game.scenes.mocktropica.chasm.components
{
	import flash.display.BitmapData;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class NpcBlit extends Component
	{
		
		public function NpcBlit($sampleNPC:Entity, $bmdWidth:Number, $bmdHeight:Number):void{
			sampleNPC = $sampleNPC;
			bmdWidth = $bmdWidth;
			bmdHeight = $bmdHeight;
			bitmapData = new BitmapData(bmdWidth, bmdHeight, true, 0x000000);
			
			trace("BITMAP DATA CREATED");
		}
		
		public var ready:Boolean = false;     // flag to start blitting when NPC is created
		
		public var sampleNPC:Entity;			    // sample NPC entity
		public var bitmapData:BitmapData;			// sampled NPC bitmapData of display
		
		public var drawnBitmapData:BitmapData;
		
		public var bmdWidth:Number; 				// bitmap data width
		public var bmdHeight:Number;				// bitmap data height
	}
}
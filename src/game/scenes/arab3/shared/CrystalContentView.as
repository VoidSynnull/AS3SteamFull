package game.scenes.arab3.shared
{

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.components.ui.CardItem;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.display.BitmapWrapper;
	import game.ui.card.CardContentView;
	import game.util.EntityUtils;
	
	public class CrystalContentView extends CardContentView
	{
		private var piecesDir:String = "items/arab3/crystals.swf";
		
		public function CrystalContentView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			super.loadFile(piecesDir, cardContentLoaded, null, onComplete);
		}
		
		private function cardContentLoaded(asset:DisplayObjectContainer, inPieces:Boolean, handler:Function = null):void
		{
			super.unpause();
			
			super.groupContainer.addChild(asset);
			
			var crystals:Entity;// = EntityUtils.createMovingTimelineEntity(this, asset["crystals"], groupContainer);
			var clip:MovieClip = asset["crystals"]; 
			var seq:BitmapSequence = BitmapTimelineCreator.createSequence( clip, true, 3 );
			crystals = makeEntity( clip, false, seq );
			Timeline(crystals.get(Timeline)).gotoAndStop("pile");
			
			if(handler != null)
				handler();
		}
		
		private function makeEntity( clip:MovieClip, play:Boolean = true, sequence:BitmapSequence = null ):Entity
		{
			if( sequence )
			{
				var target:Entity = EntityUtils.createMovingTimelineEntity(this, clip, null, play);
				target = BitmapTimelineCreator.convertToBitmapTimeline(target, clip, true, sequence, 3);
			}
			else
			{
				var wrapper:BitmapWrapper = super.convertToBitmapSprite( clip, null, true, 3 );
				target = EntityUtils.createSpatialEntity( this, wrapper.sprite );
			}
			
			target.add( new Id( clip.name ));
			return target; 
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
	}
}
package game.creators.entity
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.BitmapTimeline;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMaster;
	import game.components.timeline.TimelineMasterVariable;
	import game.data.BitmapFrameData;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;

	public class BitmapTimelineCreator
	{
		static public function createBitmapTimeline(clip:MovieClip, transparent:Boolean=true, swap:Boolean = true, sequence:BitmapSequence=null, quality:Number=1, frameRate:int = 32):Entity
		{
			return createEntity(null, clip, sequence, transparent, quality, frameRate, swap);
		}
		
		static public function convertToBitmapTimeline(entity:Entity = null, clip:MovieClip = null, transparent:Boolean = true, sequence:BitmapSequence = null, quality:Number = 1, frameRate:int = 32, swap:Boolean = true):Entity 
		{
			return createEntity(entity, clip, sequence, transparent, quality, frameRate, swap);
		}
		
		private static function createEntity(entity:Entity, clip:MovieClip, sequence:BitmapSequence = null, transparent:Boolean = true, quality:Number = 1, frameRate:int = 32, swap:Boolean = true):Entity
		{
			if(!entity)
			{
				entity = new Entity();
			}
			
			var display:Display = entity.get(Display);
			if(!display)
			{
				display = new Display();
				entity.add(display);
			}
			
			if(!clip) clip = display.displayObject;
			
			var spatial:Spatial = entity.get(Spatial);
			if(!spatial)
			{
				spatial = new Spatial();
				entity.add(spatial);
			}
			
			var timeline:Timeline = entity.get(Timeline);
			if(!timeline)
			{
				timeline = new Timeline();
				entity.add(timeline);
			}
			TimelineUtils.parseMovieClip(timeline, clip);
			
			if(frameRate != 32)
			{
				entity.remove(TimelineMaster);
				entity.add(new TimelineMasterVariable(frameRate));
			}
			else
			{
				var timelineMaster:TimelineMaster = entity.get(TimelineMaster);
				if(!timelineMaster)
				{
					timelineMaster = new TimelineMaster();
					entity.add(timelineMaster);
				}
			}
			
			if(!sequence)
			{
				sequence = createSequence(clip, transparent, quality);
			}
			else
			{
				quality = sequence.quality;
			}
			
			var sprite:Sprite 	= new Sprite();
			sprite.transform 	= clip.transform;
			sprite.mouseEnabled = false;
			clip.parent.addChild(sprite);
			
			var bitmap:Bitmap 	= new Bitmap();
			bitmap.scaleX 		= 1 / quality;
			bitmap.scaleY 		= 1 / quality;
			sprite.addChild(bitmap);
			
			if(swap)
			{
				display.displayObject = DisplayUtils.swap(sprite, clip);
			}
			else
			{
				display.displayObject = sprite;
			}
			
			EntityUtils.syncSpatial(spatial, display.displayObject);
			
			entity.add(sequence)
			entity.add(new BitmapTimeline(bitmap));
			
			if( entity.group )
			{
				entity.group.addSystem( new BitmapSequenceSystem() );
			}
			
			return entity;
		}
		
		static public function createSequence(clip:MovieClip, transparent:Boolean = true, quality:Number = 1):BitmapSequence
		{
			var sequence:BitmapSequence = new BitmapSequence(quality);
			
			clip.gotoAndStop(1);
			var previousBounds:Rectangle 	= clip.getBounds(clip);
			var previousData:BitmapData 	= BitmapUtils.createBitmapData(clip, quality, null, transparent);
			
			sequence.frameData[1] = new BitmapFrameData(previousData, previousBounds.left, previousBounds.top);
			sequence.keyFrames.push(1);
			
			var emptyData:BitmapData = new BitmapData(1, 1, transparent, 0);
			
			var totalFrames:int = clip.totalFrames;
			for(var frame:int = 2; frame <= totalFrames; ++frame)
			{
				clip.gotoAndStop(frame);
				var currentBounds:Rectangle = clip.getBounds(clip);
				
				var currentData:BitmapData = currentBounds.isEmpty() ? emptyData : BitmapUtils.createBitmapData(clip, quality, null, transparent);
				
				if(!BitmapUtils.equalBitmapData(currentData, previousData, transparent))
				{
					sequence.frameData[frame] = new BitmapFrameData( currentData, currentBounds.left, currentBounds.top );
					sequence.keyFrames.push(frame);
					
					previousData = currentData;
				}
				else if(previousBounds.left != currentBounds.left || previousBounds.top != currentBounds.top)
				{
					sequence.frameData[frame] = new BitmapFrameData( currentData, currentBounds.left, currentBounds.top );
					sequence.keyFrames.push(frame);
				}
				
				previousBounds = currentBounds;
			}
			
			return sequence;
		}
	}	
}
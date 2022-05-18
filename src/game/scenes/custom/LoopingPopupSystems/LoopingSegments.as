package game.scenes.custom.LoopingPopupSystems
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.entity.MotionMaster;
	import game.components.hit.MovieClipHit;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.creators.entity.BitmapTimelineCreator;
	import game.systems.SystemPriorities;
	import game.systems.entity.MotionMasterSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.utils.MotionWrapUtils;
	
	import org.osflash.signals.Signal;
	
	public class LoopingSegments extends DisplayGroup
	{
		public var motionMaster:MotionMaster;
		private var segments:Vector.<LoopingSegment>;
		private var current:LoopingSegment;
		private var next:LoopingSegment;
		private var index:int;
		private var pieces:Dictionary;
		private var missleSpeed:Number = 0;
		public var reachedEnd:Signal;
		
		public function LoopingSegments(container:DisplayObjectContainer=null)
		{
			reachedEnd = new Signal();
			pieces = new Dictionary();
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			if(parent.getSystem(BitmapSequenceSystem) == null)
				parent.addSystem(new BitmapSequenceSystem(), SystemPriorities.animate);
			if(parent.getSystem(TimelineControlSystem) == null)
				parent.addSystem(new TimelineControlSystem(), SystemPriorities.timelineControl);
			if(parent.getSystem(MotionMasterSystem) == null)
				parent.addSystem(new MotionMasterSystem());
			if(parent.getSystem(LoopingSegmentSystem) == null)
				parent.addSystem(new LoopingSegmentSystem());
			if(parent.getSystem(ThresholdSystem) == null)
				parent.addSystem(new ThresholdSystem(),SystemPriorities.lowest);
		}
		
		public function initData(motionUrl:String, segmentsUrl:String):void
		{
			trace("load: " + motionUrl + " and: " + segmentsUrl);
			loadFiles([motionUrl, segmentsUrl],true,true, Command.create(dataLoaded, motionUrl, segmentsUrl));
		}
		
		private function dataLoaded(motionUrl:String, segmentsUrl:String):void
		{
			trace("data loaded");
			var motionXML:XML = getData(motionUrl,true,true);
			//trace("MotionMaster: " + motionXML);
			if(motionXML.hasOwnProperty("dropVelocity"))
				missleSpeed = DataUtils.getNumber(motionXML.dropVelocity);
			motionMaster = MotionWrapUtils.CreateMotionMaster(motionXML);
			if(motionMaster.direction == "-")
				missleSpeed *= -1;
			motionMaster.active = false;
			parseSegments(getData(segmentsUrl, true, true));
			ready.dispatch(this);
		}
		
		private function parseSegments(xml:XML):void
		{
			//trace("SegmentPatters: " + xml);
			segments = new Vector.<LoopingSegment>();
			var children:XMLList = xml.child("segment");
			for(var i:int = 0; i < children.length(); i++)
			{
				segments.push(new LoopingSegment(children[i]));
			}
		}
		
		public function initSegments():void
		{
			current = segments[0];
			initSegment(current);
			next = segments[1];
			initSegment(next);
			index = 1;
		}
		
		private function initSegment(segment:LoopingSegment):void
		{
			var clip:MovieClip;
			var bg:Entity;
			var entity:Entity;
			var threshold:Threshold;
			var obstacle:ObstacleData
			var motion:Motion;
			var hit:MovieClipHit;
			var sprite:Sprite;
			//bg pos
			var spatial:Spatial;
			//obstacle pos
			var position:Spatial;
			var pool:Array;
			//create or retrieve pool for background
			if(pieces.hasOwnProperty(segment.bgId))
			{
				pool = pieces[segment.bgId];
			}
			else
			{
				pool = [];
				pieces[segment.bgId] = pool;
			}
			//create segment back ground
			if(pool.length > 0)
			{
				bg = pool.pop();
				segment.entity = bg;
				threshold = bg.get(Threshold);
				spatial = bg.get(Spatial);
				motion = bg.get(Motion);
			}
			else
			{
				clip = container[segment.bgId];
				clip.visible = false;
				sprite = convertToBitmapSprite(clip, clip.parent, false).sprite;
				DisplayUtils.moveToBack(sprite);
				bg = EntityUtils.createSpatialEntity(parent, sprite);
				spatial = bg.get(Spatial);
				
				var opperator:String = motionMaster.direction == "-"?"<":">";
				threshold = new Threshold(motionMaster.axis, opperator);
				threshold.threshold = motionMaster.axis == "x"? spatial.width:spatial.height;
				if(motionMaster.direction == "-")
					threshold.threshold *= -1;
				motion = new Motion();
				bg.add(new LoopingSegmentPiece(motionMaster)).add(new Id(clip.name))
					.add(threshold).add(motion);
				segment.entity = bg;
			}
			// position the bg to be flush with the previous bg
			if(segment != current)
			{
				var currentEntity:Entity = current.entity;
				var currentSpatial:Spatial = currentEntity.get(Spatial);
				
				var pos:Number = currentSpatial[motionMaster.axis];
				var offset:Number = current.distance;
				if(isNaN(offset) || offset <=0)
					offset = motionMaster.axis == "x"?currentSpatial.width: currentSpatial.height;
				if(motionMaster.direction == "+")
					offset = -offset;
				//making sure that nothing is getting messed up by repositioning the bg
				var delta:Number = motion[motionMaster.axis] - motion["previous"+motionMaster.axis.toUpperCase()];
				
				spatial[motionMaster.axis] = pos + offset + delta;
			}
			else
			{
				spatial[motionMaster.axis] = 0;
			}
			// create segment obstacles
			for(var i:int = 0; i < segment.obstacles.length; i++)
			{
				obstacle = segment.obstacles[i];
				if(pieces.hasOwnProperty(obstacle.obstacle))
				{
					pool = pieces[obstacle.obstacle];
				}
				else
				{
					pool = [];
					pieces[obstacle.obstacle] = pool;
				}
				if(pool.length > 0)
				{
					entity = pool.pop();
					obstacle.entity = entity;
				}
				else
				{
					clip = container[obstacle.obstacle];
					// do not want to swap so that we can keep reference to the asset to keep duplicating
					entity = BitmapTimelineCreator.createBitmapTimeline(clip, true, false);
					parent.addEntity(entity);
					entity.add(new LoopingSegmentPiece(motionMaster));
					motion = new Motion();
					motion.velocity[motionMaster.axis] = missleSpeed;
					motion.rotation = isNaN(obstacle.rotation)?0:obstacle.rotation;
					motion.rotationVelocity = isNaN(obstacle.rotationVelocity)?0:obstacle.rotationVelocity;
					entity.add(motion);
					hit = new MovieClipHit();
					var hitClip:DisplayObjectContainer = clip["hit"];//will use alternate hit box if there is one
					if(hitClip)
					{
						sprite = convertToBitmapSprite(hitClip, container, false).sprite;
						var hitOffset:Point = new Point(hitClip.x, hitClip.y);
						sprite.x = clip.x + hitOffset.x;
						sprite.y = clip.y + hitOffset.y;
						var hitEntity:Entity = EntityUtils.createSpatialEntity(this, sprite);
						var follow:FollowTarget = new FollowTarget(entity.get(Spatial),1,false,true);
						follow.offset = hitOffset;
						follow.properties.push("rotation");
						hitEntity.add(follow);
						hit.hitDisplay = sprite;
					}
					entity.add(hit);
					var count:int = 1;
					var checkId:String = clip.name;
					// increment the suffix until a unique id is found unless the original name has not been created yet
					while(parent.getEntityById(checkId)!= null)
					{
						checkId = clip.name + count;
						count++;
					}
					entity.add(new Id(checkId));
					obstacle.entity = entity;
				}
				
				position = entity.get(Spatial);
				var offsetX:Number = motionMaster.axis == "x"? spatial.width:0;
				var offsetY:Number = motionMaster.axis == "y"? spatial.height:0;
				
				if(motionMaster.axis == "x" && motionMaster.direction == "+")
					offsetX *= -1;
				if(motionMaster.axis == "y" && motionMaster.direction == "-")
					offsetY *= -1;
				
				position.x = spatial.x + offsetX + obstacle.position.x;
				position.y = spatial.y + offsetY + obstacle.position.y;
			}
			
			threshold.entered.addOnce(segmentCompleted);
		}
		
		private function segmentCompleted():void
		{
			// pool pieces
			var pool:Array = pieces[current.bgId];
			pool.push(current.entity);
			var obstacle:ObstacleData;
			for(var i:int = 0; i < current.obstacles.length; i++)
			{
				obstacle = current.obstacles[i];
				pool = pieces[obstacle.obstacle];
				pool.push(obstacle.entity);
			}
			current = next;
			index++;
			if(index < segments.length)
			{
				next = segments[index];
				initSegment(next);
			}
			else
			{
				motionMaster.active = false;
				trace("game complete");
				reachedEnd.dispatch();
				return;
			}
		}
	}
}
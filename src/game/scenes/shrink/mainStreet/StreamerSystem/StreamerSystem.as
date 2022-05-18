package game.scenes.shrink.mainStreet.StreamerSystem
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.PerformanceUtils;
	
	public class StreamerSystem extends GameSystem
	{
		public function StreamerSystem()
		{
			super(StreamerNode, updateNode);
			super._defaultPriority = SystemPriorities.render;
				
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
		}
		
//		private var frame:int = 0;
		
		public function updateNode(node:StreamerNode, time:Number):void
		{
			node.streamer.whipOffset += time * node.streamer.whipSpeed * Math.PI * 2;
			
			if(node.streamer.whipOffset > Math.PI * 2)
				node.streamer.whipOffset = 0;
			
//			++frame;
//			if(frame < updateRatio)
//				return;
//			frame = 0;
			
			var streamer:MovieClip = node.streamer.streamer;
			
			streamer.graphics.clear();
			
			streamer.graphics.lineStyle(1,node.streamer.lineColor);
			streamer.graphics.beginFill(node.streamer.streamerColor);
			
			var heightDifference:Number = node.streamer.ribbonStartHeight - node.streamer.ribbonEndHeight;
			var ribbonHeight:Number;
			var point:Point;
			var streamerRotation:Number = node.spatial.rotation + node.streamer.angleOfFixture - 90;
			//return;
			// creates the top line of the flag
			for(var forward:int = 0; forward < node.streamer.points.length; forward++)
			{
				point = node.streamer.points[forward];
				point.x = node.streamer.sectionWidth * forward;
				point.y = node.streamer.whipIntensity * Math.sin(forward / node.streamer.points.length * Math.PI * 2 * node.streamer.whips - node.streamer.whipOffset);
				
				ribbonHeight = node.streamer.ribbonStartHeight - (heightDifference * (forward + 1) / node.streamer.points.length);
				
				if(forward == 0)
				{
					// making the streamer look like it is fixed to a pole no matter the rotation
					streamer.graphics.moveTo(ribbonHeight / 2 * Math.sin(streamerRotation * Math.PI / 180), ribbonHeight / 2 * Math.cos(streamerRotation * Math.PI / 180));
				}
				else
					streamer.graphics.lineTo(point.x, point.y + ribbonHeight / 2 * Math.cos(streamerRotation * Math.PI / 180));
			}
			// creates the bottom line of the flag
			for(var back:int = node.streamer.points.length - 1; back >= 0; back--)
			{
				point = node.streamer.points[back];
				
				ribbonHeight = node.streamer.ribbonStartHeight - (heightDifference * (back + 1) / node.streamer.points.length);
				
				if(back == 0)
				{
					// making the streamer look like it is fixed to a pole no matter the rotation
					streamer.graphics.lineTo(-ribbonHeight / 2 * Math.sin(streamerRotation * Math.PI / 180), -ribbonHeight / 2 * Math.cos(streamerRotation * Math.PI / 180));
				}
				else
					streamer.graphics.lineTo(point.x, point.y - ribbonHeight / 2 * Math.cos(streamerRotation * Math.PI / 180));
			}
			streamer.graphics.endFill();
			
			// for when you want the streamer to look like it is blowing in a certain direction
			if(node.streamer.windDirectionOf == null)
				return;
			
			var dx:Number = node.streamer.windDirectionOf.x - node.spatial.x;
			var dy:Number = node.streamer.windDirectionOf.y - node.spatial.y;
			if(node.streamer.offSetByCamera)
			{
				dx += group.shellApi.camera.camera.viewportX;
				dy += group.shellApi.camera.camera.viewportY;
			}
			var rotation:Number = Math.atan2(dy, dx) * 180 / Math.PI;
			
			if(node.streamer.clampPositive)
			{
				if(rotation < 0 && rotation >= -90)
					rotation = 0;
				if(rotation < -90)
					rotation = 180;
			}
			
			//taking care of odd snapping issues when around 180 or -180
			if(rotation - node.spatial.rotation > 180)
				rotation -= 360;
			if(rotation - node.spatial.rotation < -180)
				rotation += 360;
			
			node.tween.to(node.spatial, 1/node.streamer.whipSpeed,{rotation:rotation});
		}
	}
}